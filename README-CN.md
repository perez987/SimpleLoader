# SimpleLoader - macOS 系统扩展安装工具

![Swift](https://img.shields.io/badge/Swift-5.5-orange.svg)
![Platform](https://img.shields.io/badge/macOS-11+-blue.svg)
![License](https://img.shields.io/badge/License-GPLv3-green.svg)
[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/laobamac/SimpleLoader)
![GitHub all releases](https://img.shields.io/github/downloads/laobamac/SimpleLoader/total?color=white&style=plastic)

![](Images/SimpleLoader-CN.png)

一款专为 macOS 设计的图形化工具，用于安全地合并 KDK（Kernel Development Kit）和安装内核扩展（Kext）到系统目录。

##### [English version - 英文版](README.md)

## 功能特性

### 核心功能
🔧 **KDK 合并**
- 自动检测 `/Library/Developer/KDKs` 目录下的 KDK 包
- 提供可视化选择界面
- 安全合并 KDK 到系统目录

📦 **Kext 安装**
- 拖放式文件选择界面
- 支持批量安装多个 Kext
- 可选的强制覆盖和备份功能

### 系统工具
⚡ **缓存管理**
- 一键重建内核缓存
- 自动处理 Big Sur 及以上版本的只读系统卷

📸 **快照保护**
- 创建 APFS 系统快照
- 恢复到最后一次快照状态
- 防止系统损坏的安全网

## 技术栈

- **语言**: Swift 5.5
- **UI框架**: SwiftUI
- **最低系统要求**: macOS 11 Big Sur
- **依赖管理**: Swift Package Manager

## 安装方法

### 手动安装
1. 下载最新版本 [Release](https://github.com/laobamac/SimpleLoader/releases)
2. 解压后拖拽到 Applications 文件夹

## 使用指南

1. **选择 KDK**
   - 从下拉菜单中选择已安装的 KDK 版本
   - 点击"刷新"按钮更新列表

2. **添加 Kext**
   - 拖放 `.kext/.bundle` 文件到指定区域，或点击按钮选择文件
   - 可随时移除已选文件

3. **设置选项**
   - 强制覆盖：覆盖同名 Kext
   - 备份现有：自动备份被替换的 Kext 到桌面

4. **执行操作**
   - "仅合并 KDK"：只处理 KDK 不安装 Kext
   - "开始安装"：合并 KDK 并安装所有选中的 Kext

## 高级功能

### 系统维护工具
- **重建缓存**：修复内核扩展缓存
- **创建快照**：创建系统恢复点
- **恢复快照**：回滚到上次快照状态

## 开发者

👨‍💻 **laobamac**
- GitHub: [@laobamac](https://github.com/laobamac)
- 邮箱: wxcznb@qq.com

## 贡献指南

欢迎提交 Issue 和 Pull Request！
请确保代码符合项目规范并通过测试。

## 开源协议

本项目采用 **GNU General Public License v3.0** 开源协议。
完整协议内容见 [LICENSE](LICENSE) 文件。
