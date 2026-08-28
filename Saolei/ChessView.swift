import SwiftUI
import UIKit

enum ChessPalette {
    static let background = Color(red: 0.95, green: 0.96, blue: 0.94)
    static let boardFrame = Color(red: 0.16, green: 0.22, blue: 0.27)
    static let lightSquare = Color(red: 0.91, green: 0.84, blue: 0.70)
    static let darkSquare = Color(red: 0.39, green: 0.28, blue: 0.23)
    static let blackPiece = Color(red: 0.06, green: 0.07, blue: 0.09)
    static let gold = Color(red: 0.95, green: 0.67, blue: 0.22)
    static let check = Color(red: 0.91, green: 0.29, blue: 0.25)
}

struct ChessView: View {
    let difficulty: ChessDifficulty

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var game: ChessGame
    @State private var selectedSquare: ChessSquare?
    @State private var pendingPromotionMoves: [ChessMove] = []
    @State private var showingPromotionChoice = false
    @State private var botTurnID = UUID()
    @State private var gameplayMessages: [ChessGameplayMessage] = []
    @State private var highlightedBotMove: ChessMove?
    @State private var capturedPieceMarker: ChessCapturedPieceMarker?
    @State private var hasShownInitialInstruction = false

    init(difficulty: ChessDifficulty) {
        self.difficulty = difficulty
        _game = State(initialValue: ChessGame(difficulty: difficulty))
    }

