//
//  LanguageSelectionView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/28.
//

import SwiftUI

struct LanguageSelectionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            List {
                ForEach(languageManager.availableLanguages(), id: \.self) { language in
                    Button(action: {
                        languageManager.setLanguage(language)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(languageManager.displayName(for: language))
                            Spacer()
                            if language == languageManager.currentLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Button(action: {
                languageManager.setLanguage("auto")
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Text("auto_detect".localized)
                    Spacer()
                    if languageManager.currentLanguage == "auto" {
                        Image(systemName: "checkmark")
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding()
        }
        .frame(width: 300, height: 300)
        .navigationTitle("language_settings".localized)
    }
}
