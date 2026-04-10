import SwiftUI

struct GameRoomView: View {
    @ObservedObject var gameEngine: GameEngine
    @State private var showShop = false
    @State private var isHUDExpanded = true
    @State private var inspectedTurretID: UUID?

    var body: some View {
        ZStack {
            gameBackground
            gameArea

            VStack {
                statusBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                Spacer()

                HStack {
                    sleepButton
                    Spacer()
                    shopToggleButton
                }
                .padding(.horizontal)
                .padding(.bottom, showShop ? 310 : 12)
                .animation(.spring(response: 0.25, dampingFraction: 0.9), value: showShop)
            }

            if let turret = inspectedTurret {
                turretInspector(turret)
            }

            if showShop {
                bottomShopDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            pauseButton
                .position(x: 40, y: 50)
        }
    }

    private var gameBackground: some View {
        ZStack {
            Color.black.opacity(0.92)
                .ignoresSafeArea()

            GeometryReader { _ in
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

    private var gameArea: some View {
        GeometryReader { geo in
            ZStack {
                roomView

                ForEach(gameEngine.room.turrets) { turret in
                    turretTapTarget(turret)
                        .position(turret.position)

                    turretView(turret)
                        .position(turret.position)
                }

                ForEach(gameEngine.room.traps) { trap in
                    trapView(trap)
                        .position(trap.position)
                }

                if let ghost = gameEngine.ghost, ghost.state != .dead {
                    ghostView(ghost)
                        .position(ghost.position)
                }

                ForEach(gameEngine.bullets) { bullet in
                    bulletView
                        .position(bullet.position)
                }

                playerView
                    .position(gameEngine.player.position)

                Text("拖动蓝色人物可移动")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y + gameEngine.room.size.height / 2 + 36)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var roomView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)

            Color.clear
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)
                .contentShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture { location in
                    gameEngine.movePlayer(to: CGPoint(
                        x: location.x + gameEngine.room.position.x - gameEngine.room.size.width / 2,
                        y: location.y + gameEngine.room.position.y - gameEngine.room.size.height / 2
                    ))
                }

            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brown)
                        .frame(width: 50, height: 60)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 40, height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(doorHPColor)
                        .frame(width: 40 * CGFloat(gameEngine.room.doorHP / gameEngine.room.maxDoorHP), height: 6)
                }

                Text("门 Lv.\(gameEngine.room.doorLevel)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y - gameEngine.room.size.height / 2)

            VStack(spacing: 4) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 40))
                    .foregroundColor(gameEngine.nearBedText == "床边" ? .yellow : .green)

                Text(gameEngine.nearBedText == "床边" ? "床边" : "床 Lv.\(gameEngine.room.bedLevel)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y + 20)
        }
        .position(gameEngine.room.position)
    }

    private var doorHPColor: Color {
        let ratio = gameEngine.room.doorHP / gameEngine.room.maxDoorHP
        if ratio > 0.6 { return .green }
        if ratio > 0.3 { return .yellow }
        return .red
    }

