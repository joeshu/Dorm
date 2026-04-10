import Foundation
import SwiftUI
import Combine

@MainActor
class GameEngine: ObservableObject {
    @AppStorage("mengguiDorm.bestWave") var bestWave: Int = 0
    @AppStorage("mengguiDorm.bestScore") var bestScore: Int = 0

    @Published var gameState: GameState = .lobby
    @Published var selectedRoomTemplate: RoomTemplate? = GameConfig.roomTemplates.first
    @Published var room: Room
    @Published var player: Player
    @Published var ghost: Ghost?
    @Published var bullets: [Bullet] = []
    @Published var gameTime: TimeInterval = 0
    @Published var waveNumber: Int = 0
    @Published var lastEventText: String = "先选宿舍，再开始躺平发育"
    @Published var isFastForwardEnabled: Bool = false
    @Published var prepCountdown: Int = 8
    @Published var selectedSlotID: UUID?

    private var timers: [Timer] = []
    private var lastUpdateTime: Date?
    private var buildingLastFireTimes: [UUID: Date] = [:]

    let gameBounds = CGRect(x: 0, y: 0, width: 400, height: 520)

    init() {
        let template = GameConfig.roomTemplates.first!
        self.room = Room(template: template)
        self.player = Player(position: CGPoint(x: template.center.x, y: template.center.y + 52))
    }

    func selectRoom(_ template: RoomTemplate) {
        selectedRoomTemplate = template
        let slotCount = template.slotOffsets.count
        lastEventText = "已选择 \(template.name)：\(slotCount) 个建造格，\(template.recommendedText)"
    }

    func startGame() {
        let template = selectedRoomTemplate ?? GameConfig.roomTemplates.first!
        gameState = .playing
        gameTime = 0
        waveNumber = 0
        prepCountdown = 8
        lastEventText = "抢到 \(template.name)，先上床赚金币，再补门和电力"
        isFastForwardEnabled = false
        selectedSlotID = nil
        bullets.removeAll()
        ghost = nil
        buildingLastFireTimes.removeAll()
        lastUpdateTime = nil

        room = Room(template: template)
        player = Player(position: CGPoint(x: template.center.x, y: template.center.y + 52))

        startGameLoop()
        startGoldGeneration()
        startGhostSpawning()
    }

    func quickStartGame() {
        startGame()
        player.gold = 180
        _ = buyItem(.upgradeBed)
        _ = buyItem(.powerBox)
        autoSelectFirstEmptySlotIfNeeded()
        _ = buyItem(.turret)
        lastEventText = "快速开局：床、电力、炮台已成型，继续补门"
    }

    func pauseGame() {
        gameState = .paused
        stopAllTimers()
    }

    func resumeGame() {
        gameState = .playing
        startGameLoop()
        startGoldGeneration()
        startGhostSpawning()
    }

    func endGame(win: Bool) {
        persistBestRecordIfNeeded()
        gameState = .gameOver(win)
        stopAllTimers()
    }

    func resetGame() {
        stopAllTimers()
        gameState = .lobby
        gameTime = 0
        waveNumber = 0
        ghost = nil
        bullets.removeAll()
        selectedSlotID = nil
        lastEventText = "先选宿舍，再开始躺平发育"
    }

    private func stopAllTimers() {
        timers.forEach { $0.invalidate() }
        timers.removeAll()
    }

