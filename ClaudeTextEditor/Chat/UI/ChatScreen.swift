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
   @FocusState private var textFieldFocused: Bool
   
   var body: some View {
      VStack(spacing: 0) {
         // Chat message list
         ScrollViewReader { scrollProxy in
            ScrollView {
               LazyVStack(alignment: .leading, spacing: 12) {
                  ForEach(Array(viewModel.messages.enumerated()), id: \.element.id) { index, msg in
                     MessageBubbleView(
                        msg: msg,
                        isLoading: viewModel.isStreaming ||
                        // For tool use messages, show loading when we're waiting for approval
                        (msg.role == .toolUse && viewModel.waitingForToolResultApproval) ||
                        // For the last message in any context, show loading during tool execution
                        (index == viewModel.messages.count - 1 && viewModel.waitingForToolResultApproval),
                        isLastMessage: index == viewModel.messages.count - 1
                     )
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
         VStack(spacing: 0) {
            // Custom text input area with growing capability
            HStack(alignment: .bottom) {
               // Enhanced text field with dynamic height
               TextEditor(text: $userInput)
                  .frame(minHeight: 36, maxHeight: 100)
                  .padding(8)
                  .background(Color(NSColor.textBackgroundColor))
                  .cornerRadius(8)
                  .overlay(
                     RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                  )
                  .font(.body)
                  .disabled(viewModel.waitingForToolResultApproval)
                  .opacity(viewModel.waitingForToolResultApproval ? 0.6 : 1.0)
               // Simple configuration for the text editor
                  .submitLabel(.send)
                  .focused($textFieldFocused)
                  .onKeyPress(.return) {
                     if viewModel.isStreaming {
                        viewModel.cancelStream()
                     } else {
                        sendUserMessage()
                     }
                     return .handled
                  }
                  .overlay(
                     // Placeholder text that appears when input is empty
                     Group {
                        if userInput.isEmpty {
                           Text("Type your message...")
                              .foregroundColor(Color.secondary)
                              .padding(.leading, 12)
                              .padding(.top, 10)
                              .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        }
                     }
                  )
               
               // Send/Stop button
               Button(action: {
                  if viewModel.isStreaming {
                     viewModel.cancelStream()
                  } else {
                     sendUserMessage()
                  }
               }) {
                  Image(systemName: viewModel.isStreaming ? "stop.fill" : "paperplane.fill")
                     .font(.system(size: 16, weight: .semibold))
                     .frame(width: 36, height: 36)
                     .background(
                        Circle()
                           .fill(viewModel.isStreaming ? Color.red.opacity(0.9) : Color.accentColor)
                     )
                     .foregroundColor(.white)
               }
               .buttonStyle(.plain)
               .disabled(
                  (!viewModel.isStreaming &&
                   userInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ||
                  viewModel.waitingForToolResultApproval
               )
               // Using Return/Enter shortcut to send message
               // .keyboardShortcut(.return, modifiers: [])
               .help(viewModel.isStreaming ? "Stop generation" : "Send message")
               .animation(.easeInOut, value: viewModel.isStreaming)
               .padding(.bottom, 4)
            }
            
            // Helper text showing keyboard shortcuts
            HStack {
               Text("Press ↩︎ to send")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                  .padding(.leading, 8)
                  .padding(.top, 4)
               Spacer()
            }
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
      .onAppear {
         // Set focus to the text field when the view appears
         textFieldFocused = true
      }
   }
   
   private func sendUserMessage() {
      let trimmedInput = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmedInput.isEmpty else { return }
      
      // Send message and clear input field
      viewModel.sendUserMessage(trimmedInput)
      userInput = ""
      
      // Maintain focus on the text field after sending
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
         textFieldFocused = true
      }
   }
}

