//
//  ClaudeTextEditorApp.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import SwiftUI
import MCPSwiftWrapper

@main
struct ClaudeTextEditorApp: App {
   
   
   init() {
     let service = AnthropicServiceFactory.service(apiKey: "", betaHeaders: nil, debugEnabled: true)

     // Uncomment this and comment the above for OpenAI Demo

     //      let openAIService = OpenAIServiceFactory.service(apiKey: "", debugEnabled: true)
     //
     //      let openAIChatNonStreamManager = OpenAIChatNonStreamManager(service: openAIService)
     //
     //      _chatManager = State(initialValue: openAIChatNonStreamManager)
   }

   private let claudeMCPclient = ClaudeCodeMCP()
   
   var body: some Scene {
      WindowGroup {
         ContentView()
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
               // Optional appearance customization for macOS app
               if let windowScene = NSApplication.shared.windows.first {
                  windowScene.title = "Claude Text Editor"
                  Task {
                     await print(try! claudeMCPclient.getClientAsync()?.anthropicTools())
                  }
               }
            }
      }
      .windowStyle(.titleBar)
      .windowToolbarStyle(.unified)
   }
}
