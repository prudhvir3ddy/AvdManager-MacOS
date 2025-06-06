//
//  SettingsView.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 06/06/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var tempSDKPath: String = ""
    @State private var showFileImporter = false
    @State private var isValidPath = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            // Android SDK Path Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Android SDK Path", systemImage: "folder")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Auto-detect") {
                        let detectedPath = settingsManager.autoDetectAndroidSDK()
                        if !detectedPath.isEmpty {
                            tempSDKPath = detectedPath
                            updateSDKPath()
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Text("Specify the path to your Android SDK installation")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Enter Android SDK path...", text: $tempSDKPath)
                        .textFieldStyle(.roundedBorder)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isValidPath ? Color.clear : Color.red, lineWidth: 1)
                        )
                        .onSubmit {
                            updateSDKPath()
                        }
                    
                    Button("Browse...") {
                        showFileImporter = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                if !isValidPath {
                    Text("Invalid Android SDK path. Please ensure the path contains emulator and platform-tools directories.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if !settingsManager.androidSDKPath.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current SDK Tools:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Emulator:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(settingsManager.getEmulatorPath())
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("ADB:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(settingsManager.getADBPath())
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("AVD Manager:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(settingsManager.getAVDManagerPath())
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.top, 8)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            Spacer()
            
            // Reset Section
            HStack {
                Spacer()
                
                Button("Reset to Defaults") {
                    settingsManager.resetToDefaults()
                    tempSDKPath = settingsManager.androidSDKPath
                    isValidPath = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(24)
        .frame(width: 500, height: 400)
        .onAppear {
            tempSDKPath = settingsManager.androidSDKPath
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    tempSDKPath = url.path
                    updateSDKPath()
                }
            case .failure(let error):
                print("File selection error: \(error)")
            }
        }
    }
    
    private func updateSDKPath() {
        isValidPath = tempSDKPath.isEmpty || settingsManager.validateAndroidSDKPath(tempSDKPath)
        
        if isValidPath {
            settingsManager.setAndroidSDKPath(tempSDKPath)
        }
    }
} 
