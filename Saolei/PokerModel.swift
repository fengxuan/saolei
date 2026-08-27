import Foundation

enum PokerDifficulty: String, CaseIterable, Identifiable, Equatable {
    case casual
    case smart
    case expert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .casual: return "轻松入门"
        case .smart: return "策略对手"
        case .expert: return "高手挑战"
        }
    }

    var subtitle: String {
        switch self {
        case .casual: return "机器人偏保守，适合熟悉规则"
        case .smart: return "综合牌力和底池赔率，偶尔主动施压"
        case .expert: return "通过胜率模拟，更擅长价值下注和识别弱牌"
        }
    }

    var accent: GameAccent {
        switch self {
        case .casual: return .mint
        case .smart: return .sky
        case .expert: return .purple
        }
    }

    var foldThreshold: Double {
        switch self {
        case .casual: return 0.22
        case .smart: return 0.34
        case .expert: return 0.46
        }
    }

    var raiseThreshold: Double {
        switch self {
        case .casual: return 0.74
        case .smart: return 0.60
        case .expert: return 0.49
        }
    }

    var raiseFrequency: Double {
        switch self {
        case .casual: return 0.14
        case .smart: return 0.36
        case .expert: return 0.58
        }
    }

    var bluffFrequency: Double {
        switch self {
        case .casual: return 0.06
        case .smart: return 0.10
        case .expert: return 0.15
        }
    }
}

enum PokerSuit: String, CaseIterable, Hashable {
    case hearts
    case diamonds
    case clubs
    case spades

    var symbol: String {
        switch self {
        case .hearts: return "♥"
        case .diamonds: return "♦"
        case .clubs: return "♣"
        case .spades: return "♠"
        }
    }

    var isRed: Bool {
        self == .hearts || self == .diamonds
    }
}

struct PlayingCard: Identifiable, Hashable {
    let suit: PokerSuit
    let rank: Int

    var id: String { "\(rank)-\(suit.rawValue)" }

    var rankName: String {
        switch rank {
        case 14: return "A"
        case 13: return "K"
        case 12: return "Q"
        case 11: return "J"
        default: return String(rank)
        }
    }
}

enum PokerHandCategory: Int, Comparable {
    case highCard
    case onePair
    case twoPair
    case threeOfAKind
    case straight
    case flush
    case fullHouse
    case fourOfAKind
    case straightFlush

    static func < (lhs: PokerHandCategory, rhs: PokerHandCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var title: String {
        switch self {
        case .highCard: return "高牌"
        case .onePair: return "一对"
        case .twoPair: return "两对"
        case .threeOfAKind: return "三条"
        case .straight: return "顺子"
        case .flush: return "同花"
        case .fullHouse: return "葫芦"
        case .fourOfAKind: return "四条"
        case .straightFlush: return "同花顺"
        }
    }
}

struct PokerHand: Equatable {
    let category: PokerHandCategory
    let tiebreakers: [Int]

    var title: String { category.title }
}

struct PokerEquity: Equatable {
    let winRate: Double
    let tieRate: Double

    /// 平局时双方各分一半底池，因此用于教学展示的综合赢面。
    var potShare: Double {
        min(1, max(0, winRate + tieRate * 0.5))
    }
}

enum PokerWinner: Equatable {
    case player
    case bot
    case tie

    var title: String {
        switch self {
        case .player: return "你赢了"
        case .bot: return "机器人赢了"
        case .tie: return "平局"
        }
    }
}

enum PokerStreet: Equatable {
    case preflop
    case flop
    case turn
    case river

    var title: String {
        switch self {
        case .preflop: return "翻牌前"
        case .flop: return "翻牌圈"
        case .turn: return "转牌圈"
        case .river: return "河牌圈"
        }
    }
}

enum PokerStatus: Equatable {
    case playerTurn
    case handOver(PokerWinner)
    case matchOver(PokerWinner)

    var isPlayerTurn: Bool {
        self == .playerTurn
    }

    var isFinished: Bool {
        switch self {
        case .playerTurn: return false
        case .handOver, .matchOver: return true
        }
    }

    var isMatchOver: Bool {
        if case .matchOver = self { return true }
        return false
    }
}

enum PokerBotAction: Equatable {
    case raise(to: Int)
    case call(amount: Int, allIn: Bool)
    case check
    case fold

    var title: String {
        switch self {
        case .raise(let target): return "加注到 \(target)"
        case .call(let amount, let allIn): return allIn ? "全押跟注 \(amount)" : "跟注 \(amount)"
        case .check: return "过牌"
        case .fold: return "弃牌"
        }
    }

