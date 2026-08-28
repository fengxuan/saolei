import Foundation

enum ChessColor: String, CaseIterable, Hashable {
    case white
    case black

    var opposite: ChessColor {
        self == .white ? .black : .white
    }

    var title: String {
        self == .white ? "白方" : "黑方"
    }
}

enum ChessPieceType: String, CaseIterable, Hashable {
    case pawn
    case knight
    case bishop
    case rook
    case queen
    case king

    var title: String {
        switch self {
        case .pawn: return "兵"
        case .knight: return "马"
        case .bishop: return "象"
        case .rook: return "车"
        case .queen: return "后"
        case .king: return "王"
        }
    }

    var value: Int {
        switch self {
        case .pawn: return 100
        case .knight: return 320
        case .bishop: return 330
        case .rook: return 500
        case .queen: return 900
        case .king: return 20_000
        }
    }
}

struct ChessSquare: Hashable {
    let row: Int
    let column: Int

    var notation: String {
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        guard files.indices.contains(column) else { return "?" }
        return "\(files[column])\(8 - row)"
    }
}

struct ChessPiece: Hashable {
    let type: ChessPieceType
    let color: ChessColor

    var symbol: String {
        switch (color, type) {
        case (.white, .pawn): return "♙"
        case (.white, .knight): return "♘"
        case (.white, .bishop): return "♗"
        case (.white, .rook): return "♖"
        case (.white, .queen): return "♕"
        case (.white, .king): return "♔"
        case (.black, .pawn): return "♟"
        case (.black, .knight): return "♞"
        case (.black, .bishop): return "♝"
        case (.black, .rook): return "♜"
        case (.black, .queen): return "♛"
        case (.black, .king): return "♚"
        }
    }
}

struct ChessMove: Hashable {
    let from: ChessSquare
    let to: ChessSquare
    let promotion: ChessPieceType?
    let isEnPassant: Bool
    let isCastle: Bool

    init(
        from: ChessSquare,
        to: ChessSquare,
        promotion: ChessPieceType? = nil,
        isEnPassant: Bool = false,
        isCastle: Bool = false
    ) {
        self.from = from
        self.to = to
        self.promotion = promotion
        self.isEnPassant = isEnPassant
        self.isCastle = isCastle
    }

    var notation: String {
        "\(from.notation)-\(to.notation)"
    }
}

enum ChessDifficulty: String, CaseIterable, Identifiable, Equatable {
    case beginner
    case tactician
    case master

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return "入门练习"
        case .tactician: return "战术对手"
        case .master: return "大师挑战"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return "随机走子，适合熟悉棋子规则"
        case .tactician: return "提前计算几步，开始寻找战术"
        case .master: return "更深搜索，主动争夺中心和子力"
        }
    }

    var searchDepth: Int {
        switch self {
        case .beginner: return 1
        case .tactician: return 2
        case .master: return 3
        }
    }

    var accent: GameAccent {
        switch self {
        case .beginner: return .mint
        case .tactician: return .sky
        case .master: return .purple
        }
    }
}

enum ChessGameStatus: Equatable {
    case playerTurn
    case botThinking
    case playerWon
    case botWon
    case draw

    var title: String {
        switch self {
        case .playerTurn: return "轮到你了"
        case .botThinking: return "电脑思考中"
        case .playerWon: return "恭喜，你赢了！"
        case .botWon: return "电脑获胜"
        case .draw: return "和棋"
        }
    }

    var detail: String {
        switch self {
        case .playerTurn: return "你执白棋，请选择要移动的棋子"
        case .botThinking: return "黑方正在寻找下一步"
        case .playerWon: return "将死！白方完成了漂亮的进攻"
        case .botWon: return "将死！再来一局继续练习吧"
        case .draw: return "无合法走法或双方已足够久没有推进兵"
        }
    }

    var symbol: String {
        switch self {
        case .playerTurn: return "hand.tap.fill"
        case .botThinking: return "brain.head.profile"
        case .playerWon: return "crown.fill"
        case .botWon: return "flag.fill"
        case .draw: return "equal.circle.fill"
        }
    }

