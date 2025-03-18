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
   
   var body: some View {
      switch msg.role {
      case .user:
         HStack(alignment: .top) {
            Text("You:")
               .fontWeight(.bold)
               .foregroundColor(.blue)
            MessageBubbleMarkDown(content: getContentString(from: msg.content))
         }
      case .assistant:
         VStack(alignment: .leading) {
            Text("Assistant:")
               .fontWeight(.bold)
               .foregroundColor(.pink)
            MessageBubbleMarkDown(content: getContentString(from: msg.content))
         }
         .cornerRadius(6)
            
      case .toolUse:
         VStack(alignment: .leading) {
            Text("[Tool Use]").foregroundColor(.orange)
            MessageBubbleMarkDown(content: getContentString(from: msg.content))
         }
         .padding(4)
         .background(Color.orange.opacity(0.1))
         .cornerRadius(4)
      case .toolResult:
         VStack(alignment: .leading) {
            Text("[Tool Result]").foregroundColor(.purple)
            MessageBubbleMarkDown(content: getContentString(from: msg.content))
         }
         .padding(4)
         .background(Color.purple.opacity(0.1))
         .cornerRadius(4)
      }
   }
   
   private func getContentString(from content: String) -> String {
      return content
   }
}

struct MessageBubbleMarkDown: View {
   
   let content: String
   
   var body: some View {
      let formattedContent = formatJSONAsMarkdown(content)
      Markdown(formattedContent)
         .fixedSize(horizontal: false, vertical: true)
         .textSelection(.enabled)
         .markdownTheme(.custom(fontSize: 15.0, colorScheme: colorScheme))
         .markdownCodeSyntaxHighlighter(streamSyntaxHighlighter)
   }
   
   private func formatJSONAsMarkdown(_ text: String) -> String {
      // Improved JSON detection
      let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
      if (trimmedText.starts(with: "{") && trimmedText.contains(":")) ||
         (trimmedText.starts(with: "[") && trimmedText.contains("{")) {
         return "```json\n\(text)\n```"
      }
      return text
   }
   
   @Environment(\.streamSyntaxHighlighter) private var streamSyntaxHighlighter
   @Environment(\.colorScheme) private var colorScheme
}
