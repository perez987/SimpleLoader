//
//  KDKSelectionView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI
import UniformTypeIdentifiers

struct KDKSelectionView: View {
    @ObservedObject var kdkMerger: KDKMerger

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("select_kdk".localized)
                .font(.headline)

            HStack {
                Picker("select_installed_kdk".localized, selection: $kdkMerger.selectedKDK) {
                    Text("not_selected".localized).tag(nil as String?)
                    ForEach(kdkMerger.kdkItems, id: \.self) { kdk in
                        Text(URL(fileURLWithPath: kdk).lastPathComponent).tag(kdk as String?)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .onChange(of: kdkMerger.selectedKDK) { newValue in
                    if let newValue = newValue {
                        kdkMerger.kdkPath = newValue
                        kdkMerger.isKDKSelected = true
                        kdkMerger.logMessage("selected_kdk", parameters: [": \(newValue)"])
                    } else {
                        kdkMerger.kdkPath = ""
                        kdkMerger.isKDKSelected = false
                    }
                }

                Button("refresh".localized) {
                    kdkMerger.refreshKDKList()
                }
                .buttonStyle(BorderedButtonStyle())
            }

            if kdkMerger.isKDKSelected {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("effective_kdk".localized)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.controlBackgroundColor))
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
