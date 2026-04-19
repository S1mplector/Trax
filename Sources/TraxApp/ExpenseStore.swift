import Foundation
import TraxApplication
import TraxDomain

@MainActor
final class ExpenseStore: ObservableObject {
    @Published private(set) var snapshot: ExpenseBookSnapshot?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let tracker: ExpenseTracker
    private let calendar: Calendar

    init(
        tracker: ExpenseTracker,
        calendar: Calendar = .current
    ) {
        self.tracker = tracker
        self.calendar = calendar
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            snapshot = try await tracker.snapshot(today: today, calendar: calendar)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markTodayNoSpend(note: String = "") async {
        await perform {
            try await tracker.markNoSpend(day: today, note: note)
        }
    }

    func clearTodayCheckIn() async {
        await perform {
            try await tracker.clearDailyLog(day: today)
        }
    }

    func addExpense(date: Date, amountText: String, categoryID: ExpenseCategory.ID?, note: String) async {
        guard let amount = AmountParser.decimal(from: amountText), amount > 0 else {
            errorMessage = ExpenseBookError.amountMustBePositive.localizedDescription
            return
        }

        guard let categoryID else {
            errorMessage = "Pick a category before adding an expense."
            return
        }

        await perform {
            try await tracker.addExpense(
                day: Day(date: date, calendar: calendar),
                amount: amount,
                categoryID: categoryID,
                note: note
            )
        }
    }

    func deleteExpense(id: Expense.ID) async {
        await perform {
            try await tracker.deleteExpense(id: id)
        }
    }

    func addCategory(name: String, colorHex: String, isEssential: Bool = false) async {
        await perform {
            try await tracker.addCategory(name: name, colorHex: colorHex, isEssential: isEssential)
        }
    }

    func renameCategory(id: ExpenseCategory.ID, name: String) async {
        await perform {
            try await tracker.renameCategory(id: id, name: name)
        }
    }

    func updateCategoryColor(id: ExpenseCategory.ID, colorHex: String) async {
        await perform {
            try await tracker.updateCategoryColor(id: id, colorHex: colorHex)
        }
    }

    func updateCategoryEssential(id: ExpenseCategory.ID, isEssential: Bool) async {
        await perform {
            try await tracker.updateCategoryEssential(id: id, isEssential: isEssential)
        }
    }

    func archiveCategory(id: ExpenseCategory.ID) async {
        await perform {
            try await tracker.archiveCategory(id: id)
        }
    }

    func restoreCategory(id: ExpenseCategory.ID) async {
        await perform {
            try await tracker.restoreCategory(id: id)
        }
    }

    func removeCategory(id: ExpenseCategory.ID) async {
        await perform {
            try await tracker.removeCategory(id: id)
        }
    }

    func updateCurrencyCode(_ currencyCode: String) async {
        await perform {
            try await tracker.updateCurrencyCode(currencyCode)
        }
    }

    func categoryName(for id: ExpenseCategory.ID) -> String {
        snapshot?.categories.first { $0.id == id }?.name ?? "Unknown"
    }

    func categoryIsEssential(for id: ExpenseCategory.ID) -> Bool {
        snapshot?.categories.first { $0.id == id }?.isEssential ?? false
    }

    private var today: Day {
        Day(date: Date(), calendar: calendar)
    }

    private func perform(_ operation: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await operation()
            snapshot = try await tracker.snapshot(today: today, calendar: calendar)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
