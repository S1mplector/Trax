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
    @State private var expensePendingDeletion: Expense?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            form
            recentExpenses
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
        .confirmationDialog(
            "Delete expense?",
            isPresented: Binding(
                get: { expensePendingDeletion != nil },
                set: { if $0 == false { expensePendingDeletion = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let expense = expensePendingDeletion {
                Button("Delete expense", role: .destructive) {
                    Task { await store.deleteExpense(id: expense.id) }
                }
            }
        } message: {
            if let expense = expensePendingDeletion {
                Text("This removes \(AppFormatters.currency(expense.amount, currencyCode: snapshot.settings.currencyCode)) from \(AppFormatters.shortDay(expense.day)).")
            }
        }
    }

    private var form: some View {
        PanelSection("Add expense", detail: "Logging spending clears a no-spend mark for that day.") {
            VStack(alignment: .leading, spacing: 10) {
                DatePicker("Day", selection: $date, displayedComponents: .date)

                TextField("Amount", text: $amount)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addExpense)

                Picker("Category", selection: $selectedCategoryID) {
                    Text("Pick category").tag(Optional<ExpenseCategory.ID>.none)
                    ForEach(snapshot.activeCategories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }

                TextField("Note", text: $note)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Today") {
                        date = Date()
                    }

                    Spacer()

                    Button("Add expense", action: addExpense)
                        .buttonStyle(.borderedProminent)
                        .disabled(canSubmitExpense == false)
                }
            }
        }
    }

    private var recentExpenses: some View {
        PanelSection("Latest expenses") {
            if snapshot.expenses.isEmpty {
                EmptyStateView(
                    title: "No expenses yet.",
                    message: "Log the first expense when you buy something."
                )
            } else {
                ForEach(snapshot.expenses.prefix(8)) { expense in
                    ExpenseRow(
                        expense: expense,
                        categoryName: store.categoryName(for: expense.categoryID),
                        categoryColorHex: store.categoryColor(for: expense.categoryID),
                        currencyCode: snapshot.settings.currencyCode
                    ) {
                        expensePendingDeletion = expense
                    }
                }
            }
        }
    }

    private var canSubmitExpense: Bool {
        AmountParser.decimal(from: amount).map { $0 > 0 } == true && selectedCategoryID != nil
    }

    private func addExpense() {
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
}

private struct ExpenseRow: View {
    let expense: Expense
    let categoryName: String
    let categoryColorHex: String
    let currencyCode: String
    let requestDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color(hex: categoryColorHex))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(.callout)
                Text(AppFormatters.shortDay(expense.day))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(AppFormatters.currency(expense.amount, currencyCode: currencyCode))
                .font(.callout.weight(.medium))

            Button(action: requestDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete expense")
        }
    }
}
