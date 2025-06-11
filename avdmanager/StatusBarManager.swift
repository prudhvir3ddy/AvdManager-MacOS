//
//  StatusBarManager.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import SwiftUI
import AppKit

class StatusBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    @ObservedObject private var emulatorManager = AndroidEmulatorManager()
    
    init() {
        setupStatusBar()
    }
    
    private func setupStatusBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "smartphone", accessibilityDescription: "Android Emulator Manager")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // Create popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 420, height: 520)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(
            rootView: StatusBarContentView(emulatorManager: emulatorManager)
        )
    }
    
    @objc private func statusBarButtonClicked() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            
            // Activate the app to bring popover to front
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func hidePopover() {
        popover?.performClose(nil)
    }
}

// MARK: - Status Bar Content View
struct StatusBarContentView: View {
    @ObservedObject var emulatorManager: AndroidEmulatorManager
    @Environment(\.colorScheme) var colorScheme
    @State private var hoveredEmulator: String? = nil
    @State private var isRefreshing = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section - JetBrains Toolbox Inspired
            VStack(spacing: 16) {
                // App Branding
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [Color.green.opacity(0.8), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "smartphone")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AVD Manager")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Android Virtual Devices")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: refreshEmulators) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(.linear(duration: 1).repeatCount(isRefreshing ? .max : 1, autoreverses: false), value: isRefreshing)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Refresh emulator list")
                }
                
                // Tab-like Section Header
                HStack {
                    HStack(spacing: 8) {
                        Text("Installed")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Text("\(emulatorManager.emulators.count)")
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    if !emulatorManager.emulators.isEmpty {
                        let runningCount = emulatorManager.emulators.filter { $0.isRunning }.count
                        if runningCount > 0 {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("\(runningCount) running")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? 
                          Color(NSColor.controlBackgroundColor).opacity(0.4) : 
                          Color.white.opacity(0.9))
            )
            
            // Content Section
            if emulatorManager.isLoading {
                LoadingView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if emulatorManager.emulators.isEmpty {
                EmptyStateView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(emulatorManager.emulators.enumerated()), id: \.element.id) { index, emulator in
                            ToolboxStyleEmulatorRow(
                                emulator: emulator,
                                isHovered: hoveredEmulator == emulator.name,
                                isLast: index == emulatorManager.emulators.count - 1,
                                onStart: { emulatorManager.startEmulator(emulator) },
                                onStop: { emulatorManager.stopEmulator(emulator) },
                                onColdStart: { emulatorManager.startEmulatorCold(emulator) } 
                            )
                            .onHover { isHovered in
                                hoveredEmulator = isHovered ? emulator.name : nil
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .background(Color.clear)
            }
            
            // Footer - Minimal like Toolbox
            Divider()
            
            HStack {
                Text("AVD Manager v1.0")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Settings") {
                    showingSettings = true
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .buttonStyle(PlainButtonStyle())
                
                Text("•")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.5))
                    .padding(.horizontal, 4)
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(colorScheme == .dark ? 
                          Color(NSColor.controlBackgroundColor).opacity(0.3) : 
                          Color.gray.opacity(0.03))
            )
        }
        .frame(width: 420, height: 520)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? 
                      Color(NSColor.windowBackgroundColor) : 
                      Color(NSColor.windowBackgroundColor))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func refreshEmulators() {
        isRefreshing = true
        emulatorManager.loadEmulators()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    

}

// MARK: - Toolbox Style Emulator Row
struct ToolboxStyleEmulatorRow: View {
    let emulator: Emulator
    let isHovered: Bool
    let isLast: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onColdStart: () -> Void
    
    @State private var showingMenu = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Emulator Icon - Android style
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            emulator.isRunning ? 
                            LinearGradient(colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.03)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "iphone.gen1")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(emulator.isRunning ? .green : .secondary)
                }
                
                // Emulator Information
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(emulator.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if emulator.isRunning {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("Running")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.green.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        
                        Spacer()
                    }
                    
                    // Device info in Toolbox style
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Text(emulator.device)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Text("API \(emulator.apiLevel)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Action Buttons - Toolbox style
                HStack(spacing: 8) {
                    if (emulator.isRunning) {
                        ToolboxActionButton(title: "Stop", isRunning: emulator.isRunning, action: onStop)
                    } else {
                        ToolboxActionButton(title: "Start", isRunning: emulator.isRunning, action: onStart)
                        ToolboxActionButton(title: "Cold Start", isRunning: emulator.isRunning, action: onColdStart)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(isHovered ? 
                          Color.primary.opacity(0.03) : 
                          Color.clear)
            )
            
            // Divider like Toolbox (except for last item)
            if !isLast {
                Divider()
                    .padding(.leading, 84) // Align with content, not icon
            }
        }
    }
}

// MARK: - Toolbox Action Button
struct ToolboxActionButton: View {
    let title: String
    let isRunning: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isRunning ? 
                            (isHovered ? Color.red.opacity(0.9) : Color.red) :
                            (isHovered ? Color.blue.opacity(0.9) : Color.blue)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0.0, to: 0.7)
                    .stroke(
                        LinearGradient(colors: [.blue, .green], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isAnimating)
            }
            
            Text("Loading emulators...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "iphone.gen1.slash")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.orange)
            }
            
            VStack(spacing: 12) {
                Text("No Android Emulators")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Create emulators in Android Studio\nto manage them here")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }
        }
        .padding(32)
    }
} 