    private var playerView: some View {
        ZStack {
            Circle()
                .fill(gameEngine.player.isSleeping ? Color.green.opacity(0.8) : Color.blue)
                .frame(width: 30, height: 30)
                .overlay(Circle().stroke(Color.white, lineWidth: 2))

            if gameEngine.player.isSleeping {
                Text("💤")
                    .font(.title3)
                    .offset(y: -28)
            }

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)
                .frame(width: 52, height: 52)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    gameEngine.movePlayer(to: value.location)
                }
        )
    }

    private func ghostView(_ ghost: Ghost) -> some View {
        ZStack {
            Circle()
                .fill(ghost.isFrozen ? Color.cyan.opacity(0.6) : ghost.kind.color.opacity(0.85))
                .frame(width: ghost.kind == .tank ? 48 : 40, height: ghost.kind == .tank ? 48 : 40)
                .overlay(Circle().stroke(ghost.kind.color, lineWidth: 2))

            HStack(spacing: 4) {
                Circle().fill(Color.yellow).frame(width: 8, height: 8)
                Circle().fill(Color.yellow).frame(width: 8, height: 8)
            }

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black.opacity(0.5))
                .frame(width: 40, height: 4)
                .offset(y: -28)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.red)
                .frame(width: 40 * CGFloat(ghost.hp / ghost.maxHP), height: 4)
                .offset(y: -28)

            Text("Lv.\(ghost.level)")
                .font(.caption2)
                .foregroundColor(.white)
                .offset(y: 28)

            Text(ghost.kind.name)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.85))
                .offset(y: 42)

            if ghost.isFrozen {
                Image(systemName: "snowflake")
                    .font(.title2)
                    .foregroundColor(.cyan)
                    .offset(y: -45)
            }
        }
    }

    private func turretTapTarget(_ turret: Turret) -> some View {
        Circle()
            .fill(Color.clear)
            .frame(width: 72, height: 72)
            .contentShape(Circle())
            .onTapGesture {
                withAnimation(.spring()) {
                    gameEngine.selectTurret(turret.id)
                }
            }
            .onLongPressGesture {
                withAnimation(.spring()) {
                    inspectedTurretID = inspectedTurretID == turret.id ? nil : turret.id
                }
            }
    }

    private func turretView(_ turret: Turret) -> some View {
        let isSelected = gameEngine.selectedTurretID == turret.id

        return ZStack {
            Circle()
                .fill((isSelected ? Color.mint : Color.orange).opacity(0.18))
                .frame(width: max(44, turret.range * 1.1), height: max(44, turret.range * 1.1))

            ZStack {
                Circle()
                    .fill(isSelected ? Color.mint : Color.orange)
                    .frame(width: isSelected ? 34 : 30, height: isSelected ? 34 : 30)

                Rectangle()
                    .fill((isSelected ? Color.mint : Color.orange).opacity(0.85))
                    .frame(width: 20, height: 6)
                    .rotationEffect(.radians(turret.angle))
            }

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

    private var bulletView: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 8, height: 8)
            .shadow(color: .yellow, radius: 4, x: 0, y: 0)
    }

    private var inspectedTurret: Turret? {
        guard let inspectedTurretID else { return nil }
        return gameEngine.room.turrets.first(where: { $0.id == inspectedTurretID })
    }

    private var statusBar: some View {
        VStack(spacing: 6) {
            HStack {
                Label(isHUDExpanded ? "收起" : "展开", systemImage: isHUDExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isHUDExpanded.toggle()
                        }
                    }
                Spacer()
            }

            if isHUDExpanded {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        StatusBadge(title: "金币", value: "\(gameEngine.player.gold)", systemImage: "dollarsign.circle.fill", tint: .yellow)
                        StatusBadge(title: "波次", value: gameEngine.currentWaveText, systemImage: "waveform", tint: .cyan)
                        StatusBadge(title: "进度", value: gameEngine.victoryProgressText, systemImage: "trophy.fill", tint: .orange)
                    }

                    HStack(spacing: 8) {
                        StatusBadge(title: "时间", value: formatTime(gameEngine.gameTime), systemImage: "clock.fill", tint: .blue)
                        StatusBadge(title: "评分", value: gameEngine.defenseScoreText, systemImage: "shield.lefthalf.filled", tint: .green)
                        if gameEngine.selectedTurretID != nil {
                            StatusBadge(title: "炮台", value: "已选中", systemImage: "scope", tint: .mint)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(gameEngine.lastEventText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Button(action: {
                            withAnimation(.spring()) {
                                gameEngine.toggleFastForward()
                            }
                        }) {
                            Label(gameEngine.isFastForwardEnabled ? "2x" : "1x", systemImage: "forward.fill")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(gameEngine.isFastForwardEnabled ? Color.orange : Color.white.opacity(0.12))
                                )
                        }
                    }
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var sleepButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                gameEngine.toggleSleep()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: gameEngine.player.isSleeping ? "person.fill" : "bed.double.fill")
                Text(gameEngine.player.isSleeping ? "起床" : (gameEngine.nearBedText == "床边" ? "上床" : "靠近床铺"))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 118, height: 46)
            .background(
                gameEngine.nearBedText == "床边" ?
                (gameEngine.player.isSleeping ? Color.orange.gradient : Color.green.gradient) :
                Color.gray.gradient
            )
            .cornerRadius(12)
            .shadow(color: gameEngine.player.isSleeping ? .orange.opacity(0.5) : .green.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }

    private var shopToggleButton: some View {
        Button(action: {
            withAnimation(.spring()) {
                showShop.toggle()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: showShop ? "xmark" : "cart.fill")
                Text(showShop ? "关闭" : "商店")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 92, height: 46)
            .background(Color.purple.gradient)
            .cornerRadius(12)
            .shadow(color: .purple.opacity(0.5), radius: 8, x: 0, y: 4)
        }
    }

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

    private var bottomShopDrawer: some View {
        VStack(spacing: 8) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            ShopPanelView(gameEngine: gameEngine, compact: true)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 290)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.purple.opacity(0.35), lineWidth: 1)
                )
        )
        .padding(.horizontal, 10)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private func turretInspector(_ turret: Turret) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("炮台信息")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation(.spring()) {
                        inspectedTurretID = nil
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            Text("等级：Lv.\(turret.level)")
                .foregroundColor(.white)
            Text("伤害：\(Int(turret.damage))")
                .foregroundColor(.white.opacity(0.85))
            Text("射程：\(Int(turret.range))")
                .foregroundColor(.white.opacity(0.85))
            Text("升级费用：\(turret.upgradeCost)")
                .foregroundColor(.mint)
            Text("点按选中，去商店执行升级")
                .font(.caption)
                .foregroundColor(.white.opacity(0.65))
        }
        .padding(12)
        .frame(width: 180)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.mint.opacity(0.4), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, isHUDExpanded ? 150 : 70)
        .padding(.leading, 12)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
