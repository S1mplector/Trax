import Foundation
import TraxDomain

public actor ExpenseTracker {
    private let repository: any ExpenseBookRepository
    private var cachedBook: ExpenseBook?

    public init(repository: any ExpenseBookRepository) {
        self.repository = repository
    }

    public func snapshot(
        today: Day = Day(date: Date()),
        recentDayCount: Int = 14,
        calendar: Calendar = .current
    ) async throws -> ExpenseBookSnapshot {
        let book = try await currentBook()
        return makeSnapshot(
            from: book,
            today: today,
            recentDayCount: recentDayCount,
            calendar: calendar
        )
    }

    @discardableResult
    public func addCategory(name: String, colorHex: String, isEssential: Bool = false) async throws -> ExpenseCategory {
        var book = try await currentBook()
        let category = try book.addCategory(name: name, colorHex: colorHex, isEssential: isEssential)
        try await persist(book)
        return category
    }

    public func renameCategory(id: ExpenseCategory.ID, name: String) async throws {
        var book = try await currentBook()
        try book.renameCategory(id: id, name: name)
        try await persist(book)
    }

    public func updateCategoryColor(id: ExpenseCategory.ID, colorHex: String) async throws {
        var book = try await currentBook()
        try book.updateCategoryColor(id: id, colorHex: colorHex)
        try await persist(book)
    }

    public func updateCategoryEssential(id: ExpenseCategory.ID, isEssential: Bool) async throws {
        var book = try await currentBook()
        try book.updateCategoryEssential(id: id, isEssential: isEssential)
        try await persist(book)
    }

    public func archiveCategory(id: ExpenseCategory.ID) async throws {
        var book = try await currentBook()
        try book.archiveCategory(id: id)
        try await persist(book)
    }

    public func restoreCategory(id: ExpenseCategory.ID) async throws {
        var book = try await currentBook()
        try book.restoreCategory(id: id)
        try await persist(book)
    }

    public func removeCategory(id: ExpenseCategory.ID) async throws {
        var book = try await currentBook()
        try book.removeCategory(id: id)
        try await persist(book)
    }

    @discardableResult
    public func addExpense(
        day: Day,
        amount: Decimal,
        categoryID: ExpenseCategory.ID,
        note: String = ""
    ) async throws -> Expense {
        var book = try await currentBook()
        let expense = try book.addExpense(day: day, amount: amount, categoryID: categoryID, note: note)
        try await persist(book)
        return expense
    }

    public func deleteExpense(id: Expense.ID) async throws {
        var book = try await currentBook()
        try book.deleteExpense(id: id)
        try await persist(book)
    }

    public func updateExpense(
        id: Expense.ID,
        day: Day,
        amount: Decimal,
        categoryID: ExpenseCategory.ID,
        note: String = ""
    ) async throws {
        var book = try await currentBook()
        try book.updateExpense(id: id, day: day, amount: amount, categoryID: categoryID, note: note)
        try await persist(book)
    }

    public func markNoSpend(day: Day, note: String = "") async throws {
        var book = try await currentBook()
        try book.markNoSpend(day: day, note: note)
        try await persist(book)
    }

    public func clearDailyLog(day: Day) async throws {
        var book = try await currentBook()
        book.clearDailyLog(day: day)
        try await persist(book)
    }

    public func updateCurrencyCode(_ currencyCode: String) async throws {
        var book = try await currentBook()
        try book.updateCurrencyCode(currencyCode)
        try await persist(book)
    }

    public func updateSpendingBreakdownMode(_ mode: SpendingBreakdownMode) async throws {
        var book = try await currentBook()
        book.updateSpendingBreakdownMode(mode)
        try await persist(book)
    }

    public func exportBook() async throws -> ExpenseBook {
        try await currentBook()
    }

    public func importBook(_ book: ExpenseBook) async throws {
        let normalizedBook = book.categories.isEmpty ? seedDefaultCategories(into: book) : book
        try await persist(normalizedBook)
    }

    private func currentBook() async throws -> ExpenseBook {
        if let cachedBook {
            return cachedBook
        }

        var loadedBook = try await repository.load()
        if loadedBook.categories.isEmpty {
            loadedBook = seedDefaultCategories(into: loadedBook)
            try await repository.save(loadedBook)
        }

        cachedBook = loadedBook
        return loadedBook
    }

    private func persist(_ book: ExpenseBook) async throws {
        cachedBook = book
        try await repository.save(book)
    }

    private func seedDefaultCategories(into book: ExpenseBook) -> ExpenseBook {
        var seededBook = book
        let defaults: [(String, String, Bool)] = [
            ("Groceries", "#34C759", true),
            ("Transport", "#0A84FF", true),
            ("Home", "#FFD60A", true),
            ("Health", "#64D2FF", true),
            ("Wants", "#FF453A", false),
            ("Other", "#8E8E93", false)
        ]

        for category in defaults {
            _ = try? seededBook.addCategory(name: category.0, colorHex: category.1, isEssential: category.2)
        }

        return seededBook
    }

    private func makeSnapshot(
        from book: ExpenseBook,
        today: Day,
        recentDayCount: Int,
        calendar: Calendar
    ) -> ExpenseBookSnapshot {
        let boundedRecentDayCount = max(recentDayCount, 1)
        let recentDays = (0..<boundedRecentDayCount).map { offset in
            makeDailySummary(for: today.addingDays(-offset, calendar: calendar), in: book)
        }
        let activeCategories = book.categories.filter { $0.isArchived == false }
        let archivedCategories = book.categories.filter(\.isArchived)

        return ExpenseBookSnapshot(
            settings: book.settings,
            categories: book.categories,
            activeCategories: activeCategories,
            archivedCategories: archivedCategories,
            expenses: book.expenses,
            dailyLogs: book.dailyLogs,
            today: makeDailySummary(for: today, in: book),
            recentDays: recentDays,
            monthSummary: makeMonthSummary(today: today, book: book, calendar: calendar),
            monthCategoryBreakdown: makeMonthCategoryBreakdown(today: today, book: book)
        )
    }

    private func makeDailySummary(for day: Day, in book: ExpenseBook) -> DailySummary {
        let expenses = book.expenses(on: day)
        let log = book.dailyLogs.first { $0.day == day }
        let totalSpent = expenses.reduce(Decimal.zero) { $0 + $1.amount }
        let status: DayStatus

        if expenses.isEmpty == false {
            status = .spent
        } else if log?.spentNothing == true {
            status = .noSpend
        } else {
            status = .unlogged
        }

        return DailySummary(
            day: day,
            totalSpent: totalSpent,
            expenseCount: expenses.count,
            status: status,
            note: log?.note ?? ""
        )
    }

    private func makeMonthSummary(today: Day, book: ExpenseBook, calendar: Calendar) -> MonthSummary {
        let days = monthToDateDays(through: today, calendar: calendar)
        let summaries = days.map { makeDailySummary(for: $0, in: book) }
        let totalSpent = summaries.reduce(Decimal.zero) { $0 + $1.totalSpent }
        let spentDays = summaries.filter { $0.status == .spent }.count
        let noSpendDays = summaries.filter { $0.status == .noSpend }.count
        let unloggedDays = summaries.filter { $0.status == .unlogged }.count
        let monthExpenses = book.expenses.filter { expense in
            expense.day.year == today.year && expense.day.month == today.month && expense.day <= today
        }
        let essentialSpent = monthExpenses.reduce(Decimal.zero) { result, expense in
            guard book.category(id: expense.categoryID)?.isEssential == true else {
                return result
            }
            return result + expense.amount
        }
        let nonEssentialSpent = monthExpenses.reduce(Decimal.zero) { result, expense in
            guard book.category(id: expense.categoryID)?.isEssential == false else {
                return result
            }
            return result + expense.amount
        }

        return MonthSummary(
            year: today.year,
            month: today.month,
            totalSpent: totalSpent,
            essentialSpent: essentialSpent,
            nonEssentialSpent: nonEssentialSpent,
            spentDays: spentDays,
            noSpendDays: noSpendDays,
            unloggedDays: unloggedDays,
            currentNoSpendStreak: currentNoSpendStreak(endingAt: today, book: book, calendar: calendar)
        )
    }

    private func monthToDateDays(through today: Day, calendar: Calendar) -> [Day] {
        let firstDay = Day(year: today.year, month: today.month, day: 1)
        guard firstDay <= today else { return [] }

        var days: [Day] = []
        var cursor = firstDay

        while cursor <= today {
            days.append(cursor)
            cursor = cursor.addingDays(1, calendar: calendar)
        }

        return days
    }

    private func currentNoSpendStreak(endingAt today: Day, book: ExpenseBook, calendar: Calendar) -> Int {
        var streak = 0
        var cursor = today

        while true {
            let summary = makeDailySummary(for: cursor, in: book)
            guard summary.status == .noSpend else {
                return streak
            }

            streak += 1
            cursor = cursor.addingDays(-1, calendar: calendar)
        }
    }

    private func makeMonthCategoryBreakdown(today: Day, book: ExpenseBook) -> [CategorySpendingSummary] {
        let monthExpenses = book.expenses.filter { expense in
            expense.day.year == today.year && expense.day.month == today.month && expense.day <= today
        }

        let groupedExpenses = Dictionary(grouping: monthExpenses, by: \.categoryID)

        return groupedExpenses.compactMap { categoryID, expenses in
            guard let category = book.category(id: categoryID) else {
                return nil
            }

            let totalSpent = expenses.reduce(Decimal.zero) { $0 + $1.amount }

            return CategorySpendingSummary(
                categoryID: categoryID,
                categoryName: category.name,
                colorHex: category.colorHex,
                isEssential: category.isEssential,
                totalSpent: totalSpent,
                expenseCount: expenses.count
            )
        }
        .sorted { lhs, rhs in
            if lhs.totalSpent != rhs.totalSpent {
                return lhs.totalSpent > rhs.totalSpent
            }

            return lhs.categoryName.localizedCaseInsensitiveCompare(rhs.categoryName) == .orderedAscending
        }
    }
}
