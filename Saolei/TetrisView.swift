import SwiftUI
import UIKit

struct TetrisView: View {
    @State private var game = TetrisGame()
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

    private func gameLayout(in proxy: GeometryProxy) -> some View {
        let boardSide = min(
            420,
            proxy.size.width - 40,
            max(250, (proxy.size.height - 320) / 2)
        )

        return ScrollView {
            VStack(spacing: 14) {
                gameHeader
                scoreCard

                ZStack {
                    gameBoard(side: boardSide)
                    if game.status != .playing {
                        statusOverlay
                    }
                }

                controlPanel

                Text("左右拖动调整位置 · 向上拖动直接落下 · 点击旋转")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var gameHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("小小拼图屋")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("拼满一行，方块就会消失！")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Button {
                game.reset()
                fireImpact()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SaoleiPalette.blueDeep)
                    .frame(width: 42, height: 42)
                    .background(SaoleiPalette.card)
                    .clipShape(Circle())
                    .shadow(color: SaoleiPalette.blue.opacity(0.12), radius: 8, y: 4)
            }
            .accessibilityLabel("重新开始")
        }
    }

    private var scoreCard: some View {
        HStack(spacing: 0) {
            StatView(title: "分数", value: String(game.score), symbol: "star.fill", tint: SaoleiPalette.orange)
            Divider()
                .frame(height: 40)
            StatView(title: "消除行数", value: String(game.clearedLines), symbol: "square.grid.3x3.fill", tint: SaoleiPalette.mint)
            Divider()
                .frame(height: 40)
            VStack(spacing: 4) {
                Text("下一个")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                MiniTetrisPieceView(piece: game.nextPiece)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .shadow(color: SaoleiPalette.blue.opacity(0.10), radius: 12, y: 6)
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

    private var controlPanel: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                controlButton(title: "左移", systemName: "arrow.left") {
                    game.moveLeft()
                }
                controlButton(title: "旋转", systemName: "rotate.right") {
                    game.rotate()
                }
                controlButton(title: "右移", systemName: "arrow.right") {
                    game.moveRight()
                }
            }

            HStack(spacing: 10) {
                controlButton(title: "下移", systemName: "arrow.down") {
                    game.softDrop()
                }
                controlButton(title: "到底", systemName: "chevron.down.2") {
                    game.hardDrop()
                }
            }
        }
    }

    private func controlButton(title: String, systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            fireImpact()
        } label: {
            Label(title, systemImage: systemName)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.blueDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(SaoleiPalette.card)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .shadow(color: SaoleiPalette.blue.opacity(0.09), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(!game.isPlaying)
        .opacity(game.isPlaying ? 1 : 0.5)
    }

    private var statusOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: game.status.symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(statusTint)
            Text(game.status.title)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.ink)
            Text(statusMessage)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
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
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(statusTint)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(.white.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: SaoleiPalette.blueDeep.opacity(0.20), radius: 16, y: 8)
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
    private let side: CGFloat = 10

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
