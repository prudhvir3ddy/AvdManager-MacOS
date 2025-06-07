//
//  SettingsManager.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 06/06/25.
//

import Foundation
import Combine

final class SettingsManager: SettingsManaging {
    static let shared = SettingsManager()
    
    @Published var androidSDKPath: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let androidSDKPathKey = "androidSDKPath"
    
    private init() {
        loadSettings()
    }
    
    // MARK: - SettingsManaging Protocol
    
    func validateAndroidSDKPath(_ path: String) -> Bool {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return false }
        
        let fileManager = FileManager.default
        
        // Check for essential SDK executables
        let emulatorExists = fileManager.fileExists(atPath: "\(trimmedPath)/emulator/emulator")
        let adbExists = fileManager.fileExists(atPath: "\(trimmedPath)/platform-tools/adb")
        
        print("🔍 Validating SDK path: \(trimmedPath)")
        print("🔍 Emulator exists: \(emulatorExists) at \(trimmedPath)/emulator/emulator")
        print("🔍 ADB exists: \(adbExists) at \(trimmedPath)/platform-tools/adb")
        
        return emulatorExists && adbExists
    }
    
    func autoDetectAndroidSDK() -> String {
        let possiblePaths = [
            "\(NSHomeDirectory())/Library/Android/sdk",
            "\(NSHomeDirectory())/Android/Sdk",
            "/usr/local/android-sdk",
            "/opt/android-sdk",
            "/Applications/Android Studio.app/Contents/android-sdk"
        ]
        
        print("🔍 Auto-detecting Android SDK...")
        for path in possiblePaths {
            print("🔍 Checking: \(path)")
            if validateAndroidSDKPath(path) {
                print("✅ Found Android SDK at: \(path)")
                return path
            }
        }
        
        print("❌ Android SDK not found in any common location")
        return ""
    }
    
    func getEmulatorPath() -> String {
        guard !androidSDKPath.isEmpty else { return "emulator" }
        return "\(androidSDKPath)/emulator/emulator"
    }
    
    func getADBPath() -> String {
        guard !androidSDKPath.isEmpty else { return "adb" }
        return "\(androidSDKPath)/platform-tools/adb"
    }
    
    func getAVDManagerPath() -> String {
        guard !androidSDKPath.isEmpty else { return "avdmanager" }
        
        let possiblePaths = [
            "\(androidSDKPath)/cmdline-tools/latest/bin/avdmanager",
            "\(androidSDKPath)/tools/bin/avdmanager"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return "avdmanager"
    }
    
    func resetToDefaults() {
        androidSDKPath = autoDetectAndroidSDK()
        saveSettings()
    }
    
    func saveSettings() {
        userDefaults.set(androidSDKPath, forKey: androidSDKPathKey)
    }
    
    // MARK: - Public Methods
    
    func setAndroidSDKPath(_ path: String) {
        androidSDKPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        saveSettings()
    }
    
    // MARK: - Private Methods
    
    private func loadSettings() {
        if let savedPath = userDefaults.string(forKey: androidSDKPathKey), !savedPath.isEmpty {
            androidSDKPath = savedPath
        } else {
            androidSDKPath = autoDetectAndroidSDK()
        }
        
        print("🔧 SettingsManager loaded SDK path: '\(androidSDKPath)'")
        print("🔧 Emulator path: '\(getEmulatorPath())'")
        print("🔧 ADB path: '\(getADBPath())'")
    }
} 