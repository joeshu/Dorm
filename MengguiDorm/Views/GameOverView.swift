import SwiftUI

struct GameOverView: View {
    @ObservedObject var gameEngine: GameEngine
    let isWin: Bool
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // 结果图标
                Image(systemName: isWin ? "trophy.fill" : "xmark.octagon.fill")
                    .font(.system(size: 100))
                    .foregroundColor(isWin ? .yellow : .red)
                    .shadow(color: isWin ? .yellow.opacity(0.5) : .red.opacity(0.5), radius: 20, x: 0, y: 0)
                
                // 标题
                Text(isWin ? "胜利！" : "失败！")
                    .font(.system(size: 50, weight: .bold, design: .rounded))
                    .foregroundColor(isWin ? .yellow : .red)
                
                // 描述
                Text(isWin ? "你成功守住了整晚，宿舍安全了！" : "房门被猛鬼破坏了，再调整策略试试。")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                // 统计信息
                VStack(spacing: 16) {
                    statRow(icon: "waveform", label: "波数", value: "\(gameEngine.waveNumber)", color: .cyan)
                    statRow(icon: "clock.fill", label: "存活时间", value: formatTime(gameEngine.gameTime), color: .blue)
                    statRow(icon: "dollarsign.circle.fill", label: "获得金币", value: "\(gameEngine.player.gold)", color: .yellow)
                    statRow(icon: "bed.double.fill", label: "床铺等级", value: "Lv.\(gameEngine.room.bedLevel)", color: .green)
                    statRow(icon: "door.left.hand.closed", label: "房门等级", value: "Lv.\(gameEngine.room.doorLevel)", color: .brown)
                    statRow(icon: "shield.lefthalf.filled", label: "防守评分", value: gameEngine.defenseScoreText, color: .mint)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                
                Spacer()
                
                // 按钮
                VStack(spacing: 16) {
                    Button(action: {
                        gameEngine.startGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                            Text("再来一局")
                        }
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 220, height: 55)
                        .background(
                            LinearGradient(
                                colors: isWin ? [.green, .cyan] : [.orange, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: isWin ? .green.opacity(0.5) : .orange.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        gameEngine.resetGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "house.fill")
                            Text("返回大厅")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(Color.gray.opacity(0.5))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func statRow(icon: String, label: String, value: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .foregroundColor(.white.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded).bold())
                .foregroundColor(.white)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct PauseView: View {
    @ObservedObject var gameEngine: GameEngine
    
    var body: some View {
        ZStack {
            // 背景遮罩
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 暂停图标
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.orange)
                
                Text("游戏暂停")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // 当前状态
                VStack(spacing: 12) {
                    HStack {
                        Text("当前金币:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(gameEngine.player.gold)")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    
                    HStack {
                        Text("当前波数:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(gameEngine.waveNumber)")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    
                    HStack {
                        Text("房门血量:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(gameEngine.room.doorHP))/\(Int(gameEngine.room.maxDoorHP))")
                            .font(.headline)
                            .foregroundColor(gameEngine.room.doorHP > gameEngine.room.maxDoorHP * 0.5 ? .green : .red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .frame(maxWidth: 280)
                
                Spacer()
                
                // 按钮
                VStack(spacing: 16) {
                    Button(action: {
                        gameEngine.resumeGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                            Text("继续游戏")
                        }
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 220, height: 55)
                        .background(Color.green.gradient)
                        .cornerRadius(16)
                        .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    
                    Button(action: {
                        gameEngine.resetGame()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "xmark")
                            Text("退出游戏")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(16)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
