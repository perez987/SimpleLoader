//
//  PresetsView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/29.
//

import SwiftUI

struct PresetsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var kdkMerger: KDKMerger
    @Binding var forceOverwrite: Bool
    @Binding var backupExisting: Bool
    @Binding var installToLE: Bool
    @Binding var installToPrivateFrameworks: Bool
    @State private var presets: [PatchPreset] = []
    @State private var showConfirmation = false
    @State private var selectedPreset: PatchPreset?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("presets".localized)
                    .font(.title)
                    .bold()
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding()
            
            Divider()
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(presets) { preset in
                        PresetCardView(preset: preset) {
                            selectedPreset = preset
                            showConfirmation = true
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            Text("select_preset_instruction".localized)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
        }
        .frame(width: 500, height: 600)
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("confirm_install_preset".localized),
                message: Text("\(selectedPreset?.name ?? "")\n\n\(selectedPreset?.description ?? "")"),
                primaryButton: .default(Text("install".localized)) {
                    if let preset = selectedPreset {
                        applyPreset(preset)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            presets = PatchPresetManager.shared.loadPresets()
        }
    }

    private func applyPreset(_ preset: PatchPreset) {
        // 准备文件路径
        var filePaths: [String] = []
        var mergeOperations: [(source: String, destination: String)] = []
        
        // 检查是否需要KDK
        if preset.requiresKDK && !kdkMerger.isKDKSelected {
            kdkMerger.logPublisher.send("error_preset_requires_kdk".localized)
            return
        }
        
        for file in preset.files {
            guard let versionDir = PatchPresetManager.shared.getPresetFilesDirectory(for: file.systemVersion),
                  FileManager.default.fileExists(atPath: versionDir.path) else {
                kdkMerger.logPublisher.send("warning_version_not_found".localized + ": \(file.systemVersion)")
                continue
            }
            
            let sourcePath = versionDir.appendingPathComponent(file.source).path
            
            if FileManager.default.fileExists(atPath: sourcePath) {
                switch file.conflictResolution {
                case .merge:
                    mergeOperations.append((source: sourcePath, destination: file.destination))
                default:
                    filePaths.append(sourcePath)
                }
            } else {
                kdkMerger.logPublisher.send("warning_file_not_found".localized + ": \(file.source) (版本: \(file.systemVersion))")
            }
        }
        
        // 设置安装选项
        forceOverwrite = preset.files.contains { $0.conflictResolution == .overwrite }
        backupExisting = preset.files.contains { $0.conflictResolution == .backup }
        
        // 设置文件路径并开始安装
        kdkMerger.kextPaths = filePaths
        kdkMerger.mergeOperations = mergeOperations
        
        kdkMerger.installKexts(
            forceOverwrite: forceOverwrite,
            backupExisting: backupExisting,
            rebuildCache: preset.rebuildCache,
            installToLE: installToLE,
            installToPrivateFrameworks: installToPrivateFrameworks
        )
        
        presentationMode.wrappedValue.dismiss()
    }
}

struct PresetCardView: View {
    let preset: PatchPreset
    let action: () -> Void
    
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(preset.name)
                        .font(.headline)
                    Spacer()
                    Text("v\(preset.version)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(preset.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // 显示文件版本信息
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(Set(preset.files.map { $0.systemVersion })), id: \.self) { version in
                        Text("版本: \(version)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                HStack {
                    Text("author".localized + ": \(preset.author)")
                        .font(.caption)
                    
                    Spacer()
                    
                    if preset.requiresKDK {
                        Text("requires_kdk".localized)
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    if preset.rebuildCache {
                        Text("rebuilds_cache".localized)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

class PatchPresetManager {
    static let shared = PatchPresetManager()
    private let presetsDirectory = Bundle.main.resourceURL?.appendingPathComponent("Presets")
    private let presetFilesDirectory = Bundle.main.resourceURL?.appendingPathComponent("PresetFiles")
    
    func loadPresets() -> [PatchPreset] {
        guard let presetsDirectory = presetsDirectory else { return [] }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: presetsDirectory, includingPropertiesForKeys: nil)
            let jsonFiles = files.filter { $0.pathExtension == "json" }
            
            var presets: [PatchPreset] = []
            for file in jsonFiles {
                do {
                    let data = try Data(contentsOf: file)
                    let preset = try JSONDecoder().decode(PatchPreset.self, from: data)
                    presets.append(preset)
                } catch {
                    print("Error decoding preset \(file.lastPathComponent): \(error)")
                }
            }
            return presets.sorted { $0.name < $1.name } // 按名称排序
        } catch {
            print("Error loading presets: \(error)")
            return []
        }
    }
    
    func getPresetFilesDirectory(for version: String) -> URL? {
        return presetFilesDirectory?.appendingPathComponent(version)
    }
}
