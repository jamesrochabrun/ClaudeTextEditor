//
//  MessageBubbleView.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import Foundation
import MarkdownUI
import SwiftUI

struct MessageBubbleView: View {
   
   let msg: ChatMessage
   var isLoading: Bool = false
   var isLastMessage: Bool = false
   
   @Environment(\.colorScheme) private var colorScheme
   
   var body: some View {
      HStack(alignment: .top, spacing: 8) {
         // Left avatar/icon column
         avatarView
            .frame(width: 32, height: 32)
            .background(avatarBackground)
            .clipShape(Circle())
            .overlay(
               Circle()
                  .stroke(avatarBorderColor, lineWidth: 1.5)
            )
         
         // Right content column
         VStack(alignment: .leading, spacing: 4) {
            // Header with role name and loading indicator
            HStack {
               Text(roleName)
                  .fontWeight(.semibold)
                  .foregroundColor(roleColor)
               
               if showLoadingIndicator {
                  LoadingDots()
                     .foregroundColor(roleColor)
               }
            }
            
            // Message content
            MessageBubbleMarkDown(content: getContentString(from: msg.content))
               .padding(.horizontal, 12)
               .padding(.vertical, 8)
               .background(bubbleBackground)
               .clipShape(RoundedRectangle(cornerRadius: 12))
               .shadow(
                  color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.gray.opacity(0.2),
                  radius: 3,
                  x: 0,
                  y: 1
               )
         }
      }
      .padding(.vertical, 4)
   }
   
   // MARK: - Computed Properties
   
   private var avatarView: some View {
      Group {
         switch msg.role {
         case .user:
            Image(systemName: "person.fill")
               .foregroundColor(.white)
               .font(.system(size: 16))
         case .assistant:
            Image(systemName: "brain.head.profile")
               .foregroundColor(.white)
               .font(.system(size: 16))
         case .toolUse:
            Image(systemName: "hammer.fill")
               .foregroundColor(.white)
               .font(.system(size: 16))
         case .toolResult:
            Image(systemName: "checkmark.circle.fill")
               .foregroundColor(.white)
               .font(.system(size: 16))
         }
      }
      .padding(6)
   }
   
   private var avatarBackground: Color {
      switch msg.role {
      case .user:
         return .blue
      case .assistant:
         return .pink
      case .toolUse:
         return .orange
      case .toolResult:
         return .purple
      }
   }
   
   private var avatarBorderColor: Color {
      if colorScheme == .dark {
         return Color.white.opacity(0.2)
      } else {
         return avatarBackground.opacity(0.3)
      }
   }
   
   private var roleName: String {
      switch msg.role {
      case .user:
         return "You"
      case .assistant:
         return "Assistant"
      case .toolUse:
         return "Tool Use"
      case .toolResult:
         return "Tool Result"
      }
   }
   
   private var roleColor: Color {
      switch msg.role {
      case .user:
         return .blue
      case .assistant:
         return .pink
      case .toolUse:
         return .orange
      case .toolResult:
         return .purple
      }
   }
   
   private var bubbleBackground: some View {
      switch msg.role {
      case .user:
         return Color.blue.opacity(colorScheme == .dark ? 0.2 : 0.1)
      case .assistant:
         return Color.pink.opacity(colorScheme == .dark ? 0.15 : 0.05)
      case .toolUse:
         return Color.orange.opacity(colorScheme == .dark ? 0.2 : 0.1)
      case .toolResult:
         return Color.purple.opacity(colorScheme == .dark ? 0.2 : 0.1)
      }
   }
   
   private var showLoadingIndicator: Bool {
      isLoading && isLastMessage && (msg.role != .user)
   }
   
   private func getContentString(from content: String) -> String {
      return content
   }
}

struct MessageBubbleMarkDown: View {
   
   let content: String
   
   @Environment(\.colorScheme) private var colorScheme
   
   var body: some View {
      let formattedContent = formatJSONAsMarkdown(content)
      
      Text(formattedContent)
         .fixedSize(horizontal: false, vertical: true)
         .textSelection(.enabled)
         .animation(.easeInOut(duration: 0.2), value: formattedContent)
   }
   
   private func formatJSONAsMarkdown(_ text: String) -> String {
      // Improved JSON detection
      let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if (trimmedText.starts(with: "{") && trimmedText.contains(":")) ||
            (trimmedText.starts(with: "[") && trimmedText.contains("{")) {
         return "```json\n\(text)\n```"
      }
      
      // Format code blocks for better syntax highlighting
      let containsCodeBlock = text.contains("```")
      if containsCodeBlock {
         return text
      }
      
      return text
   }
}

/// A simple animated loading indicator with three dots
struct LoadingDots: View {
   @State private var animationStep = 0
   @State private var timer: Timer? = nil
   
   var body: some View {
      HStack(spacing: 2) {
         ForEach(0..<3) { index in
            Circle()
               .frame(width: 4, height: 4)
               .opacity(index == animationStep ? 1.0 : 0.3)
         }
      }
      .padding(.horizontal, 4)
      .onAppear {
         // Create a regular Timer that updates the animation state
         timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            withAnimation {
               animationStep = (animationStep + 1) % 3
            }
         }
      }
      .onDisappear {
         // Make sure to invalidate the timer when the view disappears
         timer?.invalidate()
         timer = nil
      }
   }
}
