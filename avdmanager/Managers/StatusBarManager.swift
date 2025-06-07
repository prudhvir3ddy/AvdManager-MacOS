//
//  StatusBarManager.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import SwiftUI
import AppKit
import Combine

final class StatusBarManager: StatusBarManaging {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private let emulatorManager: AndroidEmulatorManager
    
    init(emulatorManager: AndroidEmulatorManager = AndroidEmulatorManager()) {
        self.emulatorManager = emulatorManager
        // Ensure status bar setup happens on main thread
        DispatchQueue.main.async {
            self.setupStatusBar()
        }
    }
    
    // MARK: - StatusBarManaging Protocol
    
    func hidePopover() {
        popover?.performClose(nil)
    }
    
    // MARK: - Private Methods
    
    private func setupStatusBar() {
        guard statusItem == nil else { return } // Prevent double initialization
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let statusItem = statusItem else {
            print("Failed to create status bar item")
            return
        }
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "smartphone", accessibilityDescription: "Android Emulator Manager")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        } else {
            print("Failed to get status bar button")
            return
        }
        
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 420, height: 520)
        popover?.behavior = .transient
        popover?.animates = true
        
        let contentView = StatusBarContentView(emulatorManager: emulatorManager)
        popover?.contentViewController = NSHostingController(rootView: contentView)
    }
    
    @objc private func statusBarButtonClicked() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
} 