import SwiftUI
import UIKit

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
                let isCompactLandscape = proxy.size.width > proxy.size.height && proxy.size.height < 500
                let columns = Array(
                    repeating: GridItem(.flexible(), spacing: isCompactLandscape ? 12 : 16),
                    count: isCompactLandscape ? 3 : 1
                )

                ScrollView {
                    VStack(spacing: isCompactLandscape ? 10 : 24) {
                        selectionHeader(isCompact: isCompactLandscape)

                        LazyVGrid(columns: columns, spacing: isCompactLandscape ? 12 : 16) {
                            NavigationLink {
                                TetrisView()
                            } label: {
                                TetrisEntryCard(isCompact: isCompactLandscape)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                TwentyFourView()
                            } label: {
                                TwentyFourEntryCard(isCompact: isCompactLandscape)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                MinesweeperDifficultySelectionView()
                            } label: {
                                MinesweeperEntryCard(isCompact: isCompactLandscape)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                GomokuDifficultySelectionView()
                            } label: {
                                GomokuEntryCard(isCompact: isCompactLandscape)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                ChessDifficultySelectionView()
                            } label: {
                                ChessEntryCard(isCompact: isCompactLandscape)
                            }
                            .buttonStyle(.plain)

                            NavigationLink {
                                PokerDifficultySelectionView()
                            } label: {
                                PokerEntryCard(isCompact: isCompactLandscape)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: 900)

                        Text("选择一个游戏开始挑战")
                            .font(.system(size: isCompactLandscape ? 13 : 16, weight: .medium, design: .rounded))
                            .foregroundStyle(SaoleiPalette.mutedInk)
                    }
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isCompactLandscape ? 12 : 24)
                    .padding(.vertical, isCompactLandscape ? 12 : 24)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private func selectionHeader(isCompact: Bool) -> some View {
        VStack(spacing: isCompact ? 6 : 12) {
            AppIconImage(size: isCompact ? 48 : 82)

            Text("小小游戏乐园")
                .font(.system(size: isCompact ? 30 : 42, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.ink)

            if !isCompact {
                Text("动动脑筋，挑战扫雷、方块、算 24 点、五子棋、国际象棋和德州扑克！")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }
        }
    }
}

private struct AppIconImage: View {
    let size: CGFloat

    init(size: CGFloat = 82) {
        self.size = size
    }

    var body: some View {
        if let imagePath = Bundle.main.path(forResource: "AppIcon60x60@2x", ofType: "png"),
           let uiImage = UIImage(contentsOfFile: imagePath) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel("应用图标")
        } else {
            Color.clear
                .frame(width: size, height: size)
                .accessibilityLabel("应用图标")
        }
    }
}

private struct DifficultySelectionView<Content: View>: View {
    let gameTitle: String
    let icon: String
    let subtitle: String
    let wideColumnCount: Int
    let narrowColumnCount: Int
    let content: () -> Content

    init(
        gameTitle: String,
        icon: String,
        subtitle: String,
        wideColumnCount: Int,
        narrowColumnCount: Int,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.gameTitle = gameTitle
        self.icon = icon
        self.subtitle = subtitle
        self.wideColumnCount = wideColumnCount
        self.narrowColumnCount = narrowColumnCount
        self.content = content
    }

