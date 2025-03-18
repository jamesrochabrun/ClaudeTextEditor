//
//  ChatConversationMCPViewModel.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/17/25.
//

import MCPClient
import SwiftAnthropic
import SwiftUI

@MainActor
@Observable
/// A Chat observable object that works with any MCP server
class ChatConversationMCPViewModel {
   
   // MARK: Public Properties
   
   /// Our entire chat conversation
   var messages: [ChatMessage] = []
   
   /// Whether we are currently streaming a response
   var isStreaming: Bool = false
   
   /// If any error occurs, store here
   var errorMessage: String = ""
   
   /// Set to true when we're waiting for user to approve continuing after a tool use
   var waitingForToolResultApproval: Bool = false
   
   /// Contains the pending tool result to display to user
   var pendingToolUse: PendingToolUse? = nil
   
   // MARK: Private Properties
   
   /// The AnthropicService we use for calling the API
   private let service: AnthropicService
   
   private var mcpClient: MCPClient?
   
   /// Handler for text editor commands from Claude
   private let textEditorHandler: TextEditorCommandHandler
   
   /// For any in-progress tool_use block, we store partial JSON here
   private var toolUseAccumulators: [Int: ToolUseAccumulator] = [:]
   
   // MARK: Initialization
   
   init(service: AnthropicService) {
      self.service = service
      let fileMgr = TextEditorFileManager()
      self.textEditorHandler = TextEditorCommandHandler(fileManager: fileMgr)
   }
   
   // MARK: Public Methods
   
   func updateClient(_ client: MCPClient) {
      mcpClient = client
   }
   
   /// Start a new conversation with user text
   func sendUserMessage(_ userText: String) {
      guard !userText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
      
      // 1) Append user message to local conversation
      messages.append(ChatMessage(role: .user, content: userText))
      
      // 2) Make the API call
      callClaude()
   }
   
   /// After a tool is used, user can approve continuing the conversation
   func continueConversationWithToolResult() {
      guard let pendingTool = pendingToolUse else { return }
      
      // 1) Add the tool result to our messages
      let toolResultJSON = """
        {"type":"tool_result","tool_use_id":"\(pendingTool.toolUseId)","content":"\(escapeQuotes(pendingTool.resultText))","is_error":\(pendingTool.isError ? "true":"false")}
        """
      
      // We need an assistant role message with the tool result
      // This ensures Claude sees it in the next request
      let assistantToolResultMsg = ChatMessage(role: .assistant, content: toolResultJSON)
      messages.append(assistantToolResultMsg)
      
      // 2) Reset pending state
      pendingToolUse = nil
      waitingForToolResultApproval = false
      
      // 3) Continue the conversation
      callClaude()
   }
   
   // MARK: Private Methods
   
   /// Convert our entire conversation to format for Claude
   private func conversationToParameterMessages() -> [MessageParameter.Message] {
      var paramMessages: [MessageParameter.Message] = []
      
      // Convert each local message to Claude's format
      for msg in messages {
         let role: MessageParameter.Message.Role
         switch msg.role {
         case .user:
            role = .user
         case .assistant, .toolUse, .toolResult:
            role = .assistant
         }
         paramMessages.append(
            MessageParameter.Message(
               role: role,
               content: .text(msg.content)
            )
         )
      }
      return paramMessages
   }
   
   /// Call Claude's streaming API with our full conversation
   private func callClaude() {
      
      Task {
         
         // 1) Build parameter with entire chat + tools from MCPClient
         let paramMessages = conversationToParameterMessages()
         
         // Get tools from MCPClient, fall back to empty array if not available
         let tools = try await mcpClient?.anthropicTools() ?? []
         
         let param = MessageParameter(
            model: .claude37Sonnet,
            messages: paramMessages,
            maxTokens: 4000,
            stream: true,
            tools: tools
         )
         
         // 2) Start streaming
         
         do {
            isStreaming = true
            errorMessage = ""
            
            // Add a placeholder assistant message
            let placeholder = ChatMessage(role: .assistant, content: "")
            messages.append(placeholder)
            let assistantIndex = messages.count - 1
            
            let stream = try await service.streamMessage(param)
            
            for try await event in stream {
               handleStreamEvent(event, assistantIndex: assistantIndex)
            }
            
            isStreaming = false
         } catch {
            isStreaming = false
            errorMessage = "Error: \(error.localizedDescription)"
         }
      }
   }
   
