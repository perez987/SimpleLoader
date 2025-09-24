import SwiftUI
import UniformTypeIdentifiers

@main
struct SimpleLoaderResInstallerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 400, minHeight: 300)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

struct ContentView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var progress: Double = 0
    @State private var statusText = "prepare_install".localized
    @State private var isInstalling = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.3, green: 0.1, blue: 0.5)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // App icon and title
                VStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("app_title".localized)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 30)
                
                // Status display
                VStack {
                    Text(statusText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.bottom, 5)
                    
                    ProgressView(value: progress, total: 100)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        .padding(.horizontal, 40)
                }
                
                // Action Button
                Button(action: {
                    startInstallation()
                }) {
                    Text(isInstalling ? "installing".localized : "start_install".localized)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(isInstalling ? Color.gray : Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .disabled(isInstalling)
                .padding(.bottom, 30)
            }
            
            // Success Tips
            if showSuccess {
                SuccessOverlay {
                    NSApplication.shared.terminate(nil)
                }
            }
            
            // Error message
            if showError {
                ErrorOverlay(message: errorMessage) {
                    showError = false
                }
            }
        }
    }
    
    func startInstallation() {
        isInstalling = true
        statusText = "finding_target_app".localized
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. Find target applications
                let targetAppName = "SimpleLoader.app"
                guard let targetAppURL = findApplication(named: targetAppName) else {
                    throw InstallationError.targetAppNotFound
                }
                
                DispatchQueue.main.async {
                    self.statusText = "prepare_copy_resources".localized
                    self.progress = 10
                }
                
                // 2. Get the source resource path
                guard let sourceResourcesURL = Bundle.main.resourceURL else {
                    throw InstallationError.sourceResourcesNotFound
                }
                
                let sourcePresetFilesURL = sourceResourcesURL.appendingPathComponent("PresetFiles")
                let sourcePresetsURL = sourceResourcesURL.appendingPathComponent("Presets")
                
                // 3. Check if the source file exists
                if !FileManager.default.fileExists(atPath: sourcePresetFilesURL.path) ||
                   !FileManager.default.fileExists(atPath: sourcePresetsURL.path) {
                    throw InstallationError.sourceFilesNotFound
                }
                
                DispatchQueue.main.async {
                    self.statusText = "copying_preset_files".localized
                    self.progress = 30
                }
                
                // 4. Copy PresetFiles
                let targetPresetFilesURL = targetAppURL.appendingPathComponent("Contents/Resources/PresetFiles")
                try copyDirectory(from: sourcePresetFilesURL, to: targetPresetFilesURL)
                
                DispatchQueue.main.async {
                    self.statusText = "copying_presets".localized
                    self.progress = 70
                }
                
                // 5. Copy Presets
                let targetPresetsURL = targetAppURL.appendingPathComponent("Contents/Resources/Presets")
                try copyDirectory(from: sourcePresetsURL, to: targetPresetsURL)
                
                DispatchQueue.main.async {
                    self.statusText = "安装完成!"
                    self.progress = 100
                    self.showSuccess = true
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                    self.isInstalling = false
                    self.statusText = "安装失败"
                }
            }
        }
    }
    
    // Find an application
    func findApplication(named appName: String) -> URL? {
        let fileManager = FileManager.default
        
        // 1. First check the standard application directory
        if let appsDirectory = fileManager.urls(for: .applicationDirectory, in: .localDomainMask).first {
            let appURL = appsDirectory.appendingPathComponent(appName)
            if fileManager.fileExists(atPath: appURL.path) {
                return appURL
            }
        }
        
        // 2. Check the directory where the current application is located
        let currentDirectoryURL = Bundle.main.bundleURL.deletingLastPathComponent()
        let adjacentAppURL = currentDirectoryURL.appendingPathComponent(appName)
        if fileManager.fileExists(atPath: adjacentAppURL.path) {
            return adjacentAppURL
        }
        
        // 3. Can't find, return nil
        return nil
    }
    
    // Copy Directory
    func copyDirectory(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // If the target directory exists, delete it first
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Create the target directory
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        
        // Get the source directory contents
        let contents = try fileManager.contentsOfDirectory(at: sourceURL, includingPropertiesForKeys: nil, options: [])
        
        for itemURL in contents {
            let destinationItemURL = destinationURL.appendingPathComponent(itemURL.lastPathComponent)
            
            if itemURL.hasDirectoryPath {
                try copyDirectory(from: itemURL, to: destinationItemURL)
            } else {
                try fileManager.copyItem(at: itemURL, to: destinationItemURL)
            }
        }
    }
}

// Successful
struct SuccessOverlay: View {
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("install_success".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("install_success_message".localized)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Button("完成") {
                    onClose()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 150)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(30)
            .background(Color(red: 0.2, green: 0.2, blue: 0.3))
            .cornerRadius(15)
            .shadow(radius: 20)
        }
    }
}

// Error overlay
struct ErrorOverlay: View {
    let message: String
    var onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                
                Text("install_failed".localized)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                
                Button("confirm".localized) {
                    onClose()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(width: 150)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .padding(30)
            .background(Color(red: 0.3, green: 0.2, blue: 0.2))
            .cornerRadius(15)
            .shadow(radius: 20)
        }
    }
}

// Custom error types
enum InstallationError: Error, LocalizedError {
    case targetAppNotFound
    case sourceResourcesNotFound
    case sourceFilesNotFound
    case copyFailed
    
    var errorDescription: String? {
        switch self {
        case .targetAppNotFound:
            return "target_app_not_found".localized
        case .sourceResourcesNotFound:
            return "source_resources_not_found".localized
        case .sourceFilesNotFound:
            return "source_files_not_found".localized
        case .copyFailed:
            return "copy_failed".localized
        }
    }
}
