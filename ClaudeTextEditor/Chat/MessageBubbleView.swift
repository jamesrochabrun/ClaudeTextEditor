//
//  MessageBubbleView.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import Foundation
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
            Text(msg.content)
         }
      case .assistant:
         VStack(alignment: .leading) {
            Text("Assistant:")
               .fontWeight(.bold)
            Text(msg.content)
               .textSelection(.enabled)
         }
         .padding(6)
         .background(Color.gray.opacity(0.15))
         .cornerRadius(6)
      case .toolUse:
         VStack(alignment: .leading) {
            Text("[Tool Use]").foregroundColor(.orange)
            Text(msg.content).textSelection(.enabled)
         }
         .padding(4)
         .background(Color.orange.opacity(0.1))
         .cornerRadius(4)
      case .toolResult:
         VStack(alignment: .leading) {
            Text("[Tool Result]").foregroundColor(.purple)
            Text(msg.content).textSelection(.enabled)
         }
         .padding(4)
         .background(Color.purple.opacity(0.1))
         .cornerRadius(4)
      }
   }
}
