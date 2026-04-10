import Foundation
import SwiftUI

// MARK: - 游戏状态

enum GameState: Equatable {
    case lobby
    case playing
    case gameOver(Bool)
    case paused
}

// MARK: - 房间模板

struct RoomTemplate: Identifiable, Equatable {
    let id: Int
    let name: String
    let subtitle: String
    let center: CGPoint
    let size: CGSize
    let slotOffsets: [CGPoint]
    let recommendedText: String
    let difficulty: String

    var bedPosition: CGPoint {
        CGPoint(x: center.x, y: center.y + 28)
    }

    var doorPosition: CGPoint {
        CGPoint(x: center.x, y: center.y - size.height / 2)
    }

    var worldSlotPositions: [CGPoint] {
        slotOffsets.map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }
    }
}

// MARK: - 固定建造格

struct BuildSlot: Identifiable, Equatable {
    let id: UUID
    var position: CGPoint
    var building: Building?

    init(id: UUID = UUID(), position: CGPoint, building: Building? = nil) {
        self.id = id
        self.position = position
        self.building = building
    }
}

struct Building: Identifiable, Equatable {
    let id: UUID
    var type: BuildingType
    var level: Int

    init(id: UUID = UUID(), type: BuildingType, level: Int = 1) {
        self.id = id
        self.type = type
        self.level = level
    }

    var displayName: String {
        switch type {
        case .turret: return "炮台"
        case .powerBox: return "发电机"
        case .gameConsole: return "游戏机"
        case .freezeTrap: return "冰冻器"
        case .mineTrap: return "地雷"
        }
    }

    var icon: String {
        switch type {
        case .turret: return "scope"
        case .powerBox: return "bolt.fill"
        case .gameConsole: return "gamecontroller.fill"
        case .freezeTrap: return "snowflake"
        case .mineTrap: return "burst.fill"
        }
    }

    var color: Color {
        switch type {
        case .turret: return .orange
        case .powerBox: return .yellow
        case .gameConsole: return .purple
        case .freezeTrap: return .cyan
        case .mineTrap: return .red
        }
    }

    var powerCost: Int {
        switch type {
        case .turret: return 8 + (level - 1) * 2
        case .powerBox: return 0
        case .gameConsole: return 12 + (level - 1) * 4
        case .freezeTrap: return 4
        case .mineTrap: return 4
        }
    }

    var fireRate: TimeInterval {
        switch type {
        case .turret:
            return max(0.22, 0.85 - Double(level - 1) * 0.08)
        default:
            return 10
        }
    }

    var range: CGFloat {
        switch type {
        case .turret:
            return 145 + CGFloat(level - 1) * 24
        default:
            return 0
        }
    }

    var damage: Double {
        switch type {
        case .turret:
            return 18 + Double(level - 1) * 14
        case .mineTrap:
            return 220 + Double(level - 1) * 90
        default:
            return 0
        }
    }

    var freezeDuration: TimeInterval {
        switch type {
        case .freezeTrap:
            return 2.5 + Double(level - 1) * 0.7
        default:
            return 0
        }
    }

    var economyBoost: Double {
        switch type {
        case .gameConsole:
            return 0.5 + Double(level - 1) * 0.35
        default:
            return 0
        }
    }

    var powerSupply: Int {
        switch type {
        case .powerBox:
            return 18 + (level - 1) * 10
        default:
            return 0
        }
    }
}

enum BuildingType: CaseIterable, Equatable {
    case turret
    case powerBox
    case gameConsole
    case freezeTrap
    case mineTrap
}

// MARK: - 房间

struct Room: Identifiable {
    let id = UUID()
    var template: RoomTemplate
    var doorHP: Double
    var maxDoorHP: Double
    var doorLevel: Int
    var bedLevel: Int
    var goldPerSecond: Double
    var buildSlots: [BuildSlot]

    static let initialDoorHP: Double = 120
    static let initialGoldPerSecond: Double = 4

    init(template: RoomTemplate) {
        self.template = template
        self.doorHP = Room.initialDoorHP
        self.maxDoorHP = Room.initialDoorHP
        self.doorLevel = 1
        self.bedLevel = 1
        self.goldPerSecond = Room.initialGoldPerSecond
        self.buildSlots = template.worldSlotPositions.map { BuildSlot(position: $0) }
    }

