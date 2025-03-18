//
//  ClaudeCodeMCP.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/17/25.
//

import Foundation
import MCPSwiftWrapper

final class ClaudeCodeMCP {
   init() {
      Task {
         do {
            self.client = try await MCPClient(
               info: .init(name: "ClaudeCode", version: "1.0.0"),
               transport: .stdioProcess(
                  "claude",
                  args: ["mcp", "serve"],
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
   func getClientAsync() async throws -> MCPClient? {
      for await client in clientInitialized.stream {
         return client
      }
      return nil // Stream completed without a client
   }
   
   private var client: MCPClient?
   private let clientInitialized = AsyncStream.makeStream(of: MCPClient?.self)
}

