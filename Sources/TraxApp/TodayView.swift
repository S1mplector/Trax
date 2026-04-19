import SwiftUI
import TraxApplication

struct TodayView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot
    let showSpendingBreakdown: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            todayStatus
            monthSummary
            recentDays
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
        PanelSection("This month") {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8)
                ],
                spacing: 8
            ) {
                MetricView(
                    title: "Spent",
                    value: AppFormatters.currency(snapshot.monthSummary.totalSpent, currencyCode: snapshot.settings.currencyCode),
                    action: showSpendingBreakdown
                )
                MetricView(title: "Spent days", value: "\(snapshot.monthSummary.spentDays)")
                MetricView(title: "No-spend days", value: "\(snapshot.monthSummary.noSpendDays)")
                MetricView(title: "Streak", value: "\(snapshot.monthSummary.currentNoSpendStreak)")
            }
        }
    }

    private var recentDays: some View {
        PanelSection("Recent days") {
            ForEach(snapshot.recentDays.prefix(7)) { day in
                HStack(spacing: 10) {
                    StatusDot(status: day.status)
                    Text(AppFormatters.shortDay(day.day))
                    Spacer()
                    Text(day.status == .spent ? AppFormatters.currency(day.totalSpent, currencyCode: snapshot.settings.currencyCode) : label(for: day.status))
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
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

    private func label(for status: DayStatus) -> String {
        switch status {
        case .spent:
            return "Spent"
        case .noSpend:
            return "No spend"
        case .unlogged:
            return "Unlogged"
        }
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
