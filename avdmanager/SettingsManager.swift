//
//  SettingsManager.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 06/06/25.
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var androidSDKPath: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let androidSDKPathKey = "androidSDKPath"
    
    private init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load Android SDK path from UserDefaults or auto-detect
        do {
            if let savedPath = userDefaults.string(forKey: androidSDKPathKey), !savedPath.isEmpty {
                androidSDKPath = savedPath
            } else {
                androidSDKPath = autoDetectAndroidSDK()
            }
        } catch {
            print("Error loading settings: \(error)")
            androidSDKPath = autoDetectAndroidSDK()
        }
    }
    
    func saveSettings() {
        do {
            userDefaults.set(androidSDKPath, forKey: androidSDKPathKey)
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    func setAndroidSDKPath(_ path: String) {
        androidSDKPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        saveSettings()
    }
    
    func validateAndroidSDKPath(_ path: String) -> Bool {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return false }
        
        // Check if the path exists and contains expected Android SDK components
        let fileManager = FileManager.default
        
        // Check for essential SDK directories/files
        let requiredPaths = [
            "\(trimmedPath)/emulator",
            "\(trimmedPath)/platform-tools",
            "\(trimmedPath)/tools",
            "\(trimmedPath)/cmdline-tools"
        ]
        
        // At least emulator and platform-tools should exist
        let emulatorExists = fileManager.fileExists(atPath: "\(trimmedPath)/emulator")
        let platformToolsExists = fileManager.fileExists(atPath: "\(trimmedPath)/platform-tools")
        
        return emulatorExists || platformToolsExists
    }
    
    func autoDetectAndroidSDK() -> String {
        let possiblePaths = [
            "\(NSHomeDirectory())/Library/Android/sdk",
            "\(NSHomeDirectory())/Android/Sdk",
            "/usr/local/android-sdk",
            "/opt/android-sdk",
            "/Applications/Android\\ Studio.app/Contents/android-sdk"
        ]
        
        for path in possiblePaths {
            if validateAndroidSDKPath(path) {
                return path
            }
        }
        
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
        
        // Try different possible locations
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
} 