    private func startGameLoop() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
        timers.append(timer)
    }

    private var timeScale: Double {
        isFastForwardEnabled ? 2.0 : 1.0
    }

    private var sleepGoldMultiplier: Double {
        2.0
    }

    private var isNearBed: Bool {
        let dx = player.position.x - room.bedPosition.x
        let dy = player.position.y - room.bedPosition.y
        return sqrt(dx * dx + dy * dy) <= 42
    }

    private func update() {
        guard gameState == .playing else { return }

        let now = Date()
        let rawDelta = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 1 / 60
        let deltaTime = rawDelta * timeScale
        lastUpdateTime = now

        gameTime += deltaTime
        updateGhost(deltaTime: deltaTime)
        updateBuildings(deltaTime: deltaTime)
        updateBullets(deltaTime: deltaTime)
        checkGameEnd()
    }

    private func startGoldGeneration() {
        let timer = Timer.scheduledTimer(withTimeInterval: GameConfig.goldTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.gameState == .playing else { return }
                guard self.player.isSleeping else { return }

                let income = self.room.goldPerSecond * self.room.economyMultiplier * self.sleepGoldMultiplier * self.timeScale
                self.player.gold += Int(income.rounded(.down))
            }
        }
        timers.append(timer)
    }

    private func startGhostSpawning() {
        let countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, self.gameState == .playing else {
                    timer.invalidate()
                    return
                }

                if self.prepCountdown > 1 {
                    self.prepCountdown -= 1
                    self.lastEventText = "第 1 波将在 \(self.prepCountdown) 秒后到达，优先升床或补门"
                } else {
                    self.prepCountdown = 0
                    self.spawnGhost()
                    timer.invalidate()
                }
            }
        }
        timers.append(countdownTimer)

        let timer = Timer.scheduledTimer(withTimeInterval: GameConfig.ghostSpawnInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.gameState == .playing else { return }
                if self.ghost?.state == .dead || self.ghost == nil {
                    self.spawnGhost()
                }
            }
        }
        timers.append(timer)
    }

    private func spawnGhost() {
        waveNumber += 1
        let kind: Ghost.GhostKind
        if waveNumber % 5 == 0 {
            kind = .tank
        } else if waveNumber % 3 == 0 {
            kind = .charger
        } else if waveNumber % 4 == 0 {
            kind = .frostResistant
        } else {
            kind = .normal
        }

        ghost = Ghost(level: waveNumber, kind: kind)
        lastEventText = "第 \(waveNumber) 波：\(kind.name) 已盯上 \(room.template.name)"

        let spawnPoints = [
            CGPoint(x: -50, y: gameBounds.midY),
            CGPoint(x: gameBounds.maxX + 50, y: gameBounds.midY),
            CGPoint(x: gameBounds.midX, y: -50),
            CGPoint(x: gameBounds.midX, y: gameBounds.maxY + 50)
        ]
        ghost?.position = spawnPoints.randomElement()!
        ghost?.state = .moving
    }

    private func updateGhost(deltaTime: TimeInterval) {
        guard var ghost = ghost else { return }
        ghost.updateFreezeState()

        if ghost.state == .dead {
            self.ghost = ghost
            return
        }

        if ghost.isFrozen {
            self.ghost = ghost
            return
        }

        let doorPos = room.doorPosition
        let dx = doorPos.x - ghost.position.x
        let dy = doorPos.y - ghost.position.y
        let distance = max(1, sqrt(dx * dx + dy * dy))

        if distance < 28 {
            ghost.state = .attacking
            room.doorHP -= ghost.attack * deltaTime
            if room.doorHP <= 0 {
                room.doorHP = 0
                endGame(win: false)
            }
        } else {
            ghost.state = .moving
            let moveDistance = ghost.speed * CGFloat(deltaTime)
            ghost.position.x += (dx / distance) * moveDistance
            ghost.position.y += (dy / distance) * moveDistance
        }

        self.ghost = ghost
    }

    private func updateBuildings(deltaTime: TimeInterval) {
        guard let ghost = ghost, ghost.state != .dead else { return }

        for slotIndex in room.buildSlots.indices {
            guard let building = room.buildSlots[slotIndex].building else { continue }
            let buildingID = room.buildSlots[slotIndex].id

            switch building.type {
            case .turret:
                let dx = ghost.position.x - room.buildSlots[slotIndex].position.x
                let dy = ghost.position.y - room.buildSlots[slotIndex].position.y
                let distance = sqrt(dx * dx + dy * dy)
                guard distance <= building.range else { continue }

                let now = Date()
                let lastFire = buildingLastFireTimes[buildingID]
                let canFire = lastFire == nil || now.timeIntervalSince(lastFire!) >= building.fireRate
                if canFire {
                    fireBullet(from: room.buildSlots[slotIndex].position, target: ghost.position, damage: building.damage)
                    buildingLastFireTimes[buildingID] = now
                }

            case .freezeTrap:
                let dx = ghost.position.x - room.buildSlots[slotIndex].position.x
                let dy = ghost.position.y - room.buildSlots[slotIndex].position.y
                let distance = sqrt(dx * dx + dy * dy)
                if distance < 26 {
                    var updatedGhost = ghost
                    updatedGhost.freeze(duration: building.freezeDuration)
                    self.ghost = updatedGhost
                    room.buildSlots[slotIndex].building = nil
                    lastEventText = "冰冻器生效，拖住了猛鬼"
                }

            case .mineTrap:
                let dx = ghost.position.x - room.buildSlots[slotIndex].position.x
                let dy = ghost.position.y - room.buildSlots[slotIndex].position.y
                let distance = sqrt(dx * dx + dy * dy)
                if distance < 24 {
                    var updatedGhost = ghost
                    updatedGhost.takeDamage(building.damage)
                    self.ghost = updatedGhost
                    room.buildSlots[slotIndex].building = nil
                    lastEventText = "地雷爆炸，打出了爆发伤害"
                    if updatedGhost.state == .dead {
                        player.gold += 55 * waveNumber
                        lastEventText = "地雷击退了本波猛鬼"
                    }
                }

            case .powerBox, .gameConsole:
                continue
            }
        }
    }

    private func fireBullet(from: CGPoint, target: CGPoint, damage: Double) {
        bullets.append(Bullet(position: from, target: target, damage: damage))
    }

    private func updateBullets(deltaTime: TimeInterval) {
        guard let ghost = ghost else {
            bullets.removeAll()
            return
        }

        for i in bullets.indices.reversed() {
            let dx = bullets[i].targetPosition.x - bullets[i].position.x
            let dy = bullets[i].targetPosition.y - bullets[i].position.y
            let distance = sqrt(dx * dx + dy * dy)

            if distance < 10 || bullets[i].isHit {
                if !bullets[i].isHit && ghost.state != .dead {
                    var updatedGhost = ghost
                    updatedGhost.takeDamage(bullets[i].damage)
                    self.ghost = updatedGhost
                    if updatedGhost.state == .dead {
                        player.gold += 50 * waveNumber
                        lastEventText = "成功守住第 \(waveNumber) 波"
                    }
                }
                bullets.remove(at: i)
            } else {
                let moveDistance = bullets[i].speed * CGFloat(deltaTime)
                bullets[i].position.x += (dx / distance) * moveDistance
                bullets[i].position.y += (dy / distance) * moveDistance
            }
        }
    }

    private func checkGameEnd() {
        guard let ghost = ghost else { return }
        if ghost.state == .dead && waveNumber >= GameConfig.wavesToWin {
            lastEventText = "你成功守住了 \(GameConfig.wavesToWin) 波进攻"
            endGame(win: true)
        }
    }

    func movePlayer(to point: CGPoint) {
        let halfRoomWidth = room.size.width / 2 - 24
        let halfRoomHeight = room.size.height / 2 - 24
        let minX = room.position.x - halfRoomWidth
        let maxX = room.position.x + halfRoomWidth
        let minY = room.position.y - halfRoomHeight
        let maxY = room.position.y + halfRoomHeight

        player.position = CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
        player.isInRoom = true
    }

    func toggleSleep() {
        guard isNearBed else {
            lastEventText = "请先走到床边，再开始躺平发育"
            return
        }
        player.isSleeping.toggle()
        lastEventText = player.isSleeping ? "开始睡觉，当前金币收益为 2 倍" : "已起床，赶紧补门和建筑"
    }

    func toggleFastForward() {
        isFastForwardEnabled.toggle()
        lastEventText = isFastForwardEnabled ? "已开启 2x 节奏" : "已恢复正常速度"
    }

    func selectSlot(_ slotID: UUID) {
        selectedSlotID = selectedSlotID == slotID ? nil : slotID
        guard let slot = room.buildSlots.first(where: { $0.id == selectedSlotID }) else { return }
        if let building = slot.building {
            lastEventText = "已选中 \(building.displayName) Lv.\(building.level)"
        } else {
            lastEventText = "已选中空地，可以建造建筑"
        }
    }

    private func autoSelectFirstEmptySlotIfNeeded() {
        if selectedSlot == nil {
            selectedSlotID = room.buildSlots.first(where: { $0.building == nil })?.id
        }
    }

    func buyItem(_ item: ShopItem) -> Bool {
        let cost = getCost(for: item)
        guard player.gold >= cost else { return false }

        switch item {
        case .upgradeBed:
            guard room.bedLevel < 10 else { return false }
            player.gold -= cost
            room.upgradeBed()
            lastEventText = "床铺升级到 Lv.\(room.bedLevel)，发育速度提升"
            return true

        case .upgradeDoor:
            guard room.doorLevel < 10 else { return false }
            player.gold -= cost
            room.upgradeDoor()
            lastEventText = "房门升级到 Lv.\(room.doorLevel)，并已回满血"
            return true

        case .repairDoor:
            guard room.doorHP < room.maxDoorHP else { return false }
            player.gold -= cost
            room.repairDoor(65)
            lastEventText = "紧急修门成功，继续争取发育时间"
            return true

        case .powerBox, .turret, .gameConsole, .freezeTrap, .mineTrap:
            autoSelectFirstEmptySlotIfNeeded()
            guard let index = selectedSlotIndex else {
                lastEventText = "没有空余建造格了"
                return false
            }
            guard room.buildSlots[index].building == nil else {
                lastEventText = "当前格子已有建筑，请先换一个空格"
                return false
            }

            let type: BuildingType
            switch item {
            case .powerBox: type = .powerBox
            case .turret: type = .turret
            case .gameConsole: type = .gameConsole
            case .freezeTrap: type = .freezeTrap
            case .mineTrap: type = .mineTrap
            default: return false
            }

            let building = Building(type: type)
            let futurePower = room.totalPowerUsed + (type == .powerBox ? 0 : building.powerCost)
            let powerSupply = room.totalPowerSupply + building.powerSupply
            guard futurePower <= powerSupply else {
                lastEventText = "电力不足，先建发电机再扩防御"
                return false
            }

            player.gold -= cost
            room.buildSlots[index].building = building
            lastEventText = "已在固定格建造 \(building.displayName)"
            return true

        case .upgradeBuilding:
            guard let index = selectedSlotIndex, let building = room.buildSlots[index].building else {
                lastEventText = "请先选中一座建筑"
                return false
            }
            let upgradeCost = getCost(for: .upgradeBuilding)
            guard player.gold >= upgradeCost else { return false }

            let upgraded = Building(id: building.id, type: building.type, level: building.level + 1)
            let futurePowerUsed = room.totalPowerUsed - building.powerCost + upgraded.powerCost
            guard futurePowerUsed <= room.totalPowerSupply else {
                lastEventText = "升级后电力会超载，先补发电机"
                return false
            }

            player.gold -= upgradeCost
            room.buildSlots[index].building = upgraded
            lastEventText = "\(upgraded.displayName) 已升级到 Lv.\(upgraded.level)"
            return true
        }
    }

    func getCost(for item: ShopItem) -> Int {
        switch item {
        case .upgradeBed:
            return room.bedUpgradeCost
        case .upgradeDoor:
            return room.doorUpgradeCost
        case .repairDoor:
            return 30 + room.doorLevel * 15
        case .powerBox:
            return 90
        case .turret:
            return 110 + room.turretCount * 25
        case .gameConsole:
            return 140
        case .freezeTrap:
            return 95
        case .mineTrap:
            return 135
        case .upgradeBuilding:
            guard let building = selectedSlot?.building else { return 999 }
            return 65 + building.level * 45
        }
    }

    func canAfford(_ item: ShopItem) -> Bool {
        player.gold >= getCost(for: item)
    }

    func canBuy(_ item: ShopItem) -> Bool {
        switch item {
        case .upgradeBed:
            return room.bedLevel < 10
        case .upgradeDoor:
            return room.doorLevel < 10
        case .repairDoor:
            return room.doorHP < room.maxDoorHP
        case .powerBox, .turret, .gameConsole, .freezeTrap, .mineTrap:
            return room.buildSlots.contains(where: { $0.building == nil })
        case .upgradeBuilding:
            return selectedSlot?.building != nil
        }
    }

    private var selectedSlotIndex: Int? {
        guard let selectedSlotID else { return nil }
        return room.buildSlots.firstIndex(where: { $0.id == selectedSlotID })
    }

    var selectedSlot: BuildSlot? {
        guard let selectedSlotID else { return nil }
        return room.buildSlots.first(where: { $0.id == selectedSlotID })
    }

    private func persistBestRecordIfNeeded() {
        let score = currentDefenseScore
        if waveNumber > bestWave {
            bestWave = waveNumber
        }
        if score > bestScore {
            bestScore = score
        }
    }

    var currentWaveText: String {
        if prepCountdown > 0 {
            return "准备中"
        }
        return ghost?.state == .dead ? "下一波准备中" : "第 \(max(waveNumber, 1)) 波"
    }

    var nearBedText: String {
        isNearBed ? "床边" : "未靠近"
    }

    var powerText: String {
        "\(room.totalPowerUsed)/\(room.totalPowerSupply)"
    }

    var economyText: String {
        String(format: "x%.1f", room.economyMultiplier)
    }

    var roomNameText: String {
        room.template.name
    }

    var currentDefenseScore: Int {
        player.gold + room.doorLevel * 90 + room.bedLevel * 75 + room.turretCount * 140 + room.totalPowerSupply * 6
    }

    var defenseScoreText: String {
        "\(currentDefenseScore)"
    }

    var bestWaveText: String {
        "\(bestWave)"
    }

    var bestScoreText: String {
        "\(bestScore)"
    }

    var victoryProgressText: String {
        "\(min(waveNumber, GameConfig.wavesToWin))/\(GameConfig.wavesToWin) 波"
    }

    var recommendedFlowText: String {
        if room.totalPowerSupply == 0 {
            return "建议：先升床，再补发电机"
        }
        if room.turretCount == 0 {
            return "建议：已有电力，赶紧补第一座炮台"
        }
        if room.doorHP < room.maxDoorHP * 0.35 {
            return "建议：门快炸了，先修门或升级房门"
        }
        return "建议：补经营建筑或升级炮台，准备下一波"
    }
}
