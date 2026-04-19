import SwiftUI
import TraxApplication
import TraxDomain

struct DayDetailView: View {
    let snapshot: ExpenseBookSnapshot
    let day: Day
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summary
            expensesSection
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 420, height: 520, alignment: .topLeading)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(AppFormatters.day(day))
                    .font(.title2.weight(.semibold))
                Text("Daily log")
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
            HStack {
                StatusPill(status: status)
                Spacer()
                Text(AppFormatters.currency(totalSpent, currencyCode: snapshot.settings.currencyCode))
                    .font(.title3.weight(.semibold))
            }

            Text(summaryText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var expensesSection: some View {
        PanelSection("Expenses") {
            if expenses.isEmpty {
                EmptyStateView(
                    title: status == .noSpend ? "No-spend day." : "No expenses logged.",
                    message: status == .noSpend ? "This day was intentionally marked no-spend." : "Nothing has been logged for this day."
                )
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(expenses) { expense in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(SpendKindColors.color(isEssential: category(for: expense.categoryID)?.isEssential ?? false))
                                .frame(width: 9, height: 9)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(category(for: expense.categoryID)?.name ?? "Unknown")
                                    .font(.callout.weight(.medium))
                                Text(detailText(for: expense))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(AppFormatters.currency(expense.amount, currencyCode: snapshot.settings.currencyCode))
                                .font(.callout.weight(.semibold))
                        }
                    }
                }
            }
        }
    }

    private var expenses: [Expense] {
        snapshot.expenses
            .filter { $0.day == day }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    private var totalSpent: Decimal {
        expenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var status: DayStatus {
        if expenses.isEmpty == false {
            return .spent
        }

        if snapshot.dailyLogs.contains(where: { $0.day == day && $0.spentNothing }) {
            return .noSpend
        }

        return .unlogged
    }

    private var summaryText: String {
        switch status {
        case .spent:
            return "\(expenses.count) expense\(expenses.count == 1 ? "" : "s") logged."
        case .noSpend:
            return "Marked as no-spend."
        case .unlogged:
            return "No log for this day yet."
        }
    }

    private func category(for id: ExpenseCategory.ID) -> ExpenseCategory? {
        snapshot.categories.first { $0.id == id }
    }

    private func detailText(for expense: Expense) -> String {
        let category = category(for: expense.categoryID)
        let spendKind = SpendKindColors.label(isEssential: category?.isEssential ?? false)
        guard expense.note.isEmpty == false else {
            return spendKind
        }

        return "\(spendKind) · \(expense.note)"
    }
}