    var body: some View {
        ZStack {
            ChessPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                if horizontalSizeClass == .regular {
                    if proxy.size.width > proxy.size.height {
                        if canUseLandscapeSplitLayout(size: proxy.size) {
                            iPadLandscapeLayout(size: proxy.size)
                        } else {
                            verticalLayout(size: proxy.size)
                        }
                    } else {
                        iPadPortraitLayout(size: proxy.size)
                    }
                } else {
                    verticalLayout(size: proxy.size)
                }
            }
        }
        .navigationTitle("国际象棋")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("选择升变棋子", isPresented: $showingPromotionChoice, titleVisibility: .visible) {
            ForEach(pendingPromotionMoves, id: \.self) { move in
                Button("升变为\(move.promotion?.title ?? "后")") {
                    play(move)
                }
            }
            Button("取消", role: .cancel) {
                pendingPromotionMoves = []
            }
        } message: {
            Text("兵走到最后一排后，可以变成后、车、象或马")
        }
        .onDisappear {
            botTurnID = UUID()
        }
    }

    private func canUseLandscapeSplitLayout(size: CGSize) -> Bool {
        let horizontalPadding = min(30, max(18, size.width * 0.025))
        let availableWidth = size.width - horizontalPadding * 2
        let sidebarWidth = min(300, max(250, availableWidth * 0.27))
        let boardWidth = availableWidth - sidebarWidth - 16

        return size.width >= 900 && size.height >= 568 && boardWidth >= 420
    }

    private func iPadLandscapeLayout(size: CGSize) -> some View {
        let horizontalPadding = min(30, max(18, size.width * 0.025))
        let availableWidth = size.width - horizontalPadding * 2
        let sidebarWidth = min(300, max(250, availableWidth * 0.27))
        let maxBoardSide = availableWidth - sidebarWidth - 16
        let boardSide = min(720, min(maxBoardSide, size.height - 112))

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 10) {
                pageHeader

                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 10) {
                        chessBoard(side: boardSide)
                        rulesCard
                    }
                    .frame(width: boardSide, alignment: .top)

                    VStack(spacing: 12) {
                        statusCard
                        controlsCard
                        HStack(spacing: 10) {
                            undoButton
                            restartButton
                        }
                    }
                    .frame(width: sidebarWidth, alignment: .top)
                }
            }
            .frame(maxWidth: 1_260, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, 10)
        }
    }

    private func iPadPortraitLayout(size: CGSize) -> some View {
        let horizontalPadding = min(28, max(18, size.width * 0.04))
        let contentWidth = size.width - horizontalPadding * 2
        let cardWidth = max(1, (contentWidth - 12) / 2)
        let boardSide = min(720, min(contentWidth, max(300, size.height - 278)))
        let actionButtonWidth = min(190, max(150, contentWidth * 0.24))

        return VStack(spacing: 8) {
            pageHeader

            HStack(alignment: .top, spacing: 12) {
                statusCard
                    .frame(width: cardWidth, alignment: .top)
                controlsCard
                    .frame(width: cardWidth, alignment: .top)
            }

            chessBoard(side: boardSide)

            HStack(alignment: .center, spacing: 12) {
                rulesCard
                undoButton
                    .frame(width: actionButtonWidth)
                restartButton
                    .frame(width: actionButtonWidth)
            }
        }
        .frame(maxWidth: 820)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, 12)
    }

    private func verticalLayout(size: CGSize) -> some View {
        let boardSide = min(720, min(size.width - 36, max(300, size.height - 255)))

        return ScrollView {
            VStack(spacing: 14) {
                pageHeader
                statusCard
                chessBoard(side: boardSide)
                controlsCard
                rulesCard
                HStack(spacing: 12) {
                    undoButton
                    restartButton
                }
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
                    .fill(ChessPalette.boardFrame)
                    .frame(width: 54, height: 54)
                Text("♔")
                    .font(.system(size: 34, design: .serif))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("国际象棋")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("人机对战 · \(difficulty.title)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
            }

            Spacer(minLength: 0)

            HStack(spacing: 7) {
                Image(systemName: "number.circle.fill")
                Text("第 \((game.moveCount + 1) / 2) 回合")
            }
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(ChessPalette.boardFrame)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(ChessPalette.gold.opacity(0.22))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            ZStack(alignment: .leading) {
                if !game.status.isFinished, game.isInCheck(for: game.turn) {
                    Label("\(game.turn.title)正在被将军", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(ChessPalette.check)
                } else if game.status == .playerTurn, let lastPlayerMove = game.lastPlayerMove {
                    Text(lastPlayerMoveSummary(lastPlayerMove))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 20)

            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor)

                Text("吃子分值")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)

                Spacer(minLength: 4)

                Text("你 \(game.playerCaptureScore) : \(game.botCaptureScore) 电脑")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 20)
        }
        .padding(16)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: ChessPalette.boardFrame.opacity(0.10), radius: 12, y: 6)
        .animation(.easeInOut(duration: 0.45), value: game.status)
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(selectedSquare == nil ? "选择棋子" : "选择目标格", systemImage: selectedSquare == nil ? "hand.tap.fill" : "scope")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)

                Spacer(minLength: 0)

                if let lastMove = game.lastMove {
                    Text("上一步 \(lastMove.notation)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Group {
                if gameplayMessages.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        if let selectedSquare {
                            Text("已选中 \(selectedSquare.notation)，点击高亮格完成移动")
                                .foregroundStyle(SaoleiPalette.mutedInk)
                        } else if !hasShownInitialInstruction {
                            Text("点击白色棋子，棋盘会标出所有合法走法")
                                .foregroundStyle(SaoleiPalette.mutedInk)
                        } else {
                            Text("")
                                .foregroundStyle(SaoleiPalette.mutedInk)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(gameplayMessages) { message in
                                    Text(message.text)
                                        .foregroundStyle(message.isCheck ? ChessPalette.check : SaoleiPalette.mutedInk)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.70)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .frame(height: 18, alignment: .leading)
                                        .id(message.id)
                                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(height: 38)
                        .onChange(of: gameplayMessages.last?.id) { _ in
                            guard let lastMessageID = gameplayMessages.last?.id else { return }
                            withAnimation(.easeInOut(duration: 1.0)) {
                                proxy.scrollTo(lastMessageID, anchor: .bottom)
                            }
                        }
                    }
                }
            }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 38, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var rulesCard: some View {
        Text("白方先行。支持将军、将死、王车易位、吃过路兵和兵升变。")
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(SaoleiPalette.mutedInk)
            .lineLimit(1)
            .minimumScaleFactor(0.70)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 13)
            .background(ChessPalette.gold.opacity(0.12))
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
        .foregroundStyle(ChessPalette.boardFrame)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: ChessPalette.boardFrame.opacity(0.10), radius: 8, y: 4)
        .accessibilityIdentifier("chessRestartButton")
    }

    private var undoButton: some View {
        Button {
            undoGame()
        } label: {
            Label("返回前一步", systemImage: "arrow.uturn.backward")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .foregroundStyle(ChessPalette.boardFrame)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .shadow(color: ChessPalette.boardFrame.opacity(0.10), radius: 8, y: 4)
        .opacity(game.canUndo ? 1 : 0.45)
        .disabled(!game.canUndo)
        .accessibilityIdentifier("chessUndoButton")
    }

    private func chessBoard(side: CGFloat) -> some View {
        let boardGridSide = max(1, side - 16)
        let cellSide = boardGridSide / 8
        let legalTargets = Set(selectedSquare.map { game.legalMoves(from: $0).map(\.to) } ?? [])

        return ZStack {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(cellSide), spacing: 0), count: 8),
                spacing: 0
            ) {
                ForEach(0..<64, id: \.self) { index in
                    let square = ChessSquare(row: index / 8, column: index % 8)
                    ChessSquareButton(
                        square: square,
                        piece: game.board[square],
                        side: cellSide,
                        isSelected: selectedSquare == square,
                        isLegalTarget: legalTargets.contains(square),
                        isLastMoveSquare: game.lastMove?.from == square || game.lastMove?.to == square,
                        isCheckSquare: isCheckSquare(square),
                        action: { tapSquare(square) }
                    )
                }
            }
            .frame(width: boardGridSide, height: boardGridSide)

            if let highlightedBotMove {
                ChessMoveArrow(
                    move: highlightedBotMove,
                    cellSide: cellSide,
                    isKnightMove: game.board[highlightedBotMove.to]?.type == .knight
                )
                    .frame(width: boardGridSide, height: boardGridSide)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            if let capturedPieceMarker {
                ChessCapturedPieceMarkerView(
                    piece: capturedPieceMarker.piece,
                    square: capturedPieceMarker.square,
                    cellSide: cellSide
                )
                .frame(width: boardGridSide, height: boardGridSide)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
            }
        }
        .frame(width: boardGridSide, height: boardGridSide)
        .padding(8)
        .background(ChessPalette.boardFrame)
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ChessPalette.boardFrame.opacity(0.27), radius: 16, y: 9)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("国际象棋棋盘")
    }

    private func isCheckSquare(_ square: ChessSquare) -> Bool {
        guard let piece = game.board[square], piece.type == .king else { return false }
        return game.isInCheck(for: piece.color)
    }

    private func lastPlayerMoveSummary(_ move: ChessMove) -> String {
        guard let capturedPiece = game.lastPlayerCapturedPiece else {
            return "上一步你走了 \(move.notation)"
        }
        return "上一步你走了 \(move.notation) · 吃掉了\(capturedPiece.color.title)\(capturedPiece.type.title)"
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
        case .playerTurn: return accentColor
        case .botThinking: return ChessPalette.gold
        case .playerWon: return SaoleiPalette.mint
        case .botWon: return ChessPalette.check
        case .draw: return SaoleiPalette.mutedInk
        }
    }

    private func tapSquare(_ square: ChessSquare) {
        guard game.status == .playerTurn else { return }
        hasShownInitialInstruction = true

        if let selectedSquare {
            let choices = game.legalMoves(from: selectedSquare).filter { $0.to == square }
            if choices.count == 1, let move = choices.first {
                play(move)
            } else if choices.count > 1 {
                pendingPromotionMoves = choices
                showingPromotionChoice = true
            } else if game.board[square]?.color == .white {
                self.selectedSquare = square
                fireImpact()
            } else {
                self.selectedSquare = nil
                fireImpact()
            }
        } else if game.board[square]?.color == .white {
            selectedSquare = square
            fireImpact()
        }
    }

    private func play(_ move: ChessMove) {
        highlightedBotMove = nil
        capturedPieceMarker = nil
        selectedSquare = nil
        pendingPromotionMoves = []
        showingPromotionChoice = false

        guard game.playPlayerMove(move) else { return }
        capturedPieceMarker = makeCapturedPieceMarker(for: move, capturedPiece: game.lastCapturedPiece)
        showMoveMessage(mover: "你")
        fireImpact()

        if game.status == .botThinking {
            scheduleBotMove()
        } else if game.status.isFinished {
            fireNotification(for: game.status)
        }
    }

    private func scheduleBotMove() {
        let turnID = botTurnID

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 420_000_000)
            guard !Task.isCancelled, turnID == botTurnID, game.status == .botThinking else { return }

            if game.playBotMove() {
                highlightedBotMove = game.lastMove
                if let botMove = game.lastMove {
                    if let marker = makeCapturedPieceMarker(for: botMove, capturedPiece: game.lastCapturedPiece) {
                        capturedPieceMarker = marker
                    }
                }
                showMoveMessage(mover: "电脑")
                if game.status.isFinished {
                    fireNotification(for: game.status)
                } else {
                    fireImpact()
                }
            }
        }
    }

    private func makeCapturedPieceMarker(
        for move: ChessMove,
        capturedPiece: ChessPiece?
    ) -> ChessCapturedPieceMarker? {
        guard let capturedPiece else { return nil }
        let capturedSquare = move.isEnPassant
            ? ChessSquare(row: move.from.row, column: move.to.column)
            : move.to
        return ChessCapturedPieceMarker(piece: capturedPiece, square: capturedSquare)
    }

    private func restartGame() {
        botTurnID = UUID()
        highlightedBotMove = nil
        capturedPieceMarker = nil
        selectedSquare = nil
        pendingPromotionMoves = []
        showingPromotionChoice = false
        clearGameplayMessage()
        game.reset()
        fireImpact()
    }

    private func undoGame() {
        botTurnID = UUID()
        highlightedBotMove = nil
        capturedPieceMarker = nil
        selectedSquare = nil
        pendingPromotionMoves = []
        showingPromotionChoice = false

        guard game.undoToPlayerTurn() else { return }
        clearGameplayMessage()
        fireImpact()
    }

    private func showMoveMessage(mover: String) {
        let opponent: ChessColor = mover == "你" ? .black : .white
        let checkMessage = game.isInCheck(for: opponent)
            ? (mover == "你" ? "将军！你将军了黑方王" : "电脑将军了！你的王正在被攻击")
            : nil
        let captureMessage = game.lastCapturedPiece.map {
            "\(mover)吃掉了\($0.color.title)\($0.type.title)"
        }

        let moveSummary = "\(mover)走了 \(game.lastMove?.notation ?? "")"
        let details = [captureMessage, checkMessage].compactMap { $0 }
        showGameplayMessage(
            details.isEmpty ? moveSummary : "\(moveSummary) · \(details.joined(separator: " · "))",
            isCheck: checkMessage != nil
        )
    }

    private func showGameplayMessage(_ message: String, isCheck: Bool) {
        var updatedMessages = gameplayMessages
        updatedMessages.append(ChessGameplayMessage(text: message, isCheck: isCheck))
        if updatedMessages.count > 8 {
            updatedMessages.removeFirst(updatedMessages.count - 8)
        }
        withAnimation(.easeOut(duration: 0.55)) {
            gameplayMessages = updatedMessages
        }
    }

    private func clearGameplayMessage() {
        gameplayMessages = []
    }

    private func fireImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fireNotification(for status: ChessGameStatus) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(status == .playerWon ? .success : .error)
    }
}