    var isFinished: Bool {
        switch self {
        case .playerTurn, .botThinking: return false
        case .playerWon, .botWon, .draw: return true
        }
    }
}

struct ChessGame {
    private struct CastlingRights {
        var whiteKingSide = true
        var whiteQueenSide = true
        var blackKingSide = true
        var blackQueenSide = true
    }

    private struct Snapshot {
        let board: [ChessSquare: ChessPiece]
        let turn: ChessColor
        let status: ChessGameStatus
        let lastMove: ChessMove?
        let moveCount: Int
        let castlingRights: CastlingRights
        let enPassantTarget: ChessSquare?
        let halfmoveClock: Int
        let lastCapturedPiece: ChessPiece?
    }

    private(set) var difficulty: ChessDifficulty
    private(set) var board: [ChessSquare: ChessPiece] = [:]
    private(set) var turn: ChessColor = .white
    private(set) var status: ChessGameStatus = .playerTurn
    private(set) var lastMove: ChessMove?
    private(set) var moveCount = 0
    private(set) var lastCapturedPiece: ChessPiece?

    private var castlingRights = CastlingRights()
    private var enPassantTarget: ChessSquare?
    private var halfmoveClock = 0
    private var history: [Snapshot] = []

    var canUndo: Bool {
        !history.isEmpty
    }

    init(difficulty: ChessDifficulty = .beginner) {
        self.difficulty = difficulty
        reset()
    }

    mutating func reset() {
        board = [:]
        turn = .white
        status = .playerTurn
        lastMove = nil
        moveCount = 0
        lastCapturedPiece = nil
        castlingRights = CastlingRights()
        enPassantTarget = nil
        halfmoveClock = 0
        history = []

        let backRank: [ChessPieceType] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for column in 0..<8 {
            board[ChessSquare(row: 0, column: column)] = ChessPiece(type: backRank[column], color: .black)
            board[ChessSquare(row: 1, column: column)] = ChessPiece(type: .pawn, color: .black)
            board[ChessSquare(row: 6, column: column)] = ChessPiece(type: .pawn, color: .white)
            board[ChessSquare(row: 7, column: column)] = ChessPiece(type: backRank[column], color: .white)
        }
    }

    mutating func changeDifficulty(to newDifficulty: ChessDifficulty) {
        guard difficulty != newDifficulty else { return }
        difficulty = newDifficulty
        reset()
    }

    func legalMoves(from square: ChessSquare) -> [ChessMove] {
        guard let piece = board[square], piece.color == .white, status == .playerTurn else { return [] }
        return legalMoves(for: piece.color).filter { $0.from == square }
    }

    func legalMoves(for color: ChessColor) -> [ChessMove] {
        pseudoLegalMoves(for: color).filter { move in
            var candidate = self
            candidate.apply(move)
            return !candidate.isInCheck(for: color)
        }
    }

    func isInCheck(for color: ChessColor) -> Bool {
        guard let kingSquare = board.first(where: { $0.value == ChessPiece(type: .king, color: color) })?.key else {
            return true
        }
        return isSquareAttacked(kingSquare, by: color.opposite)
    }

    func capturedPiece(for move: ChessMove) -> ChessPiece? {
        if let piece = board[move.to] {
            return piece
        }

        guard move.isEnPassant else { return nil }
        return board[ChessSquare(row: move.from.row, column: move.to.column)]
    }

    mutating func playPlayerMove(_ move: ChessMove) -> Bool {
        guard status == .playerTurn, legalMoves(for: .white).contains(move) else { return false }
        history.append(snapshot())
        lastCapturedPiece = capturedPiece(for: move)
        apply(move)
        lastMove = move
        moveCount += 1
        finishTurn(after: .white)
        return true
    }

    mutating func playBotMove() -> Bool {
        guard status == .botThinking, let move = bestBotMove() else { return false }
        history.append(snapshot())
        lastCapturedPiece = capturedPiece(for: move)
        apply(move)
        lastMove = move
        moveCount += 1
        finishTurn(after: .black)
        return true
    }

    mutating func undoToPlayerTurn() -> Bool {
        guard !history.isEmpty else { return false }

        repeat {
            guard let previous = history.popLast() else { return false }
            restore(previous)
        } while status != .playerTurn && !history.isEmpty

        return status == .playerTurn
    }

