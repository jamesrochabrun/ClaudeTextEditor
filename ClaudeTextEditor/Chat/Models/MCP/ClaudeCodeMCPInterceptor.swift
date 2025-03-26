//
//  ClaudeCodeMCPInterceptor.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/26/25.
//

import Foundation
import MCPSwiftWrapper

/// A custom MCP client implementation that intercepts and overrides specific tool calls
/// to provide Xcode-specific implementations instead of using Claude Code's file system tools.
final class ClaudeCodeMCPInterceptor {
   private var claudeClient: MCPClient?
   /*
    DEBUG: Successfully fetched 8 tools
    DEBUG: Function Tool 0: name='dispatch_agent', description='Launch a new task'
    DEBUG: Function Tool 1: name='Bash', description='Unable to generate description'
    DEBUG: Function Tool 2: name='Edit', description='A tool for editing files'
    DEBUG: Function Tool 3: name='View', description='Read a file from the local fil'
    DEBUG: Function Tool 4: name='GlobTool', description='- Fast file pattern matching t'
    DEBUG: Function Tool 5: name='GrepTool', description='
    - Fast content search tool th'
    DEBUG: Function Tool 6: name='Replace', description='Write a file to the local file'
    DEBUG: Function Tool 7: name='LS', description='Lists files and directories in'
    DEBUG: Creating chat request with 3 messages and 8 tools
    */
   private let ownTools: Set<String> = ["Edit", "Replace", "View", "LS"] // Tools to intercept
   
   init(rootDirectory: String?) {
      Task {
         do {
            // Initialize the original Claude Code MCP client
            self.claudeClient = try await MCPClient(
               info: .init(name: "XcodeClaudeCode", version: "1.0.0"),
               transport: .stdioProcess(
                  "claude",
                  args: ["mcp", "serve"],
                  cwd: rootDirectory,
                  verbose: true),
               capabilities: .init())
            
            // Signal completion
            clientInitialized.continuation.yield(self)
            clientInitialized.continuation.finish()
         } catch {
            print("Failed to initialize MCP client: \(error)")
            clientInitialized.continuation.yield(nil)
            clientInitialized.continuation.finish()
         }
      }
   }
   
   // Custom implementation to call the appropriate tool
   func callTool(name: String, input: [String: Any], debug: Bool = false) async -> String? {
      // Intercept specific tools
      if ownTools.contains(name) {
         return await handleCustomTool(name: name, input: input)
      } else {
         // Pass through to Claude Code for all other tools
         return await claudeClient?.anthropicCallTool(name: name, input: input, debug: debug)
      }
   }
   
   // Function that implements your custom tools
   private func handleCustomTool(name: String, input: [String: Any]) async -> String? {
      switch name {
      case "Edit":
         return await handleFileEdit(input: input)
      case "Replace":
         return await handleFileReplace(input: input)
      case "View":
         return await handleFileView(input: input)
      case "LS":
         return await handleDirectoryListing(input: input)
      default:
         return "Unknown tool: \(name)"
      }
   }
   
   // Implementation for file editing that integrates with Xcode
   private func handleFileEdit(input: [String: Any]) async -> String? {
      // Extract parameters from input
      guard let filePath = input["file_path"] as? String,
            let oldString = input["old_string"] as? String,
            let newString = input["new_string"] as? String else {
         return "Error: Missing required parameters for Edit tool"
      }
      
      // TODO: Implement your Xcode integration
      // For example:
      // 1. Find the file in Xcode's project navigator
      // 2. Open it in the editor if not already open
      // 3. Locate the text to replace
      // 4. Replace it with the new text
      // 5. Save changes
      
      // This is where you'd integrate with Xcode's APIs
      do {
         // Example Xcode API integration
         try await editFileInXcode(path: filePath, oldText: oldString, newText: newString)
         return "Successfully edited file \(filePath)"
      } catch {
         return "Error editing file in Xcode: \(error.localizedDescription)"
      }
   }
   
   // Implementation for file replacement
   private func handleFileReplace(input: [String: Any]) async -> String? {
      guard let filePath = input["file_path"] as? String,
            let content = input["content"] as? String else {
         return "Error: Missing required parameters for Replace tool"
      }
      
      do {
         // Implementation that would replace a file's contents in Xcode
         try await replaceFileInXcode(path: filePath, content: content)
         return "Successfully replaced contents of file \(filePath)"
      } catch {
         return "Error replacing file in Xcode: \(error.localizedDescription)"
      }
   }
   
