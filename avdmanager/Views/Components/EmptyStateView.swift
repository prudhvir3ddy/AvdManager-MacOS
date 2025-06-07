//
//  EmptyStateView.swift
//  avdmanager
//
//  Created by Mekala Prudhvi Reddy on 05/06/25.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "smartphone.slash")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                Text("No Emulators Found")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Create Android Virtual Devices using Android Studio\nor check your SDK configuration in Settings.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            Button("Open Settings") {
                // This will be handled by the parent view
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 60)
    }
} 