private struct ChessGameplayMessage: Identifiable {
    let id = UUID()
    let text: String
    let isCheck: Bool
}

private struct ChessCapturedPieceMarker: Equatable {
    let piece: ChessPiece
    let square: ChessSquare
}

private struct ChessCapturedPieceMarkerView: View {
    let piece: ChessPiece
    let square: ChessSquare
    let cellSide: CGFloat

    private var markerSymbol: String {
        switch piece.type {
        case .pawn: return "♙"
        case .knight: return "♘"
        case .bishop: return "♗"
        case .rook: return "♖"
        case .queen: return "♕"
        case .king: return "♔"
        }
    }

    private var markerColor: Color {
        piece.color == .white ? .white : ChessPalette.blackPiece
    }

    var body: some View {
        Text(markerSymbol)
            .font(.system(size: cellSide * 0.40, weight: .regular, design: .serif))
            .foregroundStyle(markerColor)
            .shadow(
                color: piece.color == .white
                    ? .black.opacity(0.40)
                    : ChessPalette.lightSquare.opacity(0.62),
                radius: 1,
                y: 1
            )
            .position(
                x: CGFloat(square.column) * cellSide + cellSide * 0.80,
                y: CGFloat(square.row) * cellSide + cellSide * 0.20
            )
            .accessibilityLabel("被吃掉的\(piece.color.title)\(piece.type.title)")
    }
}

