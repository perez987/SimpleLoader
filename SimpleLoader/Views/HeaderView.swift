//
//  HeaderView.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)
                Text("app_title".localized)
                    .font(.system(size: 24, weight: .bold))
                Spacer()
            }
            
            Text("app_subtitle".localized)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
        .overlay(Divider(), alignment: .bottom)
        .shadow(color: .black.opacity(0.1), radius: 5, y: 2)
    }
}
