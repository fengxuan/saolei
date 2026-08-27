import Foundation

enum TetrisPieceKind: CaseIterable, Hashable {
    case i
    case o
    case t
    case s
    case z
    case j
    case l
}

struct TetrisCoordinate: Hashable {
    let row: Int
    let column: Int
}

struct TetrisPiece: Equatable {
    let kind: TetrisPieceKind
    var rotation: Int
    var row: Int
    var column: Int

    var blocks: [TetrisCoordinate] {
        let rotationIndex = rotation % 4

        switch kind {
        case .i:
            return rotationIndex.isMultiple(of: 2)
                ? [TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 1, column: 2), TetrisCoordinate(row: 1, column: 3)]
                : [TetrisCoordinate(row: 0, column: 2), TetrisCoordinate(row: 1, column: 2), TetrisCoordinate(row: 2, column: 2), TetrisCoordinate(row: 3, column: 2)]
        case .o:
            return [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1)]
        case .t:
            switch rotationIndex {
            case 0: return [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 1, column: 2)]
            case 1: return [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 1), TetrisCoordinate(row: 1, column: 2)]
            case 2: return [TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 1, column: 2), TetrisCoordinate(row: 2, column: 1)]
            default: return [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 1)]
            }
        case .s:
            return rotationIndex.isMultiple(of: 2)
                ? [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 0, column: 2), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1)]
                : [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 1)]
        case .z:
            return rotationIndex.isMultiple(of: 2)
                ? [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 1, column: 2)]
                : [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 0)]
        case .j:
            switch rotationIndex {
            case 0: return [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 1, column: 2)]
            case 1: return [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 0, column: 2), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 1)]
            case 2: return [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 0, column: 2), TetrisCoordinate(row: 1, column: 2)]
            default: return [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 0), TetrisCoordinate(row: 2, column: 1)]
            }
        case .l:
            switch rotationIndex {
            case 0: return [TetrisCoordinate(row: 0, column: 2), TetrisCoordinate(row: 1, column: 0), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 1, column: 2)]
            case 1: return [TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 1), TetrisCoordinate(row: 2, column: 2)]
            case 2: return [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 0, column: 2), TetrisCoordinate(row: 1, column: 0)]
            default: return [TetrisCoordinate(row: 0, column: 0), TetrisCoordinate(row: 0, column: 1), TetrisCoordinate(row: 1, column: 1), TetrisCoordinate(row: 2, column: 1)]
            }
        }
    }

    var width: Int {
        (blocks.map { $0.column }.max() ?? 0) + 1
    }
}

enum TetrisStatus: Equatable {
    case ready
    case playing
    case paused
    case lost

    var title: String {
        switch self {
        case .ready: return "准备好了吗？"
        case .playing: return "继续拼出完整的行！"
        case .paused: return "游戏暂停啦"
        case .lost: return "方块堆到顶了"
        }
    }

    var symbol: String {
        switch self {
        case .ready: return "sparkles"
        case .playing: return "gamecontroller.fill"
        case .paused: return "pause.circle.fill"
        case .lost: return "flag.checkered"
        }
    }
}

struct TetrisGame {
    static let rows = 20
    static let defaultColumns = 10
    static let landscapeColumns = 14

    let columns: Int

    private(set) var board: [[TetrisPieceKind?]]
    private(set) var activePiece: TetrisPiece
    private(set) var nextPiece: TetrisPiece
    private(set) var status: TetrisStatus
    private(set) var score: Int
    private(set) var clearedLines: Int
    private(set) var level: Int

    init(columns: Int = Self.defaultColumns) {
        self.columns = max(Self.defaultColumns, columns)
        board = Array(repeating: Array(repeating: nil, count: self.columns), count: Self.rows)
        activePiece = TetrisPiece(kind: .t, rotation: 0, row: 0, column: 3)
        nextPiece = TetrisPiece(kind: .o, rotation: 0, row: 0, column: 0)
        status = .ready
        score = 0
        clearedLines = 0
        level = 1
        reset()
    }

    var isPlaying: Bool {
        status == .playing
    }

    mutating func reset() {
        board = Array(repeating: Array(repeating: nil, count: columns), count: Self.rows)
        score = 0
        clearedLines = 0
        level = 1
        status = .ready
        nextPiece = makePiece(kind: randomKind())
        activePiece = makePiece(kind: randomKind())
    }

