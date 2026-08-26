import SwiftUI
import UIKit

enum PokerPalette {
    static let background = Color(red: 0.94, green: 0.96, blue: 0.93)
    static let felt = Color(red: 0.08, green: 0.34, blue: 0.26)
    static let feltDeep = Color(red: 0.04, green: 0.22, blue: 0.17)
    static let gold = Color(red: 0.96, green: 0.72, blue: 0.25)
    static let red = Color(red: 0.87, green: 0.25, blue: 0.30)
    static let ink = SaoleiPalette.ink
    static let mutedInk = SaoleiPalette.mutedInk
}

struct PokerView: View {
    let difficulty: PokerDifficulty

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var game: PokerGame
    @State private var selectedBet = 40

    init(difficulty: PokerDifficulty) {
        self.difficulty = difficulty
        _game = State(initialValue: PokerGame(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            PokerPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                let useLandscapeLayout = horizontalSizeClass == .regular && proxy.size.width > proxy.size.height

                if useLandscapeLayout {
                    landscapeLayout
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            gameHeader
                            scoreCard
                            pokerTable
                            actionPanel
                            rulesCard
                        }
                        .frame(maxWidth: 760)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    .frame(width: proxy.size.width)
                }
            }
        }
        .navigationTitle("德州扑克")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var landscapeLayout: some View {
        VStack(spacing: 8) {
            HStack(alignment: .center, spacing: 16) {
                gameHeader
                scoreCard
                    .frame(width: 400)
            }

            HStack(alignment: .top, spacing: 16) {
                pokerTable(isLandscape: true)
                actionPanel(isCompact: true)
                    .frame(width: 280)
            }

            rulesCard
        }
        .frame(maxWidth: 1_040, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    private var gameHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("小小牌桌")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(PokerPalette.ink)
                Text("对战：\(difficulty.title)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            HStack(spacing: 7) {
                Image(systemName: "circle.grid.2x2.fill")
                Text("第 \(game.handNumber) 局")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(PokerPalette.feltDeep)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(PokerPalette.gold.opacity(0.22))
            .clipShape(Capsule())
        }
    }

    private var scoreCard: some View {
        HStack(spacing: 0) {
            PokerStatView(title: "你的筹码", value: String(game.playerChips), symbol: "person.fill", tint: SaoleiPalette.blue)
            Divider()
                .frame(height: 42)
            PokerStatView(title: "底池", value: String(game.pot), symbol: "circle.fill", tint: PokerPalette.gold)
            Divider()
                .frame(height: 42)
            PokerStatView(title: "机器人", value: String(game.botChips), symbol: "cpu", tint: SaoleiPalette.purple)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .shadow(color: PokerPalette.feltDeep.opacity(0.10), radius: 12, y: 6)
    }

    private var pokerTable: some View {
        pokerTable(isLandscape: false)
    }

    private func pokerTable(isLandscape: Bool) -> some View {
        GeometryReader { proxy in
            let cardWidth = min(isLandscape ? 54 : 62, max(42, (proxy.size.width - 68) / 5))
            let tableSpacing: CGFloat = isLandscape ? 8 : 12
            let tablePadding: CGFloat = isLandscape ? 12 : 16

            VStack(spacing: tableSpacing) {
                HStack {
                    tablePlayerLabel(name: "机器人", icon: "cpu", tint: SaoleiPalette.purple)
                    Spacer()
                    Text("\(game.street.title) · 底池 \(game.pot)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { index in
                        if game.shouldRevealBotCards {
                            PokerCardView(card: game.botCards[index], isHidden: false, width: cardWidth)
                        } else {
                            PokerCardView(card: nil, isHidden: true, width: cardWidth)
                        }
                    }
                }

                Text("公共牌")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: 8) {
                    ForEach(0..<5, id: \.self) { index in
                        PokerCardView(
                            card: index < game.communityCards.count ? game.communityCards[index] : nil,
                            isHidden: false,
                            width: cardWidth
                        )
                    }
                }

                Divider()
                    .overlay(.white.opacity(0.16))

                HStack {
                    tablePlayerLabel(name: "你", icon: "person.fill", tint: PokerPalette.gold)
                    Spacer()
                    Text("小盲 \(PokerGame.smallBlind) · 大盲 \(PokerGame.bigBlind)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                }

                HStack(spacing: 8) {
                    ForEach(game.playerCards) { card in
                        PokerCardView(card: card, isHidden: false, width: cardWidth)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, isLandscape ? 14 : 18)
            .padding(.vertical, tablePadding)
        }
        .frame(height: pokerTableHeight(isLandscape: isLandscape))
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(PokerPalette.felt)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(PokerPalette.gold.opacity(0.35), lineWidth: 2)
        }
        .shadow(color: PokerPalette.feltDeep.opacity(0.28), radius: 16, y: 9)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("德州扑克牌桌，\(game.street.title)，底池 \(game.pot)")
    }

    private func tablePlayerLabel(name: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
            Text(name)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private var actionPanel: some View {
        actionPanel(isCompact: false)
    }

    private func actionPanel(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 12) {
            HStack(alignment: .center) {
                Label(game.isPlayerTurn ? "轮到你行动" : resultTitle, systemImage: game.isPlayerTurn ? "hand.tap.fill" : "flag.checkered")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(game.isPlayerTurn ? PokerPalette.feltDeep : resultTint)

                Spacer(minLength: 8)

                Text(game.street.title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(PokerPalette.mutedInk)
            }

            if let botAction = game.botAction {
                PokerBotActionBanner(action: botAction)
            }

            Text(game.message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(PokerPalette.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if game.isPlayerTurn {
                if isCompact {
                    VStack(spacing: 8) {
                        actionButton(title: "弃牌", systemName: "xmark", tint: PokerPalette.red, compact: true) {
                            game.playerFold()
                            fireImpact()
                        }
                        actionButton(title: game.callTitle, systemName: game.callAmount == 0 ? "hand.wave.fill" : "arrow.right", tint: SaoleiPalette.blueDeep, compact: true) {
                            game.playerCheckOrCall()
                            syncBetSelection()
                            fireImpact()
                        }
                        betMenu(isCompact: true)
                        actionButton(title: game.currentBet == 0 ? "下注" : "加注", systemName: "arrow.up", tint: PokerPalette.felt, compact: true) {
                            game.placePlayerBet(to: selectedBetAmount)
                            syncBetSelection()
                            fireImpact()
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        actionButton(title: "弃牌", systemName: "xmark", tint: PokerPalette.red) {
                            game.playerFold()
                            fireImpact()
                        }
                        actionButton(title: game.callTitle, systemName: game.callAmount == 0 ? "hand.wave.fill" : "arrow.right", tint: SaoleiPalette.blueDeep) {
                            game.playerCheckOrCall()
                            syncBetSelection()
                            fireImpact()
                        }
                    }

                    HStack(spacing: 10) {
                        betMenu(isCompact: false)
                        actionButton(title: game.currentBet == 0 ? "下注" : "加注", systemName: "arrow.up", tint: PokerPalette.felt) {
                            game.placePlayerBet(to: selectedBetAmount)
                            syncBetSelection()
                            fireImpact()
                        }
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Text(game.status.isMatchOver ? "比赛结束" : "本局底池：\(game.lastPot)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(PokerPalette.mutedInk)

                    Button {
                        if game.status.isMatchOver {
                            game.resetMatch()
                        } else {
                            game.startNewHand()
                        }
                        syncBetSelection()
                        fireImpact()
                    } label: {
                        Label(game.status.isMatchOver ? "重新开始比赛" : "再来一局", systemImage: "arrow.clockwise")
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, isCompact ? 9 : 13)
                            .background(resultTint)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .shadow(color: PokerPalette.feltDeep.opacity(0.10), radius: 12, y: 6)
    }

    private func betMenu(isCompact: Bool) -> some View {
        Menu {
            ForEach(game.betOptions, id: \.self) { amount in
                Button("到 \(amount)") {
                    selectedBet = amount
                }
            }
        } label: {
            Label("到 \(selectedBetAmount)", systemImage: "slider.horizontal.3")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(PokerPalette.feltDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isCompact ? 9 : 13)
                .background(PokerPalette.gold.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .disabled(game.betOptions.isEmpty)
        .opacity(game.betOptions.isEmpty ? 0.5 : 1)
    }

    private func actionButton(title: String, systemName: String, tint: Color, compact: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 9 : 13)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rulesCard: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(PokerPalette.gold)
                .padding(.top, 2)

            Text("每人两张底牌，和公共牌组成最强五张牌。你是小盲，先跟注或加注；每轮都可以选择弃牌、过牌、跟注或下注。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(PokerPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(PokerPalette.gold.opacity(0.13))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var selectedBetAmount: Int {
        if game.betOptions.contains(selectedBet) {
            return selectedBet
        }
        return game.betOptions.first ?? game.minimumBet
    }

    private var resultTitle: String {
        switch game.status {
        case .playerTurn: return "你的回合"
        case .handOver(let winner), .matchOver(let winner): return winner.title
        }
    }

    private var resultTint: Color {
        switch game.status {
        case .playerTurn: return PokerPalette.felt
        case .handOver(.player), .matchOver(.player): return SaoleiPalette.mint
        case .handOver(.tie), .matchOver(.tie): return PokerPalette.gold
        case .handOver(.bot), .matchOver(.bot): return PokerPalette.red
        }
    }

    private var accentColor: Color {
        switch difficulty.accent {
        case .mint: return SaoleiPalette.mint
        case .sky: return SaoleiPalette.sky
        case .orange: return SaoleiPalette.orange
        case .purple: return SaoleiPalette.purple
        }
    }

    private func syncBetSelection() {
        if let firstOption = game.betOptions.first, !game.betOptions.contains(selectedBet) {
            selectedBet = firstOption
        }
    }

    private func fireImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func pokerTableHeight(isLandscape: Bool) -> CGFloat {
        if isLandscape {
            return 365
        }

        if horizontalSizeClass == .regular {
            return 430
        }

        return 390
    }
}

private struct PokerStatView: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(PokerPalette.mutedInk)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(PokerPalette.ink)
                .monospacedDigit()
                .minimumScaleFactor(0.65)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct PokerBotActionBanner: View {
    let action: PokerBotAction

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: action.systemName)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(actionTint)

            VStack(alignment: .leading, spacing: 2) {
                Text("机器人操作")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(PokerPalette.mutedInk)
                Text(action.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(actionTint)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(actionTint.opacity(0.13))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(actionTint.opacity(0.32), lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("机器人操作：\(action.title)")
    }

    private var actionTint: Color {
        switch action {
        case .raise: return PokerPalette.gold
        case .call: return SaoleiPalette.blueDeep
        case .check: return SaoleiPalette.mint
        case .fold: return PokerPalette.red
        }
    }
}

private struct PokerCardView: View {
    let card: PlayingCard?
    let isHidden: Bool
    let width: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: width * 0.16, style: .continuous)
                .fill(isHidden ? PokerPalette.feltDeep : .white)
                .overlay {
                    RoundedRectangle(cornerRadius: width * 0.16, style: .continuous)
                        .stroke(isHidden ? PokerPalette.gold.opacity(0.65) : .black.opacity(0.12), lineWidth: 1.5)
                }

            if isHidden {
                Image(systemName: "suit.club.fill")
                    .font(.system(size: width * 0.40, weight: .bold))
                    .foregroundStyle(PokerPalette.gold.opacity(0.75))
            } else if let card {
                VStack(spacing: 1) {
                    Text(card.rankName)
                        .font(.system(size: width * 0.31, weight: .black, design: .rounded))
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.38, weight: .bold))
                }
                .foregroundStyle(card.suit.isRed ? PokerPalette.red : PokerPalette.ink)
            } else {
                Text("?")
                    .font(.system(size: width * 0.34, weight: .black, design: .rounded))
                    .foregroundStyle(PokerPalette.mutedInk.opacity(0.65))
            }
        }
        .frame(width: width, height: width * 1.42)
        .shadow(color: .black.opacity(isHidden ? 0.16 : 0.18), radius: 4, y: 3)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if isHidden { return "机器人盖着的底牌" }
        guard let card else { return "还没有发出的公共牌" }
        return "\(card.rankName)\(card.suit.symbol)"
    }
}

#Preview("德州扑克") {
    NavigationStack {
        PokerView(difficulty: .casual)
    }
}
