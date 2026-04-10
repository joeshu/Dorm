# 猛鬼宿舍 iOS 版 (MengguiDorm)

一款紧张刺激的塔防生存游戏 iOS 版本，灵感来自经典的猛鬼宿舍小游戏。

## 游戏特色

### 🎮 核心玩法
- **上床睡觉赚取金币** - 只有睡觉时才能持续获得金币
- **升级房门抵御猛鬼** - 提升房门耐久度，修复破损
- **升级床铺提高效率** - 更高等级的床铺产出更多金币
- **建造炮台自动攻击** - 炮台会自动攻击范围内的猛鬼
- **放置陷阱控制猛鬼** - 冰冻陷阱、高爆地雷、能量盾

### 👻 智能 AI 系统
- **猛鬼 AI** - 自动寻路、攻击房门、受击反馈
- **炮台 AI** - 自动检测范围内敌人并攻击
- **波数递增** - 随着波数增加，猛鬼越来越强

### 🛒 商店系统
| 物品 | 价格 | 效果 |
|------|------|------|
| 升级大门 | 50×等级 | 提升房门耐久并修复 |
| 升级床铺 | 40×等级 | 增加金币产出速度 |
| 防御塔 | 100×等级 | 自动攻击范围内猛鬼 |
| 冰冻陷阱 | 150 | 冻结猛鬼3秒 |
| 高爆地雷 | 300 | 造成巨额瞬间伤害 |
| 能量盾 | 200 | 临时保护房门 |

## 游戏截图

### 游戏大厅
精美的渐变背景，清晰的游戏说明

### 游戏场景
- 房间、门、床的可视化展示
- 猛鬼、炮台、陷阱实时渲染
- 子弹飞行轨迹动画
- 血量条实时显示

### 商店面板
毛玻璃风格的商店界面，清晰的物品分类

### 游戏结束
胜利/失败界面，详细的游戏统计

## 技术栈

- **框架**: SwiftUI
- **语言**: Swift 5.9
- **最低版本**: iOS 16.0
- **架构**: MVVM

## 安装方法

### 方法一：从 GitHub Actions 下载
1. 访问 [Actions](https://github.com/你的用户名/MengguiDorm/actions) 页面
2. 选择最新的成功构建
3. 下载 `MengguiDorm-IPA` 构件
4. 使用 AltStore、Sideloadly 或 Xcode 安装

### 方法二：自行构建
1. 克隆仓库
```bash
git clone https://github.com/你的用户名/MengguiDorm.git
cd MengguiDorm
```

2. 使用 Xcode 打开项目
```bash
open MengguiDorm.xcodeproj
```

3. 选择目标设备，点击运行

## GitHub Actions 自动构建

本项目配置了 GitHub Actions 工作流，可以自动构建 IPA 文件：

- **触发条件**:
  - 推送到 main/master 分支
  - 手动触发 (workflow_dispatch)
  
- **构建产物**:
  - 未签名的 IPA 文件
  - 自动上传到 GitHub Releases

## 游戏攻略

### 前期策略
1. **优先升级床铺** - 确保持续的金币来源
2. **适时升级门** - 不要等门快破了才升级
3. **建造炮台** - 尽早建造炮台进行防御

### 中期策略
1. **平衡发展** - 床铺、门、炮台均衡升级
2. **放置陷阱** - 在门口放置冰冻陷阱控制猛鬼
3. **多建炮台** - 炮台越多，输出越高

### 紧急技巧
- 当房门血量告急时，点击"升级大门"可以瞬间回满血量
- 预判猛鬼的进攻路线，提前放置陷阱
- 利用冰冻陷阱争取发育时间

## 项目结构

```
MengguiDorm/
├── MengguiDorm.xcodeproj/      # Xcode 项目
├── MengguiDorm/
│   ├── Models/
│   │   ├── GameModels.swift    # 游戏数据模型
│   │   └── GameEngine.swift    # 游戏核心引擎
│   ├── Views/
│   │   ├── LobbyView.swift     # 游戏大厅
│   │   ├── GameRoomView.swift  # 游戏主界面
│   │   ├── ShopPanelView.swift # 商店面板
│   │   └── GameOverView.swift  # 游戏结束界面
│   ├── Resources/
│   │   └── Assets.xcassets/    # 资源文件
│   └── MengguiDormApp.swift    # 应用入口
├── .github/workflows/
│   └── build-ipa.yml           # GitHub Actions 配置
└── README.md                   # 项目说明
```

## 系统要求

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## 许可证

MIT License

## 致谢

灵感来源于 [xiaopan0215/project_mgss](https://github.com/xiaopan0215/project_mgss)
