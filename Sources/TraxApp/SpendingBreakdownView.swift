import SwiftUI
import TraxApplication
import TraxDomain

struct SpendingBreakdownView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot
    let close: () -> Void
    @State private var selectedMode: SpendingBreakdownMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summary
            modePicker

            ScrollView {
                modeContent
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.trailing, 4)
            }
        }
        .padding(14)
        .frame(width: 420, height: 520, alignment: .topLeading)
        .onAppear {
            selectedMode = snapshot.settings.spendingBreakdownMode
        }
        .onChange(of: snapshot.settings.spendingBreakdownMode) { _, mode in
            selectedMode = mode
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Spending")
                    .font(.title2.weight(.semibold))
                Text("Month-to-date breakdown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 26, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help("Close")
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(AppFormatters.currency(snapshot.monthSummary.totalSpent, currencyCode: snapshot.settings.currencyCode))
                .font(.largeTitle.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(snapshot.monthSummary.spentDays) spent day\(snapshot.monthSummary.spentDays == 1 ? "" : "s") this month")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                SpendSplitCard(
                    title: "Essential",
                    amount: snapshot.monthSummary.essentialSpent,
                    currencyCode: snapshot.settings.currencyCode,
                    color: SpendKindColors.essential
                )
                SpendSplitCard(
                    title: "Non-essential",
                    amount: snapshot.monthSummary.nonEssentialSpent,
                    currencyCode: snapshot.settings.currencyCode,
                    color: SpendKindColors.nonEssential
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var modePicker: some View {
        Picker(
            "View",
            selection: Binding(
                get: { currentMode },
                set: { mode in
                    selectedMode = mode
                    Task { await store.updateSpendingBreakdownMode(mode) }
                }
            )
        ) {
            ForEach(SpendingBreakdownMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    @ViewBuilder
    private var modeContent: some View {
        switch currentMode {
        case .list:
            categoryList
        case .bars:
            categoryBars
        case .donut:
            categoryDonut
        }
    }

    private var categoryList: some View {
        PanelSection("Categories") {
            if snapshot.monthCategoryBreakdown.isEmpty {
                EmptyStateView(
                    title: "No spending this month.",
                    message: "Category totals will appear after logging expenses."
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(snapshot.monthCategoryBreakdown) { category in
                        CategoryBreakdownRow(
                            category: category,
                            currencyCode: snapshot.settings.currencyCode,
                            totalSpent: snapshot.monthSummary.totalSpent
                        )
                    }
                }
            }
        }
    }

    private var categoryBars: some View {
        PanelSection("Category bars") {
            if snapshot.monthCategoryBreakdown.isEmpty {
                EmptyStateView(
                    title: "No spending this month.",
                    message: "Bars will appear after logging expenses."
                )
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(snapshot.monthCategoryBreakdown) { category in
                        CategoryBarRow(
                            category: category,
                            currencyCode: snapshot.settings.currencyCode,
                            totalSpent: snapshot.monthSummary.totalSpent
                        )
                    }
                }
            }
        }
    }

    private var categoryDonut: some View {
        PanelSection("Category donut") {
            if snapshot.monthCategoryBreakdown.isEmpty {
                EmptyStateView(
                    title: "No spending this month.",
                    message: "The chart will appear after logging expenses."
                )
            } else {
                VStack(alignment: .center, spacing: 16) {
                    DonutChart(
                        categories: snapshot.monthCategoryBreakdown,
                        totalSpent: snapshot.monthSummary.totalSpent
                    )
                    .frame(width: 190, height: 190)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(snapshot.monthCategoryBreakdown) { category in
                            CategoryLegendRow(
                                category: category,
                                currencyCode: snapshot.settings.currencyCode,
                                totalSpent: snapshot.monthSummary.totalSpent
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var currentMode: SpendingBreakdownMode {
        selectedMode ?? snapshot.settings.spendingBreakdownMode
    }
}

private struct CategoryBreakdownRow: View {
    let category: CategorySpendingSummary
    let currencyCode: String
    let totalSpent: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Circle()
                    .fill(SpendKindColors.color(isEssential: category.isEssential))
                    .frame(width: 9, height: 9)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.categoryName)
                        .font(.callout.weight(.medium))
                    Text("\(category.expenseCount) expense\(category.expenseCount == 1 ? "" : "s") · \(SpendKindColors.label(isEssential: category.isEssential))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(AppFormatters.currency(category.totalSpent, currencyCode: currencyCode))
                    .font(.callout.weight(.semibold))
            }

            ProgressView(value: progress)
                .tint(SpendKindColors.color(isEssential: category.isEssential))
        }
    }

    private var progress: Double {
        let total = (totalSpent as NSDecimalNumber).doubleValue
        guard total > 0 else {
            return 0
        }

        let categoryTotal = (category.totalSpent as NSDecimalNumber).doubleValue
        return min(max(categoryTotal / total, 0), 1)
    }
}

private struct SpendSplitCard: View {
    let title: String
    let amount: Decimal
    let currencyCode: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(AppFormatters.currency(amount, currencyCode: currencyCode))
                .font(.callout.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct CategoryBarRow: View {
    let category: CategorySpendingSummary
    let currencyCode: String
    let totalSpent: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(category.categoryName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)

                Spacer()

                Text(AppFormatters.currency(category.totalSpent, currencyCode: currencyCode))
                    .font(.callout.weight(.semibold))
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                    Capsule()
                        .fill(SpendKindColors.color(isEssential: category.isEssential))
                        .frame(width: max(proxy.size.width * progress, 4))
                }
            }
            .frame(height: 12)

            Text("\(percentText) · \(SpendKindColors.label(isEssential: category.isEssential)) · \(category.expenseCount) expense\(category.expenseCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var progress: Double {
        let total = (totalSpent as NSDecimalNumber).doubleValue
        guard total > 0 else { return 0 }
        let categoryTotal = (category.totalSpent as NSDecimalNumber).doubleValue
        return min(max(categoryTotal / total, 0), 1)
    }

    private var percentText: String {
        "\(Int((progress * 100).rounded()))%"
    }
}

private struct CategoryLegendRow: View {
    let category: CategorySpendingSummary
    let currencyCode: String
    let totalSpent: Decimal

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(SpendKindColors.color(isEssential: category.isEssential))
                .frame(width: 9, height: 9)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.categoryName)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text("\(percentText) · \(SpendKindColors.label(isEssential: category.isEssential))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(AppFormatters.currency(category.totalSpent, currencyCode: currencyCode))
                .font(.callout.weight(.semibold))
        }
    }

    private var progress: Double {
        let total = (totalSpent as NSDecimalNumber).doubleValue
        guard total > 0 else { return 0 }
        let categoryTotal = (category.totalSpent as NSDecimalNumber).doubleValue
        return min(max(categoryTotal / total, 0), 1)
    }

    private var percentText: String {
        "\(Int((progress * 100).rounded()))%"
    }
}

private struct DonutChart: View {
    let categories: [CategorySpendingSummary]
    let totalSpent: Decimal

    var body: some View {
        ZStack {
            ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                DonutSegment(
                    startFraction: startFraction(for: index),
                    endFraction: endFraction(for: index),
                    lineWidth: 34
                )
                .fill(SpendKindColors.color(isEssential: category.isEssential).opacity(opacity(for: index)))
            }

            Circle()
                .fill(Color.primary.opacity(0.04))
                .frame(width: 104, height: 104)

            VStack(spacing: 2) {
                Text("\(categories.count)")
                    .font(.title2.weight(.semibold))
                Text("categories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var total: Double {
        (totalSpent as NSDecimalNumber).doubleValue
    }

    private func startFraction(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        let subtotal = categories.prefix(index).reduce(Double.zero) { result, category in
            result + (category.totalSpent as NSDecimalNumber).doubleValue
        }
        return subtotal / total
    }

    private func endFraction(for index: Int) -> Double {
        guard total > 0 else { return 0 }
        let subtotal = categories.prefix(index + 1).reduce(Double.zero) { result, category in
            result + (category.totalSpent as NSDecimalNumber).doubleValue
        }
        return subtotal / total
    }

    private func opacity(for index: Int) -> Double {
        1 - (Double(index % 3) * 0.12)
    }
}

private struct DonutSegment: Shape {
    let startFraction: Double
    let endFraction: Double
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let startAngle = Angle(degrees: (startFraction * 360) - 90)
        let endAngle = Angle(degrees: (endFraction * 360) - 90)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path.strokedPath(
            StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .round)
        )
    }
}

private extension SpendingBreakdownMode {
    var title: String {
        switch self {
        case .list:
            return "List"
        case .bars:
            return "Bars"
        case .donut:
            return "Donut"
        }
    }
}