    mutating func start() {
        guard status == .ready else { return }
        status = .playing
    }

    mutating func pauseOrResume() {
        switch status {
        case .playing: status = .paused
        case .paused: status = .playing
        case .ready, .lost: break
        }
    }

    mutating func tick() {
        guard status == .playing else { return }
        if !moveActivePiece(rowOffset: 1, columnOffset: 0) {
            lockActivePiece()
        }
    }

    mutating func moveLeft() {
        moveHorizontally(by: -1)
    }

    mutating func moveRight() {
        moveHorizontally(by: 1)
    }

    mutating func rotate() {
        guard status == .playing else { return }

        var rotated = activePiece
        rotated.rotation = (rotated.rotation + 1) % 4

        for columnOffset in [0, -1, 1, -2, 2] {
            var candidate = rotated
            candidate.column += columnOffset
            if isValid(candidate) {
                activePiece = candidate
                return
            }
        }
    }

    mutating func softDrop() {
        guard status == .playing else { return }
        if moveActivePiece(rowOffset: 1, columnOffset: 0) {
            score += 1
        } else {
            lockActivePiece()
        }
    }

    mutating func hardDrop() {
        guard status == .playing else { return }
        while moveActivePiece(rowOffset: 1, columnOffset: 0) {
            score += 2
        }
        lockActivePiece()
    }

    func kind(at row: Int, column: Int) -> TetrisPieceKind? {
        guard row >= 0, row < Self.rows, column >= 0, column < columns else { return nil }
        if let lockedKind = board[row][column] {
            return lockedKind
        }

        return activePiece.blocks.contains(where: { block in
            activePiece.row + block.row == row && activePiece.column + block.column == column
        }) ? activePiece.kind : nil
    }

    private mutating func moveHorizontally(by offset: Int) {
        guard status == .playing else { return }
        _ = moveActivePiece(rowOffset: 0, columnOffset: offset)
    }

    private mutating func moveActivePiece(rowOffset: Int, columnOffset: Int) -> Bool {
        var candidate = activePiece
        candidate.row += rowOffset
        candidate.column += columnOffset
        guard isValid(candidate) else { return false }
        activePiece = candidate
        return true
    }

    private func isValid(_ piece: TetrisPiece) -> Bool {
        for block in piece.blocks {
            let row = piece.row + block.row
            let column = piece.column + block.column
            guard column >= 0, column < columns, row < Self.rows else { return false }
            if row >= 0, board[row][column] != nil {
                return false
            }
        }
        return true
    }

    private mutating func lockActivePiece() {
        for block in activePiece.blocks {
            let row = activePiece.row + block.row
            let column = activePiece.column + block.column
            guard row >= 0, row < Self.rows, column >= 0, column < columns else { continue }
            board[row][column] = activePiece.kind
        }

        removeCompletedLines()
        spawnNextPiece()
    }

    private mutating func removeCompletedLines() {
        let completedCount = board.filter { row in
            row.allSatisfy { $0 != nil }
        }.count
        guard completedCount > 0 else { return }

        board.removeAll { row in
            row.allSatisfy { $0 != nil }
        }
        for _ in 0..<completedCount {
            board.insert(Array(repeating: nil, count: columns), at: 0)
        }

        clearedLines += completedCount
        let points = [0, 100, 300, 500, 800][min(completedCount, 4)]
        score += points * level
        level = min(10, clearedLines / 10 + 1)
    }

    private mutating func spawnNextPiece() {
        activePiece = makePiece(kind: nextPiece.kind)
        nextPiece = makePiece(kind: randomKind())
        if !isValid(activePiece) {
            status = .lost
        }
    }

    private func makePiece(kind: TetrisPieceKind) -> TetrisPiece {
        let width = TetrisPiece(kind: kind, rotation: 0, row: 0, column: 0).width
        return TetrisPiece(
            kind: kind,
            rotation: 0,
            row: 0,
            column: max(0, (columns - width) / 2)
        )
    }

    private func randomKind() -> TetrisPieceKind {
        TetrisPieceKind.allCases.randomElement() ?? .t
    }
}
