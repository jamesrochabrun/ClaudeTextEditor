//
//  ClaudeCodeMCP.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/17/25.
//

import Foundation
import MCPSwiftWrapper

final class ClaudeCodeMCP {
   
   let npx = "npx"
   let argsToTest = ["-y", "@wonderwhy-er/desktop-commander"]
   
   let claude = "claude"
   let claudeArgs = ["mcp", "serve"]
   
   /// Initialize with a specific root directory
   /// - Parameter rootDirectory: The directory to use as the current working directory for Claude Code
   init(rootDirectory: String?) {
      Task {
         do {
            self.client = try await MCPClient(
               info: .init(name: "ClaudeCode", version: "1.0.0"),
               transport: .stdioProcess(
                  claude,
                  args: claudeArgs,
                  cwd: rootDirectory,  // Set the current working directory for Claude Code
                  verbose: true),
               capabilities: .init())
            
            clientInitialized.continuation.yield(self.client)
            clientInitialized.continuation.finish()
         } catch {
            print("Failed to initialize MCPClient: \(error)")
            clientInitialized.continuation.yield(nil)
            clientInitialized.continuation.finish()
         }
      }
   }
   
   /// Get the initialized client using Swift async/await
   /// - Returns: The initialized MCPClient if successful, nil otherwise
   func getClientAsync() async throws -> MCPClient? {
      for await client in clientInitialized.stream {
         return client
      }
      return nil // Stream completed without a client
   }
   
   /// The MCP client instance
   private var client: MCPClient?
   
   /// Stream to handle async initialization
   private let clientInitialized = AsyncStream.makeStream(of: MCPClient?.self)
}