    func bestBotMove() -> ChessMove? {
        let moves = orderedMoves(legalMoves(for: .black))
        guard !moves.isEmpty else { return nil }

        if difficulty == .beginner {
            let captures = moves.filter(isCapture)
            if !captures.isEmpty, Bool.random() {
                return captures.randomElement()
            }
            return moves.randomElement()
        }

        var bestMove = moves[0]
        var bestScore = Int.min / 2
        let depth = difficulty.searchDepth

        for move in moves {
            var next = self
            next.apply(move)
            let score = minimax(
                position: next,
                sideToMove: .white,
                depth: depth - 1,
                alpha: Int.min / 2,
                beta: Int.max / 2
            )
            if score > bestScore || (score == bestScore && Bool.random()) {
                bestScore = score
                bestMove = move
            }
        }

        return bestMove
    }

    private mutating func finishTurn(after movingColor: ChessColor) {
        turn = movingColor.opposite

        if halfmoveClock >= 100 {
            status = .draw
            return
        }

        let nextMoves = legalMoves(for: turn)
        if nextMoves.isEmpty {
            if isInCheck(for: turn) {
                status = movingColor == .white ? .playerWon : .botWon
            } else {
                status = .draw
            }
        } else {
            status = turn == .white ? .playerTurn : .botThinking
        }
    }

    private func pseudoLegalMoves(for color: ChessColor) -> [ChessMove] {
        var moves: [ChessMove] = []

        for square in board.keys.sorted(by: squareSort) {
            guard let piece = board[square], piece.color == color else { continue }

            switch piece.type {
            case .pawn:
                addPawnMoves(from: square, color: color, to: &moves)
            case .knight:
                addJumpMoves(from: square, color: color, offsets: knightOffsets, to: &moves)
            case .bishop:
                addSlidingMoves(from: square, color: color, directions: diagonalDirections, to: &moves)
            case .rook:
                addSlidingMoves(from: square, color: color, directions: straightDirections, to: &moves)
            case .queen:
                addSlidingMoves(from: square, color: color, directions: allDirections, to: &moves)
            case .king:
                addJumpMoves(from: square, color: color, offsets: allDirections, to: &moves)
                addCastlingMoves(from: square, color: color, to: &moves)
            }
        }

        return moves
    }

    private func addPawnMoves(from square: ChessSquare, color: ChessColor, to moves: inout [ChessMove]) {
        let direction = color == .white ? -1 : 1
        let startRow = color == .white ? 6 : 1
        let promotionRow = color == .white ? 0 : 7
        let oneStep = ChessSquare(row: square.row + direction, column: square.column)

        guard isOnBoard(oneStep), board[oneStep] == nil else {
            addPawnCaptures(from: square, color: color, direction: direction, promotionRow: promotionRow, to: &moves)
            return
        }

        addPawnMove(from: square, to: oneStep, promotionRow: promotionRow, to: &moves)

        let twoStep = ChessSquare(row: square.row + direction * 2, column: square.column)
        if square.row == startRow, board[twoStep] == nil {
            moves.append(ChessMove(from: square, to: twoStep))
        }

        addPawnCaptures(from: square, color: color, direction: direction, promotionRow: promotionRow, to: &moves)
    }

    private func addPawnCaptures(
        from square: ChessSquare,
        color: ChessColor,
        direction: Int,
        promotionRow: Int,
        to moves: inout [ChessMove]
    ) {
        for columnOffset in [-1, 1] {
            let target = ChessSquare(row: square.row + direction, column: square.column + columnOffset)
            guard isOnBoard(target) else { continue }

            if let targetPiece = board[target], targetPiece.color != color, targetPiece.type != .king {
                addPawnMove(from: square, to: target, promotionRow: promotionRow, to: &moves)
            } else if board[target] == nil, target == enPassantTarget {
                moves.append(ChessMove(from: square, to: target, isEnPassant: true))
            }
        }
    }

    private func addPawnMove(from: ChessSquare, to: ChessSquare, promotionRow: Int, to moves: inout [ChessMove]) {
        guard to.row == promotionRow else {
            moves.append(ChessMove(from: from, to: to))
            return
        }

        for promotion in [ChessPieceType.queen, .rook, .bishop, .knight] {
            moves.append(ChessMove(from: from, to: to, promotion: promotion))
        }
    }

