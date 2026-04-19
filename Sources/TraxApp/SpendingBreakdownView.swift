import SwiftUI
import TraxApplication

struct SpendingBreakdownView: View {
    let snapshot: ExpenseBookSnapshot
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            summary
            categoryBreakdown
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(width: 420, height: 520, alignment: .topLeading)
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
        VStack(alignment: .leading, spacing: 6) {
            Text(AppFormatters.currency(snapshot.monthSummary.totalSpent, currencyCode: snapshot.settings.currencyCode))
                .font(.largeTitle.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("\(snapshot.monthSummary.spentDays) spent day\(snapshot.monthSummary.spentDays == 1 ? "" : "s") this month")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.primary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var categoryBreakdown: some View {
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
}

private struct CategoryBreakdownRow: View {
    let category: CategorySpendingSummary
    let currencyCode: String
    let totalSpent: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 9, height: 9)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.categoryName)
                        .font(.callout.weight(.medium))
                    Text("\(category.expenseCount) expense\(category.expenseCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(AppFormatters.currency(category.totalSpent, currencyCode: currencyCode))
                    .font(.callout.weight(.semibold))
            }

            ProgressView(value: progress)
                .tint(Color(hex: category.colorHex))
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
