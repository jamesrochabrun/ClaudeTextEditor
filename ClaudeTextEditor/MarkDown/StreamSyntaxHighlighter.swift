//
//  StreamSyntaxHighlighter.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/17/25.
//

import Foundation
import MarkdownUI
import Splash
import SwiftUI

// MARK: - TextOutputFormat

/// A format that produces SwiftUI Text output for syntax highlighting.
/// This struct implements the OutputFormat protocol from the Splash framework
/// to provide custom syntax highlighting for code blocks.
struct TextOutputFormat: OutputFormat {
   /// The theme to be used for syntax highlighting.
   private let theme: Splash.Theme
   
   init(theme: Splash.Theme) {
      self.theme = theme
   }
   
   /// Creates a new Builder instance for constructing syntax-highlighted text.
   /// - Returns: A Builder instance configured with the current theme.
   func makeBuilder() -> Builder {
      Builder(theme: theme)
   }
}

// MARK: TextOutputFormat.Builder

extension TextOutputFormat {
   struct Builder: OutputBuilder {
      // MARK: Lifecycle
      
      fileprivate init(theme: Splash.Theme) {
         self.theme = theme
         accumulatedText = []
      }
      
      // MARK: Internal
      
      /// Adds a syntax token with appropriate coloring based on its type.
      /// - Parameters:
      ///   - token: The string content of the token.
      ///   - type: The type of the token (e.g., keyword, string, number).
      mutating func addToken(_ token: String, ofType type: TokenType) {
         let color = theme.tokenColors[type] ?? theme.plainTextColor
         accumulatedText.append(Text(token).foregroundColor(.init(color)))
      }
      
      /// Adds plain text with the theme's default text color.
      /// - Parameter text: The string content to add.
      mutating func addPlainText(_ text: String) {
         accumulatedText.append(
            Text(text).foregroundColor(.init(theme.plainTextColor)))
      }
      
      /// Adds whitespace to the accumulated text.
      /// - Parameter whitespace: The whitespace string to add.
      mutating func addWhitespace(_ whitespace: String) {
         accumulatedText.append(Text(whitespace))
      }
      
      /// Builds the final Text view by combining all accumulated text components.
      /// - Returns: A single Text view containing all the syntax-highlighted content.
      func build() -> Text {
         accumulatedText.reduce(Text(""), +)
      }
      
      // MARK: Private
      
      /// The theme used for syntax highlighting.
      private let theme: Splash.Theme
      /// Collection of text components that will form the final output.
      private var accumulatedText: [Text]
   }
}

// MARK: - StreamSyntaxHighlighter

/// A syntax highlighter implementation that provides code highlighting for Markdown views.
/// This class handles the syntax highlighting of code blocks within chat messages during streaming
final class StreamSyntaxHighlighter: CodeSyntaxHighlighter {
   // MARK: Lifecycle
   
   init(themeMode: ThemeMode) {
      syntaxHighlighter = SyntaxHighlighter(format: TextOutputFormat(theme: themeMode.theme))
   }
   
   // MARK: Internal
   
   /// Highlights the provided code content with appropriate syntax coloring.
   /// - Parameters:
   ///   - content: The code content to highlight.
   ///   - language: The programming language of the code (optional).
   /// - Returns: A Text view containing the highlighted code.
   func highlightCode(_ content: String, language: String?) -> Text {
      guard language != nil else {
         return Text(content)
      }
      return syntaxHighlighter.highlight(content)
   }
   
   // MARK: Private
   
   /// The underlying syntax highlighter instance.
   private let syntaxHighlighter: SyntaxHighlighter<TextOutputFormat>
}

extension EnvironmentValues {
   /// We use the `ChatCodeSyntaxHighlighter` as an environment object to inject it into a `ChatMessageView`.
   /// This approach improves performance by injecting the highlighter instead of recreating it for each chat message view.
   /// Internally, we instantiate a `Highlighter` object, which is a utility class for generating a highlighted `NSAttributedString` from a `String`.
   ///
   /// `StreamSyntaxHighlighter` conforms to `CodeSyntaxHighlighter`, a protocol from the Swift Markdown package.
   ///
   /// `StreamSyntaxHighlighter`:
   /// - A type that provides syntax highlighting to code blocks in a Markdown view.
   /// - To configure the current code syntax highlighter for a view hierarchy, use the
   /// `markdownCodeSyntaxHighlighter(_:)` modifier.
   @Entry var streamSyntaxHighlighter: CodeSyntaxHighlighter = StreamSyntaxHighlighter(themeMode: .dark)
}

extension Splash.Theme {
   /// Creates a dark theme .
   /// - Parameter font: The font to be used for the theme.
   /// - Returns: A configured Splash.Theme instance for dark mode.
   static func xcodeDark(withFont font: Splash.Font) -> Splash.Theme {
      Splash.Theme(
         font: font,
         plainTextColor: NSColor(
            red: 0.85,
            green: 0.85,
            blue: 0.85),
         tokenColors: [
            .keyword: Splash.Color(red: 0.89, green: 0.49, blue: 0.94), // purple for 'private', 'func', etc.
            .string: Splash.Color(red: 0.93, green: 0.69, blue: 0.47), // tan/orange for strings
            .type: Splash.Color(red: 0.93, green: 0.69, blue: 0.47), // tan/orange for types
            .call: Splash.Color(red: 0.85, green: 0.85, blue: 0.85), // light gray for function calls
            .number: Splash.Color(red: 0.93, green: 0.69, blue: 0.47), // tan/orange for numbers
            .comment: Splash.Color(red: 0.42, green: 0.48, blue: 0.52), // darker gray for comments
            .property: Splash.Color(red: 0.85, green: 0.85, blue: 0.85), // light gray for properties
            .dotAccess: Splash.Color(red: 0.85, green: 0.85, blue: 0.85), // light gray for dot notation
            .preprocessing: Splash.Color(red: 0.89, green: 0.49, blue: 0.94), // purple for preprocessing
         ],
         backgroundColor: Splash.Color(
            red: 0.11,
            green: 0.11,
            blue: 0.11))
   }
   
   /// Creates a theme similar to Xcode's light theme.
   /// - Parameter font: The font to be used for the theme.
   /// - Returns: A configured Splash.Theme instance for dark mode.
   static func xcodeLight(withFont font: Splash.Font) -> Splash.Theme {
      Theme(
         font: font,
         plainTextColor: Splash.Color(
            red: 0.000,
            green: 0.000,
            blue: 0.000),
         tokenColors: [
            .keyword: Splash.Color(red: 0.706, green: 0.129, blue: 0.549), // purple (internal, convenience)
            .string: Splash.Color(red: 0.788, green: 0.086, blue: 0.043), // bright red
            .call: Splash.Color(red: 0.278, green: 0.415, blue: 0.710), // blue (init)
            .number: Splash.Color(red: 0.149, green: 0.278, blue: 0.694), // royal blue
            .comment: Splash.Color(red: 0.376, green: 0.439, blue: 0.400), // gray-green
            .property: Splash.Color(red: 0.278, green: 0.415, blue: 0.710), // blue (red, green, blue, alpha)
            .dotAccess: Splash.Color(red: 0.278, green: 0.415, blue: 0.710), // blue (self.init)
            .preprocessing: Splash.Color(red: 0.706, green: 0.129, blue: 0.549), // purple (#if, #endif)
         ],
         backgroundColor:
            Splash.Color(
               red: 1.000,
               green: 1.000,
               blue: 1.000))
   }
}

extension Splash.Color {
   convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
      self.init(red: red, green: green, blue: blue, alpha: 1)
   }
}
