import SwiftUI
import UIKit

struct TwentyFourView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var game = TwentyFourGame()
    @State private var firstSelection: Int?
    @State private var selectedOperation: TwentyFourOperation?
    @State private var errorMessage: String?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            SaoleiPalette.background.ignoresSafeArea()

            GeometryReader { proxy in
                if usesIPadLayout(for: proxy.size) {
                    ScrollView {
                        iPadLayout
                    }
                } else if proxy.size.width > proxy.size.height {
                    landscapePhoneLayout(in: proxy)
                } else {
                    ScrollView {
                        phoneLayout
                    }
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(timer) { _ in
            game.tick()
        }
    }

    private var phoneLayout: some View {
        VStack(spacing: 16) {
            gameHeader
            statusCard
            numbersCard()
            operationCard()

            if !game.steps.isEmpty {
                stepsCard()
            }

            rulesCard
            answerSection
        }
        .frame(maxWidth: 720)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }

    private func landscapePhoneLayout(in proxy: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 12
        let verticalPadding: CGFloat = 4
        let contentSpacing: CGFloat = 8
        let availableWidth = max(1, proxy.size.width - horizontalPadding * 2)
        let sidebarWidth = min(250, max(220, availableWidth * 0.28))
        let primaryWidth = max(1, availableWidth - sidebarWidth - contentSpacing)

        return VStack(spacing: 4) {
            phoneLandscapeHeader

            HStack(alignment: .top, spacing: contentSpacing) {
                VStack(spacing: 6) {
                    numbersCard(compact: true)
                        .frame(maxWidth: .infinity)
                    operationCard(compact: true)
                        .frame(maxWidth: .infinity)

                    if !game.steps.isEmpty {
                        stepsCard(compact: true)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(width: primaryWidth, alignment: .top)

                VStack(spacing: 8) {
                    statusCard
                        .frame(maxWidth: .infinity)
                    answerSection
                        .frame(maxWidth: .infinity)
                }
                .frame(width: sidebarWidth, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: 1_100, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .navigationBarHidden(true)
    }

    private var phoneLandscapeHeader: some View {
        HStack(spacing: 7) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(SaoleiPalette.ink)
                    .frame(width: 28, height: 28)
                    .background(SaoleiPalette.card)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .frame(width: 36, height: 36)
            .accessibilityLabel("返回")

            VStack(alignment: .leading, spacing: 0) {
                Text("算 24 点")
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("一步一步合并数字，算出 24")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.orange)
            }

            Spacer(minLength: 4)

            Text(statusTitle)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(statusTint)
                .lineLimit(1)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.72)
        .padding(.horizontal, 4)
        .frame(height: 36)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func usesIPadLayout(for size: CGSize) -> Bool {
        horizontalSizeClass == .regular || (size.width >= 700 && size.height >= 600)
    }

    private var iPadLayout: some View {
        VStack(spacing: 14) {
            gameHeader

            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 14) {
                    statusCard
                    numbersCard()
                    operationCard()

                    if !game.steps.isEmpty {
                        stepsCard()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack(spacing: 14) {
                    rulesCard
                    answerSection
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .frame(maxWidth: 1100)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var gameHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("算 24 点")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("一步一步合并数字，算出 24")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }

            Spacer(minLength: 0)

            Button {
                newRound()
            } label: {
                Label("下一题", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.orange)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(SaoleiPalette.card)
                    .clipShape(Capsule())
                    .shadow(color: SaoleiPalette.orange.opacity(0.12), radius: 8, y: 4)
            }
            .accessibilityIdentifier("twentyFourNextButton")
        }
    }

    private var statusCard: some View {
        HStack(spacing: 12) {
            Image(systemName: statusSymbol)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(statusTint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(statusTitle)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text(interactionHint)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: SaoleiPalette.orange.opacity(0.10), radius: 12, y: 6)
    }

    private func numbersCard(compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 14) {
            HStack {
                Text(game.isComplete ? "最终结果" : "本题数字")
                    .font(.system(size: compact ? 18 : 20, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Spacer()
                Text(game.isComplete ? "可以回退检查" : "每个数字用一次")
                    .font(.system(size: compact ? 11 : 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            HStack(spacing: compact ? 6 : 10) {
                ForEach(Array(game.items.enumerated()), id: \.element.id) { index, item in
                    CalculatorNumberCard(
                        item: item,
                        isSelected: firstSelection == index,
                        compact: compact,
                        action: { selectNumber(at: index) }
                    )
                }
            }
        }
        .padding(compact ? 10 : 18)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.orange.opacity(0.10), radius: 12, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("当前数字：\(game.items.map(\.displayText).joined(separator: "、"))")
    }

    private func operationCard(compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 14) {
            HStack {
                Text("选择运算")
                    .font(.system(size: compact ? 18 : 20, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Spacer()
                Button {
                    undoLastStep()
                } label: {
                    Label("回退一步", systemImage: "arrow.uturn.backward")
                        .font(.system(size: compact ? 11 : 14, weight: .bold, design: .rounded))
                        .foregroundStyle(game.canUndo ? SaoleiPalette.blueDeep : SaoleiPalette.mutedInk)
                }
                .disabled(!game.canUndo)
                .accessibilityIdentifier("twentyFourUndoButton")
            }

            HStack(spacing: compact ? 6 : 10) {
                ForEach(TwentyFourOperation.allCases) { operation in
                    OperationButton(
                        operation: operation,
                        isSelected: selectedOperation == operation,
                        isEnabled: firstSelection != nil && !game.isComplete,
                        compact: compact,
                        action: { selectOperation(operation) }
                    )
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: compact ? 11 : 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.orange)
                    .fixedSize(horizontal: false, vertical: true)
            } else if !compact {
                Label(interactionHint, systemImage: selectedOperation == nil ? "hand.tap.fill" : "arrow.right")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }
        }
        .padding(compact ? 10 : 18)
        .background(SaoleiPalette.card)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SaoleiPalette.orange.opacity(0.10), radius: 12, y: 6)
    }

    private func stepsCard(compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 5 : 11) {
            Label("你的计算过程", systemImage: "list.number")
                .font(.system(size: compact ? 15 : 18, weight: .black, design: .rounded))
                .foregroundStyle(SaoleiPalette.blueDeep)

            ForEach(Array(game.steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: compact ? 7 : 10) {
                    Text("\(index + 1)")
                        .font(.system(size: compact ? 11 : 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(width: compact ? 19 : 23, height: compact ? 19 : 23)
                        .background(SaoleiPalette.blue)
                        .clipShape(Circle())

                    Text(step)
                        .font(.system(size: compact ? 13 : 16, weight: .bold, design: .rounded))
                        .foregroundStyle(SaoleiPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 10 : 18)
        .background(SaoleiPalette.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var rulesCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(SaoleiPalette.orange)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("操作方法")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                Text("点击第一个数字 → 选择加减乘除 → 点击另一个数字。两个数字会合并成一个结果，继续操作直到只剩一个数。")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(SaoleiPalette.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var answerSection: some View {
        if game.answerIsVisible {
            VStack(alignment: .leading, spacing: 10) {
                Label("参考答案", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mint)

                Text(game.answer)
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(SaoleiPalette.ink)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .minimumScaleFactor(0.65)
                    .lineLimit(2)
                    .padding(.vertical, 8)

                Text("每个数字都使用了一次，结果等于 24")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(SaoleiPalette.mutedInk)
            }
            .padding(18)
            .background(SaoleiPalette.mint.opacity(0.12))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SaoleiPalette.mint.opacity(0.32), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("参考答案：\(game.answer)。每个数字都使用了一次，结果等于 24")
        } else if game.answerAvailable {
            Button {
                game.revealAnswer()
                fireSuccess()
            } label: {
                Label("显示参考答案", systemImage: "lightbulb.fill")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(SaoleiPalette.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: SaoleiPalette.orange.opacity(0.25), radius: 10, y: 5)
            }
            .accessibilityIdentifier("twentyFourRevealAnswerButton")
        } else {
            HStack(spacing: 11) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(SaoleiPalette.mutedInk)
                VStack(alignment: .leading, spacing: 3) {
                    Text("参考答案将在稍后显示")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(SaoleiPalette.ink)
                    Text("先自己思考一下，答案会在稍后解锁")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(SaoleiPalette.card)
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(SaoleiPalette.orange.opacity(0.24), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private var statusTitle: String {
        if game.isCorrect { return "太棒了，正好是 24！" }
        if game.isComplete { return "还不是 24，可以回退" }
        if selectedOperation != nil { return "请选择第二个数字" }
        if firstSelection != nil { return "请选择一个运算符" }
        return "准备开始计算"
    }

    private var interactionHint: String {
        if game.isComplete {
            return game.isCorrect ? "你可以开始下一题" : "点击回退一步，修改刚才的公式"
        }
        if selectedOperation != nil { return "现在点击另一个数字完成合并" }
        if firstSelection != nil { return "接下来选择 +、−、× 或 ÷" }
        return "先点击一个数字"
    }

    private var statusSymbol: String {
        if game.isCorrect { return "checkmark.seal.fill" }
        if game.isComplete { return "arrow.uturn.backward.circle.fill" }
        if selectedOperation != nil { return "arrow.right.circle.fill" }
        return firstSelection == nil ? "brain.head.profile" : "function" 
    }

    private var statusTint: Color {
        if game.isCorrect { return SaoleiPalette.mint }
        if game.isComplete { return SaoleiPalette.orange }
        return firstSelection == nil ? SaoleiPalette.blue : SaoleiPalette.orange
    }

    private func selectNumber(at index: Int) {
        guard !game.isComplete else { return }
        errorMessage = nil

        if let firstIndex = firstSelection, let operation = selectedOperation {
            guard firstIndex != index else { return }

            if let resultIndex = game.apply(operation, firstIndex: firstIndex, secondIndex: index) {
                firstSelection = resultIndex
                selectedOperation = nil
                fireImpact()
            } else {
                selectedOperation = nil
                errorMessage = "除数不能为 0，请重新选择运算和数字"
                fireError()
            }
        } else if selectedOperation == nil {
            firstSelection = firstSelection == index ? nil : index
            fireImpact()
        }
    }

    private func selectOperation(_ operation: TwentyFourOperation) {
        guard firstSelection != nil, !game.isComplete else { return }
        errorMessage = nil
        selectedOperation = operation
        fireImpact()
    }

    private func undoLastStep() {
        game.undo()
        firstSelection = game.preferredSelectionIndex
        selectedOperation = nil
        errorMessage = nil
        fireImpact()
    }

    private func newRound() {
        game.reset()
        firstSelection = nil
        selectedOperation = nil
        errorMessage = nil
        fireImpact()
    }

    private func fireImpact() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func fireError() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    private func fireSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

private struct CalculatorNumberCard: View {
    let item: TwentyFourItem
    let isSelected: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(item.displayText)
                    .font(.system(size: compact ? 26 : 34, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? SaoleiPalette.blueDeep : SaoleiPalette.orange)
                    .minimumScaleFactor(0.60)
                    .lineLimit(1)

                if item.isCalculated {
                    Text(item.expression)
                        .font(.system(size: compact ? 9 : 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(SaoleiPalette.mutedInk)
                        .lineLimit(2)
                        .minimumScaleFactor(0.55)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 64 : 112)
            .background(isSelected ? SaoleiPalette.blue.opacity(0.13) : SaoleiPalette.orange.opacity(0.11))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected ? SaoleiPalette.blue : SaoleiPalette.orange.opacity(0.28),
                        lineWidth: 2
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("数字 \(item.displayText)")
        .accessibilityHint(isSelected ? "已选择，继续选择运算" : "点击选择这个数字")
    }
}

private struct OperationButton: View {
    let operation: TwentyFourOperation
    let isSelected: Bool
    let isEnabled: Bool
    let compact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(operation.symbol)
                .font(.system(size: compact ? 22 : 27, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : SaoleiPalette.orange)
                .frame(maxWidth: .infinity)
                .frame(height: compact ? 42 : 54)
                .background(isSelected ? SaoleiPalette.orange : SaoleiPalette.orange.opacity(0.10))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(SaoleiPalette.orange.opacity(isEnabled ? 0.35 : 0.14), lineWidth: 2)
                }
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel("选择运算符 \(operation.symbol)")
    }
}

#Preview("算 24 点") {
    NavigationStack {
        TwentyFourView()
    }
}
