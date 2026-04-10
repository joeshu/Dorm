import Foundation
import SwiftUI

// MARK: - 游戏状态
enum GameState: Equatable {
    case lobby
    case playing
    case gameOver(Bool) // true = win, false = lose
    case paused
}

// MARK: - 房间
struct Room: Identifiable {
    let id = UUID()
    var doorHP: Double
    var maxDoorHP: Double
    var doorLevel: Int
    var bedLevel: Int
    var goldPerSecond: Double
    var turrets: [Turret]
    var traps: [Trap]
    var position: CGPoint
    var size: CGSize
    
    static let initialDoorHP: Double = 100
    static let initialGoldPerSecond: Double = 5
    
    init(position: CGPoint, size: CGSize) {
        self.doorHP = Room.initialDoorHP
        self.maxDoorHP = Room.initialDoorHP
        self.doorLevel = 1
        self.bedLevel = 1
        self.goldPerSecond = Room.initialGoldPerSecond
        self.turrets = []
        self.traps = []
        self.position = position
        self.size = size
    }
    
    mutating func upgradeDoor() {
        doorLevel += 1
        let increase = Double(doorLevel) * 50
        maxDoorHP = Room.initialDoorHP + increase
        doorHP = maxDoorHP // 修复满血
    }
    
    mutating func upgradeBed() {
        bedLevel += 1
        goldPerSecond = Room.initialGoldPerSecond * Double(bedLevel)
    }
    
    var doorUpgradeCost: Int {
        return 50 * doorLevel
    }
    
    var bedUpgradeCost: Int {
        return 40 * bedLevel
    }
}

// MARK: - 玩家
struct Player: Identifiable {
    let id = UUID()
    var position: CGPoint
    var isSleeping: Bool
    var gold: Int
    var maxHP: Double
    var hp: Double
    var isInRoom: Bool
    
    init(position: CGPoint) {
        self.position = position
        self.isSleeping = false
        self.gold = 0
        self.maxHP = 100
        self.hp = 100
        self.isInRoom = true
    }
}

// MARK: - 猛鬼
struct Ghost: Identifiable {
    let id = UUID()
    var position: CGPoint
    var hp: Double
    var maxHP: Double
    var attack: Double
    var speed: CGFloat
    var state: GhostState
    var targetRoomID: UUID?
    var isFrozen: Bool
    var freezeEndTime: Date?
    var level: Int
    
    enum GhostState {
        case idle
        case moving
        case attacking
        case dead
    }
    
    init(level: Int = 1) {
        self.position = CGPoint(x: -100, y: -100)
        self.maxHP = Double(level) * 200
        self.hp = self.maxHP
        self.attack = Double(level) * 10
        self.speed = 30
        self.state = .idle
        self.targetRoomID = nil
        self.isFrozen = false
        self.freezeEndTime = nil
        self.level = level
    }
    
    mutating func takeDamage(_ damage: Double) {
        hp = max(0, hp - damage)
        if hp <= 0 {
            state = .dead
        }
    }
    
    mutating func freeze(duration: TimeInterval) {
        isFrozen = true
        freezeEndTime = Date().addingTimeInterval(duration)
    }
    
    mutating func updateFreezeState() {
        if let endTime = freezeEndTime, Date() >= endTime {
            isFrozen = false
            freezeEndTime = nil
        }
    }
}

// MARK: - 炮台
struct Turret: Identifiable {
    let id = UUID()
    var position: CGPoint
    var level: Int
    var damage: Double
    var range: CGFloat
    var fireRate: TimeInterval // 射击间隔
    var lastFireTime: Date?
    var angle: Double // 朝向角度
    
    init(position: CGPoint) {
        self.position = position
        self.level = 1
        self.damage = 15
        self.range = 150
        self.fireRate = 0.5
        self.lastFireTime = nil
        self.angle = 0
    }
    
    mutating func upgrade() {
        level += 1
        damage = 15 * Double(level)
        range = 150 + CGFloat(level) * 20
        fireRate = max(0.1, 0.5 - Double(level) * 0.05)
    }
    
    var upgradeCost: Int {
        return 80 * level
    }
    
    var canFire: Bool {
        guard let lastFire = lastFireTime else { return true }
        return Date().timeIntervalSince(lastFire) >= fireRate
    }
}