   /// Process incoming stream events from Anthropic
   private func handleStreamEvent(_ event: MessageStreamResponse, assistantIndex: Int) {
      guard let eventType = event.streamEvent else { return }
      
      // If there's an error object in the event, show it
      if let errorData = event.error {
         errorMessage = "Stream error: \(errorData.message)"
         return
      }
      
      switch eventType {
      case .contentBlockStart:
         // Possibly new text block, or tool_use block, etc.
         guard let contentBlock = event.contentBlock, let index = event.index else { return }
         if contentBlock.type == "tool_use" {
            // Claude is calling a tool - create an accumulator for partial JSON
            let toolId = contentBlock.id ?? "unknown_tool_id"
            let toolName = contentBlock.name ?? "unknown_tool_name"
            toolUseAccumulators[index] = ToolUseAccumulator(toolUseId: toolId, toolName: toolName)
         }
         
      case .contentBlockDelta:
         // partial text or partial JSON
         guard let delta = event.delta, let index = event.index else { return }
         
         // Handle different delta types
         if delta.type == "text_delta", let fragment = delta.text {
            // Normal assistant text - append to the current assistant message
            messages[assistantIndex].content += fragment
         }
         // Handle partial JSON for tool use
         else if ["input_json_delta", "tool_use_delta", "partial_json"].contains(delta.type),
                 let partialJson = delta.partialJson {
            // Accumulate the JSON fragments
            if toolUseAccumulators[index] != nil {
               toolUseAccumulators[index]!.partialJson += partialJson
            }
         }
         
      case .contentBlockStop:
         // A content block ended - could be text or tool_use
         guard let index = event.index else { return }
         
         // Handle tool_use blocks that have completed
         if let accumulator = toolUseAccumulators[index] {
            let finalJsonString = accumulator.partialJson
            toolUseAccumulators.removeValue(forKey: index)
            
            // Parse the accumulated JSON
            let (parsedDict, parseError) = parseToolUseJSON(finalJsonString)
            
            if let error = parseError {
               // JSON parsing failed
               let errMsg = ChatMessage(role: .toolUse, content: "Error parsing tool JSON: \(error)")
               messages.append(errMsg)
            } else if let inputDict = parsedDict {
               // Successfully parsed - now handle the tool use
               handleToolUse(
                  toolUseId: accumulator.toolUseId,
                  toolName: accumulator.toolName,
                  inputDict: inputDict
               )
            }
         }
         
      case .messageStart:
         // Usually indicates a brand-new message
         // We already made a placeholder message
         break
         
      case .messageDelta:
         // Top-level changes to the final message
         if let textFrag = event.delta?.text {
            messages[assistantIndex].content += textFrag
         }
         
      case .messageStop:
         // The entire message is complete
         break
      }
   }
   
