//
//  CommandService.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import Foundation

final class CommandService: CommandExecuting {
    static let shared = CommandService()
    
    private init() {}
    
    func executeCommand(_ command: String, arguments: [String], background: Bool = false) async -> String {
        return await withCheckedContinuation { continuation in
            let task = Process()
            let pipe = Pipe()
            
            task.standardOutput = pipe
            task.standardError = pipe
            
            // Use full path if available through settings, otherwise use system PATH
            if let fullPath = resolveCommandPath(command) {
                print("🔧 Using full path: \(fullPath)")
                task.executableURL = URL(fileURLWithPath: fullPath)
                task.arguments = arguments
            } else {
                print("🔧 Using system PATH for command: \(command)")
                task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                task.arguments = [command] + arguments
            }
            
            print("🔧 Executing: \(task.executableURL?.path ?? "unknown") \(task.arguments?.joined(separator: " ") ?? "")")
            
            do {
                try task.run()
                
                if background {
                    // For background processes, don't wait for completion
                    print("🔧 Background process started")
                    continuation.resume(returning: "")
                } else {
                    print("🔧 Waiting for process to complete...")
                    
                    // Add timeout protection (reduced to 10 seconds for faster feedback)
                    let timeoutTask = Task {
                        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                        if task.isRunning {
                            print("⚠️ Process timeout after 10s - terminating")
                            task.terminate()
                        }
                    }
                    
                    task.waitUntilExit()
                    timeoutTask.cancel()
                    
                    print("🔧 Process completed with exit code: \(task.terminationStatus)")
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8) ?? ""
                    print("🔧 Process output length: \(output.count) characters")
                    
                    continuation.resume(returning: output)
                }
            } catch {
                print("❌ Process execution failed: \(error.localizedDescription)")
                continuation.resume(returning: "Error: \(error.localizedDescription)")
            }
        }
    }
    
    func executeCommand(_ command: String, arguments: [String]) async -> String {
        return await executeCommand(command, arguments: arguments, background: false)
    }
    
    private func resolveCommandPath(_ command: String) -> String? {
        let settingsManager = SettingsManager.shared
        
        switch command {
        case "emulator":
            let path = settingsManager.getEmulatorPath()
            let exists = FileManager.default.fileExists(atPath: path)
            print("🔍 Emulator path: \(path) (exists: \(exists))")
            return exists ? path : nil
        case "adb":
            let path = settingsManager.getADBPath()
            let exists = FileManager.default.fileExists(atPath: path)
            print("🔍 ADB path: \(path) (exists: \(exists))")
            return exists ? path : nil
        case "avdmanager":
            let path = settingsManager.getAVDManagerPath()
            let exists = FileManager.default.fileExists(atPath: path)
            print("🔍 AVDManager path: \(path) (exists: \(exists))")
            return exists ? path : nil
        default:
            return nil
        }
    }
    
    func readFile(at path: String) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                do {
                    let content = try String(contentsOfFile: path, encoding: .utf8)
                    continuation.resume(returning: content)
                } catch {
                    continuation.resume(returning: "")
                }
            }
        }
    }
} 