    var position: CGPoint { template.center }
    var size: CGSize { template.size }
    var bedPosition: CGPoint { template.bedPosition }
    var doorPosition: CGPoint { template.doorPosition }

    mutating func upgradeDoor() {
        doorLevel += 1
        maxDoorHP = Room.initialDoorHP + Double(doorLevel - 1) * 85
        doorHP = maxDoorHP
    }

    mutating func repairDoor(_ amount: Double) {
        doorHP = min(maxDoorHP, doorHP + amount)
    }

    mutating func upgradeBed() {
        bedLevel += 1
        goldPerSecond = Room.initialGoldPerSecond + Double(bedLevel - 1) * 3.2
    }

    var doorUpgradeCost: Int {
        45 + doorLevel * 35
    }

    var bedUpgradeCost: Int {
        35 + bedLevel * 30
    }

    var totalPowerSupply: Int {
        buildSlots.compactMap { $0.building?.powerSupply }.reduce(0, +)
    }

    var totalPowerUsed: Int {
        buildSlots.compactMap { building in
            guard let building = building.building else { return nil }
            return building.type == .powerBox ? 0 : building.powerCost
        }.reduce(0, +)
    }

    var availablePower: Int {
        max(0, totalPowerSupply - totalPowerUsed)
    }

    var economyMultiplier: Double {
        1 + buildSlots.compactMap { $0.building?.economyBoost }.reduce(0, +)
    }

    var turretCount: Int {
        buildSlots.filter { $0.building?.type == .turret }.count
    }

    var trapCount: Int {
        buildSlots.filter {
            guard let type = $0.building?.type else { return false }
            return type == .freezeTrap || type == .mineTrap
        }.count
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
    var isFrozen: Bool
    var freezeEndTime: Date?
    var level: Int
    var kind: GhostKind

    enum GhostState {
        case idle
        case moving
        case attacking
        case dead
    }

    enum GhostKind: CaseIterable {
        case normal
        case charger
        case tank
        case frostResistant

        var name: String {
            switch self {
            case .normal: return "普通猛鬼"
            case .charger: return "冲锋猛鬼"
            case .tank: return "重甲猛鬼"
            case .frostResistant: return "冰抗猛鬼"
            }
        }

        var color: Color {
            switch self {
            case .normal: return .red
            case .charger: return .orange
            case .tank: return .purple
            case .frostResistant: return .cyan
            }
        }
    }

    init(level: Int = 1, kind: GhostKind = .normal) {
        self.position = CGPoint(x: -100, y: -100)
        self.level = level
        self.kind = kind

        switch kind {
        case .normal:
            self.maxHP = Double(level) * 220
            self.attack = Double(level) * 10
            self.speed = 28
        case .charger:
            self.maxHP = Double(level) * 170
            self.attack = Double(level) * 13
            self.speed = 42
        case .tank:
            self.maxHP = Double(level) * 340
            self.attack = Double(level) * 15
            self.speed = 20
        case .frostResistant:
            self.maxHP = Double(level) * 240
            self.attack = Double(level) * 11
            self.speed = 32
        }

        self.hp = self.maxHP
        self.state = .idle
        self.isFrozen = false
        self.freezeEndTime = nil
    }

    mutating func takeDamage(_ damage: Double) {
        hp = max(0, hp - damage)
        if hp <= 0 {
            state = .dead
        }
    }

    mutating func freeze(duration: TimeInterval) {
        let actualDuration: TimeInterval
        switch kind {
        case .frostResistant:
            actualDuration = max(0.8, duration * 0.45)
        default:
            actualDuration = duration
        }
        isFrozen = true
        freezeEndTime = Date().addingTimeInterval(actualDuration)
    }

    mutating func updateFreezeState() {
        if let end = freezeEndTime, Date() >= end {
            isFrozen = false
            freezeEndTime = nil
        }
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
        self.speed = 520
        self.isHit = false
    }
}

// MARK: - 商店物品

enum ShopItem: Identifiable, CaseIterable {
    case upgradeBed
    case upgradeDoor
    case repairDoor
    case powerBox
    case turret
    case gameConsole
    case freezeTrap
    case mineTrap
    case upgradeBuilding

