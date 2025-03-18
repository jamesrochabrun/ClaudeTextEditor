//
//  MarkdownUI.Theme .swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/17/25.
//

import Foundation
import MarkdownUI
import SwiftUI


extension MarkdownUI.Theme {
   
   /// Creates a custom MarkdownUI theme with specified font size. Optionally allows code to wrap within the proposed width.
   
   /// - Parameters:
   ///   - fontSize: The font size to be applied to non-code text elements.
   ///   - wrapCode: Determines if code blocks should wrap text to fit within the container's width. Defaults to `false`, meaning code will not wrap and will be scrollable horizontally instead.
   ///   - showArtifact: An optional closure that takes an `Artifact` parameter. This closure is invoked to display artifacts (e.g., diagrams) related to code blocks. For instance, when a code block contains a Mermaid diagram, this closure can be used to render the diagram visually.
   ///   - applyChange: An optional closure that takes a String parameter representing the code block content to be used to apply the content in to a file editor.
   /// - Returns: A `MarkdownUI.Theme` configured with the specified settings.
   static func custom(
      fontSize: Double,
      colorScheme: ColorScheme,
      wrapCode: Bool = false)
   -> MarkdownUI.Theme
   {
      .gitHub.text {
         // To be applied to NON Code ONLY.
         ForegroundColor(.primary)
         BackgroundColor(Color.clear)
         FontSize(fontSize)
         FontFamily(.system(.default))
         FontWeight(FontProperties.defaultWeight)
      }
      .paragraph { configuration in
         // To be applied to the NON Code ONLY.
         configuration.label
            .relativeLineSpacing(.em(0.6))
      }
      .codeBlock { configuration in
         // To be applied to Code ONLY.
         if wrapCode {
            configuration.label
            // Allows code to extend to the full width of the proposed size.
               .frame(maxWidth: .infinity, alignment: .leading)
               .codeBlockLabelStyle()
               .codeBlockStyle(colorScheme: colorScheme, configuration)
         } else {
            ScrollView(.horizontal) {
               configuration.label
                  .codeBlockLabelStyle()
            }
            .workaroundForVerticalScrollingBugInMacOS()
            .codeBlockStyle(colorScheme: colorScheme, configuration)
         }
      }
   }
}


/// To be applied to code block ONLY.

extension View {
   
   func codeBlockLabelStyle() -> some View {
      relativeLineSpacing(.em(0.225))
         .markdownTextStyle {
            FontFamilyVariant(.monospaced)
            FontSize(.em(0.85))
         }
         .padding(24)
      // Extra padding for code block.
         .padding(.top, 18)
   }
   
   func codeBlockStyle(
      colorScheme: ColorScheme,
      _ configuration: CodeBlockConfiguration)
   -> some View
   {
      background(Color.clear)
         .overlay(alignment: .top) {
            HStack(alignment: .center, spacing: 2) {
               Text(configuration.language ?? "code")
                  .foregroundStyle(.primary)
                  .font(.callout)
                  .padding(8)
                  .lineLimit(1)
               Spacer()
            }
            .background(colorScheme == .light ? Color(red: 244 / 255, green: 242 / 255, blue: 240 / 255, opacity: 0.9): Color(red: 50 / 255, green: 50 / 255, blue: 50 / 255))
         }
         .clipShape(RoundedRectangle(cornerRadius: 6))
         .markdownMargin(top: 16, bottom: 16)
         .overlay(
            RoundedRectangle(cornerRadius: 6)
               .stroke(Color.gray.opacity(0.3), lineWidth: 0.75))
   }
}


extension View {
   
   /// https://stackoverflow.com/questions/64920744/swiftui-nested-scrollviews-problem-on-macos
   
   @ViewBuilder
   func workaroundForVerticalScrollingBugInMacOS() -> some View {
      VerticalScrollingFixWrapper { self }
   }
}

// MARK: - VerticalScrollingFixWrapper

struct VerticalScrollingFixWrapper<Content>: View where Content: View {
   
   let content: Content
   
   init(@ViewBuilder content: () -> Content) {
      self.content = content()
   }
   
   var body: some View {
      VerticalScrollingFixViewRepresentable(content: content)
   }
}

// MARK: - VerticalScrollingFixViewRepresentable

struct VerticalScrollingFixViewRepresentable<Content>: NSViewRepresentable where Content: View {
   
   let content: Content
   
   func makeNSView(context _: Context) -> NSHostingView<Content> {
      VerticalScrollingFixHostingView<Content>(rootView: content)
   }
   
   func updateNSView(_: NSHostingView<Content>, context _: Context) { }
}

// MARK: - VerticalScrollingFixHostingView

final class VerticalScrollingFixHostingView<Content>: NSHostingView<Content> where Content: View {
   
   override func wantsForwardedScrollEvents(for axis: NSEvent.GestureAxis) -> Bool {
      axis == .vertical
   }
}

