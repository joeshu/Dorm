import SwiftUI

struct LobbyView: View {
    @ObservedObject var gameEngine: GameEngine
    
    var body: some View {
        ZStack {
            // 背景
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 标题
                VStack(spacing: 16) {
                    Text("猛鬼宿舍")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.red, .orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 0)
                    
                    Text("Haunted Dorm")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // 游戏说明
                VStack(alignment: .leading, spacing: 12) {
                    Label("上床睡觉赚取金币", systemImage: "bed.double.fill")
                    Label("升级房门抵御猛鬼", systemImage: "door.left.hand.closed")
                    Label("建造炮台自动攻击", systemImage: "scope")
                    Label("放置陷阱控制猛鬼", systemImage: "snowflake")
                    Label("守住 5 波即可胜利", systemImage: "trophy.fill")
                }
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.4))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
                
                Spacer()
                
                // 开始按钮
                VStack(spacing: 14) {
                    Button(action: {
                        gameEngine.startGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("开始游戏")
                                .font(.title2.bold())
                        }
                        .foregroundColor(.white)
                        .frame(width: 240, height: 60)
                        .background(
                            LinearGradient(
                                colors: [.red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .red.opacity(0.5), radius: 10, x: 0, y: 5)
                    }

                    Button(action: {
                        gameEngine.quickStartGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.headline)
                            Text("快速开局")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.white)
                        .frame(width: 240, height: 50)
                        .background(Color.blue.gradient)
                        .cornerRadius(14)
                        .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