    var id: String {
        switch self {
        case .upgradeBed: return "upgradeBed"
        case .upgradeDoor: return "upgradeDoor"
        case .repairDoor: return "repairDoor"
        case .powerBox: return "powerBox"
        case .turret: return "turret"
        case .gameConsole: return "gameConsole"
        case .freezeTrap: return "freezeTrap"
        case .mineTrap: return "mineTrap"
        case .upgradeBuilding: return "upgradeBuilding"
        }
    }

    var name: String {
        switch self {
        case .upgradeBed: return "升级床铺"
        case .upgradeDoor: return "升级房门"
        case .repairDoor: return "紧急修门"
        case .powerBox: return "建发电机"
        case .turret: return "建炮台"
        case .gameConsole: return "建游戏机"
        case .freezeTrap: return "建冰冻器"
        case .mineTrap: return "埋地雷"
        case .upgradeBuilding: return "升级选中建筑"
        }
    }

    var icon: String {
        switch self {
        case .upgradeBed: return "bed.double.fill"
        case .upgradeDoor: return "door.left.hand.closed"
        case .repairDoor: return "cross.case.fill"
        case .powerBox: return "bolt.fill"
        case .turret: return "scope"
        case .gameConsole: return "gamecontroller.fill"
        case .freezeTrap: return "snowflake"
        case .mineTrap: return "burst.fill"
        case .upgradeBuilding: return "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .upgradeBed: return .green
        case .upgradeDoor: return .brown
        case .repairDoor: return .mint
        case .powerBox: return .yellow
        case .turret: return .orange
        case .gameConsole: return .purple
        case .freezeTrap: return .cyan
        case .mineTrap: return .red
        case .upgradeBuilding: return .blue
        }
    }

    var description: String {
        switch self {
        case .upgradeBed: return "更快睡觉发育，金币核心"
        case .upgradeDoor: return "提升耐久并瞬间回满"
        case .repairDoor: return "顶住濒死房门，争取发育时间"
        case .powerBox: return "提供电力上限，解锁高级建筑"
        case .turret: return "稳定输出，防守主力"
        case .gameConsole: return "提高金币效率，偏运营"
        case .freezeTrap: return "控住猛鬼，争取输出时间"
        case .mineTrap: return "爆发伤害，克制高压波次"
        case .upgradeBuilding: return "升级当前选中的固定格建筑"
        }
    }
}

// MARK: - 游戏配置

struct GameConfig {
    static let roomSize = CGSize(width: 218, height: 218)
    static let ghostSpawnInterval: TimeInterval = 28
    static let goldTickInterval: TimeInterval = 1
    static let wavesToWin = 5

    static let roomTemplates: [RoomTemplate] = [
        RoomTemplate(
            id: 0,
            name: "A-103",
            subtitle: "中路均衡房",
            center: CGPoint(x: 200, y: 330),
            size: roomSize,
            slotOffsets: [
                CGPoint(x: -60, y: -28), CGPoint(x: 0, y: -28), CGPoint(x: 60, y: -28),
                CGPoint(x: -60, y: 36), CGPoint(x: 0, y: 36), CGPoint(x: 60, y: 36)
            ],
            recommendedText: "适合稳健开局，门床电力都好过渡",
            difficulty: "推荐"
        ),
        RoomTemplate(
            id: 1,
            name: "B-201",
            subtitle: "角落安全房",
            center: CGPoint(x: 200, y: 330),
            size: roomSize,
            slotOffsets: [
                CGPoint(x: -68, y: -42), CGPoint(x: 0, y: -42), CGPoint(x: 68, y: -42),
                CGPoint(x: -68, y: 24), CGPoint(x: 0, y: 24), CGPoint(x: 68, y: 24),
                CGPoint(x: 0, y: 88)
            ],
            recommendedText: "格子更多，适合后期运营型打法",
            difficulty: "简单"
        ),
        RoomTemplate(
            id: 2,
            name: "C-404",
            subtitle: "小房快节奏",
            center: CGPoint(x: 200, y: 330),
            size: CGSize(width: 196, height: 196),
            slotOffsets: [
                CGPoint(x: -54, y: -24), CGPoint(x: 0, y: -24), CGPoint(x: 54, y: -24),
                CGPoint(x: -54, y: 34), CGPoint(x: 0, y: 34)
            ],
            recommendedText: "门压更大，要求更高的经营顺序",
            difficulty: "挑战"
        )
    ]
}