   // Implementation for viewing files
   private func handleFileView(input: [String: Any]) async -> String? {
      guard let filePath = input["file_path"] as? String else {
         return "Error: Missing file_path parameter for View tool"
      }
      
      do {
         // Get file content from Xcode editor if open, or project file otherwise
         let content = try await readFileFromXcode(path: filePath)
         
         // Format the content with line numbers like the original View tool
         let lines = content.components(separatedBy: "\n")
         let numberedLines = lines.enumerated().map { idx, line in
            "\(idx + 1): \(line)"
         }
         
         return numberedLines.joined(separator: "\n")
      } catch {
         return "Error viewing file in Xcode: \(error.localizedDescription)"
      }
   }
   
   // Implementation for directory listing
   private func handleDirectoryListing(input: [String: Any]) async -> String? {
      guard let path = input["path"] as? String else {
         return "Error: Missing path parameter for LS tool"
      }
      
      do {
         // Get file listing from Xcode project structure
         let files = try await listFilesInXcodeProject(dirPath: path)
         
         // Format the listing similar to the original LS tool
         if files.isEmpty {
            return "No files found in \(path)"
         } else {
            return files.joined(separator: "\n")
         }
      } catch {
         return "Error listing directory in Xcode: \(error.localizedDescription)"
      }
   }
   
   // MARK: - Xcode Integration Methods
   
   // These methods would be implemented to interact with Xcode's API
   
   private func editFileInXcode(path: String, oldText: String, newText: String) async throws {
      // Example implementation using Xcode API (requires XcodeKit or similar)
      
      // 1. Get the active workspace
      // let workspace = XcodeWorkspace.current
      
      // 2. Find the file in the workspace
      // let file = try workspace.file(atPath: path)
      
      // 3. Open the file if not already open
      // let document = try workspace.openFile(file)
      
      // 4. Make the edit
      // try document.replace(oldText, with: newText)
      
      // 5. Save the file
      // try document.save()
      
      // For now, we'll simulate success
      try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
      
      // If there was an error, throw it
      // throw XcodeError.editFailed(reason: "Could not find text to replace")
   }
   
   private func replaceFileInXcode(path: String, content: String) async throws {
      // Similar to editFileInXcode but replaces the entire content
      try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
   }
   
   private func readFileFromXcode(path: String) async throws -> String {
      // Read file content from Xcode's editor or project
      // If the file is open in the editor, get the content from there
      // Otherwise, read it from the project file
      
      // Simulate getting content
      return """
        // This is a simulated content of \(path)
        // In a real implementation, this would be the actual file content from Xcode
        
        import Foundation
        
        func exampleFunction() {
            print("Hello, world!")
        }
        """
   }
   
   private func listFilesInXcodeProject(dirPath: String) async throws -> [String] {
      // Get the list of files from Xcode's project structure
      // This would interact with Xcode's project navigator
      
      // Simulate listing files
      return [
         "\(dirPath)/file1.swift",
         "\(dirPath)/file2.swift",
         "\(dirPath)/subfolder/file3.swift"
      ]
   }
   
   // Stream for async initialization
   private let clientInitialized = AsyncStream.makeStream(of: ClaudeCodeMCPInterceptor?.self)
   
   func getClientAsync() async throws -> ClaudeCodeMCPInterceptor? {
      for await client in clientInitialized.stream {
         return client
      }
      return nil
   }
   
   // Forward anthropicTools to get Claude's tool definitions
   func anthropicTools() async throws -> [AnthropicTool] {
      return try await claudeClient?.anthropicTools() ?? []
   }
   
   // MARK: - Additional Convenience Methods
   
   // Call a tool with string arguments converted to JSON
   func callToolWithStringArgs(name: String, args: [String: String]) async -> String? {
      // Convert string dictionary to Any dictionary
      let input = args.reduce(into: [String: Any]()) { result, pair in
         result[pair.key] = pair.value
      }
      
      return await callTool(name: name, input: input)
   }
   
   // Call a tool with a JSON string as input
   func callToolWithJSONString(name: String, jsonString: String) async -> String? {
      guard let data = jsonString.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
         return "Error: Invalid JSON input"
      }
      
      return await callTool(name: name, input: json)
   }
   
   // Method to check if a tool is available
   func isToolAvailable(name: String) async -> Bool {
      do {
         let tools = try await anthropicTools()
         return true //tools.contains { $0.name == name }
      } catch {
         print("Error checking tool availability: \(error)")
         return false
      }
   }
}

