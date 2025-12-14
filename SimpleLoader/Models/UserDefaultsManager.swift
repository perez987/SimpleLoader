//
//  UserDefaultsManager.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/28.
//

import Foundation

class UserDefaultsManager {
    private static let defaults = UserDefaults.standard

    // Keys
    private static let forceOverwriteKey = "forceOverwrite"
    private static let backupExistingKey = "backupExisting"
    private static let installToLEKey = "installToLE"
    private static let installToPrivateKey = "installToPrivate"
    private static let fullKDKMergeKey = "fullKDKMerge"
    private static let showAdvancedKey = "showAdvanced"

    // Default values
    private static let defaultForceOverwrite = false
    private static let defaultBackupExisting = false
    private static let defaultInstallToLE = false
    private static let defaultInstallToPrivate = false
    private static let defaultFullKDKMerge = false
    private static let defaultShowAdvanced = false

    // Save methods
    static func saveForceOverwrite(_ value: Bool) {
        defaults.set(value, forKey: forceOverwriteKey)
    }

    static func saveBackupExisting(_ value: Bool) {
        defaults.set(value, forKey: backupExistingKey)
    }

    static func saveInstallToLE(_ value: Bool) {
        defaults.set(value, forKey: installToLEKey)
    }

    static func saveInstallToPrivate(_ value: Bool) {
        defaults.set(value, forKey: installToPrivateKey)
    }

    static func saveFullKDKMerge(_ value: Bool) {
        defaults.set(value, forKey: fullKDKMergeKey)
    }

    static func saveShowAdvanced(_ value: Bool) {
        defaults.set(value, forKey: showAdvancedKey)
    }

    // Load methods
    static func loadForceOverwrite() -> Bool {
        return defaults.object(forKey: forceOverwriteKey) as? Bool ?? defaultForceOverwrite
    }

    static func loadBackupExisting() -> Bool {
        return defaults.object(forKey: backupExistingKey) as? Bool ?? defaultBackupExisting
    }

    static func loadInstallToLE() -> Bool {
        return defaults.object(forKey: installToLEKey) as? Bool ?? defaultInstallToLE
    }

    static func loadInstallToPrivate() -> Bool {
        return defaults.object(forKey: installToPrivateKey) as? Bool ?? defaultInstallToPrivate
    }

    static func loadFullKDKMerge() -> Bool {
        return defaults.object(forKey: fullKDKMergeKey) as? Bool ?? defaultFullKDKMerge
    }

    static func loadShowAdvanced() -> Bool {
        return defaults.object(forKey: showAdvancedKey) as? Bool ?? defaultShowAdvanced
    }
}
