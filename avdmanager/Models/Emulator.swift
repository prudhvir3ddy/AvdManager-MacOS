//
//  Emulator.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import Foundation

struct Emulator: Identifiable, Hashable, Codable {
    var id: String { name } // Use name as id for consistent tracking
    let name: String
    var isRunning: Bool  // Changed from 'let' to 'var' to allow updates
    let device: String
    let apiLevel: String
    let target: String
    
    // MARK: - Computed Properties
    var displayName: String {
        return name.isEmpty ? "Unknown Emulator" : name
    }
    
    var statusText: String {
        return isRunning ? "Running" : "Stopped"
    }
    
    var apiDisplayText: String {
        return "API \(apiLevel)"
    }
}

// MARK: - Extensions
extension Emulator {
    static let placeholder = Emulator(
        name: "Pixel_7_API_33",
        isRunning: false,
        device: "Pixel 7",
        apiLevel: "33",
        target: "Android 13.0"
    )
    
    static let runningPlaceholder = Emulator(
        name: "Pixel_5_API_31",
        isRunning: true,
        device: "Pixel 5",
        apiLevel: "31",
        target: "Android 12.0"
    )
} 