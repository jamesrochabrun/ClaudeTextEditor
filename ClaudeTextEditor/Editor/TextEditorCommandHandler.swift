//
//  TextEditorCommandHandler.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import Foundation
import SwiftAnthropic

/// Methods to handle the text editor commands from the model
/// Called by ChatConversationViewModel whenever a "tool_use" content block is triggered
final class TextEditorCommandHandler {
   private let fileManager: TextEditorFileManager
   
   init(fileManager: TextEditorFileManager) {
      self.fileManager = fileManager
   }
   
   /// Process an incoming tool_use input dictionary for text editor commands
   /// Return (resultText, isError)
   func processToolUse(input: [String: MessageResponse.Content.DynamicContent]) -> (String, Bool) {
      guard let command = input["command"]?.stringValue else {
         return ("Error: No 'command' field in the tool input.", true)
      }
      
      let path = input["path"]?.stringValue ?? "(missing path)"
      
      switch command {
      case "view":
         if let contents = fileManager.readFile(atPath: path) {
            return (contents, false)
         } else {
            return ("Error: File not found at path: \(path)", true)
         }
         
      case "create":
         let fileText = input["file_text"]?.stringValue ?? ""
         fileManager.createFile(atPath: path, contents: fileText)
         return ("Created file \(path) successfully.", false)
         
      case "str_replace":
         let oldStr = input["old_str"]?.stringValue ?? ""
         let newStr = input["new_str"]?.stringValue ?? ""
         let result = fileManager.strReplace(inPath: path, oldStr: oldStr, newStr: newStr)
         let isError = result.hasPrefix("Error:")
         return (result, isError)
         
      case "insert":
         let newStr = input["new_str"]?.stringValue ?? ""
         let line = input["insert_line"]?.intValue ?? 0
         let result = fileManager.insert(inPath: path, line: line, newStr: newStr)
         let isError = result.hasPrefix("Error:")
         return (result, isError)
         
      case "undo_edit":
         let result = fileManager.undoEdit(inPath: path)
         let isError = result.hasPrefix("Error:")
         return (result, isError)
         
      default:
         return ("Error: Unknown text editor command: \(command)", true)
      }
   }
}
