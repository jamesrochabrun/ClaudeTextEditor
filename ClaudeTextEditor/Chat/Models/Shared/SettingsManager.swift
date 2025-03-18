//
//  SettingsManager.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/18/25.
//

import Foundation
import Security
import SwiftUI

/// Manages application settings, including API key in Keychain and directory path in UserDefaults
@Observable
class SettingsManager {
   
   // MARK: - Properties
   
   /// Current API key, retrieves from Keychain if not set
   var apiKey: String {
      get {
         if let cachedKey = cachedApiKey {
            return cachedKey
         }
         
         if let storedKey = retrieveApiKeyFromKeychain() {
            cachedApiKey = storedKey
            return storedKey
         }
         
         return ""
      }
      set {
         cachedApiKey = newValue
         saveApiKeyToKeychain(newValue)
      }
   }
   
   /// Current root directory path for Claude Code
   var rootDirectoryPath: String {
      get {
         UserDefaults.standard.string(forKey: Keys.rootDirectoryPath) ?? defaultDirectoryPath
      }
      set {
         UserDefaults.standard.set(newValue, forKey: Keys.rootDirectoryPath)
      }
   }
   
   // MARK: - Private Properties
   
   /// Cached API key to avoid frequent Keychain access
   private var cachedApiKey: String?
   
   /// Default directory path to use if none is set
   private let defaultDirectoryPath: String = {
      // Use home directory as default
      return FileManager.default.homeDirectoryForCurrentUser.path
   }()
   
   // Keys for storage
   private enum Keys {
      static let apiKeyService = "com.claudetexteditor.apikey"
      static let apiKeyAccount = "ClaudeTextEditor"
      static let rootDirectoryPath = "rootDirectoryPath"
   }
   
   // MARK: - Initialization
   
   init() {
      // Load initial values when created
      _ = self.apiKey
      _ = self.rootDirectoryPath
   }
   
   // MARK: - Keychain Methods
   
   /// Save API key securely to the Keychain
   private func saveApiKeyToKeychain(_ apiKey: String) {
      // Delete existing key if present
      deleteApiKeyFromKeychain()
      
      guard !apiKey.isEmpty else { return }
      
      let keyData = apiKey.data(using: .utf8)!
      
      let query: [String: Any] = [
         kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Keys.apiKeyService,
         kSecAttrAccount as String: Keys.apiKeyAccount,
         kSecValueData as String: keyData,
         kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
      ]
      
      let status = SecItemAdd(query as CFDictionary, nil)
      if status != errSecSuccess {
         print("Error saving API key to Keychain: \(status)")
      }
   }
   
   /// Retrieve API key from the Keychain
   private func retrieveApiKeyFromKeychain() -> String? {
      let query: [String: Any] = [
         kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Keys.apiKeyService,
         kSecAttrAccount as String: Keys.apiKeyAccount,
         kSecReturnData as String: true,
         kSecMatchLimit as String: kSecMatchLimitOne
      ]
      
      var result: AnyObject?
      let status = SecItemCopyMatching(query as CFDictionary, &result)
      
      guard status == errSecSuccess,
            let data = result as? Data,
            let apiKey = String(data: data, encoding: .utf8) else {
         return nil
      }
      
      return apiKey
   }
   
   /// Delete API key from the Keychain
   private func deleteApiKeyFromKeychain() {
      let query: [String: Any] = [
         kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: Keys.apiKeyService,
         kSecAttrAccount as String: Keys.apiKeyAccount
      ]
      
      SecItemDelete(query as CFDictionary)
   }
}
