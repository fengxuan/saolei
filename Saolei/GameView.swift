import SwiftUI
import UIKit

struct GameView: View {
    let difficulty: GameDifficulty

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var game: MinesweeperGame
    @State private var flagMode = false
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(difficulty: GameDifficulty) {
        self.difficulty = difficulty
        _game = State(initialValue: MinesweeperGame(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            SaoleiPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                gameLayout(in: proxy)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in game.tick() }
    }

    @ViewBuilder
    private func gameLayout(in proxy: GeometryProxy) -> some View {
        if proxy.size.width > proxy.size.height && horizontalSizeClass != .regular {
            landscapePhoneLayout(in: proxy)
        } else {
            standardLayout(in: proxy)
        }
    }

    private func landscapePhoneLayout(in proxy: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 4
        let headerHeight: CGFloat = 36
        let contentSpacing: CGFloat = 8
        let availableWidth = max(1, proxy.size.width - horizontalPadding * 2)
        let minimumSidebarWidth: CGFloat = 220
        let boardOuterInset: CGFloat = 8
        let availableHeight = max(1, proxy.size.height - headerHeight - verticalPadding * 2)
        let boardSide = max(1, min(
            760,
            availableHeight - boardOuterInset,
            availableWidth - minimumSidebarWidth - contentSpacing
        ))
        let sidebarWidth = max(minimumSidebarWidth, availableWidth - boardSide - contentSpacing)

        return VStack(spacing: 4) {
            phoneLandscapeHeader

            HStack(alignment: .top, spacing: contentSpacing) {
                gameBoard(side: boardSide)
                    .layoutPriority(1)

                VStack(spacing: 8) {
                    statusCard
                        .frame(maxWidth: .infinity)
                    boardToolbar
                        .frame(maxWidth: .infinity)
                }
                .frame(width: sidebarWidth, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: 1_100, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .navigationBarHidden(true)
    }

    private var phoneLandscapeHeader: some View {
        HStack(spacing: 7) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SaoleiPalette.ink)
                    .frame(width: 28, height: 28)
                    .background(SaoleiPalette.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 36)
            .accessibilityLabel("返回")

            VStack(alignment: .leading, spacing: 0) {
                Text("小小扫雷队")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text(difficulty.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Text("雷 \(game.remainingMines)")
                Text(formattedTime)
            }
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(SaoleiPalette.mutedInk)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 4)
        .frame(height: 36)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func standardLayout(in proxy: GeometryProxy) -> some View {
        let boardSide = min(
            760,
            proxy.size.width - 48,
            max(280, proxy.size.height - 225)
        )

        return ZStack {
            VStack(spacing: 13) {
                gameHeader
                statusCard
                boardToolbar
                gameBoard(side: boardSide)
            }
            .frame(maxWidth: 900)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var gameHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("小小扫雷队")
                    .font(.system(size: 23, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text(difficulty.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            if game.status == .lost {
                Button {
                    restartGame()
                } label: {
                    Label("重新开始", systemImage: "arrow.clockwise")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                }
                .foregroundStyle(SaoleiPalette.blueDeep)
                .background(SaoleiPalette.card)
                .clipShape(Capsule())
                .shadow(color: SaoleiPalette.blue.opacity(0.12), radius: 8, y: 4)
                .accessibilityIdentifier("restartButton")
            }
        }
    }

    private var statusCard: some View {
        HStack(spacing: 0) {
            StatView(title: "剩余地雷", value: String(game.remainingMines), symbol: "flag.fill", tint: SaoleiPalette.orange)
            Divider()
                .frame(height: 40)
            StatView(title: "用时", value: formattedTime, symbol: "timer", tint: SaoleiPalette.blue)
            Divider()
                .frame(height: 40)
            HStack(spacing: 9) {
                Image(systemName: game.status.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(statusTint)
                Text(game.status.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: SaoleiPalette.blue.opacity(0.10), radius: 12, y: 6)
    }

    private var boardToolbar: some View {
        HStack {
            Label(flagMode ? "插旗模式" : "挖开模式", systemImage: flagMode ? "flag.fill" : "hand.tap.fill")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(flagMode ? SaoleiPalette.orange : SaoleiPalette.blueDeep)

            Spacer()

            Button {
                flagMode.toggle()
                fireImpact()
            } label: {
                Text(flagMode ? "切换挖开" : "切换插旗")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(flagMode ? SaoleiPalette.blueDeep : SaoleiPalette.orange)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background((flagMode ? SaoleiPalette.blue : SaoleiPalette.orange).opacity(0.13))
                    .clipShape(Capsule())
            }
            .accessibilityIdentifier("toggleFlagModeButton")
        }
    }

    private func gameBoard(side: CGFloat) -> some View {
        let gap = CGFloat(max(game.difficulty.columns - 1, 0) * 4)
        let cellSide = max(1, (side - 20 - gap) / CGFloat(game.difficulty.columns))

        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cellSide), spacing: 4), count: game.difficulty.columns),
            spacing: 4
        ) {
            ForEach(game.cells) { cell in
                CellButton(cell: cell, status: game.status, side: cellSide) {
                    play(cell: cell)
                }
            }
        }
        .frame(width: side, height: side)
        .padding(10)
        .background(SaoleiPalette.blueDeep.opacity(0.92))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.blueDeep.opacity(0.24), radius: 15, y: 9)
    }

    private var formattedTime: String {
        String(format: "%02d:%02d", game.elapsedSeconds / 60, game.elapsedSeconds % 60)
    }

    private var statusTint: Color {
        switch game.status {
        case .ready: return SaoleiPalette.blue
        case .playing, .won: return SaoleiPalette.mint
        case .lost: return SaoleiPalette.orange
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

    private func play(cell: MineCell) {
        if flagMode {
            game.toggleFlag(row: cell.row, column: cell.column)
            fireImpact()
        } else {
            let oldStatus = game.status
            game.reveal(row: cell.row, column: cell.column)
            if game.status != oldStatus {
                fireNotification(for: game.status)
            } else {
                fireImpact()
            }
        }
    }

    private func restartGame() {
        game.reset()
        flagMode = false
        fireImpact()
    }

    private func fireImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fireNotification(for status: GameStatus) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(status == .won ? .success : .error)
    }
}

private struct CellButton: View {
    let cell: MineCell
    let status: GameStatus
    let side: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: max(6, side * 0.16), style: .continuous)
                    .fill(fillColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: max(6, side * 0.16), style: .continuous)
                            .stroke(borderColor, lineWidth: cell.state == .hidden ? 2 : 1)
                    }

                cellContent
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint(cell.state == .hidden ? "轻点打开" : "")
    }

    @ViewBuilder
    private var cellContent: some View {
        if cell.state == .flagged {
            if status == .lost && !cell.isMine {
                Text("✕")
                    .font(.system(size: side * 0.38, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.orange)
            } else {
                Text("🚩")
                    .font(.system(size: side * 0.42))
            }
        } else if cell.state == .revealed {
            if cell.isMine {
                Text("💣")
                    .font(.system(size: side * 0.43))
            } else if cell.adjacentMines > 0 {
                Text("\(cell.adjacentMines)")
                    .font(.system(size: side * 0.40, weight: .black, design: .rounded))
                    .foregroundStyle(numberColor)
            } else {
                Image(systemName: "checkmark")
                    .font(.system(size: side * 0.27, weight: .black))
                    .foregroundStyle(SaoleiPalette.mint.opacity(0.65))
            }
        } else {
            Image(systemName: "sparkle")
                .font(.system(size: side * 0.22, weight: .bold))
                .foregroundStyle(.white.opacity(0.84))
        }
    }

    private var fillColor: Color {
        switch cell.state {
        case .hidden, .flagged: return SaoleiPalette.hiddenCell
        case .revealed:
            return cell.isMine ? SaoleiPalette.orange.opacity(0.24) : SaoleiPalette.revealedCell
        }
    }

    private var borderColor: Color {
        switch cell.state {
        case .hidden: return .white.opacity(0.8)
        case .flagged: return SaoleiPalette.orange.opacity(0.75)
        case .revealed: return SaoleiPalette.blue.opacity(0.11)
        }
    }

    private var numberColor: Color {
        switch cell.adjacentMines {
        case 1: return SaoleiPalette.blue
        case 2: return SaoleiPalette.mint
        case 3: return SaoleiPalette.orange
        default: return SaoleiPalette.purple
        }
    }

    private var accessibilityText: String {
        switch cell.state {
        case .hidden: return "未打开的格子"
        case .flagged: return cell.isMine ? "已标记的地雷" : "标记的格子"
        case .revealed:
            if cell.isMine { return "地雷" }
            return cell.adjacentMines == 0 ? "安全格" : "周围有 \(cell.adjacentMines) 颗地雷"
        }
    }
}

#Preview("游戏页面") {
    NavigationStack {
        GameView(difficulty: .starter)
    }
}