private struct ChessMoveArrow: View {
    let move: ChessMove
    let cellSide: CGFloat
    let isKnightMove: Bool

    var body: some View {
        let start = center(of: move.from)
        let destination = center(of: move.to)
        let direction = CGVector(dx: destination.x - start.x, dy: destination.y - start.y)
        let distance = max(1, hypot(direction.dx, direction.dy))
        let unit = CGVector(dx: direction.dx / distance, dy: direction.dy / distance)
        let lineStart = isKnightMove
            ? knightLineStart(from: start)
            : offset(start, by: unit, distance: cellSide * 0.36)
        let lineEnd = isKnightMove
            ? knightLineEnd(from: destination)
            : offset(destination, by: unit, distance: -cellSide * 0.36)
        let control1 = isKnightMove ? knightControl1(from: lineStart) : lineStart
        let control2 = isKnightMove ? knightControl2(to: lineEnd) : lineEnd
        let arrowUnit = isKnightMove
            ? normalized(CGVector(dx: lineEnd.x - control2.x, dy: lineEnd.y - control2.y))
            : unit
        let arrowSize = max(7, cellSide * 0.13)
        let perpendicular = CGVector(dx: -arrowUnit.dy, dy: arrowUnit.dx)
        let arrowBase = offset(lineEnd, by: arrowUnit, distance: -arrowSize)
        let arrowLeft = offset(arrowBase, by: perpendicular, distance: arrowSize * 0.52)
        let arrowRight = offset(arrowBase, by: perpendicular, distance: -arrowSize * 0.52)

        Path { path in
            path.move(to: lineStart)
            if isKnightMove {
                path.addCurve(to: lineEnd, control1: control1, control2: control2)
            } else {
                path.addLine(to: lineEnd)
            }
        }
        .stroke(
            SaoleiPalette.mint,
            style: StrokeStyle(
                lineWidth: max(2, cellSide * 0.035),
                lineCap: .round,
                lineJoin: .round,
                dash: [cellSide * 0.16, cellSide * 0.13]
            )
        )
        .overlay {
            Path { path in
                path.move(to: arrowLeft)
                path.addLine(to: lineEnd)
                path.addLine(to: arrowRight)
            }
            .stroke(
                SaoleiPalette.mint,
                style: StrokeStyle(
                    lineWidth: max(2, cellSide * 0.035),
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        }
        .shadow(color: SaoleiPalette.mint.opacity(0.45), radius: 2)
    }

    private func knightLineStart(from point: CGPoint) -> CGPoint {
        offset(point, by: knightLongUnit, distance: cellSide * 0.36)
    }

    private func knightLineEnd(from point: CGPoint) -> CGPoint {
        offset(point, by: knightShortUnit, distance: -cellSide * 0.36)
    }

    private func knightControl1(from point: CGPoint) -> CGPoint {
        offset(point, by: knightLongUnit, distance: cellSide * 0.80)
    }

    private func knightControl2(to point: CGPoint) -> CGPoint {
        offset(point, by: knightShortUnit, distance: -cellSide * 0.40)
    }

    private var knightLongUnit: CGVector {
        let columnDelta = move.to.column - move.from.column
        let rowDelta = move.to.row - move.from.row
        if abs(columnDelta) > abs(rowDelta) {
            return CGVector(dx: CGFloat(columnDelta.signum()), dy: 0)
        }
        return CGVector(dx: 0, dy: CGFloat(rowDelta.signum()))
    }

    private var knightShortUnit: CGVector {
        let columnDelta = move.to.column - move.from.column
        let rowDelta = move.to.row - move.from.row
        if abs(columnDelta) > abs(rowDelta) {
            return CGVector(dx: 0, dy: CGFloat(rowDelta.signum()))
        }
        return CGVector(dx: CGFloat(columnDelta.signum()), dy: 0)
    }

    private func normalized(_ vector: CGVector) -> CGVector {
        let length = max(1, hypot(vector.dx, vector.dy))
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }

    private func center(of square: ChessSquare) -> CGPoint {
        CGPoint(
            x: CGFloat(square.column) * cellSide + cellSide / 2,
            y: CGFloat(square.row) * cellSide + cellSide / 2
        )
    }

    private func offset(_ point: CGPoint, by vector: CGVector, distance: CGFloat) -> CGPoint {
        CGPoint(
            x: point.x + vector.dx * distance,
            y: point.y + vector.dy * distance
        )
    }
}

private struct ChessSquareButton: View {
    let square: ChessSquare
    let piece: ChessPiece?
    let side: CGFloat
    let isSelected: Bool
    let isLegalTarget: Bool
    let isLastMoveSquare: Bool
    let isCheckSquare: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(squareColor)

                if isLastMoveSquare {
                    Rectangle()
                        .fill(ChessPalette.gold.opacity(0.30))
                }

                if isCheckSquare {
                    Rectangle()
                        .fill(ChessPalette.check.opacity(0.72))
                }

                if isSelected {
                    Rectangle()
                        .stroke(SaoleiPalette.mint, lineWidth: max(3, side * 0.055))
                }

                if isLegalTarget {
                    if piece == nil {
                        Circle()
                            .fill(SaoleiPalette.mint.opacity(0.86))
                            .frame(width: side * 0.22, height: side * 0.22)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Rectangle()
                            .stroke(SaoleiPalette.mint, lineWidth: max(3, side * 0.07))
                            .padding(side * 0.09)
                    }
                }

                if let piece {
                    Text(piece.symbol)
                        .font(.system(size: side * (piece.color == .white ? 0.79 : 0.72), weight: .regular, design: .serif))
                        .foregroundStyle(piece.color == .white ? .white : ChessPalette.blackPiece)
                        .shadow(
                            color: piece.color == .white
                                ? .black.opacity(0.34)
                                : ChessPalette.lightSquare.opacity(0.58),
                            radius: piece.color == .white ? 2 : 1,
                            y: 2
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if square.column == 0 {
                    Text("\(8 - square.row)")
                        .font(.system(size: max(9, side * 0.14), weight: .bold, design: .rounded))
                        .foregroundStyle(labelColor)
                        .padding(3)
                }

                if square.row == 7 {
                    Text(fileName)
                        .font(.system(size: max(9, side * 0.14), weight: .bold, design: .rounded))
                        .foregroundStyle(labelColor)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .padding(3)
                }
            }
            .frame(width: side, height: side)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLegalTarget ? "合法走法" : "")
    }

    private var squareColor: Color {
        (square.row + square.column).isMultiple(of: 2) ? ChessPalette.lightSquare : ChessPalette.darkSquare
    }

    private var labelColor: Color {
        (square.row + square.column).isMultiple(of: 2) ? ChessPalette.darkSquare.opacity(0.78) : ChessPalette.lightSquare.opacity(0.85)
    }

    private var fileName: String {
        ["a", "b", "c", "d", "e", "f", "g", "h"][square.column]
    }

    private var accessibilityLabel: String {
        if let piece {
            return "\(square.notation)，\(piece.color.title)\(piece.type.title)"
        }
        return "\(square.notation)，空格"
    }
}

#Preview("国际象棋") {
    NavigationStack {
        ChessView(difficulty: .beginner)
    }
}
