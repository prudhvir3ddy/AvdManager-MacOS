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
    @State private var showingFilePicker = false
    @State private var isValidPath = true
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Android SDK Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Android SDK")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SDK Path")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                TextField("Enter Android SDK path", text: $tempSDKPath)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: tempSDKPath) { newValue in
                                        validatePath(newValue)
                                    }
                                
                                Button("Browse") {
                                    showingFilePicker = true
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            if !isValidPath && !tempSDKPath.isEmpty {
                                Text("Invalid SDK path. Please select a valid Android SDK directory.")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            
                            Text("The Android SDK path should contain 'emulator' and 'platform-tools' directories.")
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Button("Auto-detect") {
                                let detectedPath = settingsManager.autoDetectAndroidSDK()
                                tempSDKPath = detectedPath
                                validatePath(detectedPath)
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Reset to Default") {
                                settingsManager.resetToDefaults()
                                tempSDKPath = settingsManager.androidSDKPath
                                isValidPath = true
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Apply") {
                                if isValidPath {
                                    settingsManager.setAndroidSDKPath(tempSDKPath)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!isValidPath || tempSDKPath == settingsManager.androidSDKPath)
                        }
                    }
                    .padding(.all, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    )
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Version:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("1.0.0")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("Build:")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text("1")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .padding(.all, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    )
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            tempSDKPath = settingsManager.androidSDKPath
            validatePath(tempSDKPath)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    tempSDKPath = url.path
                    validatePath(tempSDKPath)
                }
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
    }
    
    private func validatePath(_ path: String) {
        isValidPath = path.isEmpty || settingsManager.validateAndroidSDKPath(path)
    }
} 