// MARK: - 陷阱
struct Trap: Identifiable {
    let id = UUID()
    var position: CGPoint
    var type: TrapType
    var isTriggered: Bool
    var triggerTime: Date?
    
    enum TrapType {
        case freeze(duration: TimeInterval)
        case mine(damage: Double)
        case shield(duration: TimeInterval)
        
        var name: String {
            switch self {
            case .freeze: return "冰冻陷阱"
            case .mine: return "高爆地雷"
            case .shield: return "能量盾"
            }
        }
        
        var icon: String {
            switch self {
            case .freeze: return "snowflake"
            case .mine: return "burst.fill"
            case .shield: return "shield.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .freeze: return .cyan
            case .mine: return .red
            case .shield: return .blue
            }
        }
        
        var cost: Int {
            switch self {
            case .freeze: return 150
            case .mine: return 300
            case .shield: return 200
            }
        }
    }
    
    init(position: CGPoint, type: TrapType) {
        self.position = position
        self.type = type
        self.isTriggered = false
        self.triggerTime = nil
    }
}

// MARK: - 子弹
struct Bullet: Identifiable {
    let id = UUID()
    var position: CGPoint
    var targetPosition: CGPoint
    var damage: Double
    var speed: CGFloat
    var isHit: Bool
    
    init(position: CGPoint, target: CGPoint, damage: Double) {
        self.position = position
        self.targetPosition = target
        self.damage = damage
        self.speed = 500
        self.isHit = false
    }
}

// MARK: - 商店物品
enum ShopItem: Identifiable, CaseIterable {
    case upgradeDoor
    case upgradeBed
    case turret
    case freezeTrap
    case mineTrap
    case shieldTrap
    
    var id: String {
        switch self {
        case .upgradeDoor: return "upgradeDoor"
        case .upgradeBed: return "upgradeBed"
        case .turret: return "turret"
        case .freezeTrap: return "freezeTrap"
        case .mineTrap: return "mineTrap"
        case .shieldTrap: return "shieldTrap"
        }
    }
    
    var name: String {
        switch self {
        case .upgradeDoor: return "升级大门"
        case .upgradeBed: return "升级床铺"
        case .turret: return "防御塔"
        case .freezeTrap: return "冰冻陷阱"
        case .mineTrap: return "高爆地雷"
        case .shieldTrap: return "能量盾"
        }
    }
    
    var icon: String {
        switch self {
        case .upgradeDoor: return "door.left.hand.closed"
        case .upgradeBed: return "bed.double.fill"
        case .turret: return "scope"
        case .freezeTrap: return "snowflake"
        case .mineTrap: return "burst.fill"
        case .shieldTrap: return "shield.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .upgradeDoor: return .brown
        case .upgradeBed: return .green
        case .turret: return .orange
        case .freezeTrap: return .cyan
        case .mineTrap: return .red
        case .shieldTrap: return .blue
        }
    }
    
    var description: String {
        switch self {
        case .upgradeDoor: return "提升房门耐久并修复"
        case .upgradeBed: return "增加金币产出速度"
        case .turret: return "自动攻击范围内的猛鬼"
        case .freezeTrap: return "冻结猛鬼数秒"
        case .mineTrap: return "造成巨额瞬间伤害"
        case .shieldTrap: return "临时保护房门"
        }
    }
    
    func getCost(level: Int = 1) -> Int {
        switch self {
        case .upgradeDoor: return 50 * level
        case .upgradeBed: return 40 * level
        case .turret: return 100 * level
        case .freezeTrap: return 150
        case .mineTrap: return 300
        case .shieldTrap: return 200
        }
    }
    
    var isUpgrade: Bool {
        switch self {
        case .upgradeDoor, .upgradeBed: return true
        default: return false
        }
    }
    
    var isTrap: Bool {
        switch self {
        case .freezeTrap, .mineTrap, .shieldTrap: return true
        default: return false
        }
    }
}

// MARK: - 游戏配置
struct GameConfig {
    static let roomSize = CGSize(width: 200, height: 200)
    static let playerSpeed: CGFloat = 150
    static let ghostSpawnInterval: TimeInterval = 30
    static let goldTickInterval: TimeInterval = 1
    static let maxTurrets = 4
    static let maxTraps = 6
}
