import SwiftUI

struct GameRoomView: View {
    @ObservedObject var gameEngine: GameEngine
    @State private var showShop = true
    
    var body: some View {
        ZStack {
            // 游戏背景
            gameBackground
            
            // 游戏区域
            gameArea
            
            // UI 层
            VStack {
                // 顶部状态栏
                statusBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                Spacer()
                
                // 底部控制栏
                HStack {
                    // 睡觉按钮
                    sleepButton
                    
                    Spacer()
                    
                    // 商店切换按钮
                    shopToggleButton
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // 商店面板
            if showShop {
                shopPanel
                    .transition(.move(edge: .trailing))
            }
            
            // 暂停按钮
            pauseButton
                .position(x: 40, y: 50)
        }
    }
    
    // MARK: - 游戏背景
    private var gameBackground: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()
            
            // 网格背景
            GeometryReader { geo in
                let gridSize: CGFloat = 40
                Canvas { context, size in
                    for x in stride(from: 0, to: size.width, by: gridSize) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            },
                            with: .color(Color.purple.opacity(0.1)),
                            lineWidth: 0.5
                        )
                    }
                    for y in stride(from: 0, to: size.height, by: gridSize) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            },
                            with: .color(Color.purple.opacity(0.1)),
                            lineWidth: 0.5
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 游戏区域
    private var gameArea: some View {
        GeometryReader { geo in
            ZStack {
                // 房间
                roomView
                
                // 炮台
                ForEach(gameEngine.room.turrets) { turret in
                    turretView(turret)
                        .position(turret.position)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                gameEngine.selectTurret(turret.id)
                            }
                        }
                }
                
                // 陷阱
                ForEach(gameEngine.room.traps) { trap in
                    trapView(trap)
                        .position(trap.position)
                }
                
                // 猛鬼
                if let ghost = gameEngine.ghost, ghost.state != .dead {
                    ghostView(ghost)
                        .position(ghost.position)
                }
                
                // 子弹
                ForEach(gameEngine.bullets) { bullet in
                    bulletView
                        .position(bullet.position)
                }
                
                // 玩家
                playerView
                    .position(gameEngine.player.position)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    // MARK: - 房间视图
    private var roomView: some View {
        ZStack {
            // 房间主体
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)
            
            // 房间边框
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)
            
            // 门
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    // 门框
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown)
                        .frame(width: 50, height: 60)
                    
