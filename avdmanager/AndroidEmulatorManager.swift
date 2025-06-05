//
//  AndroidEmulatorManager.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import Foundation
import Combine

struct Emulator: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let isRunning: Bool
    let device: String
    let apiLevel: String
    let target: String
}

class AndroidEmulatorManager: ObservableObject {
    @Published var emulators: [Emulator] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadEmulators()
    }
    
    func loadEmulators() {
        isLoading = true
        
        Task {
            let availableEmulators = await getAvailableEmulators()
            let runningEmulatorNames = await getRunningEmulatorNames()
            
            await MainActor.run {
                self.emulators = availableEmulators.map { avd in
                    Emulator(
                        name: avd.name,
                        isRunning: runningEmulatorNames.contains(avd.name),
                        device: avd.device,
                        apiLevel: avd.apiLevel,
                        target: avd.target
                    )
                }
                self.isLoading = false
                
                // Debug: Print running emulator names
                print("Available emulators: \(availableEmulators.map { $0.name })")
                print("Running emulator names: \(runningEmulatorNames)")
            }
        }
    }
    
    func startEmulator(_ emulator: Emulator) {
        Task {
            await executeCommand("emulator", arguments: ["-avd", emulator.name], background: true)
            // Wait a moment then refresh the list
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await MainActor.run {
                self.loadEmulators()
            }
        }
    }
    
    func stopEmulator(_ emulator: Emulator) {
        Task {
            var stopped = false
            
            // Method 1: Try to stop via adb if device is found
            let runningDevices = await getRunningDevices()
            
            for device in runningDevices {
                if device.contains("emulator-") {
                    // Try to get the AVD name from this device
                    let avdName = await getAVDNameForDevice(device)
                    if avdName == emulator.name {
                        // Try multiple stop commands
                        await executeCommand("adb", arguments: ["-s", device, "emu", "kill"])
                        await executeCommand("adb", arguments: ["-s", device, "shell", "reboot", "-p"])
                        stopped = true
                        break
                    }
                }
            }
            
            // Method 2: If adb method didn't work, try killing the process directly
            if !stopped {
                let processOutput = await executeCommand("ps", arguments: ["aux"])
                let processLines = processOutput.components(separatedBy: .newlines)
                
                for line in processLines {
                    if line.contains("emulator") && line.contains("-avd") && line.contains(emulator.name) {
                        // Extract PID from ps output
                        let components = line.trimmingCharacters(in: .whitespacesAndNewlines)
                            .components(separatedBy: .whitespacesAndNewlines)
                            .filter { !$0.isEmpty }
                        
                        if components.count > 1 {
                            let pid = components[1] // PID is typically the second column
                            await executeCommand("kill", arguments: ["-TERM", pid])
                            // If TERM doesn't work, try KILL
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            await executeCommand("kill", arguments: ["-KILL", pid])
                            stopped = true
                            break
                        }
                    }
                }
            }
            
            // Method 3: If still not stopped, try pkill
            if !stopped {
                await executeCommand("pkill", arguments: ["-f", "emulator.*-avd.*\(emulator.name)"])
            }
            
            // Wait a moment then refresh the list
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                self.loadEmulators()
            }
        }
    }
    
    private func getAvailableEmulators() async -> [(name: String, device: String, apiLevel: String, target: String)] {
        let output = await executeCommand("emulator", arguments: ["-list-avds"])
        let lines = output.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var emulators: [(name: String, device: String, apiLevel: String, target: String)] = []
        
        for line in lines {
            let name = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Try to get config info from the AVD directory
            let configPath = "\(NSHomeDirectory())/.android/avd/\(name).avd/config.ini"
            let configContent = await readFile(at: configPath)
            
            let device = extractValue(from: configContent, key: "hw.device.name") ?? 
                        extractValue(from: configContent, key: "hw.device.manufacturer") ?? "Unknown Device"
            let apiLevel = extractValue(from: configContent, key: "image.sysdir.1")?.components(separatedBy: "/").last ?? "Unknown API"
            let target = extractValue(from: configContent, key: "target") ?? "Unknown Target"
            
            emulators.append((name: name, device: device, apiLevel: apiLevel, target: target))
        }
        
        return emulators
    }
    
    private func getRunningEmulatorNames() async -> Set<String> {
        // Method 1: Check running processes for emulator commands
        let processOutput = await executeCommand("ps", arguments: ["aux"])
        let processLines = processOutput.components(separatedBy: .newlines)
        
        var runningNames = Set<String>()
        
        for line in processLines {
            if line.contains("emulator") && line.contains("-avd") {
                // Extract AVD name from command line
                let components = line.components(separatedBy: " ")
                if let avdIndex = components.firstIndex(of: "-avd"),
                   avdIndex + 1 < components.count {
                    let avdName = components[avdIndex + 1]
                    runningNames.insert(avdName)
                }
            }
        }
        
        // Method 2: Also check via adb devices (fallback)
        let adbOutput = await executeCommand("adb", arguments: ["devices"])
        let adbLines = adbOutput.components(separatedBy: .newlines)
        
        for line in adbLines {
            if line.contains("emulator-") && line.contains("device") {
                let components = line.components(separatedBy: .whitespaces)
                if let deviceId = components.first, deviceId.hasPrefix("emulator-") {
                    // Try to get AVD name from the device
                    let avdName = await getAVDNameForDevice(deviceId)
                    if !avdName.isEmpty {
                        runningNames.insert(avdName)
                    }
                }
            }
        }
        
        return runningNames
    }
    
    private func getRunningDevices() async -> [String] {
        let output = await executeCommand("adb", arguments: ["devices"])
        let lines = output.components(separatedBy: .newlines)
        
        var devices: [String] = []
        
        for line in lines {
            if line.contains("emulator-") && line.contains("device") {
                let components = line.components(separatedBy: .whitespaces)
                if let deviceId = components.first, deviceId.hasPrefix("emulator-") {
                    devices.append(deviceId)
                }
            }
        }
        
        return devices
    }
    
    private func getAVDNameForDevice(_ deviceId: String) async -> String {
        // Try multiple methods to get the AVD name
        
        // Method 1: Use adb shell getprop
        let getpropOutput = await executeCommand("adb", arguments: ["-s", deviceId, "shell", "getprop", "ro.kernel.qemu.avd_name"])
        let cleanName = getpropOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanName.isEmpty && !cleanName.contains("error") && cleanName != "null" {
            return cleanName
        }
        
        // Method 2: Try emu avd name command
        let emuOutput = await executeCommand("adb", arguments: ["-s", deviceId, "emu", "avd", "name"])
        let emuName = emuOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        if !emuName.isEmpty && !emuName.contains("error") && !emuName.contains("OK") && emuName != "null" {
            return emuName
        }
        
        // Method 3: Try to extract from emulator console port
        if deviceId.hasPrefix("emulator-") {
            let portStr = String(deviceId.dropFirst("emulator-".count))
            if let port = Int(portStr) {
                let telnetOutput = await executeCommand("telnet", arguments: ["localhost", String(port + 1)])
                // This method is complex and might require authentication, so skip for now
            }
        }
        
        return ""
    }
    
    private func readFile(at path: String) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                do {
                    let content = try String(contentsOfFile: path, encoding: .utf8)
                    continuation.resume(returning: content)
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
    
    private func extractValue(from content: String, key: String) -> String? {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            if line.hasPrefix(key + "=") {
                return String(line.dropFirst((key + "=").count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }
    
    @discardableResult
    private func executeCommand(_ command: String, arguments: [String] = [], background: Bool = false) async -> String {
        return await withCheckedContinuation { continuation in
            let process = Process()
            let pipe = Pipe()
            
            process.standardOutput = pipe
            process.standardError = pipe
            process.arguments = arguments
            
            // Find the command in common paths
            let possiblePaths = [
                "/usr/local/bin/\(command)",
                "/opt/homebrew/bin/\(command)",
                "/usr/bin/\(command)",
                "\(NSHomeDirectory())/Library/Android/sdk/emulator/\(command)",
                "\(NSHomeDirectory())/Library/Android/sdk/tools/bin/\(command)",
                "\(NSHomeDirectory())/Library/Android/sdk/cmdline-tools/latest/bin/\(command)",
                "\(NSHomeDirectory())/Library/Android/sdk/platform-tools/\(command)",
                "\(NSHomeDirectory())/Android/Sdk/emulator/\(command)",
                "\(NSHomeDirectory())/Android/Sdk/tools/bin/\(command)",
                "\(NSHomeDirectory())/Android/Sdk/cmdline-tools/latest/bin/\(command)",
                "\(NSHomeDirectory())/Android/Sdk/platform-tools/\(command)"
            ]
            
            var commandPath: String?
            for path in possiblePaths {
                if FileManager.default.fileExists(atPath: path) {
                    commandPath = path
                    break
                }
            }
            
            // If not found in specific paths, try using 'which' command
            if commandPath == nil {
                let whichProcess = Process()
                whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
                whichProcess.arguments = [command]
                let whichPipe = Pipe()
                whichProcess.standardOutput = whichPipe
                
                do {
                    try whichProcess.run()
                    whichProcess.waitUntilExit()
                    let whichData = whichPipe.fileHandleForReading.readDataToEndOfFile()
                    let whichOutput = String(data: whichData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let whichOutput = whichOutput, !whichOutput.isEmpty {
                        commandPath = whichOutput
                    }
                } catch {
                    // Fallback to just the command name
                    commandPath = command
                }
            }
            
            process.executableURL = URL(fileURLWithPath: commandPath ?? command)
            
            do {
                try process.run()
                
                if background {
                    // For background processes (like starting emulator), don't wait
                    continuation.resume(returning: "")
                } else {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    
                    process.waitUntilExit()
                    continuation.resume(returning: output)
                }
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
} 