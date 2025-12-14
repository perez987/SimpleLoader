//
//  FooterView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack(spacing: 4) {
            Divider()
            HStack {
                Text("© 2025 laobamac. " + "rights_reserved".localized + "。")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("version".localized + " 1.1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("GitHub", destination: URL(string: "https://github.com/laobamac/SimpleLoader")!)
                    .font(.caption)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
