//
//  ClaudeTextEditorApp.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import MCPSwiftWrapper
import SwiftUI
import SwiftAnthropic

@main
struct ClaudeTextEditorApp: App {
   
   @State private var viewModel: ChatConversationMCPViewModel
   @State private var showSettings = false
   @Environment(\.settingsManager) var settingsManager
   
   private var claudeMCPclient: ClaudeCodeMCP
   
   init() {      
      // Initialize view model with settings
      _viewModel = State(initialValue: ChatConversationMCPViewModel(
         service: {
            AnthropicServiceFactory.service(
               apiKey: "",
               betaHeaders: nil,
               debugEnabled: true)
         }()
      ))
      
      // Initialize MCP client
      self.claudeMCPclient = ClaudeCodeMCP(rootDirectory: nil)
   }
   
   var body: some Scene {
      WindowGroup {
         ChatScreen(viewModel: viewModel)
            .toolbar(removing: .title)
            .containerBackground(
               .thinMaterial, for: .window)
            .toolbarBackgroundVisibility(
               .hidden, for: .windowToolbar)
            .task {
               // Show settings immediately if API key is not set
               if settingsManager.apiKey.isEmpty {
                  showSettings = true
               }
               
               if let client = try? await claudeMCPclient.getClientAsync() {
                  viewModel.updateClient(client)
               }
            }
            .onChange(of: settingsManager.apiKey, initial: true) {
               updateServiceWithNewApiKey()
            }
            .onChange(of: settingsManager.rootDirectoryPath, initial: true) {
               updateClientWithNewRootDirectory()
            }
            .toolbar {
               ToolbarItem(placement: .primaryAction) {
                  Button(action: {
                     showSettings = true
                  }) {
                     Image(systemName: "gear")
                  }
               }
            }
            .sheet(isPresented: $showSettings) {
               SettingsView()
            }
      }
      .windowStyle(.hiddenTitleBar)
      .windowToolbarStyle(.unified)
      .commands {
         CommandGroup(replacing: .appSettings) {
            Button("Settings...") {
               showSettings = true
            }
            .keyboardShortcut(",", modifiers: .command)
         }
      }
   }
   
   /// Update the service when API key changes
   private func updateServiceWithNewApiKey() {
      viewModel = ChatConversationMCPViewModel(
         service: {
            AnthropicServiceFactory.service(
               apiKey: settingsManager.apiKey,
               betaHeaders: nil,
               debugEnabled: true)
         }()
      )
   }
   
   /// Restart MCP client when root directory changes
   private func updateClientWithNewRootDirectory() {
      Task {
         // Create a new client with the updated root directory
         let newClient = ClaudeCodeMCP(rootDirectory: settingsManager.rootDirectoryPath)
         
         // Get and update the client in the view model
         if let client = try? await newClient.getClientAsync() {
            viewModel.updateClient(client)
         }
      }
   }
}

extension EnvironmentValues {
   @Entry var settingsManager = SettingsManager()
}
