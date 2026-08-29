import Foundation

enum GomokuStone: Equatable {
    case empty
    case player
    case bot

    var title: String {
        switch self {
        case .empty: return "空位"
        case .player: return "你的黑子"
        case .bot: return "电脑的白子"
        }
    }
}

enum GomokuDifficulty: String, CaseIterable, Identifiable, Equatable {
    case beginner
    case tactician
    case master

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beginner: return "入门练习"
        case .tactician: return "进阶对手"
        case .master: return "大师挑战"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: return "电脑走子较随意，适合熟悉规则"
        case .tactician: return "重视连珠与防守，攻守更平衡"
        case .master: return "主动布局，并提前判断下一步"
        }
    }

    var accent: GameAccent {
        switch self {
        case .beginner: return .mint
        case .tactician: return .sky
        case .master: return .purple
        }
    }

    var attackWeight: Int {
        switch self {
        case .beginner: return 1
        case .tactician: return 2
        case .master: return 3
        }
    }

    var defenseWeight: Int {
        switch self {
        case .beginner: return 1
        case .tactician: return 3
        case .master: return 5
        }
    }
}

enum GomokuLearningSkill: String, CaseIterable, Identifiable, Equatable {
    case observe
    case count
    case plan
    case focus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .observe: return "观察"
        case .count: return "数数"
        case .plan: return "预判"
        case .focus: return "专注"
        }
    }

    var symbol: String {
        switch self {
        case .observe: return "eye.fill"
        case .count: return "number.circle.fill"
        case .plan: return "arrow.triangle.branch"
        case .focus: return "scope"
        }
    }
}

struct GomokuTeachingTip: Equatable {
    let title: String
    let message: String
    let skill: GomokuLearningSkill
    let symbol: String
}

enum GomokuGameStatus: Equatable {
    case playerTurn
    case botThinking
    case playerWon
    case botWon
    case draw

    var title: String {
        switch self {
        case .playerTurn: return "轮到你了"
        case .botThinking: return "电脑思考中"
        case .playerWon: return "恭喜，你赢啦！"
        case .botWon: return "电脑获胜"
        case .draw: return "棋盘已满，和棋"
        }
    }

