import SwiftUI

struct ShopPanelView: View {
    @ObservedObject var gameEngine: GameEngine
    let compact: Bool

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "cart.fill")
                    .foregroundColor(.purple)
                Text("经营面板")
                    .font(compact ? .subheadline.bold() : .headline.bold())
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Divider().background(Color.white.opacity(0.2))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    shopSection(title: "核心经营", items: [.upgradeBed, .upgradeDoor, .repairDoor])
                    Divider().background(Color.white.opacity(0.2))
                    shopSection(title: "电力与发育", items: [.powerBox, .gameConsole])
                    Divider().background(Color.white.opacity(0.2))
                    shopSection(title: "防御建筑", items: [.turret, .freezeTrap, .mineTrap, .upgradeBuilding])
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
        }
    }

    private func shopSection(title: String, items: [ShopItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.gray)
                .padding(.horizontal, 4)

            ForEach(items) { item in
                ShopItemView(
                    item: item,
                    cost: gameEngine.getCost(for: item),
                    canAfford: gameEngine.canAfford(item),
                    canBuy: gameEngine.canBuy(item),
                    compact: compact
                ) {
                    _ = gameEngine.buyItem(item)
                }
            }
        }
    }
}

struct ShopItemView: View {
    let item: ShopItem
    let cost: Int
    let canAfford: Bool
    let canBuy: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.color.opacity(0.3))
                        .frame(width: compact ? 30 : 36, height: compact ? 30 : 36)

                    Image(systemName: item.icon)
                        .font(.system(size: compact ? 15 : 18))
                        .foregroundColor(item.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(compact ? .caption.bold() : .subheadline.bold())
                        .foregroundColor(canAfford && canBuy ? .white : .gray)

                    if !compact {
                        Text(item.description)
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption2)
                    Text("\(cost)")
                        .font(compact ? .caption.bold() : .subheadline.bold())
                }
                .foregroundColor(canAfford ? .yellow : .red)
            }
            .padding(compact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(canAfford && canBuy ? item.color.opacity(0.15) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(canAfford && canBuy ? item.color.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .disabled(!canAfford || !canBuy)
        .opacity(canBuy ? 1 : 0.5)
    }
}
