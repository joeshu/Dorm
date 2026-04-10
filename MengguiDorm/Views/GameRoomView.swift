import SwiftUI

struct GameRoomView: View {
    @ObservedObject var gameEngine: GameEngine
    @State private var showShop = true
    @State private var isHUDExpanded = true

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
            Color.black.opacity(0.94)
                .ignoresSafeArea()

            GeometryReader { _ in
                let gridSize: CGFloat = 38
                Canvas { context, size in
                    for x in stride(from: 0, to: size.width, by: gridSize) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: x, y: 0))
                                path.addLine(to: CGPoint(x: x, y: size.height))
                            },
                            with: .color(Color.purple.opacity(0.08)),
                            lineWidth: 0.5
                        )
                    }
                    for y in stride(from: 0, to: size.height, by: gridSize) {
                        context.stroke(
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: size.width, y: y))
                            },
                            with: .color(Color.purple.opacity(0.08)),
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

                ForEach(gameEngine.room.buildSlots) { slot in
                    slotView(slot)
                        .position(slot.position)
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

                Text("现在更接近猛鬼宿舍：先抢房，再经营固定格")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.68))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())
                    .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y + gameEngine.room.size.height / 2 + 40)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var roomView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.26))
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)

            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)

            Color.clear
                .frame(width: gameEngine.room.size.width, height: gameEngine.room.size.height)
                .contentShape(RoundedRectangle(cornerRadius: 14))
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
                        .frame(width: 56, height: 64)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 44, height: 6)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(doorHPColor)
                        .frame(width: 44 * CGFloat(gameEngine.room.doorHP / gameEngine.room.maxDoorHP), height: 6)
                }

                Text("门 Lv.\(gameEngine.room.doorLevel)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y - gameEngine.room.size.height / 2)

            VStack(spacing: 4) {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 38))
                    .foregroundColor(gameEngine.nearBedText == "床边" ? .yellow : .green)

                Text(gameEngine.nearBedText == "床边" ? "床边" : "床 Lv.\(gameEngine.room.bedLevel)")
                    .font(.caption2)
                    .foregroundColor(.white)
            }
            .position(x: gameEngine.room.bedPosition.x, y: gameEngine.room.bedPosition.y)

            Text(gameEngine.roomNameText)
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
                .position(x: gameEngine.room.position.x, y: gameEngine.room.position.y - gameEngine.room.size.height / 2 - 26)
        }
        .position(gameEngine.room.position)
    }

    private func slotView(_ slot: BuildSlot) -> some View {
        let selected = gameEngine.selectedSlot?.id == slot.id

        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(selected ? Color.yellow.opacity(0.18) : Color.white.opacity(0.06))
                .frame(width: 46, height: 46)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selected ? Color.yellow : Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 1.5, dash: slot.building == nil ? [4, 4] : []))
                )

            if let building = slot.building {
                VStack(spacing: 2) {
                    Image(systemName: building.icon)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(building.color)
                    Text("\(building.level)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "plus")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            withAnimation(.spring()) {
                gameEngine.selectSlot(slot.id)
            }
        }
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
                .fill(gameEngine.player.isSleeping ? Color.green.opacity(0.82) : Color.blue)
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
        }
    }

    private var bulletView: some View {
        Circle()
            .fill(Color.yellow)
            .frame(width: 8, height: 8)
            .shadow(color: .yellow, radius: 4, x: 0, y: 0)
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
                        StatusBadge(title: "电力", value: gameEngine.powerText, systemImage: "bolt.fill", tint: .orange)
                        StatusBadge(title: "波次", value: gameEngine.currentWaveText, systemImage: "waveform", tint: .cyan)
                    }

                    HStack(spacing: 8) {
                        StatusBadge(title: "宿舍", value: gameEngine.roomNameText, systemImage: "house.fill", tint: .purple)
                        StatusBadge(title: "经营", value: gameEngine.economyText, systemImage: "chart.line.uptrend.xyaxis", tint: .green)
                        StatusBadge(title: "进度", value: gameEngine.victoryProgressText, systemImage: "trophy.fill", tint: .mint)
                    }

                    HStack(spacing: 8) {
                        Text(gameEngine.recommendedFlowText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.92))
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
                .fill(Color.black.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
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
                Image(systemName: gameEngine.player.isSleeping ? "figure.walk" : "bed.double.fill")
                Text(gameEngine.player.isSleeping ? "起床" : (gameEngine.nearBedText == "床边" ? "上床" : "靠近床铺"))
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 132, height: 48)
            .background(gameEngine.nearBedText == "床边" ? Color.green.gradient : Color.gray.opacity(0.6).gradient)
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
                Text(showShop ? "关闭" : "经营")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.white)
            .frame(width: 98, height: 46)
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

            selectedSlotPanel
            ShopPanelView(gameEngine: gameEngine, compact: true)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
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

    private var selectedSlotPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("当前格子")
                .font(.caption.bold())
                .foregroundColor(.white.opacity(0.65))

            if let slot = gameEngine.selectedSlot {
                if let building = slot.building {
                    HStack {
                        Label("\(building.displayName) Lv.\(building.level)", systemImage: building.icon)
                            .foregroundColor(.white)
                        Spacer()
                        Text("耗电 \(building.powerCost)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } else {
                    Text("空地：适合建造发电机、炮台或经营建筑")
                        .foregroundColor(.white)
                }
            } else {
                Text("点击房间里的格子后，再进行建造或升级")
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.top, 4)
    }
}