    var systemName: String {
        switch self {
        case .raise: return "arrow.up.circle.fill"
        case .call: return "arrow.right.circle.fill"
        case .check: return "hand.wave.fill"
        case .fold: return "xmark.circle.fill"
        }
    }
}

enum PokerHandEvaluator {
    static func bestHand(from cards: [PlayingCard]) -> PokerHand? {
        guard cards.count >= 5 else { return nil }

        return combinations(cards, choose: 5)
            .map(evaluateFiveCardHand)
            .max(by: { isWeaker($0, than: $1) })
    }

    private static func evaluateFiveCardHand(_ cards: [PlayingCard]) -> PokerHand {
        let ranks = cards.map(\.rank).sorted(by: >)
        let grouped = Dictionary(grouping: ranks, by: { $0 }).map { (rank: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count { return $0.rank > $1.rank }
                return $0.count > $1.count
            }
        let flush = Set(cards.map(\.suit)).count == 1
        let straightHigh = straightHighCard(from: ranks)

        if flush, let straightHigh {
            return PokerHand(category: .straightFlush, tiebreakers: [straightHigh])
        }

        if grouped[0].count == 4 {
            return PokerHand(
                category: .fourOfAKind,
                tiebreakers: [grouped[0].rank, grouped[1].rank]
            )
        }

        if grouped[0].count == 3, grouped[1].count == 2 {
            return PokerHand(
                category: .fullHouse,
                tiebreakers: [grouped[0].rank, grouped[1].rank]
            )
        }

        if flush {
            return PokerHand(category: .flush, tiebreakers: ranks)
        }

        if let straightHigh {
            return PokerHand(category: .straight, tiebreakers: [straightHigh])
        }

        if grouped[0].count == 3 {
            let kickers = grouped.dropFirst().map(\.rank).sorted(by: >)
            return PokerHand(category: .threeOfAKind, tiebreakers: [grouped[0].rank] + kickers)
        }

        if grouped[0].count == 2, grouped[1].count == 2 {
            let pairRanks = [grouped[0].rank, grouped[1].rank].sorted(by: >)
            return PokerHand(
                category: .twoPair,
                tiebreakers: pairRanks + [grouped[2].rank]
            )
        }

        if grouped[0].count == 2 {
            let kickers = grouped.dropFirst().map(\.rank).sorted(by: >)
            return PokerHand(category: .onePair, tiebreakers: [grouped[0].rank] + kickers)
        }

        return PokerHand(category: .highCard, tiebreakers: ranks)
    }

    private static func straightHighCard(from ranks: [Int]) -> Int? {
        let uniqueRanks = Array(Set(ranks)).sorted(by: >)
        guard uniqueRanks.count == 5 else { return nil }

        if uniqueRanks == [14, 5, 4, 3, 2] {
            return 5
        }

        guard let highest = uniqueRanks.first,
              uniqueRanks == Array(stride(from: highest, through: highest - 4, by: -1)) else {
            return nil
        }
        return highest
    }

    private static func isWeaker(_ lhs: PokerHand, than rhs: PokerHand) -> Bool {
        if lhs.category != rhs.category {
            return lhs.category < rhs.category
        }

        for (left, right) in zip(lhs.tiebreakers, rhs.tiebreakers) where left != right {
            return left < right
        }
        return lhs.tiebreakers.count < rhs.tiebreakers.count
    }

    private static func combinations(_ cards: [PlayingCard], choose: Int) -> [[PlayingCard]] {
        guard cards.count >= choose, choose > 0 else { return [] }
        var result: [[PlayingCard]] = []

        func build(start: Int, selected: [PlayingCard]) {
            if selected.count == choose {
                result.append(selected)
                return
            }

            let remainingNeeded = choose - selected.count
            guard cards.count - start >= remainingNeeded else { return }

            for index in start..<(cards.count - remainingNeeded + 1) {
                build(start: index + 1, selected: selected + [cards[index]])
            }
        }

        build(start: 0, selected: [])
        return result
    }
}

struct PokerGame {
    static let startingStack = 1_000
    static let smallBlind = 10
    static let bigBlind = 20
    static let knowledgeTips = [
        "翻牌前起手牌越强，越值得主动加注；还要结合对手行动判断。",
        "底池赔率能帮助你判断跟注是否划算：需要的胜率越低，跟注越容易成立。",
        "同花听牌通常有 9 张补牌，但这些补牌不一定都是绝对安全的。",
        "公共牌越连贯、越同花，越要留意对手可能已经组成顺子或同花。",
        "下注前先想清楚目的：是希望更差的牌跟注，还是希望更好的牌弃牌。",
        "不要只看自己的牌；下注大小和对手的行动同样能提供重要信息。"
    ]

