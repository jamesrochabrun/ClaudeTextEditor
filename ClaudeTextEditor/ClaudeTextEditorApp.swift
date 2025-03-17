//
//  ClaudeTextEditorApp.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import SwiftUI

@main
struct ClaudeTextEditorApp: App {
   var body: some Scene {
      WindowGroup {
         ContentView()
            .frame(minWidth: 800, minHeight: 600)
            .onAppear {
               // Optional appearance customization for macOS app
               if let windowScene = NSApplication.shared.windows.first {
                  windowScene.title = "Claude Text Editor"
               }
            }
      }
      .windowStyle(.titleBar)
      .windowToolbarStyle(.unified)
   }
}
