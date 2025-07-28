//
//  ContentView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var kdkMerger = KDKMerger()
    @State private var showAdvancedOptions = false
    @State private var forceOverwrite = false
    @State private var backupExisting = false
    @State private var installToLE = false
    @State private var installToPrivateFrameworks = false
    @State private var fullKDKMerge = false
    @State private var alertMessage: AlertMessage? = nil
    @State private var showAbout = false
    
    // 添加一个强制刷新的ID
    @State private var refreshID = UUID()
    
    var body: some View {
        VStack(spacing: 0) {
            HeaderView()
                .zIndex(1)
            
            ScrollView {
                VStack(spacing: 20) {
                    KDKSelectionView(kdkMerger: kdkMerger)
                    
                    KextSelectionView(kextPaths: $kdkMerger.kextPaths)
                    
                    LogView(logMessages: $kdkMerger.logMessages)
                        .frame(height: 150)
                    
                    InstallationOptionsView(
                        showAdvancedOptions: $showAdvancedOptions,
                        forceOverwrite: $forceOverwrite,
                        backupExisting: $backupExisting,
                        installToLE: $installToLE,
                        installToPrivateFrameworks: $installToPrivateFrameworks,
                        fullKDKMerge: $fullKDKMerge
                    )
                    
                    StatusView(
                        isInstalling: $kdkMerger.isInstalling,
                        isMerging: $kdkMerger.isMerging,
                        progress: $kdkMerger.installationProgress,
                        currentOperation: $kdkMerger.currentOperation
                    )
                    
                    ActionButtonsView(
                        isKDKSelected: $kdkMerger.isKDKSelected,
                        isInstalling: $kdkMerger.isInstalling,
                        isMerging: $kdkMerger.isMerging,
                        hasKextsSelected: .init(
                            get: { !kdkMerger.kextPaths.isEmpty },
                            set: { _ in }
                        ),
                        installAction: {
                            kdkMerger.installKexts(
                                forceOverwrite: forceOverwrite,
                                backupExisting: backupExisting,
                                rebuildCache: true,
                                installToLE: installToLE,
                                installToPrivateFrameworks: installToPrivateFrameworks
                            )
                        },
                        mergeAction: { kdkMerger.mergeKDK(fullMerge: fullKDKMerge) },
                        cancelAction: kdkMerger.cancelOperation,
                        openKDKDirectoryAction: kdkMerger.openKDKDirectory,
                        rebuildCacheAction: {
                            kdkMerger.currentOperation = "Rebuilding kernel cache".localized
                            kdkMerger.rebuildKernelCache()
                        },
                        createSnapshotAction: {
                            kdkMerger.currentOperation = "Creating system snapshot".localized
                            kdkMerger.createSystemSnapshot()
                        },
                        restoreSnapshotAction: {
                            kdkMerger.currentOperation = "Restoring snapshot".localized
                            kdkMerger.restoreLastSnapshot()
                        },
                        aboutAction: { showAbout = true }
                    )
                }
                .padding()
            }
            .background(Color(.windowBackgroundColor))
            
            FooterView()
        }
        .id(refreshID) // 使用ID强制刷新整个视图
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showAdvancedOptions)
        .sheet(isPresented: $showAbout) {
            AboutView()
                .environmentObject(languageManager)
        }
        .alert(item: $alertMessage) { message in
            Alert(
                title: Text(message.title),
                message: Text(message.message),
                dismissButton: .default(Text("OK".localized)))
        }
        .onReceive(kdkMerger.alertPublisher) { message in
            alertMessage = message
        }
        .onChange(of: languageManager.currentLanguage) { _ in
            // 当语言改变时，更新refreshID强制刷新视图
            refreshID = UUID()
        }
    }
}


struct AlertMessage: Identifiable {
    var id: String { title + message }
    let title: String
    let message: String
}