    private(set) var difficulty: PokerDifficulty
    private(set) var playerChips = startingStack
    private(set) var botChips = startingStack
    private(set) var pot = 0
    private(set) var lastPot = 0
    private(set) var handNumber = 0
    private(set) var playerWins = 0
    private(set) var botWins = 0
    private(set) var ties = 0
    private(set) var street: PokerStreet = .preflop
    private(set) var playerCards: [PlayingCard] = []
    private(set) var botCards: [PlayingCard] = []
    private(set) var communityCards: [PlayingCard] = []
    private(set) var status: PokerStatus = .playerTurn
    private(set) var message = ""
    private(set) var knowledgeTip = ""
    private(set) var botAction: PokerBotAction? = nil
    private(set) var currentBet = bigBlind
    private(set) var playerEquity: PokerEquity? = nil

    private var deck: [PlayingCard] = []
    private var playerBetThisStreet = smallBlind
    private var botBetThisStreet = bigBlind
    private var raisesThisStreet = 0

    init(difficulty: PokerDifficulty = .casual) {
        self.difficulty = difficulty
        startNewHand()
    }

    var isPlayerTurn: Bool { status.isPlayerTurn }
    var isFinished: Bool { status.isFinished }
    var shouldRevealBotCards: Bool { status.isFinished }

    var playerHand: PokerHand? {
        PokerHandEvaluator.bestHand(from: playerCards + communityCards)
    }

    var botHand: PokerHand? {
        PokerHandEvaluator.bestHand(from: botCards + communityCards)
    }

    var callAmount: Int {
        max(0, currentBet - playerBetThisStreet)
    }

    var callTitle: String {
        callAmount == 0 ? "过牌" : "跟注 \(callAmount)"
    }

    var minimumBet: Int {
        min(playerBetThisStreet + playerChips, max(PokerGame.bigBlind, currentBet + PokerGame.bigBlind))
    }

    var betOptions: [Int] {
        let maximum = playerBetThisStreet + playerChips
        guard maximum > currentBet else { return [] }

        let minimum = min(maximum, max(PokerGame.bigBlind, currentBet + PokerGame.bigBlind))
        guard minimum <= maximum else { return [] }

        var options = Array(stride(from: minimum, through: maximum, by: PokerGame.bigBlind))
        if options.last != maximum {
            options.append(maximum)
        }
        return options
    }

    var halfPotBet: Int? {
        potSizedBet(multiplier: 0.5)
    }

    var fullPotBet: Int? {
        potSizedBet(multiplier: 1.0)
    }

    mutating func placePlayerBet(to total: Int) {
        guard isPlayerTurn else { return }

        let maximum = playerBetThisStreet + playerChips
        let target = min(total, maximum)
        guard target > currentBet else { return }

        let amount = target - playerBetThisStreet
        playerChips -= amount
        pot += amount
        playerBetThisStreet = target
        currentBet = target
        raisesThisStreet += 1
        message = target == maximum ? "你全押到 \(target)" : "你下注到 \(target)"
        botRespond()
    }

    mutating func playerCheckOrCall() {
        guard isPlayerTurn else { return }

        let amount = min(callAmount, playerChips)
        if amount > 0 {
            playerChips -= amount
            pot += amount
            playerBetThisStreet += amount
            message = "你跟注了 \(amount)"
        } else {
            message = "你选择过牌"
        }
        botRespond()
    }

    mutating func playerFold() {
        guard isPlayerTurn else { return }
        botAction = nil
        message = "你弃牌了：主动放弃本局，机器人获胜"
        finishHand(winner: .bot)
    }