    private func addJumpMoves(
        from square: ChessSquare,
        color: ChessColor,
        offsets: [(Int, Int)],
        to moves: inout [ChessMove]
    ) {
        for (rowOffset, columnOffset) in offsets {
            let target = ChessSquare(row: square.row + rowOffset, column: square.column + columnOffset)
            guard isOnBoard(target), board[target]?.color != color, board[target]?.type != .king else { continue }
            moves.append(ChessMove(from: square, to: target))
        }
    }

    private func addSlidingMoves(
        from square: ChessSquare,
        color: ChessColor,
        directions: [(Int, Int)],
        to moves: inout [ChessMove]
    ) {
        for (rowOffset, columnOffset) in directions {
            var row = square.row + rowOffset
            var column = square.column + columnOffset

            while isOnBoard(row: row, column: column) {
                let target = ChessSquare(row: row, column: column)
                if let targetPiece = board[target] {
                    if targetPiece.color != color, targetPiece.type != .king {
                        moves.append(ChessMove(from: square, to: target))
                    }
                    break
                }

                moves.append(ChessMove(from: square, to: target))
                row += rowOffset
                column += columnOffset
            }
        }
    }

    private func addCastlingMoves(from square: ChessSquare, color: ChessColor, to moves: inout [ChessMove]) {
        guard !isInCheck(for: color), square == ChessSquare(row: color == .white ? 7 : 0, column: 4) else { return }
        let row = square.row

        if canCastle(color: color, kingSide: true, row: row) {
            moves.append(ChessMove(from: square, to: ChessSquare(row: row, column: 6), isCastle: true))
        }
        if canCastle(color: color, kingSide: false, row: row) {
            moves.append(ChessMove(from: square, to: ChessSquare(row: row, column: 2), isCastle: true))
        }
    }

    private func canCastle(color: ChessColor, kingSide: Bool, row: Int) -> Bool {
        let allowed = color == .white
            ? (kingSide ? castlingRights.whiteKingSide : castlingRights.whiteQueenSide)
            : (kingSide ? castlingRights.blackKingSide : castlingRights.blackQueenSide)
        guard allowed else { return false }

        let rookColumn = kingSide ? 7 : 0
        let betweenColumns = kingSide ? [5, 6] : [1, 2, 3]
        guard board[ChessSquare(row: row, column: rookColumn)] == ChessPiece(type: .rook, color: color),
              betweenColumns.allSatisfy({ board[ChessSquare(row: row, column: $0)] == nil }) else {
            return false
        }

        let passingColumn = kingSide ? 5 : 3
        let destinationColumn = kingSide ? 6 : 2
        return !isSquareAttacked(ChessSquare(row: row, column: passingColumn), by: color.opposite)
            && !isSquareAttacked(ChessSquare(row: row, column: destinationColumn), by: color.opposite)
    }

    private mutating func apply(_ move: ChessMove) {
        guard let movingPiece = board.removeValue(forKey: move.from) else { return }
        let capturedPiece = board[move.to]
        updateCastlingRights(forCapturedPiece: capturedPiece, at: move.to)

        if move.isEnPassant {
            let capturedPawnSquare = ChessSquare(row: move.from.row, column: move.to.column)
            board.removeValue(forKey: capturedPawnSquare)
        }

        switch movingPiece.type {
        case .king:
            revokeCastlingRights(for: movingPiece.color)
            if move.isCastle {
                let rookFromColumn = move.to.column > move.from.column ? 7 : 0
                let rookToColumn = move.to.column > move.from.column ? 5 : 3
                let rookFrom = ChessSquare(row: move.from.row, column: rookFromColumn)
                let rookTo = ChessSquare(row: move.from.row, column: rookToColumn)
                if let rook = board.removeValue(forKey: rookFrom) {
                    board[rookTo] = rook
                }
            }
        case .rook:
            revokeCastlingRights(for: movingPiece.color, rookStartingAt: move.from)
        default:
            break
        }

        let reachesPromotionRow = movingPiece.type == .pawn && (move.to.row == 0 || move.to.row == 7)
        let resultingType = reachesPromotionRow ? (move.promotion ?? .queen) : movingPiece.type
        board[move.to] = ChessPiece(type: resultingType, color: movingPiece.color)

        if movingPiece.type == .pawn, abs(move.to.row - move.from.row) == 2 {
            enPassantTarget = ChessSquare(row: (move.to.row + move.from.row) / 2, column: move.from.column)
        } else {
            enPassantTarget = nil
        }

        if movingPiece.type == .pawn || capturedPiece != nil || move.isEnPassant {
            halfmoveClock = 0
        } else {
            halfmoveClock += 1
        }
    }

