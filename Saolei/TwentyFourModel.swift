import Foundation

struct TwentyFourValue: Equatable {
    let numerator: Int
    let denominator: Int

    init(_ numerator: Int, _ denominator: Int = 1) {
        precondition(denominator != 0)

        let sign = denominator < 0 ? -1 : 1
        let divisor = Self.greatestCommonDivisor(abs(numerator), abs(denominator))
        self.numerator = numerator * sign / divisor
        self.denominator = abs(denominator) / divisor
    }

    var isZero: Bool {
        numerator == 0
    }

    var isWholeNumber: Bool {
        denominator == 1
    }

    var displayText: String {
        isWholeNumber ? String(numerator) : "\(numerator)/\(denominator)"
    }

    static func + (lhs: TwentyFourValue, rhs: TwentyFourValue) -> TwentyFourValue {
        TwentyFourValue(
            lhs.numerator * rhs.denominator + rhs.numerator * lhs.denominator,
            lhs.denominator * rhs.denominator
        )
    }

    static func - (lhs: TwentyFourValue, rhs: TwentyFourValue) -> TwentyFourValue {
        TwentyFourValue(
            lhs.numerator * rhs.denominator - rhs.numerator * lhs.denominator,
            lhs.denominator * rhs.denominator
        )
    }

    static func * (lhs: TwentyFourValue, rhs: TwentyFourValue) -> TwentyFourValue {
        TwentyFourValue(lhs.numerator * rhs.numerator, lhs.denominator * rhs.denominator)
    }

    static func / (lhs: TwentyFourValue, rhs: TwentyFourValue) -> TwentyFourValue? {
        guard !rhs.isZero else { return nil }
        return TwentyFourValue(lhs.numerator * rhs.denominator, lhs.denominator * rhs.numerator)
    }

    private static func greatestCommonDivisor(_ lhs: Int, _ rhs: Int) -> Int {
        var a = lhs
        var b = rhs
        while b != 0 {
            let remainder = a % b
            a = b
            b = remainder
        }
        return max(a, 1)
    }
}

enum TwentyFourOperation: String, CaseIterable, Identifiable {
    case addition
    case subtraction
    case multiplication
    case division

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "−"
        case .multiplication: return "×"
        case .division: return "÷"
        }
    }

    func calculate(_ first: TwentyFourValue, _ second: TwentyFourValue) -> TwentyFourValue? {
        switch self {
        case .addition: return first + second
        case .subtraction: return first - second
        case .multiplication: return first * second
        case .division: return first / second
        }
    }
}

struct TwentyFourItem: Identifiable, Equatable {
    let id: Int
    let value: TwentyFourValue
    let expression: String

    var displayText: String {
        value.displayText
    }

    var isCalculated: Bool {
        expression.hasPrefix("(")
    }
}

struct TwentyFourGame {
    static let answerDelay = 10

    private(set) var items: [TwentyFourItem] = []
    private(set) var steps: [String] = []
    private(set) var answer = ""
    private(set) var elapsedSeconds = 0
    private(set) var answerIsVisible = false

    private var history: [[TwentyFourItem]] = []
    private var nextItemID = 0

    init() {
        reset()
    }

    var answerAvailable: Bool {
        elapsedSeconds >= Self.answerDelay
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    var isComplete: Bool {
        items.count == 1
    }

    var isCorrect: Bool {
        isComplete && items[0].value == TwentyFourValue(24)
    }

    var preferredSelectionIndex: Int? {
        items.lastIndex(where: { $0.isCalculated })
    }

    mutating func reset() {
        let puzzle = Self.makePuzzle()
        nextItemID = 0
        items = puzzle.numbers.map { number in
            let item = TwentyFourItem(
                id: nextItemID,
                value: TwentyFourValue(number),
                expression: String(number)
            )
            nextItemID += 1
            return item
        }
        steps = []
        answer = puzzle.answer
        elapsedSeconds = 0
        answerIsVisible = false
        history = []
    }

    mutating func tick() {
        guard !answerIsVisible, elapsedSeconds < Self.answerDelay else { return }
        elapsedSeconds += 1
    }

    mutating func revealAnswer() {
        guard answerAvailable else { return }
        answerIsVisible = true
    }

    @discardableResult
    mutating func apply(
        _ operation: TwentyFourOperation,
        firstIndex: Int,
        secondIndex: Int
    ) -> Int? {
        guard firstIndex != secondIndex,
              items.indices.contains(firstIndex),
              items.indices.contains(secondIndex),
              let result = operation.calculate(items[firstIndex].value, items[secondIndex].value) else {
            return nil
        }

        let first = items[firstIndex]
        let second = items[secondIndex]
        let resultItem = TwentyFourItem(
            id: nextItemID,
            value: result,
            expression: "(\(first.expression) \(operation.symbol) \(second.expression))"
        )
        nextItemID += 1

        history.append(items)
        let lowerIndex = min(firstIndex, secondIndex)
        let upperIndex = max(firstIndex, secondIndex)
        var updatedItems = items
        updatedItems[lowerIndex] = resultItem
        updatedItems.remove(at: upperIndex)
        items = updatedItems
        steps.append("\(first.expression) \(operation.symbol) \(second.expression) = \(result.displayText)")
        return lowerIndex
    }

    mutating func undo() {
        guard let previousItems = history.popLast() else { return }
        items = previousItems
        if !steps.isEmpty {
            steps.removeLast()
        }
    }

    private static func makePuzzle() -> (numbers: [Int], answer: String) {
        while true {
            let numbers = (0..<4).map { _ in Int.random(in: 1...13) }
            if let answer = findAnswer(for: numbers) {
                return (numbers, answer)
            }
        }
    }

    private struct AnswerExpression {
        let value: Double
        let text: String
    }

    private static func findAnswer(for numbers: [Int]) -> String? {
        findAnswer(from: numbers.map {
            AnswerExpression(value: Double($0), text: String($0))
        })
    }

    private static func findAnswer(from expressions: [AnswerExpression]) -> String? {
        guard expressions.count > 1 else {
            guard let expression = expressions.first,
                  abs(expression.value - 24) < 0.0001 else { return nil }
            return expression.text
        }

        for firstIndex in 0..<(expressions.count - 1) {
            for secondIndex in (firstIndex + 1)..<expressions.count {
                let first = expressions[firstIndex]
                let second = expressions[secondIndex]
                let remaining = expressions.enumerated().compactMap { index, expression in
                    index == firstIndex || index == secondIndex ? nil : expression
                }

                var candidates = [
                    AnswerExpression(value: first.value + second.value, text: combine(first, "+", second)),
                    AnswerExpression(value: first.value * second.value, text: combine(first, "×", second)),
                    AnswerExpression(value: first.value - second.value, text: combine(first, "−", second)),
                    AnswerExpression(value: second.value - first.value, text: combine(second, "−", first))
                ]

                if abs(second.value) > 0.0001 {
                    candidates.append(AnswerExpression(
                        value: first.value / second.value,
                        text: combine(first, "÷", second)
                    ))
                }
                if abs(first.value) > 0.0001 {
                    candidates.append(AnswerExpression(
                        value: second.value / first.value,
                        text: combine(second, "÷", first)
                    ))
                }

                for candidate in candidates {
                    guard candidate.value >= -0.0001 else { continue }
                    if let answer = findAnswer(from: remaining + [candidate]) {
                        return answer
                    }
                }
            }
        }

        return nil
    }

    private static func combine(
        _ first: AnswerExpression,
        _ operation: String,
        _ second: AnswerExpression
    ) -> String {
        "(\(first.text) \(operation) \(second.text))"
    }
}
