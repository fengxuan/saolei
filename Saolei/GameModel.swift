import Foundation

enum GameDifficulty: String, CaseIterable, Identifiable, Equatable {
    case starter
    case explorer
    case adventurer
    case champion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .starter: return "小小新手"
        case .explorer: return "快乐探索"
        case .adventurer: return "勇敢挑战"
        case .champion: return "扫雷冠军"
        }
    }

    var subtitle: String {
        switch self {
        case .starter: return "6 × 6 · 5 颗雷"
        case .explorer: return "8 × 8 · 10 颗雷"
        case .adventurer: return "10 × 10 · 18 颗雷"
        case .champion: return "12 × 12 · 30 颗雷"
        }
    }

    var rows: Int {
        switch self {
        case .starter: return 6
        case .explorer: return 8
        case .adventurer: return 10
        case .champion: return 12
        }
    }

    var columns: Int { rows }

    var mineCount: Int {
        switch self {
        case .starter: return 5
        case .explorer: return 10
        case .adventurer: return 18
        case .champion: return 30
        }
    }

    var accent: GameAccent {
        switch self {
        case .starter: return .mint
        case .explorer: return .sky
        case .adventurer: return .orange
        case .champion: return .purple
        }
    }
}

enum GameAccent {
    case mint
    case sky
    case orange
    case purple
}

enum CellState: Equatable {
    case hidden
    case revealed
    case flagged
}

struct MineCell: Identifiable {
    let id: Int
    let row: Int
    let column: Int
    var isMine = false
    var adjacentMines = 0
    var state: CellState = .hidden
}

enum GameStatus: Equatable {
    case ready
    case playing
    case won
    case lost

    var title: String {
        switch self {
        case .ready: return "准备好了吗？"
        case .playing: return "继续寻找安全格！"
        case .won: return "太棒了，你赢啦！"
        case .lost: return "哎呀，踩到地雷了"
        }
    }

    var symbol: String {
        switch self {
        case .ready: return "sparkles"
        case .playing: return "magnifyingglass"
        case .won: return "party.popper.fill"
        case .lost: return "exclamationmark.triangle.fill"
        }
    }
}

struct MinesweeperGame {
    private(set) var difficulty: GameDifficulty
    private(set) var cells: [MineCell] = []
    private(set) var status: GameStatus = .ready
    private(set) var elapsedSeconds = 0

    init(difficulty: GameDifficulty = .starter) {
        self.difficulty = difficulty
        reset()
    }

    var remainingMines: Int {
        max(0, difficulty.mineCount - cells.filter { $0.state == .flagged }.count)
    }

    mutating func reset() {
        status = .ready
        elapsedSeconds = 0
        cells = (0..<(difficulty.rows * difficulty.columns)).map { index in
            MineCell(
                id: index,
                row: index / difficulty.columns,
                column: index % difficulty.columns
            )
        }

        var mineLocations = Array(cells.indices).shuffled()
        for _ in 0..<difficulty.mineCount {
            let location = mineLocations.removeLast()
            cells[location].isMine = true
        }
        updateAdjacentMineCounts()
    }

    mutating func changeDifficulty(to newDifficulty: GameDifficulty) {
        guard newDifficulty != difficulty else { return }
        difficulty = newDifficulty
        reset()
    }

    mutating func tick() {
        guard status == .playing else { return }
        elapsedSeconds += 1
    }

    mutating func reveal(row: Int, column: Int) {
        guard let index = index(row: row, column: column), status != .won, status != .lost else { return }
        guard cells[index].state != .flagged, cells[index].state != .revealed else { return }

        if status == .ready {
            status = .playing
        }

        if !hasRevealedCells, cells[index].isMine {
            moveMineAway(from: index)
        }

        if cells[index].isMine {
            cells[index].state = .revealed
            revealAllMines()
            status = .lost
            return
        }

        revealSafeArea(from: index)
        if allSafeCellsAreRevealed {
            status = .won
            revealAllMines()
        }
    }

    mutating func toggleFlag(row: Int, column: Int) {
        guard let index = index(row: row, column: column), status != .won, status != .lost else { return }
        guard cells[index].state != .revealed else { return }

        if status == .ready {
            status = .playing
        }

        cells[index].state = cells[index].state == .flagged ? .hidden : .flagged
    }

    private var allSafeCellsAreRevealed: Bool {
        cells.filter { !$0.isMine }.allSatisfy { $0.state == .revealed }
    }

    private var hasRevealedCells: Bool {
        cells.contains { $0.state == .revealed && !$0.isMine }
    }

    private func index(row: Int, column: Int) -> Int? {
        guard row >= 0, row < difficulty.rows, column >= 0, column < difficulty.columns else { return nil }
        return row * difficulty.columns + column
    }

    private func neighborIndices(of index: Int) -> [Int] {
        let row = cells[index].row
        let column = cells[index].column
        var neighbors: [Int] = []

        for rowOffset in -1...1 {
            for columnOffset in -1...1 {
                guard rowOffset != 0 || columnOffset != 0 else { continue }
                if let neighbor = self.index(row: row + rowOffset, column: column + columnOffset) {
                    neighbors.append(neighbor)
                }
            }
        }
        return neighbors
    }

    private mutating func updateAdjacentMineCounts() {
        for index in cells.indices where !cells[index].isMine {
            cells[index].adjacentMines = neighborIndices(of: index).filter { cells[$0].isMine }.count
        }
    }

    private mutating func moveMineAway(from index: Int) {
        guard let newLocation = cells.indices.first(where: { $0 != index && !cells[$0].isMine }) else { return }
        cells[index].isMine = false
        cells[newLocation].isMine = true
        updateAdjacentMineCounts()
    }

    private mutating func revealSafeArea(from start: Int) {
        var queue = [start]
        var visited = Set<Int>()

        while !queue.isEmpty {
            let current = queue.removeFirst()
            guard visited.insert(current).inserted else { continue }
            guard cells[current].state != .flagged, !cells[current].isMine else { continue }

            cells[current].state = .revealed
            guard cells[current].adjacentMines == 0 else { continue }

            queue.append(contentsOf: neighborIndices(of: current).filter {
                cells[$0].state == .hidden && !cells[$0].isMine
            })
        }
    }

    private mutating func revealAllMines() {
        for index in cells.indices where cells[index].isMine {
            cells[index].state = .revealed
        }
    }
}
