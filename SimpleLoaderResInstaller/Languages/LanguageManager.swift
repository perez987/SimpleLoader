//
//  LanguageManager.swift
//  SimpleLoaderResInstaller
//
//  Created by Assistant on 2025/7/28.
//

import Foundation

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: String
    
    private init() {
        // Get system language and default to supported language
        let systemLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
        
        // Check if system language is supported, otherwise default to English
        switch systemLanguage {
        case "zh":
            currentLanguage = "zh-Hans"
        case "en":
            currentLanguage = "en"
        default:
            currentLanguage = "en"
        }
    }
    
    func availableLanguages() -> [String] {
        return ["en", "zh-Hans"]
    }
    
    func displayName(for language: String) -> String {
        switch language {
        case "en": return "English"
        case "zh-Hans": return "简体中文"
        default: return language
        }
    }
}