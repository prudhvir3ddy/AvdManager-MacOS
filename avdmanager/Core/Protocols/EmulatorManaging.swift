//
//  EmulatorManaging.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import Foundation
import Combine

protocol EmulatorManaging: ObservableObject {
    var emulators: [Emulator] { get }
    var isLoading: Bool { get }
    
    func loadEmulators() async
    func startEmulator(_ emulator: Emulator) async throws
    func stopEmulator(_ emulator: Emulator) async throws
    func refreshEmulators() async
}

protocol CommandExecuting {
    func executeCommand(_ command: String, arguments: [String], background: Bool) async -> String
    func executeCommand(_ command: String, arguments: [String]) async -> String
}

protocol SettingsManaging: ObservableObject {
    var androidSDKPath: String { get set }
    
    func validateAndroidSDKPath(_ path: String) -> Bool
    func autoDetectAndroidSDK() -> String
    func getEmulatorPath() -> String
    func getADBPath() -> String
    func getAVDManagerPath() -> String
    func resetToDefaults()
    func saveSettings()
}

protocol StatusBarManaging: ObservableObject {
    func hidePopover()
} 