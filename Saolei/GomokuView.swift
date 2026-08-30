import SwiftUI
import UIKit

enum GomokuPalette {
    static let background = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let boardFrame = Color(red: 0.27, green: 0.16, blue: 0.10)
    static let board = Color(red: 0.86, green: 0.65, blue: 0.34)
    static let grid = Color(red: 0.31, green: 0.19, blue: 0.11)
    static let playerStone = Color(red: 0.02, green: 0.03, blue: 0.06)
    static let botStone = Color(red: 0.96, green: 0.98, blue: 1.0)
    static let winning = Color(red: 0.94, green: 0.36, blue: 0.22)
}

struct GomokuView: View {
    let difficulty: GomokuDifficulty

    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var game: GomokuGame
    @State private var botTurnID = UUID()

    init(difficulty: GomokuDifficulty) {
        self.difficulty = difficulty
        _game = State(initialValue: GomokuGame(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            GomokuPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                gameLayout(in: proxy)
            }
        }
        .navigationTitle("五子棋")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            botTurnID = UUID()
        }
    }

    @ViewBuilder
    private func gameLayout(in proxy: GeometryProxy) -> some View {
        if proxy.size.width > proxy.size.height && horizontalSizeClass != .regular {
            phoneLandscapeLayout(in: proxy)
        } else if proxy.size.width > proxy.size.height {
            landscapeLayout(in: proxy)
        } else {
            portraitLayout(in: proxy)
        }
    }

    private func portraitLayout(in proxy: GeometryProxy) -> some View {
        let boardSide = min(
            720,
            max(180, proxy.size.width - 64),
            max(180, proxy.size.height - 320)
        )

        return VStack(spacing: 8) {
            pageHeader
            statusCard
            teachingCard
            gameBoard(side: boardSide)
            restartButton
        }
        .frame(maxWidth: 820, maxHeight: .infinity, alignment: .top)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func landscapeLayout(in proxy: GeometryProxy) -> some View {
        let boardSide = min(
            720,
            max(200, proxy.size.height - 30),
            proxy.size.width * 0.58
        )

        return HStack(alignment: .center, spacing: 14) {
            gameBoard(side: boardSide)

            VStack(alignment: .leading, spacing: 10) {
                landscapeHeader
                landscapeStatusCard
                teachingCard
                Spacer(minLength: 0)
                restartButton
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: 1100, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func phoneLandscapeLayout(in proxy: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 4
        let headerHeight: CGFloat = 36
        let contentSpacing: CGFloat = 8
        let availableWidth = max(1, proxy.size.width - horizontalPadding * 2)
        let minimumSidebarWidth: CGFloat = 220
        let boardOuterInset: CGFloat = 8
        let availableHeight = max(1, proxy.size.height - headerHeight - verticalPadding * 2)
        let boardSide = max(1, min(
            720,
            availableHeight - boardOuterInset,
            availableWidth - minimumSidebarWidth - contentSpacing
        ))
        let sidebarWidth = max(minimumSidebarWidth, availableWidth - boardSide - contentSpacing)

        return VStack(spacing: 4) {
            phoneLandscapeHeader

            HStack(alignment: .top, spacing: contentSpacing) {
                gameBoard(side: boardSide)
                    .layoutPriority(1)

                VStack(alignment: .leading, spacing: 8) {
                    landscapeStatusCard
                        .frame(maxWidth: .infinity)
                    teachingCard
                        .frame(maxWidth: .infinity)
                    restartButton
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
                Text("五子棋")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("人机对战 · \(difficulty.title)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 4)

            Text("第 \(game.moveCount + 1) 手")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(GomokuPalette.boardFrame)
                .lineLimit(1)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 4)
        .frame(height: 36)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var pageHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(GomokuPalette.boardFrame)
                    .frame(width: 54, height: 54)
                Text("●○")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("五子棋")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("人机对战 · \(difficulty.title)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            HStack(spacing: 7) {
                Image(systemName: "number.circle.fill")
                Text("第 \(game.moveCount + 1) 手")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(GomokuPalette.boardFrame)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(GomokuPalette.board.opacity(0.28))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: game.status.symbol)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(statusTint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.status.title)
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(SaoleiPalette.ink)
                    Text(game.status.detail)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 18) {
                GomokuStoneLegend(stone: .player, title: "你 · 黑方")
                GomokuStoneLegend(stone: .bot, title: "电脑 · 白方")
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: GomokuPalette.boardFrame.opacity(0.11), radius: 12, y: 6)
        .animation(.easeInOut(duration: 0.35), value: game.status)
    }

    private var landscapeHeader: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("五子棋")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("人机对战 · \(difficulty.title)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Text("第 \(game.moveCount + 1) 手")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(GomokuPalette.boardFrame)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var landscapeStatusCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: game.status.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(statusTint)

                VStack(alignment: .leading, spacing: 1) {
                    Text(game.status.title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(SaoleiPalette.ink)
                        .lineLimit(1)
                    Text(game.status.detail)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                GomokuStoneLegend(stone: .player, title: "黑方")
                GomokuStoneLegend(stone: .bot, title: "白方")
                Spacer(minLength: 0)
            }
        }
        .padding(12)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: GomokuPalette.boardFrame.opacity(0.10), radius: 10, y: 5)
        .animation(.easeInOut(duration: 0.35), value: game.status)
    }

    private var teachingCard: some View {
        let tip = game.teachingTip

        return HStack(spacing: 8) {
            Image(systemName: tip.symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(accentColor)

            Text("玩法：黑方先行，连成五子获胜 · 教学：\(tip.message)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(GomokuPalette.board.opacity(0.16))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 1.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .animation(.easeInOut(duration: 0.35), value: tip)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("玩法和教学提示：黑方先行，连成五子获胜。\(tip.title)：\(tip.message)。正在练习\(tip.skill.title)")
    }

    private func gameBoard(side: CGFloat) -> some View {
        let cellSide = side / CGFloat(GomokuGame.boardSize)

        return ZStack {
            Canvas { context, size in
                let inset = cellSide / 2
                var lines = Path()

                for index in 0..<GomokuGame.boardSize {
                    let coordinate = inset + CGFloat(index) * cellSide
                    lines.move(to: CGPoint(x: inset, y: coordinate))
                    lines.addLine(to: CGPoint(x: size.width - inset, y: coordinate))
                    lines.move(to: CGPoint(x: coordinate, y: inset))
                    lines.addLine(to: CGPoint(x: coordinate, y: size.height - inset))
                }
                context.stroke(lines, with: .color(GomokuPalette.grid.opacity(0.78)), lineWidth: max(1, cellSide * 0.045))

                let starPoints = [3, 7, 11]
                for row in starPoints {
                    for column in starPoints {
                        let center = CGPoint(
                            x: inset + CGFloat(column) * cellSide,
                            y: inset + CGFloat(row) * cellSide
                        )
                        let radius = max(2.5, cellSide * 0.11)
                        context.fill(Path(ellipseIn: CGRect(
                            x: center.x - radius,
                            y: center.y - radius,
                            width: radius * 2,
                            height: radius * 2
                        )), with: .color(GomokuPalette.grid))
                    }
                }
            }
            .allowsHitTesting(false)

            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSide), spacing: 0), count: GomokuGame.boardSize),
                spacing: 0
            ) {
                ForEach(game.board.indices, id: \.self) { index in
                    boardCell(index: index, side: cellSide)
                }
            }
        }
        .frame(width: side, height: side)
        .background(GomokuPalette.board)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .padding(10)
        .background(GomokuPalette.boardFrame)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: GomokuPalette.boardFrame.opacity(0.25), radius: 15, y: 9)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("五子棋棋盘，\(game.status.title)")
    }

    private func boardCell(index: Int, side: CGFloat) -> some View {
        let row = index / GomokuGame.boardSize
        let column = index % GomokuGame.boardSize
        let position = GomokuPosition(row: row, column: column)
        let stone = game.board[index]

        return Button {
            play(row: row, column: column)
        } label: {
            GomokuBoardCell(
                stone: stone,
                side: side,
                isLastMove: game.lastMove == position,
                isWinning: game.winningLine.contains(position)
            )
        }
        .buttonStyle(.plain)
        .disabled(game.status != .playerTurn || stone != .empty)
        .accessibilityLabel("第 \(row + 1) 行，第 \(column + 1) 列，\(stone.title)")
        .accessibilityHint(stone == .empty && game.status == .playerTurn ? "轻点落子" : "")
    }

    private var restartButton: some View {
        Button {
            restartGame()
        } label: {
            Label("重新开始", systemImage: "arrow.clockwise")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .foregroundStyle(.white)
        .background(GomokuPalette.boardFrame)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityIdentifier("gomokuRestartButton")
    }

    private var accentColor: Color {
        switch difficulty.accent {
        case .mint: return SaoleiPalette.mint
        case .sky: return SaoleiPalette.sky
        case .orange: return SaoleiPalette.orange
        case .purple: return SaoleiPalette.purple
        }
    }

    private var statusTint: Color {
        switch game.status {
        case .playerTurn: return SaoleiPalette.blue
        case .botThinking: return SaoleiPalette.purple
        case .playerWon: return SaoleiPalette.mint
        case .botWon: return SaoleiPalette.orange
        case .draw: return SaoleiPalette.mutedInk
        }
    }

    private func play(row: Int, column: Int) {
        guard game.playPlayerMove(row: row, column: column) else { return }

        fireImpact()

        guard game.status == .botThinking else {
            fireNotification(for: game.status)
            return
        }

        let turnID = UUID()
        botTurnID = turnID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.42) {
            guard turnID == botTurnID else { return }
            guard game.playBotMove() else { return }
            fireImpact()
            if game.status.isFinished {
                fireNotification(for: game.status)
            }
        }
    }

    private func restartGame() {
        botTurnID = UUID()
        game.reset()
        fireImpact()
    }

    private func fireImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fireNotification(for status: GomokuGameStatus) {
        let generator = UINotificationFeedbackGenerator()
        switch status {
        case .playerWon: generator.notificationOccurred(.success)
        case .botWon: generator.notificationOccurred(.error)
        case .draw: generator.notificationOccurred(.warning)
        case .playerTurn, .botThinking: break
        }
    }
}

private struct GomokuBoardCell: View {
    let stone: GomokuStone
    let side: CGFloat
    let isLastMove: Bool
    let isWinning: Bool

    var body: some View {
        ZStack {
            if stone != .empty {
                Circle()
                    .fill(stoneFill)
                    .overlay {
                        Circle()
                            .stroke(
                                stone == .player ? .white.opacity(0.20) : GomokuPalette.grid.opacity(0.30),
                                lineWidth: max(0.8, side * 0.035)
                            )
                    }
                    .shadow(
                        color: .black.opacity(stone == .player ? 0.28 : 0.24),
                        radius: max(2, side * 0.08),
                        y: max(1, side * 0.04)
                    )
                    .frame(width: side * 0.78, height: side * 0.78)

                if isLastMove {
                    Circle()
                        .fill(stone == .player ? .white : GomokuPalette.playerStone)
                        .frame(width: max(4, side * 0.14), height: max(4, side * 0.14))
                }

                if isWinning {
                    Circle()
                        .stroke(GomokuPalette.winning, lineWidth: max(2, side * 0.09))
                        .frame(width: side * 0.92, height: side * 0.92)
                }
            }
        }
        .frame(width: side, height: side)
        .contentShape(Rectangle())
    }

    private var stoneFill: LinearGradient {
        switch stone {
        case .player:
            return LinearGradient(
                colors: [
                    Color(red: 0.30, green: 0.34, blue: 0.42),
                    GomokuPalette.playerStone,
                    Color(red: 0.01, green: 0.01, blue: 0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .bot:
            return LinearGradient(
                colors: [
                    .white,
                    GomokuPalette.botStone,
                    Color(red: 0.82, green: 0.87, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .empty:
            return LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

private struct GomokuStoneLegend: View {
    let stone: GomokuStone
    let title: String

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(stone == .player ? GomokuPalette.playerStone : GomokuPalette.botStone)
                .overlay {
                    Circle()
                        .stroke(GomokuPalette.grid.opacity(0.78), lineWidth: 1.5)
                }
                .frame(width: 20, height: 20)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SaoleiPalette.ink)
        }
    }
}

#Preview("五子棋") {
    NavigationStack {
        GomokuView(difficulty: .beginner)
    }
}
