import SwiftUI
import TraxApplication
import TraxDomain

struct ExpenseEntryView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot

    @State private var date = Date()
    @State private var amount = ""
    @State private var selectedCategoryID: ExpenseCategory.ID?
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            form
            recentExpenses
            Spacer(minLength: 0)
        }
        .onAppear {
            selectedCategoryID = selectedCategoryID ?? snapshot.activeCategories.first?.id
        }
        .onChange(of: snapshot.activeCategories) { _, categories in
            guard let selectedCategoryID else {
                self.selectedCategoryID = categories.first?.id
                return
            }

            if categories.contains(where: { $0.id == selectedCategoryID }) == false {
                self.selectedCategoryID = categories.first?.id
            }
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 10) {
            DatePicker("Day", selection: $date, displayedComponents: .date)

            TextField("Amount", text: $amount)
                .textFieldStyle(.roundedBorder)

            Picker("Category", selection: $selectedCategoryID) {
                Text("Pick category").tag(Optional<ExpenseCategory.ID>.none)
                ForEach(snapshot.activeCategories) { category in
                    Text(category.name).tag(Optional(category.id))
                }
            }

            TextField("Note", text: $note)
                .textFieldStyle(.roundedBorder)

            Button("Add expense") {
                Task {
                    await store.addExpense(
                        date: date,
                        amountText: amount,
                        categoryID: selectedCategoryID,
                        note: note
                    )
                    if store.errorMessage == nil {
                        amount = ""
                        note = ""
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(snapshot.activeCategories.isEmpty)
        }
    }

    private var recentExpenses: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Latest expenses")
                .font(.headline)

            if snapshot.expenses.isEmpty {
                Text("No expenses yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.expenses.prefix(8)) { expense in
                    ExpenseRow(expense: expense)
                }
            }
        }
    }
}

private struct ExpenseRow: View {
    @EnvironmentObject private var store: ExpenseStore
    let expense: Expense

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: store.categoryColor(for: expense.categoryID)))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(store.categoryName(for: expense.categoryID))
                    .font(.callout)
                Text(AppFormatters.shortDay(expense.day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(AppFormatters.currency(expense.amount))
                .font(.callout.weight(.medium))

            Button {
                Task { await store.deleteExpense(id: expense.id) }
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete expense")
        }
    }
}