                    // 门血量条背景
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 40, height: 6)
                    
                    // 门血量条
                    RoundedRectangle(cornerRadius: 2)
                        .fill(doorHPColor)
                        .frame(width: 40 * CGFloat(gameEngine.room.doorHP / gameEngine.room.maxDoorHP), height: 6)
                }
                
                Text("门 Lv.\(gameEngine.room.doorLevel)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y - gameEngine.room.size.height/2)
            
            // 床
            VStack(spacing: 4) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                
                Text("床 Lv.\(gameEngine.room.bedLevel)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y + 20)
        }
        .position(gameEngine.room.position)
    }
    
    private var doorHPColor: Color {
        let ratio = gameEngine.room.doorHP / gameEngine.room.maxDoorHP
        if ratio > 0.6 {
            return .green
        } else if ratio > 0.3 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - 玩家视图
    private var playerView: some View {
        ZStack {
            // 玩家身体
            Circle()
                .fill(gameEngine.player.isSleeping ? Color.green.opacity(0.8) : Color.blue)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
            
            // 睡眠指示器
            if gameEngine.player.isSleeping {
                Text("💤")
                    .font(.title3)
                    .offset(y: -25)
            }
        }
    }
    
    // MARK: - 猛鬼视图
    private func ghostView(_ ghost: Ghost) -> some View {
        ZStack {
            // 猛鬼身体
            Circle()
                .fill(ghost.isFrozen ? Color.cyan.opacity(0.6) : ghost.kind.color.opacity(0.85))
                .frame(width: ghost.kind == .tank ? 48 : 40, height: ghost.kind == .tank ? 48 : 40)
                .overlay(
                    Circle()
                        .stroke(ghost.kind.color, lineWidth: 2)
                )
            
            // 眼睛
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
            }
            
            // 血量条背景
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.5))
                .frame(width: 40, height: 4)
                .offset(y: -28)
            
            // 血量条
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red)
                .frame(width: 40 * CGFloat(ghost.hp / ghost.maxHP), height: 4)
                .offset(y: -28)
            
            // 等级标识
            Text("Lv.\(ghost.level)")
                .font(.caption2)
                .foregroundColor(.white)
                .offset(y: 28)

            Text(ghost.kind.name)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .offset(y: 42)
            
            // 冻结效果
            if ghost.isFrozen {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .offset(y: -45)
            }
        }
    }
    
    // MARK: - 炮台视图
    private func turretView(_ turret: Turret) -> some View {
        let isSelected = gameEngine.selectedTurretID == turret.id

        return ZStack {
            // 炮台底座
            Circle()
                .fill((isSelected ? Color.mint : Color.orange).opacity(0.18))
                .frame(width: turret.range * 2, height: turret.range * 2)
            
            // 炮台主体
            ZStack {
                Circle()
                    .fill(isSelected ? Color.mint : Color.orange)
                    .frame(width: isSelected ? 34 : 30, height: isSelected ? 34 : 30)
                
                // 炮管
                Rectangle()
                    .fill((isSelected ? Color.mint : Color.orange).opacity(0.85))
                    .frame(width: 20, height: 6)
                    .rotationEffect(.radians(turret.angle))
            }
            
            // 等级
            Text("\(turret.level)")
                .font(.caption2.bold())
                .foregroundColor(.white)
                .offset(y: -20)

            if isSelected {
                Text("已选中")
                    .font(.caption2.bold())
                    .foregroundColor(.mint)
                    .offset(y: 24)
            }
        }
    }
    
    // MARK: - 陷阱视图
    private func trapView(_ trap: Trap) -> some View {
        ZStack {
            Circle()
                .fill(trap.type.color.opacity(0.4))
                .frame(width: 35, height: 35)
            
            Image(systemName: trap.type.icon)
                .font(.title3)
                .foregroundColor(trap.type.color)
            
            if trap.isTriggered {
                Circle()
                    .stroke(trap.type.color, lineWidth: 2)
                    .frame(width: 40, height: 40)
            }
        }
    }
    
    // MARK: - 子弹视图
    private var bulletView: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 8, height: 8)
            .shadow(color: .yellow, radius: 4, x: 0, y: 0)
    }
    
    // MARK: - 状态栏
    private var statusBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                StatusBadge(title: "金币", value: "\(gameEngine.player.gold)", systemImage: "dollarsign.circle.fill", tint: .yellow)
                StatusBadge(title: "波次", value: gameEngine.currentWaveText, systemImage: "waveform", tint: .cyan)
                StatusBadge(title: "进度", value: gameEngine.victoryProgressText, systemImage: "trophy.fill", tint: .orange)
                StatusBadge(title: "时间", value: formatTime(gameEngine.gameTime), systemImage: "clock.fill", tint: .blue)
                StatusBadge(title: "评分", value: gameEngine.defenseScoreText, systemImage: "shield.lefthalf.filled", tint: .green)
            }

            HStack(spacing: 10) {
                Label(gameEngine.lastEventText, systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button(action: {
                    withAnimation(.spring()) {
                        gameEngine.toggleFastForward()
                    }
                }) {
                    Label(gameEngine.isFastForwardEnabled ? "2x" : "1x", systemImage: "forward.fill")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(gameEngine.isFastForwardEnabled ? Color.orange.gradient : Color.white.opacity(0.12))
                        )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - 睡觉按钮
    private var sleepButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                gameEngine.toggleSleep()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: gameEngine.player.isSleeping ? "person.fill" : "bed.double.fill")
                Text(gameEngine.player.isSleeping ? "起床" : "睡觉")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 120, height: 50)
            .background(
                gameEngine.player.isSleeping ?
                Color.orange.gradient :
                Color.green.gradient
            )
            .cornerRadius(12)
            .shadow(color: gameEngine.player.isSleeping ? .orange.opacity(0.5) : .green.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - 商店切换按钮
    private var shopToggleButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                showShop.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "cart.fill")
                Text("商店")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(width: 100, height: 50)
            .background(Color.purple.gradient)
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - 暂停按钮
    private var pauseButton: some View {
        Button(action: {
            gameEngine.pauseGame()
        }) {
            Image(systemName: "pause.fill")
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
    }
    
    // MARK: - 商店面板
    private var shopPanel: some View {
        ShopPanelView(gameEngine: gameEngine)
            .frame(width: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.purple.opacity(0.5), lineWidth: 1)
                    )
            )
            .position(x: UIScreen.main.bounds.width - 110, y: UIScreen.main.bounds.height / 2)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
