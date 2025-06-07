//
//  StatusBarContentView.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import SwiftUI

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
                    
                    HStack(spacing: 8) {
                        Button(action: refreshEmulators) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                                .animation(.linear(duration: 1).repeatCount(isRefreshing ? .max : 1, autoreverses: false), value: isRefreshing)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Refresh emulator list")
                        
                        if emulatorManager.startingEmulators.count > 0 || emulatorManager.stoppingEmulators.count > 0 {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .progressViewStyle(CircularProgressViewStyle())
                                
                                Text("\(emulatorManager.startingEmulators.count + emulatorManager.stoppingEmulators.count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
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
                                isStarting: emulatorManager.startingEmulators.contains(emulator.name),
                                isStopping: emulatorManager.stoppingEmulators.contains(emulator.name),
                                onStart: { 
                                    Task {
                                        try? await emulatorManager.startEmulator(emulator)
                                    }
                                },
                                onStop: { 
                                    Task {
                                        try? await emulatorManager.stopEmulator(emulator)
                                    }
                                }
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
                          Color.gray.opacity(0.05))
            )
        }
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? 
                      Color(NSColor.windowBackgroundColor) : 
                      Color.white)
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
    
    private func refreshEmulators() {
        isRefreshing = true
        
        Task {
            await emulatorManager.refreshEmulators()
            
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    isRefreshing = false
                }
            }
        }
    }
} 