    mutating func startNewHand() {
        guard playerChips >= PokerGame.smallBlind, botChips >= PokerGame.bigBlind else {
            playerEquity = nil
            let winner: PokerWinner = playerChips < PokerGame.smallBlind ? .bot : .player
            status = .matchOver(winner)
            message = winner == .player
                ? "比赛结束：机器人筹码不足，你获胜"
                : "比赛结束：你的筹码不足，机器人获胜"
            return
        }

        handNumber += 1
        deck = PokerGame.makeDeck().shuffled()
        playerCards = [drawCard(), drawCard()]
        botCards = [drawCard(), drawCard()]
        communityCards = []
        street = .preflop
        pot = 0
        lastPot = 0
        currentBet = PokerGame.bigBlind
        playerBetThisStreet = min(playerChips, PokerGame.smallBlind)
        playerChips -= playerBetThisStreet
        botBetThisStreet = min(botChips, PokerGame.bigBlind)
        botChips -= botBetThisStreet
        pot = playerBetThisStreet + botBetThisStreet
        raisesThisStreet = 0
        status = .playerTurn
        botAction = nil
        message = "你是小盲，轮到你行动"
        let availableTips = PokerGame.knowledgeTips.filter { $0 != knowledgeTip }
        knowledgeTip = (availableTips.isEmpty ? PokerGame.knowledgeTips : availableTips).randomElement()
            ?? "先看牌型，再结合底池和对手行动做决定。"
        updatePlayerEquity()
    }

    mutating func resetMatch() {
        playerChips = PokerGame.startingStack
        botChips = PokerGame.startingStack
        playerWins = 0
        botWins = 0
        ties = 0
        handNumber = 0
        startNewHand()
    }

    private mutating func botRespond() {
        guard isPlayerTurn else { return }

        if playerChips == 0, playerBetThisStreet < botBetThisStreet {
            returnUncalledBet()
            runOutAndShowdown()
            return
        }

        let strength = botStrength
        let amountToCall = max(0, currentBet - botBetThisStreet)
        let facingBet = amountToCall > 0
        let canRaise = botBetThisStreet + botChips > currentBet && raisesThisStreet < 2
        let potOdds = amountToCall == 0 ? 0 : Double(amountToCall) / Double(max(1, pot + amountToCall))
        let randomValue = Double.random(in: 0...1)

        let shouldFold: Bool
        switch difficulty {
        case .casual:
            shouldFold = strength < difficulty.foldThreshold
        case .smart:
            shouldFold = strength < potOdds - 0.02
        case .expert:
            shouldFold = strength < potOdds - 0.05
        }

        let foldProbability: Double
        switch difficulty {
        case .casual: foldProbability = 0.38
        case .smart: foldProbability = 0.68
        case .expert: foldProbability = 0.84
        }

        if facingBet, shouldFold, randomValue < foldProbability {
            botAction = .fold
            message = "机器人弃牌了：你无需比牌即可获胜"
            finishHand(winner: .player)
            return
        }

        let shouldRaise = canRaise && (
            (strength >= difficulty.raiseThreshold && randomValue < difficulty.raiseFrequency) ||
            (strength < difficulty.raiseThreshold && randomValue < difficulty.bluffFrequency)
        )

        if shouldRaise, let target = botRaiseTarget(strength: strength) {
            let amount = target - botBetThisStreet
            botChips -= amount
            botBetThisStreet = target
            pot += amount
            currentBet = target
            raisesThisStreet += 1
            botAction = .raise(to: target)
            message = "机器人加注到 \(target)，轮到你了"
            return
        }

        if amountToCall > 0 {
            let amount = min(amountToCall, botChips)
            botChips -= amount
            botBetThisStreet += amount
            pot += amount
            botAction = .call(amount: amount, allIn: amount < amountToCall)
            message = amount == amountToCall ? "机器人跟注了 \(amount)" : "机器人全押跟注了 \(amount)"
        } else {
            botAction = .check
            message = "机器人过牌，进入下一轮"
        }

        if botBetThisStreet < currentBet {
            returnUncalledBet()
            runOutAndShowdown()
        } else {
            settleStreet()
        }
    }

    private func potSizedBet(multiplier: Double) -> Int? {
        guard let maximum = betOptions.last else { return nil }

        let potAmount = max(PokerGame.bigBlind, Int((Double(max(1, pot)) * multiplier).rounded()))
        let target = currentBet + potAmount
        return betOptions.first(where: { $0 >= target }) ?? maximum
    }

    private mutating func settleStreet() {
        guard playerBetThisStreet == botBetThisStreet else { return }

        if playerChips == 0 || botChips == 0 {
            runOutAndShowdown()
            return
        }

        switch street {
        case .preflop:
            revealFlop()
        case .flop:
            revealTurn()
        case .turn:
            revealRiver()
        case .river:
            showdown()
        }
    }

