import SwiftUI
import TraxApplication
import TraxDomain

struct TodayView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot
    let showSpendingBreakdown: () -> Void
    let showDayDetail: (Day) -> Void
    @State private var heatmapDate = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            todayStatus
            monthSummary
            heatmap
        }
    }

    private var todayStatus: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusPill(status: snapshot.today.status)
                Spacer()
                Text(AppFormatters.currency(snapshot.today.totalSpent, currencyCode: snapshot.settings.currencyCode))
                    .font(.title3.weight(.semibold))
            }

            Text(todayMessage)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack {
                Button("No spend today") {
                    Task { await store.markTodayNoSpend() }
                }
                .disabled(snapshot.today.status != .unlogged)

                if snapshot.today.status == .noSpend {
                    Button("Clear") {
                        Task { await store.clearTodayCheckIn() }
                    }
                }
            }
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var monthSummary: some View {
        MetricView(
            title: "Spent this month",
            value: AppFormatters.currency(snapshot.monthSummary.totalSpent, currencyCode: snapshot.settings.currencyCode),
            action: showSpendingBreakdown
        )
    }

    private var heatmap: some View {
        PanelSection("Calendar") {
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("Month", selection: $heatmapDate, displayedComponents: .date)
                    .controlSize(.small)

                HStack(spacing: HeatmapLayout.cellSpacing) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: HeatmapLayout.cellWidth)
                    }
                }

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(HeatmapLayout.cellWidth), spacing: HeatmapLayout.cellSpacing),
                        count: 7
                    ),
                    spacing: HeatmapLayout.rowSpacing
                ) {
                    ForEach(heatmapEntries) { entry in
                        if let day = entry.day {
                            HeatmapDayButton(
                                summary: summary(for: day),
                                currencyCode: snapshot.settings.currencyCode,
                                isToday: day == Day(date: Date())
                            ) {
                                showDayDetail(day)
                            }
                        } else {
                            Color.clear
                                .frame(width: HeatmapLayout.cellWidth, height: HeatmapLayout.cellHeight)
                        }
                    }
                }

                HStack(spacing: 10) {
                    HeatmapLegendItem(color: .green, label: "No-spend")
                    HeatmapLegendItem(color: .red, label: "Spent")
                    HeatmapLegendItem(color: Color.primary.opacity(0.16), label: "Unlogged")
                }
            }
        }
    }

    private var todayMessage: String {
        switch snapshot.today.status {
        case .spent:
            return "Logged \(snapshot.today.expenseCount) expense\(snapshot.today.expenseCount == 1 ? "" : "s") today."
        case .noSpend:
            return "No-spend day logged."
        case .unlogged:
            return "Log an expense or mark today as no-spend."
        }
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? []
        let firstWeekday = Calendar.current.firstWeekday - 1
        return Array(symbols[firstWeekday...] + symbols[..<firstWeekday]).map { String($0.prefix(2)) }
    }

    private var heatmapEntries: [HeatmapEntry] {
        let calendar = Calendar.current
        let selectedDay = Day(date: heatmapDate, calendar: calendar)
        let firstDay = Day(year: selectedDay.year, month: selectedDay.month, day: 1)
        let firstDate = firstDay.date(calendar: calendar)
        let dayRange = calendar.range(of: .day, in: .month, for: firstDate) ?? 1..<2
        let weekday = calendar.component(.weekday, from: firstDate)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7
        let days = dayRange.map { Day(year: selectedDay.year, month: selectedDay.month, day: $0) }

        return (0..<leadingBlanks).map { HeatmapEntry(index: "blank-\($0)", day: nil) }
            + days.map { HeatmapEntry(index: $0.id, day: $0) }
    }

    private func summary(for day: Day) -> HeatmapDaySummary {
        let expenses = snapshot.expenses.filter { $0.day == day }
        let totalSpent = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let log = snapshot.dailyLogs.first { $0.day == day }
        let status: DayStatus

        if expenses.isEmpty == false {
            status = .spent
        } else if log?.spentNothing == true {
            status = .noSpend
        } else {
            status = .unlogged
        }

        return HeatmapDaySummary(
            day: day,
            totalSpent: totalSpent,
            expenseCount: expenses.count,
            status: status
        )
    }
}

private struct MetricView: View {
    let title: String
    let value: String
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 4)

                if let action {
                    Button(action: action) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 11, weight: .semibold))
                            .frame(width: 20, height: 18)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .help("Show spending breakdown")
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HeatmapEntry: Identifiable {
    let index: String
    let day: Day?

    var id: String { index }
}

private struct HeatmapDaySummary {
    let day: Day
    let totalSpent: Decimal
    let expenseCount: Int
    let status: DayStatus
}

private enum HeatmapLayout {
    static let cellWidth: CGFloat = 40
    static let cellHeight: CGFloat = 26
    static let cellSpacing: CGFloat = 5
    static let rowSpacing: CGFloat = 5
}

private struct HeatmapDayButton: View {
    let summary: HeatmapDaySummary
    let currencyCode: String
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(verbatim: "\(summary.day.day)")
                    .font(.system(size: 12, weight: .semibold))
                    .monospacedDigit()
                    .lineLimit(1)
                    .foregroundStyle(foregroundColor)

                Circle()
                    .fill(indicatorColor)
                    .frame(width: 4, height: 4)
            }
            .frame(width: HeatmapLayout.cellWidth, height: HeatmapLayout.cellHeight)
            .background(backgroundColor)
            .overlay {
                RoundedRectangle(cornerRadius: 7)
                    .stroke(isToday ? Color.accentColor : Color.clear, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .help(helpText)
    }

    private var backgroundColor: Color {
        switch summary.status {
        case .spent:
            return .red.opacity(0.74)
        case .noSpend:
            return .green.opacity(0.68)
        case .unlogged:
            return Color.primary.opacity(0.08)
        }
    }

    private var foregroundColor: Color {
        switch summary.status {
        case .spent, .noSpend:
            return .white
        case .unlogged:
            return .primary
        }
    }

    private var indicatorColor: Color {
        switch summary.status {
        case .spent, .noSpend:
            return .white.opacity(0.82)
        case .unlogged:
            return .secondary.opacity(0.55)
        }
    }

    private var helpText: String {
        switch summary.status {
        case .spent:
            return "\(AppFormatters.day(summary.day)): \(AppFormatters.currency(summary.totalSpent, currencyCode: currencyCode))"
        case .noSpend:
            return "\(AppFormatters.day(summary.day)): no spend"
        case .unlogged:
            return "\(AppFormatters.day(summary.day)): unlogged"
        }
    }
}

private struct HeatmapLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 9, height: 9)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}
