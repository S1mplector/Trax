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
    @State private var editingExpense: Expense?
    @State private var selectedFilterCategoryID: ExpenseCategory.ID?
    @State private var selectedDateFilter: ExpenseDateFilter = .all

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            form
            recentExpenses
        }
        .onAppear {
            selectedCategoryID = selectedCategoryID ?? preferredCategoryID(in: snapshot.activeCategories)
        }
        .onChange(of: snapshot.activeCategories) { _, categories in
            guard let selectedCategoryID else {
                self.selectedCategoryID = preferredCategoryID(in: categories)
                return
            }

            if categories.contains(where: { $0.id == selectedCategoryID }) == false {
                self.selectedCategoryID = preferredCategoryID(in: categories)
            }

            if let selectedFilterCategoryID, snapshot.categories.contains(where: { $0.id == selectedFilterCategoryID }) == false {
                self.selectedFilterCategoryID = nil
            }
        }
        .onChange(of: snapshot.settings.lastUsedCategoryID) { _, categoryID in
            guard editingExpense == nil else { return }

            if let categoryID, snapshot.activeCategories.contains(where: { $0.id == categoryID }) {
                selectedCategoryID = categoryID
            }
        }
    }

    private var form: some View {
        PanelSection(
            editingExpense == nil ? "Add expense" : "Edit expense",
            detail: editingExpense == nil ? "Logging spending clears a no-spend mark for that day." : "Update the amount, day, category, or note."
        ) {
            VStack(alignment: .leading, spacing: 10) {
                DatePicker("Day", selection: $date, displayedComponents: .date)

                TextField("Amount", text: $amount)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveExpense)

                Picker("Category", selection: $selectedCategoryID) {
                    Text("Pick category").tag(Optional<ExpenseCategory.ID>.none)
                    ForEach(snapshot.activeCategories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }

                TextField("Note", text: $note)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveExpense)

                HStack {
                    Button("Today") {
                        date = Date()
                    }

                    if editingExpense != nil {
                        Button("Cancel") {
                            resetForm()
                        }
                    }

                    Spacer()

                    PrimaryInlineButton(
                        title: editingExpense == nil ? "Add expense" : "Save changes",
                        minWidth: 112,
                        isEnabled: canSubmitExpense,
                        action: saveExpense
                    )
                }
            }
        }
    }

    private var recentExpenses: some View {
        PanelSection("Latest expenses", detail: "Filter by category and date range to review corrections faster.") {
            VStack(alignment: .leading, spacing: 10) {
                filterControls

                if filteredExpenses.isEmpty {
                    EmptyStateView(
                        title: snapshot.expenses.isEmpty ? "No expenses yet." : "No expenses match the filters.",
                        message: snapshot.expenses.isEmpty ? "Log the first expense when you buy something." : "Try another category or date range."
                    )
                } else {
                    ForEach(filteredExpenses.prefix(20)) { expense in
                        ExpenseRow(
                            expense: expense,
                            categoryName: store.categoryName(for: expense.categoryID),
                            isEssential: store.categoryIsEssential(for: expense.categoryID),
                            currencyCode: snapshot.settings.currencyCode,
                            isPendingDeletion: expensePendingDeletion?.id == expense.id,
                            isEditing: editingExpense?.id == expense.id,
                            requestEdit: {
                                beginEditing(expense)
                            },
                            requestDelete: {
                                editingExpense = nil
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
    }

    private var filterControls: some View {
        HStack(spacing: 10) {
            Picker("Category filter", selection: $selectedFilterCategoryID) {
                Text("All categories").tag(Optional<ExpenseCategory.ID>.none)
                ForEach(snapshot.categories) { category in
                    Text(category.name).tag(Optional(category.id))
                }
            }
            .pickerStyle(.menu)

            Picker("Date filter", selection: $selectedDateFilter) {
                ForEach(ExpenseDateFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var filteredExpenses: [Expense] {
        let today = Day(date: Date())
        let firstDayOfMonth = Day(year: today.year, month: today.month, day: 1)

        return snapshot.expenses.filter { expense in
            let categoryMatches = selectedFilterCategoryID.map { expense.categoryID == $0 } ?? true
            let dateMatches: Bool

            switch selectedDateFilter {
            case .all:
                dateMatches = true
            case .today:
                dateMatches = expense.day == today
            case .last7Days:
                let lowerBound = today.addingDays(-6)
                dateMatches = expense.day >= lowerBound && expense.day <= today
            case .thisMonth:
                dateMatches = expense.day >= firstDayOfMonth && expense.day <= today
            }

            return categoryMatches && dateMatches
        }
    }

    private var canSubmitExpense: Bool {
        AmountParser.decimal(from: amount).map { $0 > 0 } == true && selectedCategoryID != nil
    }

    private func saveExpense() {
        Task {
            if let editingExpense {
                await store.updateExpense(
                    id: editingExpense.id,
                    date: date,
                    amountText: amount,
                    categoryID: selectedCategoryID,
                    note: note
                )
            } else {
                await store.addExpense(
                    date: date,
                    amountText: amount,
                    categoryID: selectedCategoryID,
                    note: note
                )
            }

            if store.errorMessage == nil {
                let preferredCategoryID = self.preferredCategoryID(in: snapshot.activeCategories) ?? selectedCategoryID
                resetForm()
                selectedCategoryID = preferredCategoryID
            }
        }
    }

    private func beginEditing(_ expense: Expense) {
        editingExpense = expense
        expensePendingDeletion = nil
        date = expense.day.date()
        amount = NSDecimalNumber(decimal: expense.amount).stringValue
        selectedCategoryID = expense.categoryID
        note = expense.note
    }

    private func resetForm() {
        editingExpense = nil
        amount = ""
        note = ""
        date = Date()
        selectedCategoryID = preferredCategoryID(in: snapshot.activeCategories)
    }

    private func preferredCategoryID(in categories: [ExpenseCategory]) -> ExpenseCategory.ID? {
        if let lastUsedCategoryID = snapshot.settings.lastUsedCategoryID,
           categories.contains(where: { $0.id == lastUsedCategoryID }) {
            return lastUsedCategoryID
        }

        return categories.first?.id
    }
}

private struct ExpenseRow: View {
    let expense: Expense
    let categoryName: String
    let isEssential: Bool
    let currencyCode: String
    let isPendingDeletion: Bool
    let isEditing: Bool
    let requestEdit: () -> Void
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

            if isEditing {
                Text("Editing")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(AppFormatters.currency(expense.amount, currencyCode: currencyCode))
                .font(.callout.weight(.medium))

            if isPendingDeletion == false {
                Button(action: requestEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Edit expense")

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

private enum ExpenseDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case last7Days
    case thisMonth

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All time"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 days"
        case .thisMonth:
            return "This month"
        }
    }
}
