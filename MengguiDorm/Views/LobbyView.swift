import SwiftUI

struct LobbyView: View {
    @ObservedObject var gameEngine: GameEngine

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.35), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("猛鬼宿舍")
                            .font(.system(size: 54, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.red, .orange, .yellow], startPoint: .leading, endPoint: .trailing)
                            )

                        Text("这次更像真正的躺平发育：先抢房，再经营，再守门")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.75))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 28)

                    introPanel
                    roomSelectionPanel
                    recordPanel
                    actionPanel
                }
                .padding()
            }
        }
    }

    private var introPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("核心流程")
                .font(.headline.bold())
                .foregroundColor(.white)

            Label("开局先抢一间宿舍", systemImage: "house.fill")
            Label("走到床边后上床睡觉赚金币", systemImage: "bed.double.fill")
            Label("优先拉床 / 门 / 电力的经营顺序", systemImage: "arrow.triangle.branch")
            Label("在固定建造格中补发电机、炮台、经营建筑", systemImage: "square.grid.3x2.fill")
            Label("守住 5 波猛鬼进攻", systemImage: "trophy.fill")
        }
        .font(.headline)
        .foregroundColor(.white.opacity(0.84))
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.36))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                )
        )
    }

    private var roomSelectionPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("抢宿舍")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                Spacer()
                Text(gameEngine.selectedRoomTemplate?.name ?? "未选择")
                    .font(.caption.bold())
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.yellow.opacity(0.16))
                    .clipShape(Capsule())
            }

            ForEach(GameConfig.roomTemplates) { template in
                Button {
                    gameEngine.selectRoom(template)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 8) {
                                Text(template.name)
                                    .font(.headline.bold())
                                    .foregroundColor(.white)
                                Text(template.difficulty)
                                    .font(.caption.bold())
                                    .foregroundColor(template.difficulty == "挑战" ? .red : .green)
                            }
                            Text(template.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.75))
                            Text(template.recommendedText)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.62))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {
                            Label("\(template.slotOffsets.count) 格", systemImage: "square.grid.3x2")
                            Label(template.id == 2 ? "压门强" : "可运营", systemImage: "shield")
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill((gameEngine.selectedRoomTemplate == template ? Color.orange : Color.white).opacity(gameEngine.selectedRoomTemplate == template ? 0.18 : 0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(gameEngine.selectedRoomTemplate == template ? Color.orange : Color.white.opacity(0.12), lineWidth: 1)
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.34))
        )
    }

    private var recordPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("历史记录")
                .font(.headline.bold())
                .foregroundColor(.white)

            Label("最高波数：\(gameEngine.bestWaveText)", systemImage: "flag.fill")
            Label("最高评分：\(gameEngine.bestScoreText)", systemImage: "star.fill")
            Label("当前改版重点：选房间 / 固定格 / 电力经营", systemImage: "wrench.and.screwdriver.fill")
        }
        .font(.headline)
        .foregroundColor(.white.opacity(0.82))
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.black.opacity(0.28))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var actionPanel: some View {
        VStack(spacing: 14) {
            Button(action: {
                gameEngine.startGame()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title2)
                    Text("开始抢房开局")
                        .font(.title2.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(16)
                .shadow(color: .red.opacity(0.45), radius: 10, x: 0, y: 5)
            }

            Button(action: {
                gameEngine.quickStartGame()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                    Text("快速经营开局")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue.gradient)
                .cornerRadius(14)
            }
        }
    }
}
