import SwiftUI

enum SaoleiPalette {
    static let background = Color(red: 0.95, green: 0.97, blue: 1.0)
    static let card = Color.white
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.22)
    static let mutedInk = Color(red: 0.38, green: 0.45, blue: 0.56)
    static let blue = Color(red: 0.22, green: 0.47, blue: 0.92)
    static let blueDeep = Color(red: 0.12, green: 0.31, blue: 0.72)
    static let mint = Color(red: 0.20, green: 0.72, blue: 0.58)
    static let sky = Color(red: 0.22, green: 0.62, blue: 0.92)
    static let orange = Color(red: 0.96, green: 0.53, blue: 0.22)
    static let purple = Color(red: 0.54, green: 0.39, blue: 0.89)
    static let hiddenCell = Color(red: 0.82, green: 0.88, blue: 0.96)
    static let revealedCell = Color(red: 0.97, green: 0.98, blue: 1.0)
}

struct ContentView: View {
    var body: some View {
        ZStack {
            SaoleiPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 24) {
                        selectionHeader

                        NavigationLink {
                            TetrisView()
                        } label: {
                            TetrisEntryCard()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: 900)

                        NavigationLink {
                            TwentyFourView()
                        } label: {
                            TwentyFourEntryCard()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: 900)

                        NavigationLink {
                            ChessView(difficulty: .beginner)
                        } label: {
                            ChessEntryCard()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: 900)

                        Text("选择国际象棋等级")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(SaoleiPalette.mutedInk)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: proxy.size.width > 700 ? 3 : 1),
                            spacing: 16
                        ) {
                            ForEach(ChessDifficulty.allCases) { difficulty in
                                NavigationLink {
                                    ChessView(difficulty: difficulty)
                                } label: {
                                    ChessDifficultyCard(difficulty: difficulty)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: 900)

                        NavigationLink {
                            PokerView(difficulty: .casual)
                        } label: {
                            PokerEntryCard()
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: 900)

                        Text("选择扫雷难度")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(SaoleiPalette.mutedInk)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: proxy.size.width > 700 ? 4 : 2),
                            spacing: 16
                        ) {
                            ForEach(GameDifficulty.allCases) { difficulty in
                                NavigationLink {
                                    GameView(difficulty: difficulty)
                                } label: {
                                    DifficultyCard(difficulty: difficulty)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: 900)

                        Text("选择德州扑克难度")
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(SaoleiPalette.mutedInk)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: proxy.size.width > 700 ? 3 : 1),
                            spacing: 16
                        ) {
                            ForEach(PokerDifficulty.allCases) { difficulty in
                                NavigationLink {
                                    PokerView(difficulty: difficulty)
                                } label: {
                                    PokerDifficultyCard(difficulty: difficulty)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: 900)

                        Text("扫雷、方块、算 24 点和牌桌，选一个开始挑战")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(SaoleiPalette.mutedInk)
                    }
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 24)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var selectionHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(SaoleiPalette.blue)
                    .frame(width: 82, height: 82)
                Text("💣")
                    .font(.system(size: 42))
            }

            Text("小小游戏乐园")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.ink)

            Text("动动脑筋，挑战扫雷、方块、算 24 点、国际象棋和德州扑克！")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)
        }
    }
}

private struct ChessEntryCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ChessPalette.gold.opacity(0.17))
                    .frame(width: 70, height: 70)
                Text("♔♞")
                    .font(.system(size: 31, design: .serif))
                    .foregroundStyle(ChessPalette.boardFrame)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("国际象棋")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("和电脑对弈，练习布局、战术与将军")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(ChessPalette.gold)
        }
        .padding(16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(ChessPalette.gold.opacity(0.40), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ChessPalette.gold.opacity(0.12), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("国际象棋，和电脑对弈，练习布局、战术与将军，开始游戏")
    }
}

private struct ChessDifficultyCard: View {
    let difficulty: ChessDifficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 14, height: 14)
                Text(difficulty.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
            }

            Text(difficulty.subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)
                .lineLimit(2)

            HStack {
                Text("开始对弈")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 21, weight: .bold))
            }
            .foregroundStyle(accentColor)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.28), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: ChessPalette.boardFrame.opacity(0.10), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("国际象棋等级：\(difficulty.title)，\(difficulty.subtitle)，开始对弈")
    }

    private var accentColor: Color {
        switch difficulty.accent {
        case .mint: return SaoleiPalette.mint
        case .sky: return SaoleiPalette.sky
        case .orange: return SaoleiPalette.orange
        case .purple: return SaoleiPalette.purple
        }
    }
}

private struct PokerEntryCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PokerPalette.felt.opacity(0.13))
                    .frame(width: 70, height: 70)
                Text("♠♥")
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(PokerPalette.felt)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("德州扑克")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("和机器人比牌，拼出最强的五张牌")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(PokerPalette.felt)
        }
        .padding(16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PokerPalette.felt.opacity(0.32), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PokerPalette.felt.opacity(0.11), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("德州扑克，和机器人比牌，拼出最强的五张牌，开始游戏")
    }
}

private struct PokerDifficultyCard: View {
    let difficulty: PokerDifficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 14, height: 14)
                Text(difficulty.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
            }

            Text(difficulty.subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)

            HStack {
                Text("开始对战")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 21, weight: .bold))
            }
            .foregroundStyle(accentColor)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.28), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: PokerPalette.felt.opacity(0.10), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("德州扑克难度：\(difficulty.title)，\(difficulty.subtitle)，开始对战")
    }

    private var accentColor: Color {
        switch difficulty.accent {
        case .mint: return SaoleiPalette.mint
        case .sky: return SaoleiPalette.sky
        case .orange: return SaoleiPalette.orange
        case .purple: return SaoleiPalette.purple
        }
    }
}

private struct TetrisEntryCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SaoleiPalette.purple.opacity(0.16))
                    .frame(width: 70, height: 70)
                Text("🧩")
                    .font(.system(size: 37))
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("俄罗斯方块")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("移动、旋转方块，拼满一行就消除")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(SaoleiPalette.purple)
        }
        .padding(16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SaoleiPalette.purple.opacity(0.32), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.purple.opacity(0.11), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("俄罗斯方块，移动、旋转方块，拼满一行就消除，开始游戏")
    }
}

private struct TwentyFourEntryCard: View {
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SaoleiPalette.orange.opacity(0.15))
                    .frame(width: 70, height: 70)
                Text("24")
                    .font(.system(size: 29, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.orange)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("算 24 点")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("用四个数字和四则运算，挑战算出 24")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 25, weight: .bold))
                .foregroundStyle(SaoleiPalette.orange)
        }
        .padding(16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SaoleiPalette.orange.opacity(0.34), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.orange.opacity(0.11), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("算 24 点，用四个数字和四则运算，挑战算出 24，开始游戏")
    }
}

private struct DifficultyCard: View {
    let difficulty: GameDifficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor)
                    .frame(width: 14, height: 14)
                Text(difficulty.title)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
            }

            Text(difficulty.subtitle)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(SaoleiPalette.mutedInk)

            HStack {
                Text("开始挑战")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 21, weight: .bold))
            }
            .foregroundStyle(accentColor)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.28), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.blue.opacity(0.10), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("难度：\(difficulty.title)，\(difficulty.subtitle)，开始挑战")
    }

    private var accentColor: Color {
        switch difficulty.accent {
        case .mint: return SaoleiPalette.mint
        case .sky: return SaoleiPalette.sky
        case .orange: return SaoleiPalette.orange
        case .purple: return SaoleiPalette.purple
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview("选择难度") {
    NavigationStack {
        ContentView()
    }
}
