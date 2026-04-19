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

                    PrimaryInlineButton(
                        title: "Add expense",
                        minWidth: 104,
                        isEnabled: canSubmitExpense,
                        action: addExpense
                    )
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
                        isEssential: store.categoryIsEssential(for: expense.categoryID),
                        currencyCode: snapshot.settings.currencyCode,
                        isPendingDeletion: expensePendingDeletion?.id == expense.id,
                        requestDelete: {
                            expensePendingDeletion = expense
                        },
                        confirmDelete: {
                            Task {
                                await store.deleteExpense(id: expense.id)
                                if store.errorMessage == nil {
                                    expensePendingDeletion = nil
                                }
                            }
                        },
                        cancelDelete: {
                            expensePendingDeletion = nil
                        }
                    )
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
    let isEssential: Bool
    let currencyCode: String
    let isPendingDeletion: Bool
    let requestDelete: () -> Void
    let confirmDelete: () -> Void
    let cancelDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row

            if isPendingDeletion {
                deleteConfirmation
            }
        }
        .padding(.vertical, 4)
    }

    private var row: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(SpendKindColors.color(isEssential: isEssential))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(categoryName)
                    .font(.callout)
                Text("\(AppFormatters.shortDay(expense.day)) · \(SpendKindColors.label(isEssential: isEssential))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(AppFormatters.currency(expense.amount, currencyCode: currencyCode))
                .font(.callout.weight(.medium))

            if isPendingDeletion == false {
                Button(action: requestDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Delete expense")
            }
        }
    }

    private var deleteConfirmation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delete expense?")
                .font(.caption.weight(.medium))

            Text("This removes \(AppFormatters.currency(expense.amount, currencyCode: currencyCode)) from \(AppFormatters.shortDay(expense.day)).")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Spacer()
                Button("Cancel", action: cancelDelete)
                    .controlSize(.small)
                ExpenseDeleteButton(title: "Delete", action: confirmDelete)
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.leading, 18)
    }
}

private struct ExpenseDeleteButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(minWidth: 54)
                .padding(.vertical, 5)
                .padding(.horizontal, 8)
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .background(Color.red.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .help(title)
    }
}
