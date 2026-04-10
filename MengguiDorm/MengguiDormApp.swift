import SwiftUI

@main
struct MengguiDormApp: App {
    @StateObject private var gameEngine = GameEngine()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameEngine)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var gameEngine: GameEngine
    
    var body: some View {
        ZStack {
            switch gameEngine.gameState {
            case .lobby:
                LobbyView(gameEngine: gameEngine)
                
            case .playing:
                GameRoomView(gameEngine: gameEngine)
                
            case .paused:
                ZStack {
                    GameRoomView(gameEngine: gameEngine)
                    PauseView(gameEngine: gameEngine)
                }
                
            case .gameOver(let isWin):
                ZStack {
                    GameRoomView(gameEngine: gameEngine)
                    GameOverView(gameEngine: gameEngine, isWin: isWin)
                }
            }
        }
    }
}