   /// Handle a finalized tool use after JSON is fully parsed
   private func handleToolUse(
      toolUseId: String,
      toolName: String,
      inputDict: [String: MessageResponse.Content.DynamicContent]
   ) {
      // 1) Add a message showing the tool use details to our chat
      let debugInfo = formatToolInputForDisplay(toolName: toolName, input: inputDict)
      let toolUseMsg = ChatMessage(role: .toolUse, content: debugInfo)
      messages.append(toolUseMsg)
      
      // 2) Call the tool via MCPClient
      Task {
         if let mcpClient = mcpClient {
            // Convert our dictionary to the format expected by MCPClient
            let toolResponse = await mcpClient.anthropicCallTool(
               name: toolName,
               input: convertToMCPInput(inputDict),
               debug: true
            )
            
            // 3) Add a tool result message in the UI
            let resultText = toolResponse ?? "Tool execution failed"
            let isError = toolResponse == nil
            let resultMsg = ChatMessage(role: .toolResult, content: resultText)
            messages.append(resultMsg)
            
            // 4) Store this pending tool result and wait for user approval
            pendingToolUse = PendingToolUse(
               toolUseId: toolUseId,
               toolName: toolName,
               resultText: resultText,
               isError: isError
            )
            waitingForToolResultApproval = true
         } else {
            // Fallback to the old method if MCPClient is not available
            let (resultText, isError) = textEditorHandler.processToolUse(input: inputDict)
            
            let resultMsg = ChatMessage(role: .toolResult, content: resultText)
            messages.append(resultMsg)
            
            pendingToolUse = PendingToolUse(
               toolUseId: toolUseId,
               toolName: toolName,
               resultText: resultText,
               isError: isError
            )
            waitingForToolResultApproval = true
         }
      }
   }
   
   // Helper to convert our dictionary format to what MCPClient expects
   private func convertToMCPInput(_ dict: [String: MessageResponse.Content.DynamicContent]) -> [String: Any] {
      var result: [String: Any] = [:]
      
      for (key, value) in dict {
         switch value {
         case .string(let string):
            result[key] = string
         case .integer(let int):
            result[key] = int
         case .double(let double):
            result[key] = double
         case .bool(let bool):
            result[key] = bool
         case .null:
            result[key] = NSNull()
         case .array(let array):
            result[key] = convertDynamicArray(array)
         case .dictionary(let dict):
            result[key] = convertDynamicDict(dict)
         }
      }
      
      return result
   }
   
   // Helper for arrays
   private func convertDynamicArray(_ array: [MessageResponse.Content.DynamicContent]) -> [Any] {
      array.map { content in
         switch content {
         case .string(let string): return string
         case .integer(let int): return int
         case .double(let double): return double
         case .bool(let bool): return bool
         case .null: return NSNull()
         case .array(let array): return convertDynamicArray(array)
         case .dictionary(let dict): return convertDynamicDict(dict)
         }
      }
   }
   
   // Helper for dictionaries
   private func convertDynamicDict(_ dict: [String: MessageResponse.Content.DynamicContent]) -> [String: Any] {
      var result: [String: Any] = [:]
      
      for (key, value) in dict {
         switch value {
         case .string(let string):
            result[key] = string
         case .integer(let int):
            result[key] = int
         case .double(let double):
            result[key] = double
         case .bool(let bool):
            result[key] = bool
         case .null:
            result[key] = NSNull()
         case .array(let array):
            result[key] = convertDynamicArray(array)
         case .dictionary(let dict):
            result[key] = convertDynamicDict(dict)
         }
      }
      
      return result
   }
   
   /// Pretty-format a tool input for display
   private func formatToolInputForDisplay(toolName: String, input: [String: MessageResponse.Content.DynamicContent]) -> String {
      var output = "Tool Used: \(toolName)\n"
      
      if let command = input["command"]?.stringValue {
         output += "Command: \(command)\n"
         
         if let path = input["path"]?.stringValue {
            output += "Path: \(path)\n"
         }
         
         // Show additional parameters based on command
         switch command {
         case "str_replace":
            if let oldStr = input["old_str"]?.stringValue {
               output += "Replace: \"\(oldStr)\"\n"
            }
            if let newStr = input["new_str"]?.stringValue {
               output += "With: \"\(newStr)\"\n"
            }
         case "insert":
            if let line = input["insert_line"]?.intValue {
               output += "Insert Line: \(line)\n"
            }
            if let newStr = input["new_str"]?.stringValue {
               output += "Text to Insert: \"\(newStr)\"\n"
            }
         default:
            break
         }
      }
      
      return output
   }
   
