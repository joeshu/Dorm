# MengguiDorm

一款基于 SwiftUI 实现的《猛鬼宿舍》风格 iOS 塔防生存游戏。

目前仓库已经整理为可持续迭代的结构：
- 游戏源码保留在 `MengguiDorm/`
- 使用 **XcodeGen** 生成 Xcode 工程
- 使用 **GitHub Actions** 自动构建未签名 IPA

## 游戏玩法

- 上床睡觉赚取金币
- 升级房门抵御猛鬼攻击
- 升级床铺提高金币产出
- 建造炮台自动攻击敌人
- 放置陷阱控制或消灭猛鬼

## 技术栈

- SwiftUI
- Swift 5.9
- iOS 16.0+
- XcodeGen
- GitHub Actions
- GitHub Releases（自动附加 unsigned IPA）

## 项目结构

```text
.
├── .github/workflows/
│   └── build-unsigned-ipa.yml
├── ExportOptions.plist
├── project.yml
├── MengguiDorm/
│   ├── MengguiDormApp.swift
│   ├── Models/
│   │   ├── GameEngine.swift
│   │   └── GameModels.swift
│   ├── Views/
│   │   ├── LobbyView.swift
│   │   ├── GameRoomView.swift
│   │   ├── ShopPanelView.swift
│   │   └── GameOverView.swift
│   └── Resources/
│       └── Assets.xcassets/
└── README.md
```

## 本地开发

### 1. 安装 XcodeGen

```bash
brew install xcodegen
```

### 2. 生成 Xcode 工程

```bash
xcodegen generate
```

### 3. 打开工程

```bash
open MengguiDorm.xcodeproj
```

## GitHub Actions 自动构建

仓库已配置工作流：

- `.github/workflows/build-unsigned-ipa.yml`

触发方式：
- push 到 `main` / `master`
- PR 到 `main` / `master`
- 手动触发 `workflow_dispatch`

构建产物：
- `MengguiDorm-IPA`
- 产物中包含 `MengguiDorm.ipa`
- push 到 `main` 时自动创建 GitHub Release 并附加 IPA

## 安装说明

当前构建产物为 **未签名 IPA**，可用于：
- AltStore
- Sideloadly
- 其它签名/侧载工具

## 当前状态

- 已移除损坏的旧 `.xcodeproj` 文件
- 已改为 XcodeGen 生成工程
- GitHub Actions 已成功跑通 unsigned IPA 构建流程

## 后续可继续优化的方向

- 增加正式 App 图标与资源素材
- 优化游戏平衡与数值曲线
- 增加更多波次、敌人、陷阱与炮台类型
- 增加设置页、音效、存档与排行榜
