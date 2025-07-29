//
//  PatchPreset.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/29.
//

import Foundation

struct PatchPreset: Codable, Identifiable {
    var id: String { name }
    let name: String
    let author: String
    let description: String
    let version: String
    let requiresKDK: Bool
    let files: [PatchFile]
    let rebuildCache: Bool
    let createSnapshot: Bool
}

struct PatchFile: Codable {
    let source: String
    let destination: String
    let conflictResolution: ConflictResolution
    let systemVersion: String // 文件所属的系统版本
}

enum ConflictResolution: String, Codable {
    case overwrite = "overwrite"
    case backup = "backup"
    case skip = "skip"
    case merge = "merge"
}
