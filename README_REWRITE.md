# MengguiDorm（重写版 CI 工程）

这个版本保留了现有 SwiftUI 游戏代码，并改为 **XcodeGen + GitHub Actions** 的稳定构建方式。

## 当前结构

```text
.
├── .github/workflows/build-unsigned-ipa.yml
├── ExportOptions.plist
├── project.yml
└── MengguiDorm/
    ├── MengguiDormApp.swift
    ├── Models/
    ├── Views/
    └── Resources/
```

## 本次重写的重点

- 不再依赖手写且已损坏的 `.xcodeproj`
- 使用 `project.yml` 在 CI 上自动生成 `MengguiDorm.xcodeproj`
- workflow 中先 `xcodegen generate`，再执行 `xcodebuild archive`
- 最终导出未签名 IPA artifact：`MengguiDorm.ipa`

## 本地使用

### 1. 安装 XcodeGen

```bash
brew install xcodegen
```

### 2. 生成工程

```bash
xcodegen generate
```

### 3. 打开工程

```bash
open MengguiDorm.xcodeproj
```

## GitHub Actions

工作流文件：

- `.github/workflows/build-unsigned-ipa.yml`

触发条件：
- push 到 `main/master`
- pull request 到 `main/master`
- 手动触发 `workflow_dispatch`

产物：
- `MengguiDorm-IPA`
- 内含 `MengguiDorm.ipa`

## 注意

如果后续你要真机安装：
- 当前产物是 **unsigned IPA**
- 可配合 AltStore / Sideloadly / 其它签名工具安装

如果你希望，我下一步可以继续：
1. 直接把旧的损坏 `build-ipa.yml` 替换掉
2. 顺手整理 `.gitignore`
3. 帮你生成一个可直接提交的修复 patch 清单