    private func snapshot() -> Snapshot {
        Snapshot(
            board: board,
            turn: turn,
            status: status,
            lastMove: lastMove,
            moveCount: moveCount,
            castlingRights: castlingRights,
            enPassantTarget: enPassantTarget,
            halfmoveClock: halfmoveClock,
            lastCapturedPiece: lastCapturedPiece
        )
    }

    private mutating func restore(_ snapshot: Snapshot) {
        board = snapshot.board
        turn = snapshot.turn
        status = snapshot.status
        lastMove = snapshot.lastMove
        moveCount = snapshot.moveCount
        castlingRights = snapshot.castlingRights
        enPassantTarget = snapshot.enPassantTarget
        halfmoveClock = snapshot.halfmoveClock
        lastCapturedPiece = snapshot.lastCapturedPiece
    }

    private func isSquareAttacked(_ target: ChessSquare, by attacker: ChessColor) -> Bool {
        let pawnSourceRow = target.row - (attacker == .white ? -1 : 1)
        for sourceColumn in [target.column - 1, target.column + 1] {
            let source = ChessSquare(row: pawnSourceRow, column: sourceColumn)
            if board[source] == ChessPiece(type: .pawn, color: attacker) {
                return true
            }
        }

        for (rowOffset, columnOffset) in knightOffsets {
            let source = ChessSquare(row: target.row + rowOffset, column: target.column + columnOffset)
            if board[source] == ChessPiece(type: .knight, color: attacker) {
                return true
            }
        }

        for (rowOffset, columnOffset) in allDirections {
            let source = ChessSquare(row: target.row + rowOffset, column: target.column + columnOffset)
            if board[source] == ChessPiece(type: .king, color: attacker) {
                return true
            }
        }

        for (rowOffset, columnOffset) in diagonalDirections {
            if rayContainsAttacker(from: target, rowOffset: rowOffset, columnOffset: columnOffset, attacker: attacker, types: [.bishop, .queen]) {
                return true
            }
        }

        for (rowOffset, columnOffset) in straightDirections {
            if rayContainsAttacker(from: target, rowOffset: rowOffset, columnOffset: columnOffset, attacker: attacker, types: [.rook, .queen]) {
                return true
            }
        }

        return false
    }

    private func rayContainsAttacker(
        from square: ChessSquare,
        rowOffset: Int,
        columnOffset: Int,
        attacker: ChessColor,
        types: Set<ChessPieceType>
    ) -> Bool {
        var row = square.row + rowOffset
        var column = square.column + columnOffset

        while isOnBoard(row: row, column: column) {
            if let piece = board[ChessSquare(row: row, column: column)] {
                return piece.color == attacker && types.contains(piece.type)
            }
            row += rowOffset
            column += columnOffset
        }

        return false
    }

    private mutating func updateCastlingRights(forCapturedPiece piece: ChessPiece?, at square: ChessSquare) {
        guard piece?.type == .rook, let color = piece?.color else { return }
        revokeCastlingRights(for: color, rookStartingAt: square)
    }

    private mutating func revokeCastlingRights(for color: ChessColor, rookStartingAt square: ChessSquare? = nil) {
        switch color {
        case .white:
            if square == nil {
                castlingRights.whiteKingSide = false
                castlingRights.whiteQueenSide = false
            } else if square == ChessSquare(row: 7, column: 0) {
                castlingRights.whiteQueenSide = false
            } else if square == ChessSquare(row: 7, column: 7) {
                castlingRights.whiteKingSide = false
            }
        case .black:
            if square == nil {
                castlingRights.blackKingSide = false
                castlingRights.blackQueenSide = false
            } else if square == ChessSquare(row: 0, column: 0) {
                castlingRights.blackQueenSide = false
            } else if square == ChessSquare(row: 0, column: 7) {
                castlingRights.blackKingSide = false
            }
        }
    }