    var body: some View {
        ZStack {
            SaoleiPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height

                ScrollView {
                    VStack(spacing: isLandscape ? 12 : 24) {
                        VStack(spacing: isLandscape ? 6 : 12) {
                            Text(icon)
                                .font(.system(size: isLandscape ? 32 : 42))

                            Text("选择\(gameTitle)难度")
                                .font(.system(size: isLandscape ? 26 : 30, weight: .black, design: .rounded))
                                .foregroundStyle(SaoleiPalette.ink)

                            Text(subtitle)
                                .font(.system(size: isLandscape ? 15 : 17, weight: .medium, design: .rounded))
                                .foregroundStyle(SaoleiPalette.mutedInk)
                        }
                        .multilineTextAlignment(.center)

                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: 16),
                                count: proxy.size.width > 700 ? wideColumnCount : narrowColumnCount
                            ),
                            spacing: isLandscape ? 12 : 16,
                            content: content
                        )
                        .frame(maxWidth: 900)
                    }
                    .frame(maxWidth: 900)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isLandscape ? 16 : 24)
                    .padding(.top, isLandscape ? 8 : 24)
                    .padding(.bottom, isLandscape ? 16 : 24)
                }
            }
        }
        .navigationTitle("选择难度")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MinesweeperDifficultySelectionView: View {
    var body: some View {
        DifficultySelectionView(
            gameTitle: "扫雷",
            icon: "💣",
            subtitle: "选择棋盘大小和地雷数量，开始挑战",
            wideColumnCount: 4,
            narrowColumnCount: 2
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
    }
}

private struct GomokuDifficultySelectionView: View {
    var body: some View {
        DifficultySelectionView(
            gameTitle: "五子棋",
            icon: "●○",
            subtitle: "选择电脑强度，开始对弈",
            wideColumnCount: 3,
            narrowColumnCount: 1
        ) {
            ForEach(GomokuDifficulty.allCases) { difficulty in
                NavigationLink {
                    GomokuView(difficulty: difficulty)
                } label: {
                    GomokuDifficultyCard(difficulty: difficulty)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ChessDifficultySelectionView: View {
    var body: some View {
        DifficultySelectionView(
            gameTitle: "国际象棋",
            icon: "♔♞",
            subtitle: "选择电脑等级，开始对弈",
            wideColumnCount: 3,
            narrowColumnCount: 1
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
    }
}

private struct PokerDifficultySelectionView: View {
    var body: some View {
        DifficultySelectionView(
            gameTitle: "德州扑克",
            icon: "♠♥",
            subtitle: "选择机器人难度，开始对战",
            wideColumnCount: 3,
            narrowColumnCount: 1
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
    }
}

private struct MinesweeperEntryCard: View {
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SaoleiPalette.blue.opacity(0.13))
                    .frame(width: isCompact ? 48 : 70, height: isCompact ? 48 : 70)
                Text("💣")
                    .font(.system(size: isCompact ? 27 : 37))
            }

            VStack(alignment: .leading, spacing: isCompact ? 0 : 5) {
                Text("扫雷")
                    .font(.system(size: isCompact ? 17 : 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                if !isCompact {
                    Text("找出所有安全格，避开隐藏的地雷")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: isCompact ? 20 : 25, weight: .bold))
                .foregroundStyle(SaoleiPalette.blue)
        }
        .padding(isCompact ? 10 : 16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(SaoleiPalette.blue.opacity(0.32), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.blue.opacity(0.11), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("扫雷，找出所有安全格，避开隐藏的地雷，选择难度")
    }
}

private struct GomokuEntryCard: View {
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(GomokuPalette.board.opacity(0.25))
                    .frame(width: isCompact ? 48 : 70, height: isCompact ? 48 : 70)
                Text("●○")
                    .font(.system(size: isCompact ? 23 : 29, weight: .black, design: .rounded))
                    .foregroundStyle(GomokuPalette.boardFrame)
            }

            VStack(alignment: .leading, spacing: isCompact ? 0 : 5) {
                Text("五子棋")
                    .font(.system(size: isCompact ? 17 : 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                if !isCompact {
                    Text("黑方先手，连成五子，挑战不同强度的电脑")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: isCompact ? 20 : 25, weight: .bold))
                .foregroundStyle(GomokuPalette.boardFrame)
        }
        .padding(isCompact ? 10 : 16)
        .background(SaoleiPalette.card)
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(GomokuPalette.board.opacity(0.72), lineWidth: 2)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: GomokuPalette.boardFrame.opacity(0.11), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("五子棋，黑方先手，连成五子，挑战不同强度的电脑，开始游戏")
    }
}

private struct GomokuDifficultyCard: View {
    let difficulty: GomokuDifficulty

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
        .shadow(color: GomokuPalette.boardFrame.opacity(0.10), radius: 12, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("五子棋难度：\(difficulty.title)，\(difficulty.subtitle)，开始对弈")
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

private struct ChessEntryCard: View {
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(ChessPalette.gold.opacity(0.17))
                    .frame(width: isCompact ? 48 : 70, height: isCompact ? 48 : 70)
                Text("♔♞")
                    .font(.system(size: isCompact ? 24 : 31, design: .serif))
                    .foregroundStyle(ChessPalette.boardFrame)
            }

            VStack(alignment: .leading, spacing: isCompact ? 0 : 5) {
                Text("国际象棋")
                    .font(.system(size: isCompact ? 17 : 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                if !isCompact {
                    Text("和电脑对弈，练习布局、战术与将军")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: isCompact ? 20 : 25, weight: .bold))
                .foregroundStyle(ChessPalette.gold)
        }
        .padding(isCompact ? 10 : 16)
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
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(PokerPalette.felt.opacity(0.13))
                    .frame(width: isCompact ? 48 : 70, height: isCompact ? 48 : 70)
                Text("♠♥")
                    .font(.system(size: isCompact ? 21 : 27, weight: .black, design: .rounded))
                    .foregroundStyle(PokerPalette.felt)
            }

            VStack(alignment: .leading, spacing: isCompact ? 0 : 5) {
                Text("德州扑克")
                    .font(.system(size: isCompact ? 17 : 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                if !isCompact {
                    Text("和机器人比牌，拼出最强的五张牌")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: isCompact ? 20 : 25, weight: .bold))
                .foregroundStyle(PokerPalette.felt)
        }
        .padding(isCompact ? 10 : 16)
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
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SaoleiPalette.purple.opacity(0.16))
                    .frame(width: isCompact ? 48 : 70, height: isCompact ? 48 : 70)
                Text("🧩")
                    .font(.system(size: isCompact ? 27 : 37))
            }

            VStack(alignment: .leading, spacing: isCompact ? 0 : 5) {
                Text("俄罗斯方块")
                    .font(.system(size: isCompact ? 17 : 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                if !isCompact {
                    Text("移动、旋转方块，拼满一行就消除")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: isCompact ? 20 : 25, weight: .bold))
                .foregroundStyle(SaoleiPalette.purple)
        }
        .padding(isCompact ? 10 : 16)
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
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 8 : 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(SaoleiPalette.orange.opacity(0.15))
                    .frame(width: isCompact ? 48 : 70, height: isCompact ? 48 : 70)
                Text("24")
                    .font(.system(size: isCompact ? 23 : 29, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.orange)
            }

            VStack(alignment: .leading, spacing: isCompact ? 0 : 5) {
                Text("算 24 点")
                    .font(.system(size: isCompact ? 17 : 21, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)

                if !isCompact {
                    Text("用四个数字和四则运算，挑战算出 24")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: isCompact ? 20 : 25, weight: .bold))
                .foregroundStyle(SaoleiPalette.orange)
        }
        .padding(isCompact ? 10 : 16)
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

#Preview("游戏列表") {
    NavigationStack {
        ContentView()
    }
}