   // MARK: - JSON Parsing Helpers
   
   /// Parse a JSON string into our dynamic content dictionary
   private func parseToolUseJSON(_ jsonString: String) -> ([String: MessageResponse.Content.DynamicContent]?, String?) {
      guard !jsonString.isEmpty else {
         return (nil, "Tool use JSON was empty.")
      }
      
      do {
         let data = Data(jsonString.utf8)
         
         // Try standard Dictionary approach first for simpler cases
         if let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Convert standard dictionary to our DynamicContent dictionary
            var result: [String: MessageResponse.Content.DynamicContent] = [:]
            
            for (key, value) in dict {
               if let stringValue = value as? String {
                  result[key] = .string(stringValue)
               } else if let intValue = value as? Int {
                  result[key] = .integer(intValue)
               } else if let doubleValue = value as? Double {
                  result[key] = .double(doubleValue)
               } else if let boolValue = value as? Bool {
                  result[key] = .bool(boolValue)
               } else if value is NSNull {
                  result[key] = .null
               } else if let arrayValue = value as? [Any] {
                  // Simplistic approach for arrays - not handling nested structures
                  var arrayResult: [MessageResponse.Content.DynamicContent] = []
                  for item in arrayValue {
                     if let s = item as? String {
                        arrayResult.append(.string(s))
                     } else if let i = item as? Int {
                        arrayResult.append(.integer(i))
                     }
                     // Add other types as needed
                  }
                  result[key] = .array(arrayResult)
               } else if let dictValue = value as? [String: Any] {
                  // Simplistic approach for dictionaries
                  let subDict = try parseSimpleDictionary(dictValue)
                  result[key] = .dictionary(subDict)
               }
            }
            
            return (result, nil)
         }
         
         // If the simpler approach fails, fall back to custom decoder
         let decoder = JSONDecoder()
         let wrapper = try decoder.decode(DynamicWrapper.self, from: data)
         return (wrapper.map, nil)
      } catch {
         return (nil, "JSON parsing error: \(error.localizedDescription)")
      }
   }
   
   /// Convert a simple [String: Any] to our DynamicContent dictionary
   private func parseSimpleDictionary(_ dict: [String: Any]) throws -> [String: MessageResponse.Content.DynamicContent] {
      var result: [String: MessageResponse.Content.DynamicContent] = [:]
      
      for (key, value) in dict {
         if let stringValue = value as? String {
            result[key] = .string(stringValue)
         } else if let intValue = value as? Int {
            result[key] = .integer(intValue)
         } else if let doubleValue = value as? Double {
            result[key] = .double(doubleValue)
         } else if let boolValue = value as? Bool {
            result[key] = .bool(boolValue)
         } else if value is NSNull {
            result[key] = .null
         }
         // Skip unsupported types for simplicity
      }
      
      return result
   }
   
   /// Helper wrapper for decoding JSON to our dictionary format
   private struct DynamicWrapper: Decodable {
      let map: [String: MessageResponse.Content.DynamicContent]
      
      init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: DynamicKey.self)
         var temp: [String: MessageResponse.Content.DynamicContent] = [:]
         
         for key in container.allKeys {
            temp[key.stringValue] = try container.decode(MessageResponse.Content.DynamicContent.self, forKey: key)
         }
         
         self.map = temp
      }
   }
   
   /// Dynamic key for decoding arbitrary JSON keys
   private struct DynamicKey: CodingKey {
      var stringValue: String
      init?(stringValue: String) { self.stringValue = stringValue }
      var intValue: Int? { nil }
      init?(intValue: Int) { return nil }
   }
   
   /// Escape quotes in a string for JSON embedding
   private func escapeQuotes(_ s: String) -> String {
      s.replacingOccurrences(of: "\"", with: "\\\"")
         .replacingOccurrences(of: "\n", with: "\\n")
   }
}