    private func orderedMoves(_ moves: [ChessMove]) -> [ChessMove] {
        moves.sorted { lhs, rhs in
            moveOrderingScore(lhs) > moveOrderingScore(rhs)
        }
    }

    private func moveOrderingScore(_ move: ChessMove) -> Int {
        let capturedValue = board[move.to]?.type.value ?? (move.isEnPassant ? ChessPieceType.pawn.value : 0)
        let promotionValue = move.promotion?.value ?? 0
        let centerBonus = (3 - abs(3 - move.to.row)) + (3 - abs(3 - move.to.column))
        return capturedValue * 10 + promotionValue * 4 + centerBonus
    }

    private func isCapture(_ move: ChessMove) -> Bool {
        board[move.to] != nil || move.isEnPassant
    }

    private func minimax(
        position: ChessGame,
        sideToMove: ChessColor,
        depth: Int,
        alpha: Int,
        beta: Int
    ) -> Int {
        let moves = position.legalMoves(for: sideToMove)
        if moves.isEmpty {
            if position.isInCheck(for: sideToMove) {
                return sideToMove == .black ? -1_000_000 - depth : 1_000_000 + depth
            }
            return 0
        }

        guard depth > 0 else { return position.evaluationForBlack() }

        let orderedMoves = position.orderedMoves(moves)
        if sideToMove == .black {
            var best = Int.min / 2
            var currentAlpha = alpha
            for move in orderedMoves {
                var next = position
                next.apply(move)
                best = max(best, minimax(position: next, sideToMove: .white, depth: depth - 1, alpha: currentAlpha, beta: beta))
                currentAlpha = max(currentAlpha, best)
                if currentAlpha >= beta { break }
            }
            return best
        } else {
            var best = Int.max / 2
            var currentBeta = beta
            for move in orderedMoves {
                var next = position
                next.apply(move)
                best = min(best, minimax(position: next, sideToMove: .black, depth: depth - 1, alpha: alpha, beta: currentBeta))
                currentBeta = min(currentBeta, best)
                if alpha >= currentBeta { break }
            }
            return best
        }
    }

    private func evaluationForBlack() -> Int {
        var score = 0

        for (square, piece) in board {
            let material = piece.type.value
            let centerBonus = max(0, 4 - abs(3 - square.row)) + max(0, 4 - abs(3 - square.column))
            let advancement = piece.type == .pawn ? (piece.color == .black ? square.row : 7 - square.row) * 4 : 0
            let pieceScore = material + centerBonus * (piece.type == .pawn ? 2 : 1) + advancement
            score += piece.color == .black ? pieceScore : -pieceScore
        }

        if isInCheck(for: .white) { score += 35 }
        if isInCheck(for: .black) { score -= 35 }
        return score
    }

    private func isOnBoard(_ square: ChessSquare) -> Bool {
        isOnBoard(row: square.row, column: square.column)
    }

    private func isOnBoard(row: Int, column: Int) -> Bool {
        (0..<8).contains(row) && (0..<8).contains(column)
    }

    private func squareSort(_ lhs: ChessSquare, _ rhs: ChessSquare) -> Bool {
        if lhs.row != rhs.row { return lhs.row < rhs.row }
        return lhs.column < rhs.column
    }

    private let knightOffsets = [
        (-2, -1), (-2, 1), (-1, -2), (-1, 2),
        (1, -2), (1, 2), (2, -1), (2, 1)
    ]
    private let straightDirections = [(-1, 0), (1, 0), (0, -1), (0, 1)]
    private let diagonalDirections = [(-1, -1), (-1, 1), (1, -1), (1, 1)]
    private let allDirections = [
        (-1, -1), (-1, 0), (-1, 1), (0, -1),
        (0, 1), (1, -1), (1, 0), (1, 1)
    ]
}
