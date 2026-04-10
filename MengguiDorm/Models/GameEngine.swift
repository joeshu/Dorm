import Foundation
import SwiftUI
import Combine

@MainActor
class GameEngine: ObservableObject {
    @Published var gameState: GameState = .lobby
    @Published var room: Room
    @Published var player: Player
    @Published var ghost: Ghost?
    @Published var bullets: [Bullet] = []
    @Published var gameTime: TimeInterval = 0
    @Published var waveNumber: Int = 0
    
    private var timers: [Timer] = []
    private var lastUpdateTime: Date?
    
    // 游戏区域
    let gameBounds = CGRect(x: 0, y: 0, width: 400, height: 400)
    
    init() {
        let roomPos = CGPoint(x: gameBounds.midX, y: gameBounds.midY)
        self.room = Room(position: roomPos, size: GameConfig.roomSize)
        self.player = Player(position: CGPoint(x: roomPos.x, y: roomPos.y + 50))
    }
    
    // MARK: - 游戏生命周期
    
    func startGame() {
        gameState = .playing
        gameTime = 0
        waveNumber = 1
        
        // 重置状态
        let roomPos = CGPoint(x: gameBounds.midX, y: gameBounds.midY)
        room = Room(position: roomPos, size: GameConfig.roomSize)
        player = Player(position: CGPoint(x: roomPos.x, y: roomPos.y + 50))
        ghost = nil
        bullets.removeAll()
        
        // 启动游戏循环
        startGameLoop()
        startGoldGeneration()
        startGhostSpawning()
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
        gameState = .gameOver(win)
        stopAllTimers()
    }
    
    func resetGame() {
        stopAllTimers()
        gameState = .lobby
        gameTime = 0
        waveNumber = 0
    }
    
    private func stopAllTimers() {
        timers.forEach { $0.invalidate() }
        timers.removeAll()
    }
    
    // MARK: - 游戏循环
    
