import SwiftUI
import UIKit

enum GomokuPalette {
    static let background = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let boardFrame = Color(red: 0.27, green: 0.16, blue: 0.10)
    static let board = Color(red: 0.86, green: 0.65, blue: 0.34)
    static let grid = Color(red: 0.31, green: 0.19, blue: 0.11)
    static let playerStone = Color(red: 0.07, green: 0.08, blue: 0.11)
    static let botStone = Color(red: 0.96, green: 0.96, blue: 0.94)
    static let winning = Color(red: 0.94, green: 0.36, blue: 0.22)
}

struct GomokuView: View {
    let difficulty: GomokuDifficulty

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

    private func gameLayout(in proxy: GeometryProxy) -> some View {
        let boardSide = min(
            720,
            proxy.size.width - 36,
            max(300, proxy.size.height - 300)
        )

        return ScrollView {
            VStack(spacing: 12) {
                pageHeader
                statusCard
                teachingCard
                gameBoard(side: boardSide)
                controlsCard
                restartButton
            }
            .frame(maxWidth: 820)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
        }
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

    private var teachingCard: some View {
        let tip = game.teachingTip

        return VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 8) {
                Image(systemName: "graduationcap.fill")
                    .foregroundStyle(accentColor)
                Text("教学提示")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                Spacer(minLength: 0)

                Text("边玩边学")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(accentColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: tip.symbol)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(accentColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(tip.title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(SaoleiPalette.ink)
                    Text(tip.message)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                ForEach(GomokuLearningSkill.allCases) { skill in
                    GomokuSkillBadge(
                        skill: skill,
                        isHighlighted: skill == tip.skill
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(accentColor.opacity(0.28), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: GomokuPalette.boardFrame.opacity(0.10), radius: 12, y: 6)
        .animation(.easeInOut(duration: 0.35), value: tip)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("教学提示：\(tip.title)。\(tip.message)。正在练习\(tip.skill.title)")
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

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("玩法提示", systemImage: "lightbulb.fill")
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(accentColor)

            Text("黑方先行，横、竖或斜线连成五个棋子即可获胜。点击空位落子，电脑会自动应战。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(GomokuPalette.board.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    .fill(stone == .player ? GomokuPalette.playerStone : GomokuPalette.botStone)
                    .overlay {
                        Circle()
                            .stroke(
                                stone == .player ? .white.opacity(0.16) : GomokuPalette.grid.opacity(0.28),
                                lineWidth: max(0.8, side * 0.035)
                            )
                    }
                    .shadow(
                        color: .black.opacity(stone == .player ? 0.28 : 0.16),
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
                        .stroke(GomokuPalette.grid.opacity(0.25), lineWidth: 1)
                }
                .frame(width: 20, height: 20)
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(SaoleiPalette.ink)
        }
    }
}

private struct GomokuSkillBadge: View {
    let skill: GomokuLearningSkill
    let isHighlighted: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: skill.symbol)
                .font(.system(size: 11, weight: .bold))
            Text(skill.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(isHighlighted ? accentColor : SaoleiPalette.mutedInk)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(isHighlighted ? accentColor.opacity(0.14) : SaoleiPalette.background)
        .clipShape(Capsule())
    }

    private var accentColor: Color {
        switch skill {
        case .observe: return SaoleiPalette.blue
        case .count: return SaoleiPalette.mint
        case .plan: return SaoleiPalette.orange
        case .focus: return SaoleiPalette.purple
        }
    }
}

#Preview("五子棋") {
    NavigationStack {
        GomokuView(difficulty: .beginner)
    }
}
