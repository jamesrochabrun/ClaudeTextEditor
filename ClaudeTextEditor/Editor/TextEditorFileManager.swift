//
//  TextEditorFileManager.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/16/25.
//

import Foundation

/// A very naive "file manager" that just stores file contents in memory.
/// In a real app, you'd read/write from the actual filesystem or user-chosen files.
final class TextEditorFileManager {
   /// Mock files with synthetic errors
   private var files: [String: String] = [
      "/repo/primes.py": """
        def is_prime(n):
            \"\"\"Check if a number is prime.\"\"\"
            if n <= 1:
                return False
            if n <= 3:
                return True
            if n % 2 == 0 or n % 3 == 0:
                return False
            i = 5
            while i * i <= n:
                if n % i == 0 or n % (i + 2) == 0:
                    return False
                i += 6
            return True
        
        def get_primes(limit):
            \"\"\"Generate a list of prime numbers up to the given limit.\"\"\"
            primes = []
            for num in range(2, limit + 1)
                if is_prime(num):
                    primes.append(num)
            return primes
        
        def main():
            \"\"\"Main function to demonstrate prime number generation.\"\"\"
            limit = 100
            prime_list = get_primes(limit)
            print(f"Prime numbers up to {limit}:")
            print(prime_list)
            print(f"Found {len(prime_list)} prime numbers.")
        
        if __name__ == "__main__":
            main()
        """,
      
      "/repo/foo.swift": """
        // Example Swift file with an error
        import Foundation
        
        struct User {
            let name: String
            let age: Int
            
            func greet() -> String {
                "Hello, \\(name)!"
            }
            
            // Missing closing brace here
            func isAdult() -> Bool {
                return age >= 18
        }
        
        func createUsers() -> [User] {
            return [
                User(name: "Alice", age: 28),
                User(name: "Bob", age: 19),
                User(name: "Charlie", age: 16)
            ]
        }
        """
   ]
   
   /// Returns file contents or nil if not found
   func readFile(atPath path: String) -> String? {
      // Format with line numbers for better readability
      if let content = files[path] {
         let lines = content.components(separatedBy: "\n")
         let numberedLines = lines.enumerated().map { idx, line in
            "\(idx + 1): \(line)"
         }
         return numberedLines.joined(separator: "\n")
      }
      return nil
   }
   
   func createFile(atPath path: String, contents: String) {
      files[path] = contents
   }
   
   func strReplace(inPath path: String, oldStr: String, newStr: String) -> String {
      guard var content = files[path] else {
         return "Error: File not found at \(path)."
      }
      
      // For str_replace, we need to match the exact string without line numbers
      let occurrences = content.components(separatedBy: oldStr).count - 1
      
      switch occurrences {
      case 0:
         return "Error: No match found for replacement."
      case 1:
         content = content.replacingOccurrences(of: oldStr, with: newStr)
         files[path] = content
         return "Successfully replaced text at exactly one location."
      default:
         return "Error: Found \(occurrences) matches. Provide more context for a unique match."
      }
   }
   
   func insert(inPath path: String, line: Int, newStr: String) -> String {
      guard var content = files[path] else {
         return "Error: File not found at \(path)."
      }
      
      let lines = content.components(separatedBy: "\n")
      if line < 0 || line > lines.count {
         return "Error: Invalid line number."
      }
      
      var updated = [String]()
      for (idx, l) in lines.enumerated() {
         updated.append(l)
         if idx + 1 == line {
            updated.append(newStr)
         }
      }
      
      if line == lines.count {
         updated.append(newStr)
      }
      
      files[path] = updated.joined(separator: "\n")
      return "Successfully inserted text after line \(line)."
   }
   
   func undoEdit(inPath path: String) -> String {
      return "Error: undo_edit not implemented in this example."
   }
}