    var detail: String {
        switch self {
        case .playerTurn: return "你执黑棋，请点击棋盘落子"
        case .botThinking: return "白方正在寻找下一步"
        case .playerWon: return "漂亮！连续五子连成一线"
        case .botWon: return "这次棋差一着，再来一局吧"
        case .draw: return "双方都没有连成五子"
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

struct GomokuPosition: Hashable {
    let row: Int
    let column: Int
}

struct GomokuGame {
    static let boardSize = 15

    private struct Direction {
        let row: Int
        let column: Int
    }

    private static let directions = [
        Direction(row: 0, column: 1),
        Direction(row: 1, column: 0),
        Direction(row: 1, column: 1),
        Direction(row: 1, column: -1)
    ]

    private(set) var difficulty: GomokuDifficulty
    private(set) var board = Array(repeating: GomokuStone.empty, count: GomokuGame.boardSize * GomokuGame.boardSize)
    private(set) var status: GomokuGameStatus = .playerTurn
    private(set) var lastMove: GomokuPosition?
    private(set) var winningLine: Set<GomokuPosition> = []
    private(set) var moveCount = 0

    var teachingTip: GomokuTeachingTip {
        switch status {
        case .playerTurn:
            let botWinningMoves = immediateWinningMoveCount(for: .bot)
            let playerWinningMoves = immediateWinningMoveCount(for: .player)

            if botWinningMoves > 0 {
                return GomokuTeachingTip(
                    title: "小小防守员",
                    message: "白方快连成五子了，先找最长的一条线，想想哪里要挡。",
                    skill: .observe,
                    symbol: "shield.fill"
                )
            }

            if playerWinningMoves > 0 {
                return GomokuTeachingTip(
                    title: "发现好机会",
                    message: "你有机会连成五子，横、竖、斜线都数一数。",
                    skill: .count,
                    symbol: "sparkles"
                )
            }

            switch moveCount {
            case 0:
                return GomokuTeachingTip(
                    title: "第一步：认识棋盘",
                    message: "看棋盘中心，想一想有几个方向可以发展。",
                    skill: .observe,
                    symbol: "eye.fill"
                )
            case 1...4:
                return GomokuTeachingTip(
                    title: "边下边数",
                    message: "数一数自己的棋子，哪条线已有两颗或三颗？",
                    skill: .count,
                    symbol: "number.circle.fill"
                )
            case 5...10:
                return GomokuTeachingTip(
                    title: "想一想下一步",
                    message: "落子前想一想，下一步还能往哪个方向继续？",
                    skill: .plan,
                    symbol: "arrow.triangle.branch"
                )
            default:
                return GomokuTeachingTip(
                    title: "四个方向都看看",
                    message: "检查横、竖和两条斜线，耐心寻找机会。",
                    skill: .focus,
                    symbol: "scope"
                )
            }

        case .botThinking:
            return GomokuTeachingTip(
                title: "观察电脑的选择",
                message: "猜一猜电脑是在进攻，还是在挡住你的连子？",
                skill: .observe,
                symbol: "brain.head.profile"
            )

        case .playerWon:
            return GomokuTeachingTip(
                title: "小冠军复盘",
                message: "数一数获胜线上的黑子，想想哪一步带来了机会。",
                skill: .count,
                symbol: "graduationcap.fill"
            )

        case .botWon:
            return GomokuTeachingTip(
                title: "从棋局中学习",
                message: "找找哪一步没留意白子，下局先观察三子和四子。",
                skill: .focus,
                symbol: "lightbulb.fill"
            )

        case .draw:
            return GomokuTeachingTip(
                title: "耐心完成棋局",
                message: "没有分出胜负也是练习，找找三种不同的连线方向。",
                skill: .plan,
                symbol: "equal.circle.fill"
            )
        }
    }

    init(difficulty: GomokuDifficulty = .beginner) {
        self.difficulty = difficulty
        reset()
    }

    func stone(at row: Int, column: Int) -> GomokuStone {
        guard let index = index(row: row, column: column) else { return .empty }
        return board[index]
    }

    mutating func reset() {
        board = Array(repeating: .empty, count: Self.boardSize * Self.boardSize)
        status = .playerTurn
        lastMove = nil
        winningLine = []
        moveCount = 0
    }

    mutating func changeDifficulty(to newDifficulty: GomokuDifficulty) {
        guard difficulty != newDifficulty else { return }
        difficulty = newDifficulty
        reset()
    }

    mutating func playPlayerMove(row: Int, column: Int) -> Bool {
        guard status == .playerTurn, let position = validEmptyPosition(row: row, column: column) else {
            return false
        }

        place(.player, at: position)
        if let line = winningLine(for: position, stone: .player) {
            winningLine = Set(line)
            status = .playerWon
        } else if moveCount == board.count {
            status = .draw
        } else {
            status = .botThinking
        }
        return true
    }

    mutating func playBotMove() -> Bool {
        guard status == .botThinking else { return false }

        guard let position = bestBotMove() else {
            status = .draw
            return false
        }

        place(.bot, at: position)
        if let line = winningLine(for: position, stone: .bot) {
            winningLine = Set(line)
            status = .botWon
        } else if moveCount == board.count {
            status = .draw
        } else {
            status = .playerTurn
        }
        return true
    }

    private mutating func place(_ stone: GomokuStone, at position: GomokuPosition) {
        guard let index = index(row: position.row, column: position.column) else { return }
        board[index] = stone
        lastMove = position
        moveCount += 1
    }

    private func validEmptyPosition(row: Int, column: Int) -> GomokuPosition? {
        guard let index = index(row: row, column: column), board[index] == .empty else { return nil }
        return GomokuPosition(row: row, column: column)
    }

    private func index(row: Int, column: Int) -> Int? {
        guard row >= 0, row < Self.boardSize, column >= 0, column < Self.boardSize else { return nil }
        return row * Self.boardSize + column
    }

    private func position(from index: Int) -> GomokuPosition {
        GomokuPosition(row: index / Self.boardSize, column: index % Self.boardSize)
    }

    private func winningLine(for position: GomokuPosition, stone: GomokuStone) -> [GomokuPosition]? {
        for direction in Self.directions {
            let line = contiguousLine(from: position, stone: stone, direction: direction)
            if line.count >= 5 {
                return line
            }
        }
        return nil
    }

    private func contiguousLine(
        from position: GomokuPosition,
        stone: GomokuStone,
        direction: Direction
    ) -> [GomokuPosition] {
        var line = [position]
        line.append(contentsOf: positions(from: position, stone: stone, direction: direction))
        line.insert(contentsOf: positions(from: position, stone: stone, direction: Direction(row: -direction.row, column: -direction.column)), at: 0)
        return line
    }

    private func positions(
        from position: GomokuPosition,
        stone: GomokuStone,
        direction: Direction
    ) -> [GomokuPosition] {
        var positions: [GomokuPosition] = []
        var row = position.row + direction.row
        var column = position.column + direction.column

        while let index = index(row: row, column: column), board[index] == stone {
            positions.append(GomokuPosition(row: row, column: column))
            row += direction.row
            column += direction.column
        }
        return positions
    }

    private func bestBotMove() -> GomokuPosition? {
        let candidates = candidatePositions()
        guard !candidates.isEmpty else { return nil }

        if moveCount == 1 {
            return candidates.min { centerDistance($0) < centerDistance($1) }
        }

        if let winningMove = candidates.first(where: { isWinningMove($0, for: .bot) }) {
            return winningMove
        }

        if difficulty != .beginner,
           let blockingMove = candidates.first(where: { isWinningMove($0, for: .player) }) {
            return blockingMove
        }

        let orderedCandidates = candidates.sorted {
            score(for: $0) > score(for: $1)
        }

        if difficulty == .beginner {
            return Array(orderedCandidates.prefix(min(5, orderedCandidates.count))).randomElement()
        }

        if difficulty == .master {
            return bestLookaheadMove(from: Array(orderedCandidates.prefix(min(10, orderedCandidates.count))))
        }

        return orderedCandidates.first
    }

    private func candidatePositions() -> [GomokuPosition] {
        let occupied = board.indices.filter { board[$0] != .empty }
        guard !occupied.isEmpty else {
            return [GomokuPosition(row: Self.boardSize / 2, column: Self.boardSize / 2)]
        }

        var candidates = Set<GomokuPosition>()
        for occupiedIndex in occupied {
            let occupiedPosition = position(from: occupiedIndex)
            for rowOffset in -2...2 {
                for columnOffset in -2...2 {
                    let row = occupiedPosition.row + rowOffset
                    let column = occupiedPosition.column + columnOffset
                    if let index = index(row: row, column: column), board[index] == .empty {
                        candidates.insert(GomokuPosition(row: row, column: column))
                    }
                }
            }
        }
        return candidates.sorted { centerDistance($0) < centerDistance($1) }
    }

    private func isWinningMove(_ position: GomokuPosition, for stone: GomokuStone) -> Bool {
        guard let index = index(row: position.row, column: position.column), board[index] == .empty else {
            return false
        }

        var next = self
        next.board[index] = stone
        return next.winningLine(for: position, stone: stone) != nil
    }

    private func immediateWinningMoveCount(for stone: GomokuStone) -> Int {
        candidatePositions().reduce(into: 0) { count, position in
            if isWinningMove(position, for: stone) {
                count += 1
            }
        }
    }

    private func bestLookaheadMove(from candidates: [GomokuPosition]) -> GomokuPosition? {
        var bestMove: GomokuPosition?
        var bestScore = Int.min

        for candidate in candidates {
            guard let index = index(row: candidate.row, column: candidate.column) else { continue }
            var next = self
            next.board[index] = .bot

            let immediateScore = score(for: candidate)
            let opponentReply = next.candidatePositions()
                .sorted { next.score(for: $0, as: .player) > next.score(for: $1, as: .player) }
                .prefix(8)
                .map { next.score(for: $0, as: .player) }
                .max() ?? 0
            let combinedScore = immediateScore - opponentReply / 2

            if combinedScore > bestScore || (combinedScore == bestScore && Bool.random()) {
                bestScore = combinedScore
                bestMove = candidate
            }
        }

        return bestMove ?? candidates.first
    }

    private func score(for position: GomokuPosition) -> Int {
        score(for: position, as: .bot) * difficulty.attackWeight
            + score(for: position, as: .player) * difficulty.defenseWeight
            + max(0, 8 - centerDistance(position)) * 3
    }

    private func score(for position: GomokuPosition, as stone: GomokuStone) -> Int {
        guard let index = index(row: position.row, column: position.column), board[index] == .empty else {
            return 0
        }

        var total = 0
        for direction in Self.directions {
            let forward = count(from: position, stone: stone, direction: direction)
            let backwardDirection = Direction(row: -direction.row, column: -direction.column)
            let backward = count(from: position, stone: stone, direction: backwardDirection)
            let length = forward + backward + 1
            let openEnds = openEndCount(
                from: position,
                direction: direction,
                forwardLength: forward,
                backwardLength: backward
            )

            switch length {
            case 5...: total += 100_000
            case 4: total += openEnds == 2 ? 12_000 : 2_400
            case 3: total += openEnds == 2 ? 1_200 : 180
            case 2: total += openEnds == 2 ? 120 : 20
            default: total += openEnds * 3
            }
        }
        return total
    }

    private func count(from position: GomokuPosition, stone: GomokuStone, direction: Direction) -> Int {
        var count = 0
        var row = position.row + direction.row
        var column = position.column + direction.column

        while let index = index(row: row, column: column), board[index] == stone {
            count += 1
            row += direction.row
            column += direction.column
        }
        return count
    }

    private func openEndCount(
        from position: GomokuPosition,
        direction: Direction,
        forwardLength: Int,
        backwardLength: Int
    ) -> Int {
        let forwardRow = position.row + direction.row * (forwardLength + 1)
        let forwardColumn = position.column + direction.column * (forwardLength + 1)
        let backwardRow = position.row - direction.row * (backwardLength + 1)
        let backwardColumn = position.column - direction.column * (backwardLength + 1)
        var openEnds = 0

        if let forwardIndex = index(row: forwardRow, column: forwardColumn), board[forwardIndex] == .empty {
            openEnds += 1
        }
        if let backwardIndex = index(row: backwardRow, column: backwardColumn), board[backwardIndex] == .empty {
            openEnds += 1
        }
        return openEnds
    }

    private func centerDistance(_ position: GomokuPosition) -> Int {
        abs(position.row - Self.boardSize / 2) + abs(position.column - Self.boardSize / 2)
    }
}
