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
    @State private var progress: Double = 0
    @State private var statusText = "准备安装资源文件"
    @State private var isInstalling = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: [Color(red: 0.1, green: 0.2, blue: 0.45), Color(red: 0.3, green: 0.1, blue: 0.5)]),
                           startPoint: .top,
                           endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 应用图标和标题
                VStack {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("SimpleLoader 资源安装工具")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.top, 30)
                
                // 状态显示
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
                
                // 操作按钮
                Button(action: {
                    startInstallation()
                }) {
                    Text(isInstalling ? "安装中..." : "开始安装")
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
            
            // 成功提示
            if showSuccess {
                SuccessOverlay {
                    NSApplication.shared.terminate(nil)
                }
            }
            
            // 错误提示
            if showError {
                ErrorOverlay(message: errorMessage) {
                    showError = false
                }
            }
        }
    }
    
    func startInstallation() {
        isInstalling = true
        statusText = "正在查找目标应用..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // 1. 查找目标应用
                let targetAppName = "SimpleLoader.app"
                guard let targetAppURL = findApplication(named: targetAppName) else {
                    throw InstallationError.targetAppNotFound
                }
                
                DispatchQueue.main.async {
                    self.statusText = "准备复制资源文件..."
                    self.progress = 10
                }
                
                // 2. 获取源资源路径
                guard let sourceResourcesURL = Bundle.main.resourceURL else {
                    throw InstallationError.sourceResourcesNotFound
                }
                
                let sourcePresetFilesURL = sourceResourcesURL.appendingPathComponent("PresetFiles")
                let sourcePresetsURL = sourceResourcesURL.appendingPathComponent("Presets")
                
                // 3. 检查源文件是否存在
                if !FileManager.default.fileExists(atPath: sourcePresetFilesURL.path) ||
                   !FileManager.default.fileExists(atPath: sourcePresetsURL.path) {
                    throw InstallationError.sourceFilesNotFound
                }
                
                DispatchQueue.main.async {
                    self.statusText = "正在复制 PresetFiles..."
                    self.progress = 30
                }
                
                // 4. 复制 PresetFiles
                let targetPresetFilesURL = targetAppURL.appendingPathComponent("Contents/Resources/PresetFiles")
                try copyDirectory(from: sourcePresetFilesURL, to: targetPresetFilesURL)
                
                DispatchQueue.main.async {
                    self.statusText = "正在复制 Presets..."
                    self.progress = 70
                }
                
                // 5. 复制 Presets
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
    
    // 查找应用程序
    func findApplication(named appName: String) -> URL? {
        let fileManager = FileManager.default
        
        // 1. 首先检查标准应用程序目录
        if let appsDirectory = fileManager.urls(for: .applicationDirectory, in: .localDomainMask).first {
            let appURL = appsDirectory.appendingPathComponent(appName)
            if fileManager.fileExists(atPath: appURL.path) {
                return appURL
            }
        }
        
        // 2. 检查当前应用所在目录
        let currentDirectoryURL = Bundle.main.bundleURL.deletingLastPathComponent()
        let adjacentAppURL = currentDirectoryURL.appendingPathComponent(appName)
        if fileManager.fileExists(atPath: adjacentAppURL.path) {
            return adjacentAppURL
        }
        
        // 3. 都找不到返回nil
        return nil
    }
    
    // 复制目录
    func copyDirectory(from sourceURL: URL, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        
        // 如果目标目录存在，先删除
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // 创建目标目录
        try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
        
        // 获取源目录内容
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

// 成功覆盖层
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
                
                Text("安装成功!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("资源文件已成功安装到 SimpleLoader.app")
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

// 错误覆盖层
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
                
                Text("安装失败")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 300)
                
                Button("确定") {
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

// 自定义错误类型
enum InstallationError: Error, LocalizedError {
    case targetAppNotFound
    case sourceResourcesNotFound
    case sourceFilesNotFound
    case copyFailed
    
    var errorDescription: String? {
        switch self {
        case .targetAppNotFound:
            return "找不到 SimpleLoader.app\n请确保它已安装在应用程序文件夹或与此安装程序同一目录"
        case .sourceResourcesNotFound:
            return "找不到源资源文件夹"
        case .sourceFilesNotFound:
            return "源资源文件夹中缺少 PresetFiles 或 Presets 文件夹"
        case .copyFailed:
            return "复制文件时出错"
        }
    }
}
