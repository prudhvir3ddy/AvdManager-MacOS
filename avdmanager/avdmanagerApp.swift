//
//  avdmanagerApp.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon and make it a status bar accessory
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}

@main
struct avdmanagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var emulatorManager: AndroidEmulatorManager
    @StateObject private var statusBarManager: StatusBarManager
    
    init() {
        // Create the emulator manager first
        let emulatorManager = AndroidEmulatorManager()
        // Create the status bar manager with the same emulator manager instance
        let statusBarManager = StatusBarManager(emulatorManager: emulatorManager)
        
        // Use the same instances for StateObject
        self._emulatorManager = StateObject(wrappedValue: emulatorManager)
        self._statusBarManager = StateObject(wrappedValue: statusBarManager)
    }
    
    var body: some Scene {
        // Create an empty settings window to satisfy the Scene requirement
        Settings {
            EmptyView()
        }
    }
}
