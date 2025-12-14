//
//  InstallationOptionsView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

struct InstallationOptionsView: View {
    @Binding var showAdvancedOptions: Bool
    @Binding var forceOverwrite: Bool
    @Binding var backupExisting: Bool
    @Binding var installToLE: Bool
    @Binding var installToPrivateFrameworks: Bool
    @Binding var fullKDKMerge: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("installation_options".localized)
                    .font(.headline)
                Spacer()
                Button(action: {
                    withAnimation(.spring()) {
                        showAdvancedOptions.toggle()
                        UserDefaultsManager.saveShowAdvanced(showAdvancedOptions)
                    }
                }) {
                    Text(showAdvancedOptions ? "hide_advanced".localized : "show_advanced".localized)
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())
            }

            Toggle("force_overwrite".localized, isOn: $forceOverwrite)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .onChange(of: forceOverwrite) { newValue in
                    if !newValue {
                        backupExisting = false
                    }
                    UserDefaultsManager.saveForceOverwrite(newValue)
                }

            Toggle("backup_existing".localized, isOn: $backupExisting)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                .disabled(!forceOverwrite)
                .onChange(of: backupExisting) { newValue in
                    UserDefaultsManager.saveBackupExisting(newValue)
                }

            if showAdvancedOptions {
                Divider()
                    .transition(.opacity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("advanced_options".localized)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Toggle("install_to_le".localized, isOn: $installToLE)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .onChange(of: installToLE) { newValue in
                            UserDefaultsManager.saveInstallToLE(newValue)
                        }

                    Toggle("install_to_private".localized, isOn: $installToPrivateFrameworks)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .onChange(of: installToPrivateFrameworks) { newValue in
                            UserDefaultsManager.saveInstallToPrivate(newValue)
                        }
                    Text("private_warning".localized)
                        .font(.caption2)
                        .foregroundColor(.red)

                    Toggle("full_kdk_merge".localized, isOn: $fullKDKMerge)
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .onChange(of: fullKDKMerge) { newValue in
                            UserDefaultsManager.saveFullKDKMerge(newValue)
                        }
                    Text("kdk_warning".localized)
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            // Load saved options
            forceOverwrite = UserDefaultsManager.loadForceOverwrite()
            backupExisting = UserDefaultsManager.loadBackupExisting()
            installToLE = UserDefaultsManager.loadInstallToLE()
            installToPrivateFrameworks = UserDefaultsManager.loadInstallToPrivate()
            fullKDKMerge = UserDefaultsManager.loadFullKDKMerge()
            showAdvancedOptions = UserDefaultsManager.loadShowAdvanced()
        }
    }
}
