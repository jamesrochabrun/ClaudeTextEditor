//
//  ThemeMode.swift
//  ClaudeTextEditor
//
//  Created by James Rochabrun on 3/17/25.
//

import Foundation
import Splash

enum ThemeMode {
   case light
   case dark
   
   var themeName: String {
      switch self {
      case .light: "xcode"
      case .dark: "atom-one-dark"
      }
   }
   
   var theme: Splash.Theme {
      switch self {
      case .light: .xcodeLight(withFont: .init(size: 24))
      case .dark: .xcodeDark(withFont: .init(size: 24))
      }
   }
}
