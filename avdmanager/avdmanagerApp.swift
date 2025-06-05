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
}

@main
struct avdmanagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var statusBarManager = StatusBarManager()
    
    var body: some Scene {
        // Create an empty settings window to satisfy the Scene requirement
        Settings {
            EmptyView()
        }
    }
}
