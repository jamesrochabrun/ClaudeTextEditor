//
//  ChatMessage.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import Foundation

enum ChatRole: String, Codable, CaseIterable {
   case user
   case assistant
   case toolUse
   case toolResult
}

/// A single chat message
struct ChatMessage: Identifiable, Codable {
   var id = UUID()
   let role: ChatRole
   var content: String
}
