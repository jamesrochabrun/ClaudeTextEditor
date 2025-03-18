//
//  ClaudeTextEditorApp.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import MCPSwiftWrapper
import SwiftUI

@main
struct ClaudeTextEditorApp: App {
   
   @State private var viewModel = ChatConversationMCPViewModel(
      service: {
         AnthropicServiceFactory.service(
            apiKey: "",
            betaHeaders: nil,
            debugEnabled: true)
      }()
   )
   
   private let claudeMCPclient = ClaudeCodeMCP()
   
   var body: some Scene {
      WindowGroup {
         ChatScreen(viewModel: viewModel)
            .toolbar(removing: .title)
            .containerBackground(
               .thinMaterial, for: .window)
            .toolbarBackgroundVisibility(
               .hidden, for: .windowToolbar)
            .task {
               if let client = try? await claudeMCPclient.getClientAsync() {
                  viewModel.updateClient(client)
               }
            }
      }
      .windowStyle(.hiddenTitleBar)
      .windowToolbarStyle(.unified)
   }
}
