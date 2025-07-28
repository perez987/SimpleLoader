//
//  SimpleLoaderApp.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

@main
struct SimpleLoaderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var languageManager = LanguageManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(languageManager)
                .frame(
                    minWidth: 500, idealWidth: 600, maxWidth: .infinity,
                    minHeight: 600, idealHeight: 700, maxHeight: .infinity
                )
                .onAppear {
                    if languageManager.currentLanguage == "auto" {
                        languageManager.currentLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
