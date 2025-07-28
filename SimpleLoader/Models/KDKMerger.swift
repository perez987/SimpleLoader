//
//  KDKMerger.swift
//  SimpleLoader
//
//  Created by laobamac on 2025/7/27.
//

import Foundation
import Combine
import AppKit

class KDKMerger: ObservableObject {
    @Published var isKDKSelected = false
    @Published var kdkPath = ""
    @Published var kextPaths: [String] = []
    @Published var isInstalling = false
    @Published var isMerging = false
    @Published var installationProgress: Double = 0
    @Published var logMessages: [String] = ["waiting".localized]
    @Published var selectedKDK: String?
    @Published var kdkItems: [String] = []
    @Published var logPublisher = PassthroughSubject<String, Never>()
    @Published var currentOperation: String? = nil
    
    private let fileManager = FileManager.default
    private let kdkDirectory = "/Library/Developer/KDKs"
    private var cancellables = Set<AnyCancellable>()
    private var progressTimer: Timer?
    
    var alertPublisher = PassthroughSubject<AlertMessage, Never>()

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            self.alertPublisher.send(AlertMessage(title: title, message: message))
        }
    }
    
    init() {
        setupLogging()
        checkKDKDirectory()
    }
    
    private func setupLogging() {
        logPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.logMessages.append(message)
                if self?.logMessages.count ?? 0 > 100 {
                    self?.logMessages.removeFirst()
                }
            }
            .store(in: &cancellables)
    }
    
    func refreshKDKList() {
        let url = URL(fileURLWithPath: kdkDirectory)
        do {
            let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            let kdks = items.filter { $0.pathExtension == "kdk" || $0.lastPathComponent.contains("KDK") }
                .map { $0.path }
                .sorted()
            
            DispatchQueue.main.async {
                self.kdkItems = kdks
                if kdks.isEmpty {
                    self.logPublisher.send("warning_no_kdk".localized)
                    self.showAlert(title: "warning".localized, message: "warning_no_kdk".localized)
                } else {
                    self.logPublisher.send("found".localized + " \(kdks.count) 个KDK")
                }
            }
        } catch {
            logPublisher.send("error_cant_read_kdk_dir".localized + "- \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.kdkItems = []
            }
        }
    }
    
    func mergeKDK(fullMerge: Bool) {
        guard let selectedKDK = selectedKDK else {
            logPublisher.send("error_not_selected_kdk".localized)
            self.showAlert(title: "error".localized, message: "not_selected_kdk".localized)
            return
        }
        
        isMerging = true
        installationProgress = 0
        logPublisher.send("starting_merging".localized + ": \(selectedKDK)")
        
        startProgressUpdates()
        
        let mergeCommand = fullMerge ?
        "rsync -r -i -a '\(selectedKDK)/System/' \"$MOUNT_PATH/System\"" :
        "rsync -r -i -a '\(selectedKDK)/System/Library/Extensions/' \"$MOUNT_PATH/System/Library/Extensions\""
        
        let shellScript = """
        umount "$MOUNT_PATH"; \
        echo '开始合并KDK进程...' && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "原始标识符: $ROOT_VOLUME_ORIGIN" && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        \(mergeCommand) && \
        kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
        bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
        if [ -f "$MOUNT_PATH/System/Library/Extensions/System.kext/PlugIns/Libkern.kext/Libkern" ]; then \
            echo 'KDK合并成功' && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                umount "$MOUNT_PATH"; \
            fi && \
            echo '卸载根卷，操作完成'; \
        else \
            echo '错误: KDK合并失败' && \
            exit 1; \
        fi
        """
        
        let appleScript = """
        do shell script "\(shellScript.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        logPublisher.send("locating_root_vol".localized)
        logPublisher.send("starting_merging_to_root_vol".localized)
        logPublisher.send("slow_step".localized)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.executeAppleScript(script: appleScript) { success, output in
                DispatchQueue.main.async {
                    self.stopProgressUpdates()
                    
                    if success {
                        self.installationProgress = 1.0
                        self.logPublisher.send("merged_completed_umounted".localized)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.isMerging = false
                            self.installationProgress = 0
                        }
                        self.showAlert(title: "merged_successfully".localized, message: "kdk_merged_successfully".localized)
                    } else {
                        self.logPublisher.send("error_merged_kdk_failed".localized + " - \(output ?? "none_out".localized)")
                        self.isMerging = false
                        self.installationProgress = 0
                        self.showAlert(title: "merged_failed".localized, message: output ?? "unkn_error".localized)
                    }
                }
            }
        }
    }
    
    func installKexts(forceOverwrite: Bool, backupExisting: Bool, rebuildCache: Bool, installToLE: Bool, installToPrivateFrameworks: Bool) {
        guard !kextPaths.isEmpty else {
            logPublisher.send("error_not_selected_bundle".localized)
            return
        }
        
        let selectedKDKpath: String
        if let selectedKDKvalue = selectedKDK {
            logPublisher.send("whether_select_kdk".localized + "：\(isKDKSelected)")
            selectedKDKpath = selectedKDKvalue
        } else {
            logPublisher.send("info_not_selected_kdk".localized)
            selectedKDKpath = ""
        }
        
        isInstalling = true
        installationProgress = 0
        logPublisher.send("starting_install_kext".localized)
        logPublisher.send("options".localized + ": " + "force".localized + "=\(forceOverwrite)," +  "backup".localized + "=\(backupExisting)," + "rebuild".localized + "=\(rebuildCache)")
        
        startProgressUpdates()
        
        let shellScript: String
        if isKDKSelected {
            logPublisher.send("starting_merge_and_install".localized)
            shellScript = """
            echo '开始合并KDK并安装Kext...' && \
            echo '开始合并KDK进程...' && \
            ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
            if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
                echo '处理快照' && \
                ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
            else \
                ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
            fi && \
            echo "原始标识符: $ROOT_VOLUME_ORIGIN" && \
            echo "根卷标识符: $ROOT_VOLUME" && \
            if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
                umount /System/Volumes/Update/mnt1; \
            else \
                echo '没有挂载'; \
            fi && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                echo '检测到macOS Big Sur或更高版本' && \
                mkdir -p /System/Volumes/Update/mnt1 && \
                mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
                MOUNT_PATH='/System/Volumes/Update/mnt1'; \
            else \
                echo '检测到macOS Catalina或更早版本' && \
                mount -uw / && \
                MOUNT_PATH='/'; \
            fi && \
            echo "挂载路径: $MOUNT_PATH" && \
            rsync -r -i -a "\(selectedKDKpath)/System/Library/Extensions/" "$MOUNT_PATH/System/Library/Extensions" && \
            \(kextInstallationCommands(mountPath: "$MOUNT_PATH", forceOverwrite: forceOverwrite, backupExisting: backupExisting, installToLE: installToLE, installToPrivateFrameworks: installToPrivateFrameworks)) && \
            \(rebuildCache ? "kmutil create --volume-root \"$MOUNT_PATH\" --update-all --allow-missing-kdk &&" : "") \
            kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
            bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                umount "$MOUNT_PATH"; \
            fi && \
            echo '操作完成'
            """
        } else {
            logPublisher.send("starting_install_kext".localized)
            shellScript = """
            echo '开始安装Kext...' && \
            ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
            if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
                echo '处理快照' && \
                ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
            else \
                ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
            fi && \
            echo "根卷标识符: $ROOT_VOLUME" && \
            if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
                umount /System/Volumes/Update/mnt1; \
            else \
                echo '没有挂载'; \
            fi && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                echo '检测到macOS Big Sur或更高版本' && \
                mkdir -p /System/Volumes/Update/mnt1 && \
                mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
                MOUNT_PATH='/System/Volumes/Update/mnt1'; \
            else \
                echo '检测到macOS Catalina或更早版本' && \
                mount -uw / && \
                MOUNT_PATH='/'; \
            fi && \
            echo "挂载路径: $MOUNT_PATH" && \
            \(kextInstallationCommands(mountPath: "$MOUNT_PATH", forceOverwrite: forceOverwrite, backupExisting: backupExisting, installToLE: installToLE, installToPrivateFrameworks: installToPrivateFrameworks)) && \
            \(rebuildCache ? "kmutil create --volume-root \"$MOUNT_PATH\" --update-all --allow-missing-kdk &&" : "") \
            kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
            bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
            if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
                umount "$MOUNT_PATH"; \
            fi && \
            echo '操作完成'
            """
        }
        
        let appleScript = """
        do shell script "\(shellScript.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.executeAppleScript(script: appleScript) { success, output in
                DispatchQueue.main.async {
                    self.stopProgressUpdates()
                    
                    if success {
                        self.installationProgress = 1.0
                        self.logPublisher.send("install_completed".localized)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            self.isInstalling = false
                            self.installationProgress = 0
                        }
                        self.showAlert(title: "op_successfully".localized, message: "kext_has_been_installed".localized)
                    } else {
                        self.logPublisher.send("error_installed_failed".localized + " - \(output ?? "none_out".localized)")
                        self.isInstalling = false
                        self.installationProgress = 0
                        self.showAlert(title: "op_failed".localized, message: output ?? "unkn_error".localized)
                    }
                }
            }
        }
    }
    
    private func kextInstallationCommands(mountPath: String, forceOverwrite: Bool, backupExisting: Bool, installToLE: Bool, installToPrivateFrameworks: Bool) -> String {
        var commands = [String]()
        let backupDir = "\(NSHomeDirectory())/Desktop/SimpleLoaderBak"
        
        // 创建备份目录（如果需要）
        if backupExisting {
            commands.append("""
                            mkdir -p "\(backupDir)"
                """)
        }
        
        for path in kextPaths {
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            let fileExtension = URL(fileURLWithPath: path).pathExtension.lowercased()
            
            var destDir = ""
            if fileExtension == "framework" {
                destDir = installToPrivateFrameworks ?
                    "\(mountPath)/System/Library/PrivateFrameworks" :
                    "\(mountPath)/System/Library/Frameworks"
            } else {
                destDir = installToLE ?
                    "\(mountPath)/Library/Extensions" :
                    "\(mountPath)/System/Library/Extensions"
            }
            
            let destPath = "\(destDir)/\(fileName)"
            
            commands.append("echo '正在处理 \(fileName)'")
            
            // 备份现有文件（如果需要）
            if backupExisting {
                commands.append("""
                if [ -d "\(destPath)" ]; then \
                    rsync -a "\(destPath)" "\(backupDir)/\(fileName)" && \
                    echo "已备份原有 \(fileName)"; \
                fi
                """)
            }
            
            // 安装新文件
            if forceOverwrite {
                commands.append("""
                rsync -r -i -a --delete "\(path)" "\(destDir)/"
                """)
            } else {
                commands.append("""
                if [ ! -d "\(destPath)" ]; then \
                    rsync -r -i -a "\(path)" "\(destDir)/"; \
                else \
                    echo "跳过已存在的 \(fileName)"; \
                fi
                """)
            }
            
            commands.append("""
                            echo "已处理 \(fileName)"
            """)
        }
        return commands.joined(separator: " && \\\n")
    }
    
    private func startProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isInstalling || self.isMerging else { return }
            
            DispatchQueue.main.async {
                if self.installationProgress < 0.95 {
                    self.installationProgress += 0.05
                }
            }
        }
    }
    
    private func stopProgressUpdates() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func cancelOperation() {
        isInstalling = false
        isMerging = false
        installationProgress = 0
        currentOperation = nil
        stopProgressUpdates()
        logPublisher.send("op_canceled".localized)
    }
    
    func openKDKDirectory() {
        let url = URL(fileURLWithPath: kdkDirectory)
        NSWorkspace.shared.open(url)
        logPublisher.send("opened_kdk_dir".localized + ": \(kdkDirectory)")
    }
    
    private func checkKDKDirectory() {
        let url = URL(fileURLWithPath: kdkDirectory)
        if fileManager.fileExists(atPath: url.path) {
            logPublisher.send("kdk_dir_exists".localized + ": \(kdkDirectory)")
            refreshKDKList()
        } else {
            logPublisher.send("warning_kdk_dir_doesnt_exist".localized)
        }
    }
    
    private func executeAppleScript(script: String, completion: @escaping (Bool, String?) -> Void) {
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)
            if let error = error {
                completion(false, error.description)
            } else {
                completion(true, output.stringValue)
            }
        } else {
            completion(false, "error_cant_gr_as".localized)
        }
    }
    
    func rebuildKernelCache() {
        isInstalling = true
        installationProgress = 0
        logPublisher.send("starting_rebuild".localized)
        
        startProgressUpdates()
        
        let shellScript = """
        echo '开始重建内核缓存...' && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        kmutil create --volume-root "$MOUNT_PATH" --update-all --allow-missing-kdk && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            umount "$MOUNT_PATH"; \
        fi && \
        echo '内核缓存重建完成'
        """
        
        executeScriptWithProgress(shellScript: shellScript, successMessage: "rebuild_successfully".localized, failureMessage: "rebuild_failed".localized)
    }
    
    func createSystemSnapshot() {
        isInstalling = true
        installationProgress = 0
        logPublisher.send("starting_snapshot".localized)
        
        startProgressUpdates()
        
        let shellScript = """
        echo '开始创建系统快照...' && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        bless --mount "$MOUNT_PATH" --bootefi --create-snapshot && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            umount "$MOUNT_PATH"; \
        fi && \
        echo '系统快照创建完成'
        """
        
        executeScriptWithProgress(shellScript: shellScript, successMessage: "snapshot_successfully".localized, failureMessage: "snapshot_failed".localized)
    }
    
    func restoreLastSnapshot() {
        isInstalling = true
        installationProgress = 0
        logPublisher.send("last_sealed_snapshot".localized)
        
        startProgressUpdates()
        
        let shellScript = """
        echo '开始恢复最后一个快照...' && \
        if [[ $(mount | grep -c "/System/Volumes/Update/mnt1") -gt 0 ]]; then \
            umount /System/Volumes/Update/mnt1; \
        else \
            echo '没有挂载'; \
        fi && \
        ROOT_VOLUME_ORIGIN=$(diskutil info -plist / | plutil -extract DeviceIdentifier xml1 -o - - | xmllint --xpath '//string[1]/text()' -) && \
        if [[ $(diskutil info -plist / | grep -c APFSSnapshot) -gt 0 ]]; then \
            echo '处理快照' && \
            ROOT_VOLUME=$(diskutil list | grep -B 1 -- "$ROOT_VOLUME_ORIGIN" | head -n 1 | awk '{print $NF}'); \
        else \
            ROOT_VOLUME=$ROOT_VOLUME_ORIGIN; \
        fi && \
        echo "根卷标识符: $ROOT_VOLUME" && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            echo '检测到macOS Big Sur或更高版本' && \
            mkdir -p /System/Volumes/Update/mnt1 && \
            mount -o nobrowse -t apfs /dev/$ROOT_VOLUME /System/Volumes/Update/mnt1 && \
            MOUNT_PATH='/System/Volumes/Update/mnt1'; \
        else \
            echo '检测到macOS Catalina或更早版本' && \
            mount -uw / && \
            MOUNT_PATH='/'; \
        fi && \
        echo "挂载路径: $MOUNT_PATH" && \
        bless --mount "$MOUNT_PATH" --bootefi --last-sealed-snapshot && \
        if [[ $(sw_vers -productVersion | cut -d '.' -f 1) -ge 11 ]]; then \
            umount "$MOUNT_PATH"; \
        fi && \
        echo '快照恢复完成'
        """
        
        executeScriptWithProgress(shellScript: shellScript, successMessage: "revert_successfully".localized, failureMessage: "revert_failed".localized)
    }
    
    private func executeScriptWithProgress(shellScript: String, successMessage: String, failureMessage: String) {
        let appleScript = """
        do shell script "\(shellScript.replacingOccurrences(of: "\"", with: "\\\""))" with administrator privileges
        """
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.executeAppleScript(script: appleScript) { success, output in
                DispatchQueue.main.async {
                    self.stopProgressUpdates()
                    
                    if success {
                        self.installationProgress = 1.0
                        self.logPublisher.send(successMessage)
                        self.showAlert(title: "op_successfully".localized, message: successMessage)
                    } else {
                        self.logPublisher.send("error".localized + ": \(failureMessage) - \(output ?? "none_out".localized)")
                        self.showAlert(title: "op_failed".localized, message: output ?? failureMessage)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.isInstalling = false
                        self.installationProgress = 0
                    }
                }
            }
        }
    }
}