    private func startGameLoop() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update()
            }
        }
        timers.append(timer)
    }
    
    private func update() {
        guard gameState == .playing else { return }
        
        let now = Date()
        let deltaTime = lastUpdateTime.map { now.timeIntervalSince($0) } ?? 1/60
        lastUpdateTime = now
        
        // 更新游戏时间
        gameTime += deltaTime
        
        // 更新猛鬼
        updateGhost(deltaTime: deltaTime)
        
        // 更新炮台
        updateTurrets()
        
        // 更新子弹
        updateBullets(deltaTime: deltaTime)
        
        // 更新陷阱
        updateTraps()
        
        // 检查游戏结束条件
        checkGameEnd()
    }
    
    // MARK: - 金币生成
    
    private func startGoldGeneration() {
        let timer = Timer.scheduledTimer(withTimeInterval: GameConfig.goldTickInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.gameState == .playing else { return }
                
                if self.player.isSleeping {
                    self.player.gold += Int(self.room.goldPerSecond)
                }
            }
        }
        timers.append(timer)
    }
    
    // MARK: - 猛鬼系统
    
    private func startGhostSpawning() {
        // 延迟5秒后生成第一个猛鬼
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.spawnGhost()
        }
        
        // 定期生成猛鬼
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
        ghost = Ghost(level: waveNumber)
        
        // 随机生成位置（房间外围）
        let spawnPoints = [
            CGPoint(x: -50, y: gameBounds.midY),
            CGPoint(x: gameBounds.maxX + 50, y: gameBounds.midY),
            CGPoint(x: gameBounds.midX, y: -50),
            CGPoint(x: gameBounds.midX, y: gameBounds.maxY + 50)
        ]
        ghost?.position = spawnPoints.randomElement()!
        ghost?.state = .moving
        ghost?.targetRoomID = room.id
    }
    
    private func updateGhost(deltaTime: TimeInterval) {
        guard var ghost = ghost else { return }
        
        ghost.updateFreezeState()
        
        if ghost.state == .dead { return }
        
        if ghost.isFrozen {
            self.ghost = ghost
            return
        }
        
        // 计算到房间门的距离
        let doorPos = CGPoint(x: room.position.x, y: room.position.y - room.size.height/2)
        let dx = doorPos.x - ghost.position.x
        let dy = doorPos.y - ghost.position.y
        let distance = sqrt(dx*dx + dy*dy)
        
        // 判断是否到达门
        if distance < 30 {
            ghost.state = .attacking
            // 攻击门
            room.doorHP -= ghost.attack * deltaTime
            
            // 检查门是否被破坏
            if room.doorHP <= 0 {
                room.doorHP = 0
                endGame(win: false)
            }
        } else {
            ghost.state = .moving
            // 向门移动
            let moveDistance = ghost.speed * CGFloat(deltaTime)
            ghost.position.x += (dx / distance) * moveDistance
            ghost.position.y += (dy / distance) * moveDistance
        }
        
        self.ghost = ghost
    }
    
    // MARK: - 炮台系统
    
    private func updateTurrets() {
        guard let ghost = ghost, ghost.state != .dead else { return }
        
        for i in 0..<room.turrets.count {
            if room.turrets[i].canFire {
                // 检查猛鬼是否在射程内
                let dx = ghost.position.x - room.turrets[i].position.x
                let dy = ghost.position.y - room.turrets[i].position.y
                let distance = sqrt(dx*dx + dy*dy)
                
                if distance <= room.turrets[i].range {
                    // 计算角度
                    room.turrets[i].angle = atan2(dy, dx)
                    
                    // 发射子弹
                    fireBullet(from: room.turrets[i].position, target: ghost.position, damage: room.turrets[i].damage)
                    room.turrets[i].lastFireTime = Date()
                }
            }
        }
    }
    
    private func fireBullet(from: CGPoint, target: CGPoint, damage: Double) {
        let bullet = Bullet(position: from, target: target, damage: damage)
        bullets.append(bullet)
    }
    
    private func updateBullets(deltaTime: TimeInterval) {
        guard let ghost = ghost else {
            bullets.removeAll()
            return
        }
        
        for i in bullets.indices.reversed() {
            let dx = bullets[i].targetPosition.x - bullets[i].position.x
            let dy = bullets[i].targetPosition.y - bullets[i].position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance < 10 || bullets[i].isHit {
                // 命中
                if !bullets[i].isHit && ghost.state != .dead {
                    var updatedGhost = ghost
                    updatedGhost.takeDamage(bullets[i].damage)
                    self.ghost = updatedGhost
                    
                    // 检查猛鬼是否死亡
                    if updatedGhost.state == .dead {
                        player.gold += 50 * waveNumber // 击杀奖励
                    }
                }
                bullets.remove(at: i)
            } else {
                // 移动子弹
                let moveDistance = bullets[i].speed * CGFloat(deltaTime)
                bullets[i].position.x += (dx / distance) * moveDistance
                bullets[i].position.y += (dy / distance) * moveDistance
            }
        }
    }
    
    // MARK: - 陷阱系统
    
    private func updateTraps() {
        guard var ghost = ghost, ghost.state != .dead else { return }
        
        for i in room.traps.indices.reversed() {
            let trap = room.traps[i]
            
            // 检查猛鬼是否踩到陷阱
            let dx = ghost.position.x - trap.position.x
            let dy = ghost.position.y - trap.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance < 30 && !trap.isTriggered {
                room.traps[i].isTriggered = true
                room.traps[i].triggerTime = Date()
                
                // 触发效果
                switch trap.type {
                case .freeze(let duration):
                    ghost.freeze(duration: duration)
                    
                case .mine(let damage):
                    ghost.takeDamage(damage)
                    if ghost.state == .dead {
                        player.gold += 50 * waveNumber
                    }
                    
                case .shield:
                    // 临时修复门
                    room.doorHP = min(room.doorHP + 50, room.maxDoorHP)
                }
                
                // 一次性陷阱，触发后移除
                if case .mine = trap.type {
                    room.traps.remove(at: i)
                }
            }
            
            // 检查陷阱持续时间
            if trap.isTriggered, let triggerTime = trap.triggerTime {
                var shouldRemove = false
                
                switch trap.type {
                case .freeze:
                    if Date().timeIntervalSince(triggerTime) > 5 {
                        shouldRemove = true
                    }
                case .shield:
                    if Date().timeIntervalSince(triggerTime) > 10 {
                        shouldRemove = true
                    }
                default:
                    break
                }
                
                if shouldRemove {
                    room.traps.remove(at: i)
                }
            }
        }
        
        self.ghost = ghost
    }
    
    // MARK: - 游戏结束检查
    
    private func checkGameEnd() {
        // 检查胜利条件（猛鬼死亡且达到一定波数）
        if let ghost = ghost, ghost.state == .dead && waveNumber >= 5 {
            // 可以继续下一波或胜利
        }
    }
    
    // MARK: - 玩家操作
    
    func toggleSleep() {
        player.isSleeping.toggle()
    }
    
    func buyItem(_ item: ShopItem) -> Bool {
        let cost = item.getCost(level: getItemLevel(item))
        
        guard player.gold >= cost else { return false }
        
        switch item {
        case .upgradeDoor:
            guard room.doorLevel < 10 else { return false }
            player.gold -= cost
            room.upgradeDoor()
            
        case .upgradeBed:
            guard room.bedLevel < 10 else { return false }
            player.gold -= cost
            room.upgradeBed()
            
        case .turret:
            guard room.turrets.count < GameConfig.maxTurrets else { return false }
            player.gold -= cost
            // 在房间周围放置炮台
            let angle = Double(room.turrets.count) * (.pi / 2)
            let radius: CGFloat = 80
            let pos = CGPoint(
                x: room.position.x + cos(angle) * radius,
                y: room.position.y + sin(angle) * radius
            )
            room.turrets.append(Turret(position: pos))
            
        case .freezeTrap:
            guard room.traps.count < GameConfig.maxTraps else { return false }
            player.gold -= cost
            room.traps.append(Trap(position: getTrapPosition(), type: .freeze(duration: 3)))
            
        case .mineTrap:
            guard room.traps.count < GameConfig.maxTraps else { return false }
            player.gold -= cost
            room.traps.append(Trap(position: getTrapPosition(), type: .mine(damage: 300)))
            
        case .shieldTrap:
            guard room.traps.count < GameConfig.maxTraps else { return false }
            player.gold -= cost
            room.traps.append(Trap(position: getTrapPosition(), type: .shield(duration: 10)))
        }
        
        return true
    }
    
    private func getItemLevel(_ item: ShopItem) -> Int {
        switch item {
        case .upgradeDoor: return room.doorLevel
        case .upgradeBed: return room.bedLevel
        case .turret: return room.turrets.count + 1
        default: return 1
        }
    }
    
    private func getTrapPosition() -> CGPoint {
        // 在门口附近放置陷阱
        let doorPos = CGPoint(x: room.position.x, y: room.position.y - room.size.height/2)
        let offset = CGFloat.random(in: -40...40)
        return CGPoint(x: doorPos.x + offset, y: doorPos.y + 40)
    }
    
    // MARK: - 获取购买成本
    
    func getCost(for item: ShopItem) -> Int {
        return item.getCost(level: getItemLevel(item))
    }
    
    func canAfford(_ item: ShopItem) -> Bool {
        return player.gold >= getCost(for: item)
    }
    
    func canBuy(_ item: ShopItem) -> Bool {
        switch item {
        case .upgradeDoor:
            return room.doorLevel < 10
        case .upgradeBed:
            return room.bedLevel < 10
        case .turret:
            return room.turrets.count < GameConfig.maxTurrets
        case .freezeTrap, .mineTrap, .shieldTrap:
            return room.traps.count < GameConfig.maxTraps
        default:
            return true
        }
    }
}
