//
//  AndroidEmulatorManager.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import Foundation
import Combine

final class AndroidEmulatorManager: EmulatorManaging {
    @Published var emulators: [Emulator] = []
    @Published var isLoading = false
    @Published var startingEmulators: Set<String> = []
    @Published var stoppingEmulators: Set<String> = []
    
    private var cancellables = Set<AnyCancellable>()
    private let commandService: CommandExecuting
    private let settingsManager: any SettingsManaging
    private var statusUpdateTimer: Timer?
    
    init(commandService: CommandExecuting = CommandService.shared,
         settingsManager: SettingsManaging = SettingsManager.shared) {
        self.commandService = commandService
        self.settingsManager = settingsManager
        
        // Force SDK path detection if not set
        if settingsManager.androidSDKPath.isEmpty {
            print("🔧 SDK path empty, forcing auto-detection...")
            settingsManager.resetToDefaults()
        }
        
        Task {
            await loadEmulators()
        }
        
        // Start periodic status updates
        startPeriodicStatusUpdates()
    }
    
    deinit {
        statusUpdateTimer?.invalidate()
    }
    
    // MARK: - EmulatorManaging Protocol
    
    func loadEmulators() async {
        await MainActor.run {
            isLoading = true
        }
        
        // Add timeout to prevent hanging forever
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds timeout
            await MainActor.run {
                if self.isLoading {
                    print("⏰ Loading timeout - resetting state")
                    self.isLoading = false
                    // Show some default emulators on timeout
                    self.emulators = [
                        Emulator(
                            name: "Timeout_Check_SDK_Config",
                            isRunning: false,
                            device: "SDK Configuration Needed",
                            apiLevel: "??",
                            target: "Check Android SDK Setup"
                        )
                    ]
                }
            }
        }
        
        print("📱 Loading emulators...")
        
        // Remove the try-catch since getAvailableEmulators doesn't throw
        print("🔍 Getting available emulators...")
        let availableEmulators = await getAvailableEmulators()
        print("✅ Found \(availableEmulators.count) available emulators: \(availableEmulators.map { $0.name })")
        
        // Cancel timeout task since we completed successfully
        timeoutTask.cancel()
        
        if availableEmulators.isEmpty {
            await MainActor.run {
                self.isLoading = false
                // Add some placeholder emulators for debugging
                self.emulators = [
                    Emulator(
                        name: "No_Emulators_Found",
                        isRunning: false,
                        device: "Check Android SDK",
                        apiLevel: "??",
                        target: "Create AVDs in Android Studio"
                    )
                ]
                print("🔧 No emulators found - added debug emulator")
            }
            return
        }
        
        // STEP 1: Show emulators immediately (assume none running for speed)
        await MainActor.run {
            self.emulators = availableEmulators.map { avd in
                Emulator(
                    name: avd.name,
                    isRunning: false, // Start with false, update in background
                    device: avd.device,
                    apiLevel: avd.apiLevel,
                    target: avd.target
                )
            }
            self.isLoading = false
            print("✅ Emulator loading completed FAST. Total: \(self.emulators.count)")
        }
        
