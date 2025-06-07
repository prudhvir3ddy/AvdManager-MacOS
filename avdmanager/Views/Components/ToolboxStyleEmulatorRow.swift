//
//  ToolboxStyleEmulatorRow.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import SwiftUI

struct ToolboxStyleEmulatorRow: View {
    let emulator: Emulator
    let isHovered: Bool
    let isLast: Bool
    let isStarting: Bool
    let isStopping: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Status Indicator
                ZStack {
                    Circle()
                        .fill(emulator.isRunning ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                    
                    if emulator.isRunning {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: emulator.isRunning)
                    }
                }
                
                // Emulator Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(emulator.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        if emulator.isRunning {
                            Text("RUNNING")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .clipShape(Capsule())
                        }
                    }
                    
                    HStack(spacing: 12) {
                        Text(emulator.device)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(emulator.apiDisplayText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action Button
                let shouldShowButton = emulator.isRunning || isHovered || isStarting || isStopping
                if shouldShowButton {
                    Button(action: emulator.isRunning ? onStop : onStart) {
                        HStack(spacing: 6) {
                            if isStarting || isStopping {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle())
                            } else {
                                Image(systemName: emulator.isRunning ? "stop.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            
                            Text(isStarting ? "Starting..." : 
                                 isStopping ? "Stopping..." :
                                 emulator.isRunning ? "Stop" : "Start")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(emulator.isRunning ? 
                                      Color.red.opacity(0.1) : 
                                      Color.blue.opacity(0.1))
                        )
                        .foregroundColor(emulator.isRunning ? .red : .blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(isStarting || isStopping)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(isHovered ? 
                          (colorScheme == .dark ? 
                           Color.white.opacity(0.05) : 
                           Color.black.opacity(0.03)) : 
                          Color.clear)
            )
            
            if !isLast {
                Divider()
                    .padding(.leading, 52)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
} 