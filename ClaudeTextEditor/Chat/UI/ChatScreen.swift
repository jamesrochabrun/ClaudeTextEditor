//
//  ChatScreen.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import SwiftAnthropic
import SwiftUI

struct ChatScreen: View {
   
   init(viewModel: ChatConversationMCPViewModel) {
      self.viewModel = viewModel
   }
   
   private let viewModel: ChatConversationMCPViewModel
   @State private var userInput: String = ""
   
   var body: some View {
      VStack(spacing: 0) {
         // Chat message list
         ScrollViewReader { scrollProxy in
            ScrollView {
               LazyVStack(alignment: .leading, spacing: 12) {
                  ForEach(viewModel.messages) { msg in
                     MessageBubbleView(msg: msg)
                        .id(msg.id)
                  }
               }
               .padding()
            }
            .onChange(of: viewModel.messages.count) {
               // Scroll to bottom when messages are added
               if let lastId = viewModel.messages.last?.id {
                  withAnimation {
                     scrollProxy.scrollTo(lastId, anchor: .bottom)
                  }
               }
            }
         }
         .background(Color(NSColor.textBackgroundColor).opacity(0.5))
         
         Divider()
         
         // Tool result approval section - shown when Claude uses a tool
         if viewModel.waitingForToolResultApproval {
            VStack(alignment: .leading, spacing: 8) {
               Text("Claude used the text editor tool")
                  .font(.headline)
               
               if let pendingToolUse = viewModel.pendingToolUse {
                  Text("Tool: \(pendingToolUse.toolName)")
                     .foregroundColor(.secondary)
                     .font(.subheadline)
                  
                  Text("Result: \(pendingToolUse.isError ? "Error" : "Success")")
                     .foregroundColor(pendingToolUse.isError ? .red : .green)
                     .font(.subheadline)
               }
               
               HStack {
                  Button("Continue with this result") {
                     viewModel.continueConversationWithToolResult()
                  }
                  .keyboardShortcut(.defaultAction)
                  
                  Button("Cancel") {
                     viewModel.cancelToolExecution()
                  }
                  .keyboardShortcut(.cancelAction)
               }
               .padding(.top, 4)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
         }
         
         // User input area
         HStack {
            TextField("Type your message...", text: $userInput, axis: .vertical)
               .textFieldStyle(.roundedBorder)
               .lineLimit(1...5)
               .disabled(viewModel.waitingForToolResultApproval)
               .onKeyPress(.return) {
                  sendUserMessage()
                  return .handled
               }
            
            // Updated button that toggles between send and stop
            Button(action: {
               if viewModel.isStreaming {
                  viewModel.cancelStream()
               } else {
                  sendUserMessage()
               }
            }) {
               Image(systemName: viewModel.isStreaming ? "stop.fill" : "paperplane.fill")
                  .foregroundColor(viewModel.isStreaming ? .red : .accentColor)
            }
            .disabled(
               (!viewModel.isStreaming &&
                userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
               viewModel.waitingForToolResultApproval
            )
            .keyboardShortcut(.return, modifiers: [.command])
            .help(viewModel.isStreaming ? "Stop generation" : "Send message")
            .animation(.easeInOut, value: viewModel.isStreaming)
         }
         .padding()
         
         // Error message display
         if !viewModel.errorMessage.isEmpty {
            Text(viewModel.errorMessage)
               .foregroundColor(.red)
               .font(.callout)
               .padding([.horizontal, .bottom])
         }
      }
      .frame(minWidth: 700, minHeight: 500)
   }
   
   private func sendUserMessage() {
      let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedInput.isEmpty else { return }
      
      viewModel.sendUserMessage(trimmedInput)
      userInput = ""
   }
}
