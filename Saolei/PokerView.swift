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
    @Environment(\.dismiss) private var dismiss
    @State private var game: PokerGame
    @State private var selectedBet: Int

    init(difficulty: PokerDifficulty) {
        let initialGame = PokerGame(difficulty: difficulty)
        self.difficulty = difficulty
        _game = State(initialValue: initialGame)
        _selectedBet = State(initialValue: initialGame.halfPotBet ?? initialGame.minimumBet)
    }

    var body: some View {
        ZStack {
            PokerPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                let isIPadLayout = horizontalSizeClass == .regular
                let isLandscape = proxy.size.width > proxy.size.height

                if isIPadLayout {
                    iPadLayout(isLandscape: isLandscape, size: proxy.size)
                } else {
                    phoneLayout(size: proxy.size)
                }
            }
        }
        .navigationTitle(horizontalSizeClass == .regular ? "德州扑克" : "")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(horizontalSizeClass != .regular)
        .navigationBarHidden(horizontalSizeClass != .regular)
        .toolbar(horizontalSizeClass == .regular ? .visible : .hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func iPadLayout(isLandscape: Bool, size: CGSize) -> some View {
        if isLandscape {
            iPadLandscapeLayout(size: size)
        } else {
            iPadPortraitLayout(size: size)
        }
    }

    @ViewBuilder
    private func phoneLayout(size: CGSize) -> some View {
        if size.width > size.height {
            phoneLandscapeLayout(size: size)
        } else {
            phonePortraitLayout(size: size)
        }
    }

    private func phonePortraitLayout(size: CGSize) -> some View {
        let horizontalPadding = min(14, max(10, size.width * 0.03))

        return VStack(spacing: 4) {
            phoneNavigationHeader

            pokerTable(isLandscape: false, fillsAvailableHeight: true, isPhoneCompact: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(1)

            actionPanel(isCompact: true, isPhoneCompact: true)
        }
        .frame(maxWidth: 760, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, horizontalPadding)
        .padding(.top, 0)
        .padding(.bottom, 4)
    }

    private func phoneLandscapeLayout(size: CGSize) -> some View {
        let horizontalPadding = min(16, max(10, size.width * 0.025))
        let actionWidth = min(280, max(238, size.width * 0.34))

        return VStack(spacing: 4) {
            phoneNavigationHeader

            HStack(alignment: .top, spacing: 8) {
                pokerTable(isLandscape: true, fillsAvailableHeight: true, isPhoneCompact: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                actionPanel(isCompact: true, isPhoneCompact: true)
                    .frame(width: actionWidth, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 1_240, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 4)
    }

    private func iPadLandscapeLayout(size: CGSize) -> some View {
        let horizontalPadding = min(30, max(18, size.width * 0.025))
        let actionWidth = min(300, max(252, size.width * 0.25))

        return VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                gameHeader
                scoreCard
                    .frame(width: min(390, size.width * 0.40))
            }

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 8) {
                    pokerTable(isLandscape: true, fillsAvailableHeight: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    pokerKnowledgeTip(isCompact: true)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                actionPanel(isCompact: true)
                    .frame(width: actionWidth, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: 1_240, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 10)
    }

    private func iPadPortraitLayout(size: CGSize) -> some View {
        let horizontalPadding = min(28, max(18, size.width * 0.035))
        let usesHeaderRow = size.width >= 700

        return VStack(spacing: 10) {
            if usesHeaderRow {
                HStack(alignment: .center, spacing: 12) {
                    gameHeader
                    scoreCard
                        .frame(width: min(360, size.width * 0.46))
                }
            } else {
                VStack(spacing: 8) {
                    gameHeader
                    scoreCard
                }
            }

            pokerTable(isLandscape: false, fillsAvailableHeight: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            pokerKnowledgeTip(isCompact: true)

            actionPanel(isCompact: true, usesHorizontalActions: usesHeaderRow)
        }
        .frame(maxWidth: 820, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 10)
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

    private var phoneNavigationHeader: some View {
        HStack(spacing: 7) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(PokerPalette.ink)
                    .frame(width: 28, height: 28)
                    .background(SaoleiPalette.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 36)
            .accessibilityLabel("返回")

            VStack(alignment: .leading, spacing: 0) {
                Text("德州扑克")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(PokerPalette.ink)
                Text(difficulty.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Text("筹 \(game.playerChips)")
                Text("池 \(game.pot)")
                Text("#\(game.handNumber)")
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(PokerPalette.mutedInk)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 4)
        .frame(height: 36)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func pokerTable(isLandscape: Bool, fillsAvailableHeight: Bool, isPhoneCompact: Bool = false) -> some View {
        Group {
            if fillsAvailableHeight {
                pokerTableBody(isLandscape: isLandscape, isPhoneCompact: isPhoneCompact)
                    .frame(maxHeight: .infinity)
            } else {
                pokerTableBody(isLandscape: isLandscape, isPhoneCompact: isPhoneCompact)
                    .frame(height: pokerTableHeight(isLandscape: isLandscape))
            }
        }
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

    private func pokerTableBody(isLandscape: Bool, isPhoneCompact: Bool = false) -> some View {
        GeometryReader { proxy in
            let tableSpacing: CGFloat = isPhoneCompact ? (isLandscape ? 5 : 6) : (isLandscape ? 9 : (horizontalSizeClass == .regular ? 10 : 12))
            let tablePadding: CGFloat = isPhoneCompact ? (isLandscape ? 7 : 8) : (isLandscape ? 16 : (horizontalSizeClass == .regular ? 18 : 16))
            let cardSpacing: CGFloat = isPhoneCompact ? 5 : (isLandscape ? 9 : 8)
            let widthLimited = (proxy.size.width - tablePadding * 2 - cardSpacing * 4) / 5
            let fixedHeight = isPhoneCompact
                ? tablePadding * 2 + 20 + 14 + 1 + 20 + tableSpacing * 6
                : tablePadding * 2 + 24 + 18 + 1 + 24 + tableSpacing * 6
            let heightLimited = (proxy.size.height - fixedHeight) / 4.26
            let maxCardWidth: CGFloat = horizontalSizeClass == .regular
                ? (isLandscape ? 112 : 102)
                : (isPhoneCompact ? 56 : 62)
            let cardWidth = max(isPhoneCompact ? 32 : 38, min(maxCardWidth, widthLimited, heightLimited))

            VStack(spacing: tableSpacing) {
                HStack {
                    tablePlayerLabel(name: "机器人", icon: "cpu", tint: SaoleiPalette.purple, isCompact: isPhoneCompact)
                    Spacer()
                    Text("\(game.street.title) · 底池 \(game.pot)")
                        .font(.system(size: isPhoneCompact ? 11 : 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }

                HStack(spacing: cardSpacing) {
                    ForEach(0..<2, id: \.self) { index in
                        if game.shouldRevealBotCards {
                            PokerCardView(card: game.botCards[index], isHidden: false, width: cardWidth)
                        } else {
                            PokerCardView(card: nil, isHidden: true, width: cardWidth)
                        }
                    }
                }

                Text("公共牌")
                    .font(.system(size: isPhoneCompact ? 11 : 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))

                HStack(spacing: cardSpacing) {
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
                    tablePlayerLabel(name: "你", icon: "person.fill", tint: PokerPalette.gold, isCompact: isPhoneCompact)
                    Spacer()
                    if game.isPlayerTurn, let equity = game.playerEquity {
                        PokerEquityBadge(equity: equity)
                    }
                    Text("小盲 \(PokerGame.smallBlind) · 大盲 \(PokerGame.bigBlind)")
                        .font(.system(size: isPhoneCompact ? 10 : 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                }

                HStack(spacing: cardSpacing) {
                    ForEach(game.playerCards) { card in
                        PokerCardView(card: card, isHidden: false, width: cardWidth)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, isPhoneCompact ? (isLandscape ? 9 : 12) : (isLandscape ? 14 : 18))
            .padding(.vertical, tablePadding)
        }
    }

    private func tablePlayerLabel(name: String, icon: String, tint: Color, isCompact: Bool = false) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: isCompact ? 13 : 15, weight: .bold))
                .foregroundStyle(tint)
            Text(name)
                .font(.system(size: isCompact ? 14 : 16, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    private func actionPanel(isCompact: Bool, isPhoneCompact: Bool = false, usesHorizontalActions: Bool = false) -> some View {
        VStack(spacing: isPhoneCompact ? 4 : (isCompact ? 8 : 12)) {
            actionStatusArea(isCompact: isCompact, isPhoneCompact: isPhoneCompact)

            Text(game.message)
                .font(.system(size: isPhoneCompact ? 13 : 15, weight: .semibold, design: .rounded))
                .foregroundStyle(PokerPalette.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: isPhoneCompact ? 20 : (isCompact ? 38 : 42), alignment: .leading)
                .lineLimit(isPhoneCompact ? 1 : 2)

            if game.isPlayerTurn {
                if horizontalSizeClass == .regular {
                    iPadActionControls(isCompact: isCompact, usesHorizontalActions: usesHorizontalActions)
                } else {
                    phoneActionControls(isCompact: isPhoneCompact)
                }
            } else {
                resultActionControls(isCompact: isCompact)
            }
        }
        .padding(isPhoneCompact ? 8 : (isCompact ? 12 : 16))
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: isPhoneCompact ? 17 : 21, style: .continuous))
        .shadow(color: PokerPalette.feltDeep.opacity(0.10), radius: 12, y: 6)
    }

    private func pokerKnowledgeTip(isCompact: Bool) -> some View {
        (Text(Image(systemName: "lightbulb.fill")) + Text("  \(game.knowledgeTip)"))
        .font(.system(size: isCompact ? 13 : 15, weight: .bold, design: .rounded))
        .foregroundStyle(SaoleiPalette.mint)
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .minimumScaleFactor(0.72)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 34 : 38, maxHeight: isCompact ? 34 : 38, alignment: .center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(game.knowledgeTip)
    }

    @ViewBuilder
    private func actionStatusArea(isCompact: Bool, isPhoneCompact: Bool = false) -> some View {
        if isPhoneCompact {
            VStack(spacing: 4) {
                actionStatusHeader(isPhoneCompact: true)

                if let botAction = game.botAction {
                    Text("机器人：\(botAction.title)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(PokerPalette.feltDeep)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .frame(height: 24)
                        .background(PokerPalette.gold.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: game.botAction == nil ? 22 : 50, alignment: .top)
        } else {
            VStack(spacing: isCompact ? 8 : 10) {
                actionStatusHeader(isPhoneCompact: false)

                if let botAction = game.botAction {
                    PokerBotActionBanner(action: botAction)
                        .frame(height: isCompact ? 52 : 58)
                } else {
                    Color.clear
                        .frame(height: isCompact ? 52 : 58)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: isCompact ? 86 : 96, alignment: .top)
        }
    }

    private func actionStatusHeader(isPhoneCompact: Bool) -> some View {
        HStack(alignment: .center) {
            Label(game.isPlayerTurn ? "轮到你行动" : resultTitle, systemImage: game.isPlayerTurn ? "hand.tap.fill" : "flag.checkered")
                .font(.system(size: isPhoneCompact ? 15 : 18, weight: .black, design: .rounded))
                .foregroundStyle(game.isPlayerTurn ? PokerPalette.feltDeep : resultTint)

            Spacer(minLength: 8)

            Text(game.street.title)
                .font(.system(size: isPhoneCompact ? 11 : 13, weight: .bold, design: .rounded))
                .foregroundStyle(PokerPalette.mutedInk)
        }
    }

    private func iPadActionControls(isCompact: Bool, usesHorizontalActions: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 10) {
            if usesHorizontalActions {
                HStack(spacing: 8) {
                    iPadCallButton(isCompact: isCompact)
                    iPadRaiseButton(isCompact: isCompact)
                    iPadFoldButton(isCompact: isCompact)
                }

                iPadBetPresetRow(isCompact: isCompact)
            } else {
                iPadCallButton(isCompact: isCompact)
                iPadBetPresetRow(isCompact: isCompact)
                iPadRaiseButton(isCompact: isCompact)
                iPadFoldButton(isCompact: isCompact)
            }
        }
    }

    private func iPadCallButton(isCompact: Bool) -> some View {
        actionButton(
            title: game.callTitle,
            systemName: game.callAmount == 0 ? "hand.wave.fill" : "arrow.right",
            tint: SaoleiPalette.blueDeep,
            compact: isCompact
        ) {
            game.playerCheckOrCall()
            syncBetSelection()
            fireImpact()
        }
    }

    private func iPadRaiseButton(isCompact: Bool) -> some View {
        actionButton(
            title: game.currentBet == 0 ? "下注到 \(selectedBetAmount)" : "加注到 \(selectedBetAmount)",
            systemName: "arrow.up",
            tint: PokerPalette.felt,
            compact: isCompact
        ) {
            game.placePlayerBet(to: selectedBetAmount)
            syncBetSelection()
            fireImpact()
        }
        .disabled(game.betOptions.isEmpty)
    }

    private func iPadFoldButton(isCompact: Bool) -> some View {
        actionButton(title: "弃牌", systemName: "xmark", tint: PokerPalette.red, compact: isCompact) {
            game.playerFold()
            fireImpact()
        }
    }

    private func resultActionControls(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 8 : 10) {
            actionButton(
                title: game.status.isMatchOver ? "重新开始比赛" : "再来一局",
                systemName: "arrow.clockwise",
                tint: resultTint,
                compact: isCompact
            ) {
                if game.status.isMatchOver {
                    game.resetMatch()
                } else {
                    game.startNewHand()
                }
                syncBetSelection(resetToDefault: true)
                fireImpact()
            }

            Text(game.status.isMatchOver ? "比赛结束" : "本局底池：\(game.lastPot)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(PokerPalette.mutedInk)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: isCompact ? 24 : 26, alignment: .leading)
        }
    }

    @ViewBuilder
    private func phoneActionControls(isCompact: Bool) -> some View {
        if isCompact {
            VStack(spacing: 4) {
                HStack(spacing: 6) {
                    actionButton(title: game.callTitle, systemName: game.callAmount == 0 ? "hand.wave.fill" : "arrow.right", tint: SaoleiPalette.blueDeep, compact: true) {
                        game.playerCheckOrCall()
                        syncBetSelection()
                        fireImpact()
                    }

                    actionButton(title: game.currentBet == 0 ? "下注 \(selectedBetAmount)" : "加注 \(selectedBetAmount)", systemName: "arrow.up", tint: PokerPalette.felt, compact: true) {
                        game.placePlayerBet(to: selectedBetAmount)
                        syncBetSelection()
                        fireImpact()
                    }
                    .disabled(game.betOptions.isEmpty)

                    actionButton(title: "弃牌", systemName: "xmark", tint: PokerPalette.red, compact: true) {
                        game.playerFold()
                        fireImpact()
                    }
                }

                iPadBetPresetRow(isCompact: true)
            }
        } else {
            VStack(spacing: 10) {
                actionButton(title: game.callTitle, systemName: game.callAmount == 0 ? "hand.wave.fill" : "arrow.right", tint: SaoleiPalette.blueDeep) {
                    game.playerCheckOrCall()
                    syncBetSelection()
                    fireImpact()
                }

                HStack(spacing: 10) {
                    betIncrementButton(isCompact: false)
                    actionButton(title: game.currentBet == 0 ? "下注" : "加注", systemName: "arrow.up", tint: PokerPalette.felt) {
                        game.placePlayerBet(to: selectedBetAmount)
                        syncBetSelection()
                        fireImpact()
                    }
                }

                actionButton(title: "弃牌", systemName: "xmark", tint: PokerPalette.red) {
                    game.playerFold()
                    fireImpact()
                }
            }
        }
    }

    private func iPadBetPresetRow(isCompact: Bool) -> some View {
        HStack(spacing: 6) {
            potPresetButton(title: "半底池", amount: game.halfPotBet, compact: isCompact)
            potPresetButton(title: "1倍底池", amount: game.fullPotBet, compact: isCompact)
            betIncrementButton(isCompact: isCompact)
        }
    }

    private func potPresetButton(title: String, amount: Int?, compact: Bool) -> some View {
        Button {
            guard let amount else { return }
            selectedBet = amount
        } label: {
            VStack(spacing: 1) {
                Text(title)
                    .font(.system(size: compact ? 11 : 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(amount.map { String($0) } ?? "—")
                    .font(.system(size: compact ? 14 : 15, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(PokerPalette.feltDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 4 : 8)
            .background((amount == selectedBet ? PokerPalette.gold.opacity(0.36) : PokerPalette.gold.opacity(0.20)))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(amount == nil)
        .opacity(amount == nil ? 0.45 : 1)
    }

    private func betIncrementButton(isCompact: Bool) -> some View {
        let nextAmount = nextIncrementalBetAmount
        let isUnavailable = game.betOptions.isEmpty
        let isAllIn = !isUnavailable && nextAmount == nil

        return Button {
            guard let nextAmount else { return }
            selectedBet = nextAmount
        } label: {
            VStack(spacing: 1) {
                Text(isUnavailable ? "不可加注" : (isAllIn ? "All in" : "+1倍底池"))
                    .font(.system(size: isCompact ? 11 : 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(nextAmount.map(String.init) ?? (isAllIn ? String(selectedBetAmount) : "—"))
                    .font(.system(size: isCompact ? 14 : 15, weight: .black, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundStyle(PokerPalette.feltDeep)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isCompact ? 4 : 8)
            .background(PokerPalette.gold.opacity(isAllIn ? 0.42 : 0.24))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isUnavailable || isAllIn)
        .opacity(isUnavailable ? 0.5 : 1)
        .accessibilityLabel(
            isUnavailable
                ? "当前没有可用加注"
                : (isAllIn ? "已选择 All in，金额 \(selectedBetAmount)" : "增加一倍底池，选择到 \(nextAmount ?? 0)")
        )
    }

    private var nextIncrementalBetAmount: Int? {
        guard let maximum = game.betOptions.last,
              selectedBetAmount < maximum else {
            return nil
        }

        let increment = max(PokerGame.bigBlind, game.pot)
        let desiredAmount = selectedBetAmount + increment
        return game.betOptions.first(where: { $0 >= desiredAmount }) ?? maximum
    }

    private func actionButton(title: String, systemName: String, tint: Color, compact: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemName)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(tint)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 5 : 13)
                .lineLimit(1)
                .minimumScaleFactor(compact ? 0.72 : 1)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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

    private func syncBetSelection(resetToDefault: Bool = false) {
        guard !game.betOptions.isEmpty else { return }

        if resetToDefault {
            selectedBet = game.halfPotBet ?? game.betOptions.first ?? game.minimumBet
        } else if let firstOption = game.betOptions.first, !game.betOptions.contains(selectedBet) {
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

private struct PokerEquityBadge: View {
    let equity: PokerEquity

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 10, weight: .black))
            Text("估算赢面 \(percentage(equity.potShare))%")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(PokerPalette.feltDeep)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(PokerPalette.gold.opacity(0.82))
        .clipShape(Capsule())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "估算赢面 \(percentage(equity.potShare))%，胜率 \(percentage(equity.winRate))%，平局率 \(percentage(equity.tieRate))%，基于随机模拟，仅供教学参考"
        )
    }

    private func percentage(_ value: Double) -> Int {
        min(100, max(0, Int((value * 100).rounded())))
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
