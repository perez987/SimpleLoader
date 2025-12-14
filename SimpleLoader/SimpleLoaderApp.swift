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
                //				.frame(
                //					minWidth: 880,
                //					idealWidth: 880,
                //					maxWidth: 880,
                //					minHeight: 560,
                //					idealHeight: 560,
                //					maxHeight: 970
                //				)
                .frame(
                    minWidth: 880,
                    idealWidth: 880,
                    maxWidth: 880,
                    minHeight: 560
                )
//                .fixedSize()
                .onAppear {
                    if languageManager.currentLanguage == "auto" {
                        languageManager.currentLanguage = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
                    }
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
//        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {}

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        return true
    }
}
