import SwiftUI
import UIKit

struct TetrisView: View {
    @State private var game = TetrisGame()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private let timer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SaoleiPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                gameLayout(in: proxy)
            }
        }
        .navigationTitle("俄罗斯方块")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            game.tick()
        }
    }

    @ViewBuilder
    private func gameLayout(in proxy: GeometryProxy) -> some View {
        let isLargeLayout = horizontalSizeClass == .regular || (proxy.size.width >= 700 && proxy.size.height >= 600)

        if isLargeLayout {
            iPadGameLayout(in: proxy)
        } else if proxy.size.width > proxy.size.height {
            widePhoneGameLayout(in: proxy)
        } else {
            phoneGameLayout(in: proxy)
        }
    }

    private func phoneGameLayout(in proxy: GeometryProxy) -> some View {
        let isCompact = proxy.size.height < 700
        let horizontalPadding: CGFloat = isCompact ? 12 : 20
        let verticalPadding: CGFloat = isCompact ? 6 : 10
        let spacing: CGFloat = isCompact ? 8 : 10
        let boardReservation: CGFloat = isCompact ? 254 : 318
        let availableWidth = max(140, proxy.size.width - horizontalPadding * 2)
        let availableHeight = max(140, (proxy.size.height - boardReservation) / 2)
        let boardSide = min(420, availableWidth, availableHeight)

        return VStack(spacing: spacing) {
            gameHeader(compact: isCompact)
            scoreCard(compact: isCompact)
            boardWithStatus(side: boardSide, compact: isCompact)
            controlPanel(compact: isCompact)
            instructions(compact: isCompact)
        }
        .frame(maxWidth: 520)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
    }

    private func widePhoneGameLayout(in proxy: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 12
        let contentSpacing: CGFloat = 12
        let sidebarWidth = min(250, max(220, proxy.size.width * 0.32))
        let boardWidth = proxy.size.width - horizontalPadding * 2 - contentSpacing - sidebarWidth
        let boardHeight = max(140, (proxy.size.height - 24) / 2)
        let boardSide = min(260, boardWidth, boardHeight)

        return HStack(alignment: .top, spacing: contentSpacing) {
            boardWithStatus(side: boardSide, compact: true)
                .frame(maxWidth: .infinity, alignment: .top)

            VStack(spacing: 8) {
                gameHeader(compact: true)
                scoreCard(compact: true)
                controlPanel(compact: true)
                instructions(compact: true)
            }
            .frame(width: sidebarWidth)
        }
        .frame(maxWidth: 760)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 12)
    }

    private func iPadGameLayout(in proxy: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = proxy.size.width > 1_000 ? 32 : 20
        let contentSpacing: CGFloat = 24
        let sidebarWidth = min(340, max(250, proxy.size.width * 0.32))
        let boardWidth = proxy.size.width - horizontalPadding * 2 - contentSpacing - sidebarWidth
        let boardHeight = max(200, (proxy.size.height - 128) / 2)
        let boardSide = min(420, boardWidth, boardHeight)

        return VStack(spacing: 18) {
            gameHeader()

            HStack(alignment: .top, spacing: contentSpacing) {
                boardWithStatus(side: boardSide)
                    .frame(maxWidth: .infinity, alignment: .top)

                VStack(spacing: 16) {
                    scoreCard()
                    controlPanel()
                    instructions()
                }
                .frame(width: sidebarWidth)
            }
        }
        .frame(maxWidth: 1_180)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 16)
    }

    private func gameHeader(compact: Bool = false) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("小小拼图屋")
                    .font(.system(size: compact ? 21 : 24, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("拼满一行，方块就会消失！")
                    .font(.system(size: compact ? 12 : 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Button {
                game.reset()
                fireImpact()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: compact ? 16 : 18, weight: .bold))
                    .foregroundStyle(SaoleiPalette.blueDeep)
                    .frame(width: compact ? 36 : 42, height: compact ? 36 : 42)
                    .background(SaoleiPalette.card)
                    .clipShape(Circle())
                    .shadow(color: SaoleiPalette.blue.opacity(0.12), radius: 8, y: 4)
            }
            .accessibilityLabel("重新开始")
        }
    }

    private func scoreCard(compact: Bool = false) -> some View {
        HStack(spacing: 0) {
            StatView(title: "分数", value: String(game.score), symbol: "star.fill", tint: SaoleiPalette.orange)
            Divider()
                .frame(height: compact ? 34 : 40)
            StatView(title: "消除行数", value: String(game.clearedLines), symbol: "square.grid.3x3.fill", tint: SaoleiPalette.mint)
            Divider()
                .frame(height: compact ? 34 : 40)
            VStack(spacing: 4) {
                Text("下一个")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                MiniTetrisPieceView(piece: game.nextPiece, side: compact ? 8 : 10)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, compact ? 7 : 10)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .shadow(color: SaoleiPalette.blue.opacity(0.10), radius: 12, y: 6)
    }

    private func boardWithStatus(side: CGFloat, compact: Bool = false) -> some View {
        ZStack {
            gameBoard(side: side)
            if game.status != .playing {
                statusOverlay(compact: compact)
            }
        }
    }

    private func gameBoard(side: CGFloat) -> some View {
        let horizontalSpacing: CGFloat = 2
        let cellSide = max(12, (side - 16 - horizontalSpacing * CGFloat(TetrisGame.columns - 1)) / CGFloat(TetrisGame.columns))

        return LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(cellSide), spacing: horizontalSpacing), count: TetrisGame.columns),
            spacing: horizontalSpacing
        ) {
            ForEach(0..<(TetrisGame.rows * TetrisGame.columns), id: \.self) { index in
                let row = index / TetrisGame.columns
                let column = index % TetrisGame.columns
                TetrisBoardCell(kind: game.kind(at: row, column: column), side: cellSide)
            }
        }
        .padding(8)
        .frame(width: side, height: side * 2)
        .background(SaoleiPalette.blueDeep.opacity(0.94))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.blueDeep.opacity(0.25), radius: 15, y: 9)
        .contentShape(Rectangle())
        .gesture(boardGesture)
        .onTapGesture {
            guard game.isPlaying else { return }
            game.rotate()
            fireImpact()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("俄罗斯方块游戏棋盘")
    }

    private var boardGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onEnded { value in
                guard game.isPlaying else { return }

                let translation = value.translation
                if abs(translation.width) > abs(translation.height) {
                    let moves = max(1, min(4, Int(abs(translation.width) / 24)))
                    for _ in 0..<moves {
                        if translation.width > 0 {
                            game.moveRight()
                        } else {
                            game.moveLeft()
                        }
                    }
                } else if translation.height > 0 {
                    game.softDrop()
                } else {
                    game.hardDrop()
                }
                fireImpact()
            }
    }

    private func controlPanel(compact: Bool = false) -> some View {
        VStack(spacing: compact ? 8 : 10) {
            HStack(spacing: compact ? 8 : 10) {
                controlButton(title: "左移", systemName: "arrow.left", compact: compact) {
                    game.moveLeft()
                }
                controlButton(title: "旋转", systemName: "rotate.right", compact: compact) {
                    game.rotate()
                }
                controlButton(title: "右移", systemName: "arrow.right", compact: compact) {
                    game.moveRight()
                }
            }

            HStack(spacing: compact ? 8 : 10) {
                controlButton(title: "下移", systemName: "arrow.down", compact: compact) {
                    game.softDrop()
                }
                controlButton(title: "到底", systemName: "chevron.down.2", compact: compact) {
                    game.hardDrop()
                }
            }
        }
    }

    private func controlButton(title: String, systemName: String, compact: Bool = false, action: @escaping () -> Void) -> some View {
        Button {
            action()
            fireImpact()
        } label: {
            Label(title, systemImage: systemName)
                .font(.system(size: compact ? 14 : 16, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.blueDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, compact ? 7 : 12)
                .background(SaoleiPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: SaoleiPalette.blue.opacity(0.09), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!game.isPlaying)
        .opacity(game.isPlaying ? 1 : 0.5)
    }

    private func instructions(compact: Bool = false) -> some View {
        Text("左右拖动调整位置 · 向上拖动直接落下 · 点击旋转")
            .font(.system(size: compact ? 12 : 14, weight: .medium, design: .rounded))
            .foregroundStyle(SaoleiPalette.mutedInk)
            .multilineTextAlignment(.center)
            .lineLimit(compact ? 2 : 1)
    }

    private func statusOverlay(compact: Bool = false) -> some View {
        VStack(spacing: 12) {
            Image(systemName: game.status.symbol)
                .font(.system(size: compact ? 22 : 28, weight: .bold))
                .foregroundStyle(statusTint)
            Text(game.status.title)
                .font(.system(size: compact ? 18 : 20, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.ink)
            Text(statusMessage)
                .font(.system(size: compact ? 12 : 14, weight: .semibold, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)

            Button {
                if game.status == .ready {
                    game.start()
                } else if game.status == .paused {
                    game.pauseOrResume()
                } else {
                    game.reset()
                    game.start()
                }
                fireImpact()
            } label: {
                Text(statusButtonTitle)
                    .font(.system(size: compact ? 14 : 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, compact ? 16 : 22)
                    .padding(.vertical, compact ? 8 : 11)
                    .background(statusTint)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, compact ? 14 : 22)
        .padding(.vertical, compact ? 14 : 20)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: SaoleiPalette.blueDeep.opacity(0.20), radius: 16, y: 8)
        .zIndex(1)
    }

    private var statusMessage: String {
        switch game.status {
        case .ready: return "拖动方块，把它们拼成完整的一行"
        case .playing: return ""
        case .paused: return "休息一下，准备好后继续"
        case .lost: return "再试一次，这次一定能拼出更多行"
        }
    }

    private var statusButtonTitle: String {
        switch game.status {
        case .ready: return "开始游戏"
        case .playing: return "继续游戏"
        case .paused: return "继续游戏"
        case .lost: return "再来一局"
        }
    }

    private var statusTint: Color {
        switch game.status {
        case .ready, .paused: return SaoleiPalette.blue
        case .playing: return SaoleiPalette.mint
        case .lost: return SaoleiPalette.orange
        }
    }

    private func fireImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private struct TetrisBoardCell: View {
    let kind: TetrisPieceKind?
    let side: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: max(3, side * 0.16), style: .continuous)
            .fill(fillColor)
            .overlay {
                RoundedRectangle(cornerRadius: max(3, side * 0.16), style: .continuous)
                    .stroke(kind == nil ? .white.opacity(0.08) : .white.opacity(0.42), lineWidth: kind == nil ? 1 : 1.5)
            }
            .overlay {
                if kind != nil {
                    RoundedRectangle(cornerRadius: max(3, side * 0.16), style: .continuous)
                        .fill(.white.opacity(0.16))
                        .padding(side * 0.16)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
            .frame(width: side, height: side)
    }

    private var fillColor: Color {
        guard let kind = kind else { return .white.opacity(0.07) }
        return TetrisColors.color(for: kind)
    }
}

private struct MiniTetrisPieceView: View {
    let piece: TetrisPiece
    let side: CGFloat

    init(piece: TetrisPiece, side: CGFloat = 10) {
        self.piece = piece
        self.side = side
    }

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(side), spacing: 1), count: 4), spacing: 1) {
            ForEach(0..<16, id: \.self) { index in
                let row = index / 4
                let column = index % 4
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(isPieceBlock(row: row, column: column) ? TetrisColors.color(for: piece.kind) : .clear)
                    .frame(width: side, height: side)
            }
        }
        .frame(width: side * 4 + 3, height: side * 4 + 3)
    }

    private func isPieceBlock(row: Int, column: Int) -> Bool {
        piece.blocks.contains { $0.row == row && $0.column == column }
    }
}

private enum TetrisColors {
    static func color(for kind: TetrisPieceKind) -> Color {
        switch kind {
        case .i: return SaoleiPalette.sky
        case .o: return Color(red: 0.98, green: 0.75, blue: 0.20)
        case .t: return SaoleiPalette.purple
        case .s: return SaoleiPalette.mint
        case .z: return SaoleiPalette.orange
        case .j: return SaoleiPalette.blue
        case .l: return Color(red: 0.95, green: 0.37, blue: 0.55)
        }
    }
}

#Preview("俄罗斯方块") {
    NavigationStack {
        TetrisView()
    }
}