        // STEP 2: Check running status in background (don't block UI)
        await updateRunningStatus()
    }
    
    func startEmulator(_ emulator: Emulator) async throws {
        await MainActor.run {
            startingEmulators.insert(emulator.name)
        }
        
        defer {
            Task { @MainActor in
                startingEmulators.remove(emulator.name)
            }
        }
        
        let result = await commandService.executeCommand("emulator", arguments: ["-avd", emulator.name], background: true)
        
        if result.contains("Error") {
            throw AVDManagerError.commandExecutionFailed("emulator -avd \(emulator.name)")
        }
        
        // Optimistically update the emulator status immediately
        await MainActor.run {
            if let index = self.emulators.firstIndex(where: { $0.name == emulator.name }) {
                self.emulators[index].isRunning = true
                print("✅ Optimistically set \(emulator.name) as running")
            }
        }
        
        // Verify the status in background and correct if needed
        Task {
            // Wait a bit for emulator to fully start
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            
            // Verify the actual status
            let runningNames = await getRunningEmulatorNames()
            let isActuallyRunning = runningNames.contains(emulator.name)
            
            await MainActor.run {
                if let index = self.emulators.firstIndex(where: { $0.name == emulator.name }) {
                    self.emulators[index].isRunning = isActuallyRunning
                    print("🔄 Verified \(emulator.name) status: \(isActuallyRunning)")
                }
            }
            
            // If not detected yet, keep checking for a bit longer
            if !isActuallyRunning {
                for attempt in 1...3 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds per attempt
                    let updatedRunningNames = await getRunningEmulatorNames()
                    if updatedRunningNames.contains(emulator.name) {
                        await MainActor.run {
                            if let index = self.emulators.firstIndex(where: { $0.name == emulator.name }) {
                                self.emulators[index].isRunning = true
                                print("✅ Verified \(emulator.name) is running after attempt \(attempt)")
                            }
                        }
                        return
                    }
                    print("Attempt \(attempt): Emulator \(emulator.name) not detected yet...")
                }
            }
        }
    }
    
    func stopEmulator(_ emulator: Emulator) async throws {
        await MainActor.run {
            stoppingEmulators.insert(emulator.name)
        }
        
        defer {
            Task { @MainActor in
                stoppingEmulators.remove(emulator.name)
            }
        }
        
        var stopped = false
        
        // Method 1: Try to stop via adb if device is found
        let runningDevices = await getRunningDevices()
        
        for device in runningDevices {
            if device.contains("emulator-") {
                let avdName = await getAVDNameForDevice(device)
                if avdName == emulator.name {
                    await commandService.executeCommand("adb", arguments: ["-s", device, "emu", "kill"])
                    await commandService.executeCommand("adb", arguments: ["-s", device, "shell", "reboot", "-p"])
                    stopped = true
                    break
                }
            }
        }
        
        // Method 2: If adb method didn't work, try killing the process directly
        if !stopped {
            let processOutput = await commandService.executeCommand("ps", arguments: ["aux"])
            let processLines = processOutput.components(separatedBy: .newlines)
            
            for line in processLines {
                if line.contains("emulator") && line.contains("-avd") && line.contains(emulator.name) {
                    let components = line.trimmingCharacters(in: .whitespacesAndNewlines)
                        .components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }
                    
                    if components.count > 1 {
                        let pid = components[1]
                        await commandService.executeCommand("kill", arguments: ["-TERM", pid])
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        await commandService.executeCommand("kill", arguments: ["-KILL", pid])
                        stopped = true
                        break
                    }
                }
            }
        }
        
        // Method 3: If still not stopped, try pkill
        if !stopped {
            await commandService.executeCommand("pkill", arguments: ["-f", "emulator.*-avd.*\(emulator.name)"])
        }
        
        // Optimistically update the emulator status immediately
        await MainActor.run {
            if let index = self.emulators.firstIndex(where: { $0.name == emulator.name }) {
                self.emulators[index].isRunning = false
                print("✅ Optimistically set \(emulator.name) as stopped")
            }
        }
        
        // Wait a moment then verify the status
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await updateRunningStatus()
    }
    
    func refreshEmulators() async {
        await loadEmulators()
    }
    
    // Force reset loading state - useful for debugging
    func forceResetState() {
        Task { @MainActor in
            isLoading = false
            startingEmulators.removeAll()
            stoppingEmulators.removeAll()
            print("🔄 Force reset state completed")
        }
    }
    
    // MARK: - Private Status Update Methods
    
    private func startPeriodicStatusUpdates() {
        DispatchQueue.main.async { [weak self] in
            self?.statusUpdateTimer?.invalidate()
            
            // Update every 5 seconds to keep the status fresh
            self?.statusUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
                Task { [weak self] in
                    await self?.updateRunningStatus()
                }
            }
            
            // Ensure the timer is added to the main run loop
            if let timer = self?.statusUpdateTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
            print("✅ Started periodic status updates every 5 seconds")
        }
    }
    
    private func updateRunningStatus() async {
        guard !emulators.isEmpty else { 
            print("⚠️ No emulators to check status for")
            return 
        }
        
        print("🏃 Checking running emulators in background...")
        print("🏃 Current emulators: \(emulators.map { "\($0.name):\($0.isRunning)" })")
        
        let runningEmulatorNames = await getRunningEmulatorNames()
        print("✅ Found \(runningEmulatorNames.count) running emulators: \(runningEmulatorNames)")
        
        await MainActor.run {
            var hasChanges = false
            
            // Update running status
            for i in 0..<self.emulators.count {
                let wasRunning = self.emulators[i].isRunning
                let isNowRunning = runningEmulatorNames.contains(self.emulators[i].name)
                
                if wasRunning != isNowRunning {
                    self.emulators[i].isRunning = isNowRunning
                    hasChanges = true
                    print("🔄 Status changed for \(self.emulators[i].name): \(wasRunning) → \(isNowRunning)")
                }
            }
            
            if hasChanges {
                print("✅ Updated running status for emulators - UI should refresh now")
                // Force UI update by triggering objectWillChange
                self.objectWillChange.send()
            } else {
                print("📝 No status changes detected")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func getAvailableEmulators() async -> [(name: String, device: String, apiLevel: String, target: String)] {
        print("🔧 Getting available emulators (FAST MODE)...")
        
        print("🔧 Executing: emulator -list-avds")
        let output = await commandService.executeCommand("emulator", arguments: ["-list-avds"])
        print("📝 Emulator list output: '\(output)'")
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        print("📋 Found \(lines.count) emulator lines")
        
        var emulators: [(name: String, device: String, apiLevel: String, target: String)] = []
        
        if lines.isEmpty {
            print("❌ No emulators found via 'emulator -list-avds'")
            return []
        }
        
        // FAST MODE: Just return basic info, no detailed parsing
        for line in lines {
            let name = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to extract basic info from the name if possible
            var apiLevel = "Unknown"
            var device = "Android Device"
            
            // Quick API level extraction from common naming patterns
            if name.contains("API_") {
                let components = name.components(separatedBy: "_")
                for (index, component) in components.enumerated() {
                    if component == "API", index + 1 < components.count {
                        apiLevel = components[index + 1]
                        break
                    }
                }
            }
            
            // Quick device type detection
            if name.lowercased().contains("phone") {
                device = "Phone"
            } else if name.lowercased().contains("tablet") {
                device = "Tablet"
            } else if name.lowercased().contains("tv") {
                device = "TV"
            } else if name.lowercased().contains("wear") {
                device = "Wear OS"
            }
            
            emulators.append((
                name: name,
                device: device,
                apiLevel: apiLevel,
                target: "Android \(apiLevel)"
            ))
        }
        
        print("✅ Returning \(emulators.count) emulators (FAST)")
        return emulators
    }
    
    private func getRunningEmulatorNames() async -> Set<String> {
        print("🔧 Checking running emulators (FAST MODE)...")
        var runningNames: Set<String> = []
        
        // FAST METHOD: Only check adb devices (skip heavy ps aux)
        let devices = await getRunningDevices() 
        print("📱 Found \(devices.count) connected devices")
        
        for device in devices {
            if device.contains("emulator-") {
                let avdName = await getAVDNameForDevice(device)
                print("📱 Device \(device) → AVD: \(avdName)")
                if !avdName.isEmpty {
                    runningNames.insert(avdName)
                }
            }
        }
        
        print("✅ Found \(runningNames.count) running emulators via adb")
        return runningNames
    }
    
    private func getRunningDevices() async -> [String] {
        print("🔧 Executing 'adb devices'...")
        let output = await commandService.executeCommand("adb", arguments: ["devices"])
        print("📝 ADB devices output: '\(output)'")
        
        let lines = output.components(separatedBy: .newlines)
        var devices: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            print("📝 Processing line: '\(trimmed)'")
            
            if trimmed.contains("\t") && trimmed.contains("device") {
                let deviceId = trimmed.components(separatedBy: "\t")[0]
                devices.append(deviceId)
                print("📱 Found device: '\(deviceId)'")
            }
        }
        
        print("📱 Total devices found: \(devices.count)")
        return devices
    }
    
    private func getAVDNameForDevice(_ device: String) async -> String {
        let output = await commandService.executeCommand("adb", arguments: ["-s", device, "emu", "avd", "name"])
        let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Parse the output - adb emu avd name returns the name followed by "OK"
        let lines = trimmed.components(separatedBy: .newlines)
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleanLine.isEmpty && cleanLine != "OK" {
                print("📱 Parsed AVD name: '\(cleanLine)' from device \(device)")
                return cleanLine
            }
        }
        
        print("⚠️ Could not parse AVD name from output: '\(trimmed)'")
        return ""
    }
    
    // MARK: - Parsing Helpers
    
    private func parseAVDManagerOutput(_ output: String) -> [String: (device: String, apiLevel: String, target: String)] {
        var avdDetails: [String: (device: String, apiLevel: String, target: String)] = [:]
        
        let lines = output.components(separatedBy: .newlines)
        var currentAVD: String?
        var currentDevice = "Unknown Device"
        var currentAPI = "Unknown"
        var currentTarget = "Android"
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.hasPrefix("Name:") {
                currentAVD = String(trimmedLine.dropFirst("Name:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("Device:") {
                currentDevice = String(trimmedLine.dropFirst("Device:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedLine.hasPrefix("Target:") {
                let targetString = String(trimmedLine.dropFirst("Target:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                currentTarget = targetString
                
                if let apiRange = targetString.range(of: "API Level ") {
                    let apiSubstring = targetString[apiRange.upperBound...]
                    let apiComponents = apiSubstring.components(separatedBy: " ")
                    if let firstComponent = apiComponents.first, Int(firstComponent) != nil {
                        currentAPI = firstComponent
                    }
                }
            } else if trimmedLine.contains("---------") && currentAVD != nil {
                if let avdName = currentAVD {
                    avdDetails[avdName] = (device: currentDevice, apiLevel: currentAPI, target: currentTarget)
                }
                currentAVD = nil
                currentDevice = "Unknown Device"
                currentAPI = "Unknown"
                currentTarget = "Android"
            }
        }
        
        return avdDetails
    }
    
    private func extractDeviceName(from configContent: String) -> String {
        let lines = configContent.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("hw.device.name=") {
                return String(line.dropFirst("hw.device.name=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return "Unknown Device"
    }
    
    private func extractAPILevel(from configContent: String, avdName: String) -> String {
        let lines = configContent.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("target=") {
                let target = String(line.dropFirst("target=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                if let apiRange = target.range(of: "android-") {
                    let apiSubstring = target[apiRange.upperBound...]
                    return String(apiSubstring)
                }
            }
        }
        return "Unknown"
    }
    
    private func extractTarget(from configContent: String, avdName: String) -> String {
        let lines = configContent.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix("target=") {
                return String(line.dropFirst("target=".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return "Android"
    }
} 