    private mutating func revealFlop() {
        communityCards.append(drawCard())
        communityCards.append(drawCard())
        communityCards.append(drawCard())
        beginNextStreet(.flop, message: "翻牌：轮到你先行动")
    }

    private mutating func revealTurn() {
        communityCards.append(drawCard())
        beginNextStreet(.turn, message: "转牌：局势开始升温")
    }

    private mutating func revealRiver() {
        communityCards.append(drawCard())
        beginNextStreet(.river, message: "河牌：最后一次行动机会")
    }

    private mutating func beginNextStreet(_ nextStreet: PokerStreet, message: String) {
        street = nextStreet
        currentBet = 0
        playerBetThisStreet = 0
        botBetThisStreet = 0
        raisesThisStreet = 0
        status = .playerTurn
        self.message = message
        updatePlayerEquity()
    }

    private mutating func runOutAndShowdown() {
        while communityCards.count < 5 {
            communityCards.append(drawCard())
        }
        showdown()
    }

    private mutating func showdown() {
        guard let playerHand, let botHand else { return }

        let comparison = compareHands(playerHand, botHand)
        let winner: PokerWinner = comparison > 0 ? .player : comparison < 0 ? .bot : .tie

        message = showdownMessage(playerHand: playerHand, botHand: botHand, winner: winner)
        finishHand(winner: winner)
    }

    private func showdownMessage(playerHand: PokerHand, botHand: PokerHand, winner: PokerWinner) -> String {
        switch winner {
        case .player:
            if playerHand.category == botHand.category {
                return "你赢了：双方都是\(playerHand.title)，你的关键牌更大"
            }
            return "你赢了：你的\(playerHand.title)大于机器人的\(botHand.title)"
        case .bot:
            if playerHand.category == botHand.category {
                return "你输了：双方都是\(playerHand.title)，机器人的关键牌更大"
            }
            return "你输了：机器人的\(botHand.title)大于你的\(playerHand.title)"
        case .tie:
            return "平局：双方都是\(playerHand.title)，牌型和关键牌相同"
        }
    }

    private mutating func finishHand(winner: PokerWinner) {
        let awardedPot = pot
        lastPot = awardedPot
        pot = 0
        playerEquity = nil

        switch winner {
        case .player:
            playerWins += 1
            playerChips += awardedPot
        case .bot:
            botWins += 1
            botChips += awardedPot
        case .tie:
            ties += 1
            let split = awardedPot / 2
            playerChips += split + awardedPot % 2
            botChips += split
        }

        if playerChips < PokerGame.smallBlind || botChips < PokerGame.bigBlind {
            status = .matchOver(winner)
        } else {
            status = .handOver(winner)
        }
    }

    private mutating func returnUncalledBet() {
        if playerBetThisStreet > botBetThisStreet {
            let unmatched = playerBetThisStreet - botBetThisStreet
            playerChips += unmatched
            pot = max(0, pot - unmatched)
            playerBetThisStreet -= unmatched
        } else if botBetThisStreet > playerBetThisStreet {
            let unmatched = botBetThisStreet - playerBetThisStreet
            botChips += unmatched
            pot = max(0, pot - unmatched)
            botBetThisStreet -= unmatched
        }
        currentBet = max(playerBetThisStreet, botBetThisStreet)
    }

    private var botStrength: Double {
        let heuristicStrength = heuristicBotStrength
        switch difficulty {
        case .casual:
            return heuristicStrength
        case .smart:
            let simulatedEquity = botEquity(simulations: 80)
            return heuristicStrength * 0.35 + simulatedEquity * 0.65
        case .expert:
            return botEquity(simulations: 240)
        }
    }

    private var heuristicBotStrength: Double {
        guard !botCards.isEmpty else { return 0 }

        if communityCards.isEmpty {
            let high = Double(botCards.map(\.rank).max() ?? 2)
            let low = Double(botCards.map(\.rank).min() ?? 2)
            let pairBonus = botCards[0].rank == botCards[1].rank ? 0.35 : 0
            let suitedBonus = botCards[0].suit == botCards[1].suit ? 0.08 : 0
            let connectedBonus = abs(botCards[0].rank - botCards[1].rank) <= 2 ? 0.06 : 0
            return min(1, 0.12 + (high - 2) / 60 + (low - 2) / 100 + pairBonus + suitedBonus + connectedBonus)
        }

        guard let hand = botHand else { return 0.2 }
        switch hand.category {
        case .highCard: return 0.18 + Double(hand.tiebreakers.first ?? 2) / 100
        case .onePair: return 0.38 + Double(hand.tiebreakers.first ?? 2) / 70
        case .twoPair: return 0.61
        case .threeOfAKind: return 0.73
        case .straight, .flush: return 0.82
        case .fullHouse: return 0.91
        case .fourOfAKind: return 0.98
        case .straightFlush: return 1
        }
    }

