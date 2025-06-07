//
//  AVDManagerError.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import Foundation

enum AVDManagerError: LocalizedError {
    case sdkNotFound
    case emulatorNotFound(String)
    case commandExecutionFailed(String)
    case invalidConfiguration
    case permissionDenied
    case networkError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .sdkNotFound:
            return "Android SDK not found. Please check your SDK installation and path settings."
        case .emulatorNotFound(let name):
            return "Emulator '\(name)' not found or not accessible."
        case .commandExecutionFailed(let command):
            return "Failed to execute command: \(command)"
        case .invalidConfiguration:
            return "Invalid configuration detected. Please check your settings."
        case .permissionDenied:
            return "Permission denied. Please check file permissions and security settings."
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknownError(let message):
            return "An unknown error occurred: \(message)"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .sdkNotFound:
            return "The Android SDK path is not configured or the SDK is not installed properly."
        case .emulatorNotFound:
            return "The specified emulator does not exist in the AVD list."
        case .commandExecutionFailed:
            return "The system command failed to execute successfully."
        case .invalidConfiguration:
            return "The application configuration contains invalid values."
        case .permissionDenied:
            return "The application does not have sufficient permissions."
        case .networkError:
            return "A network-related error occurred."
        case .unknownError:
            return "An unexpected error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .sdkNotFound:
            return "Install Android SDK or update the SDK path in settings."
        case .emulatorNotFound:
            return "Create the emulator using Android Studio or verify the emulator name."
        case .commandExecutionFailed:
            return "Check system permissions and try again."
        case .invalidConfiguration:
            return "Reset settings to default values."
        case .permissionDenied:
            return "Grant necessary permissions to the application."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknownError:
            return "Restart the application or contact support."
        }
    }
} 