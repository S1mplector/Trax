import SwiftUI
import TraxApplication
import TraxDomain

struct DayDetailView: View {
    let snapshot: ExpenseBookSnapshot
    let day: Day
    let showDay: (Day) -> Void
    let close: () -> Void

    @State private var selectedCategoryID: ExpenseCategory.ID?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summary
            expensesSection
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 420, height: 520, alignment: .topLeading)
        .onChange(of: day) { _, _ in
            selectedCategoryID = nil
        }
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

            HStack(spacing: 4) {
                Button {
                    showDay(day.addingDays(-1))
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 26, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Previous day")

                Button {
                    showDay(day.addingDays(1))
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 26, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help("Next day")

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
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusPill(
                    status: status,
                    spentColor: SpendKindColors.spentColor(for: dayExpenses, categories: snapshot.categories)
                )
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
        PanelSection("Expenses", detail: "Filter the day by category or step through adjacent days.") {
            VStack(alignment: .leading, spacing: 10) {
                if dayCategories.isEmpty == false {
                    Picker("Category", selection: $selectedCategoryID) {
                        Text("All categories").tag(Optional<ExpenseCategory.ID>.none)
                        ForEach(dayCategories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    .pickerStyle(.menu)
                }

                if dayExpenses.isEmpty {
                    EmptyStateView(
                        title: status == .noSpend ? "No-spend day." : "No expenses logged.",
                        message: status == .noSpend ? "This day was intentionally marked no-spend." : "Nothing has been logged for this day."
                    )
                } else if filteredExpenses.isEmpty {
                    EmptyStateView(
                        title: "No expenses match the filter.",
                        message: "Try another category or clear the filter."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(filteredExpenses) { expense in
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
    }

    private var dayExpenses: [Expense] {
        snapshot.expenses
            .filter { $0.day == day }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    private var filteredExpenses: [Expense] {
        guard let selectedCategoryID else {
            return dayExpenses
        }

        return dayExpenses.filter { $0.categoryID == selectedCategoryID }
    }

    private var dayCategories: [ExpenseCategory] {
        let dayCategoryIDs = Set(dayExpenses.map(\.categoryID))
        return snapshot.categories
            .filter { dayCategoryIDs.contains($0.id) }
            .sorted { lhs, rhs in
                lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
    }

    private var totalSpent: Decimal {
        dayExpenses.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var status: DayStatus {
        if dayExpenses.isEmpty == false {
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
            if let selectedCategoryID, let category = category(for: selectedCategoryID) {
                return "\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s") in \(category.name)."
            }

            return "\(dayExpenses.count) expense\(dayExpenses.count == 1 ? "" : "s") logged."
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
