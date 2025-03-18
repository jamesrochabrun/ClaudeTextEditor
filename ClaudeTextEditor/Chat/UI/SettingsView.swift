//
//  SettingsView.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/18/25.
//

import Foundation
import SwiftUI

struct SettingsView: View {
   @Environment(\.dismiss) private var dismiss
   @Environment(\.settingsManager) var settingsManager
   
   @State private var apiKey: String = ""
   @State private var showApiKey: Bool = false
   @State private var directoryPath: String = ""
   
   var body: some View {
      VStack(alignment: .leading, spacing: 20) {
         Text("Claude Text Editor Settings")
            .font(.title)
            .padding(.bottom, 10)
         
         Text("⚠️ You MUST restart the app for these changes to be applied!")
            .font(.subheadline)
            .padding(.bottom, 10)
         
         // API Key Section
         VStack(alignment: .leading, spacing: 10) {
            Text("Anthropic API Key")
               .font(.headline)
            
            HStack {
               if showApiKey {
                  TextField("Enter your API key", text: $apiKey)
                     .textFieldStyle(.roundedBorder)
               } else {
                  SecureField("Enter your API key", text: $apiKey)
                     .textFieldStyle(.roundedBorder)
               }
               
               Button(action: {
                  showApiKey.toggle()
               }) {
                  Image(systemName: showApiKey ? "eye.slash" : "eye")
                     .foregroundColor(.secondary)
               }
               .buttonStyle(.plain)
            }
            
            Text("Your API key is stored securely in Keychain")
               .font(.caption)
               .foregroundColor(.secondary)
         }
         .padding(.bottom, 10)
         
         // Directory Section
         VStack(alignment: .leading, spacing: 10) {
            Text("Claude Code Directory")
               .font(.headline)
            
            HStack {
               TextField("Root directory path", text: $directoryPath)
                  .textFieldStyle(.roundedBorder)
                  .disabled(true)
               
               Button("Browse...") {
                  selectDirectory()
               }
               .buttonStyle(.bordered)
            }
            
            Text("This directory will be used as the root for Claude Code operations")
               .font(.caption)
               .foregroundColor(.secondary)
         }
         
         Spacer()
         
         // Save Button
         HStack {
            Spacer()
            
            Button("Cancel") {
               dismiss()
            }
            .keyboardShortcut(.escape, modifiers: [])
            
            Button("Save") {
               saveSettings()
               dismiss()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .buttonStyle(.borderedProminent)
         }
      }
      .padding()
      .onAppear {
         loadSettings()
      }
   }
   
   private func loadSettings() {
      apiKey = settingsManager.apiKey
      directoryPath = settingsManager.rootDirectoryPath
   }
   
   private func saveSettings() {
      settingsManager.apiKey = apiKey
      settingsManager.rootDirectoryPath = directoryPath
   }
   
   private func selectDirectory() {
      let openPanel = NSOpenPanel()
      openPanel.canChooseFiles = false
      openPanel.canChooseDirectories = true
      openPanel.allowsMultipleSelection = false
      openPanel.canCreateDirectories = true
      
      if openPanel.runModal() == .OK {
         if let url = openPanel.url {
            directoryPath = url.path
         }
      }
   }
}

#Preview {
   SettingsView()
}