    private func botEquity(simulations: Int) -> Double {
        guard simulations > 0, botCards.count == 2 else { return heuristicBotStrength }

        let knownCards = Set(botCards + communityCards)
        let unseenCards = PokerGame.makeDeck().filter { !knownCards.contains($0) }
        let cardsToCome = 5 - communityCards.count
        var equity = 0.0

        for _ in 0..<simulations {
            var sample = unseenCards.shuffled()
            let opponentCards = [sample.removeLast(), sample.removeLast()]
            let futureCards = (0..<cardsToCome).map { _ in sample.removeLast() }
            let completedCommunity = communityCards + futureCards

            guard let botHand = PokerHandEvaluator.bestHand(from: botCards + completedCommunity),
                  let opponentHand = PokerHandEvaluator.bestHand(from: opponentCards + completedCommunity) else {
                continue
            }

            let comparison = compareHands(botHand, opponentHand)
            if comparison > 0 {
                equity += 1
            } else if comparison == 0 {
                equity += 0.5
            }
        }

        return equity / Double(simulations)
    }

    private mutating func updatePlayerEquity() {
        playerEquity = equity(
            for: playerCards,
            communityCards: communityCards,
            simulations: 240
        )
    }

    private func equity(
        for heroCards: [PlayingCard],
        communityCards: [PlayingCard],
        simulations: Int
    ) -> PokerEquity? {
        guard heroCards.count == 2,
              communityCards.count <= 5,
              simulations > 0 else {
            return nil
        }

        let knownCards = Set(heroCards + communityCards)
        let unseenCards = PokerGame.makeDeck().filter { !knownCards.contains($0) }
        let cardsToCome = 5 - communityCards.count
        guard unseenCards.count >= 2 + cardsToCome else { return nil }

        var wins = 0
        var ties = 0
        var completedSimulations = 0

        for _ in 0..<simulations {
            var sample = unseenCards.shuffled()
            let opponentCards = [sample.removeLast(), sample.removeLast()]
            let futureCards = (0..<cardsToCome).map { _ in sample.removeLast() }
            let completedCommunity = communityCards + futureCards

            guard let heroHand = PokerHandEvaluator.bestHand(from: heroCards + completedCommunity),
                  let opponentHand = PokerHandEvaluator.bestHand(from: opponentCards + completedCommunity) else {
                continue
            }

            completedSimulations += 1
            let comparison = compareHands(heroHand, opponentHand)
            if comparison > 0 {
                wins += 1
            } else if comparison == 0 {
                ties += 1
            }
        }

        guard completedSimulations > 0 else { return nil }
        let total = Double(completedSimulations)
        return PokerEquity(
            winRate: Double(wins) / total,
            tieRate: Double(ties) / total
        )
    }

    private func botRaiseTarget(strength: Double) -> Int? {
        let maximum = botBetThisStreet + botChips
        let minimum = max(currentBet + PokerGame.bigBlind, PokerGame.bigBlind)
        guard maximum >= minimum else { return nil }

        let multiplier = strength > 0.82 ? 2.0 : 1.5
        let proposed = currentBet == 0 ? PokerGame.bigBlind : Int(Double(currentBet) * multiplier)
        return min(maximum, max(minimum, proposed))
    }

    private mutating func drawCard() -> PlayingCard {
        deck.removeLast()
    }

    private func compareTiebreakers(_ lhs: [Int], _ rhs: [Int]) -> Int {
        for (left, right) in zip(lhs, rhs) where left != right {
            return left > right ? 1 : -1
        }
        return lhs.count == rhs.count ? 0 : (lhs.count > rhs.count ? 1 : -1)
    }

    private func compareHands(_ lhs: PokerHand, _ rhs: PokerHand) -> Int {
        if lhs.category != rhs.category {
            return lhs.category > rhs.category ? 1 : -1
        }
        return compareTiebreakers(lhs.tiebreakers, rhs.tiebreakers)
    }

    private static func makeDeck() -> [PlayingCard] {
        PokerSuit.allCases.flatMap { suit in
            (2...14).map { rank in PlayingCard(suit: suit, rank: rank) }
        }
    }
}
