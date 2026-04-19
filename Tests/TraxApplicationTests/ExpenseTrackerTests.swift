import XCTest
import TraxApplication
import TraxDomain

final class ExpenseTrackerTests: XCTestCase {
    func testSnapshotSeedsDefaultCategories() async throws {
        let repository = InMemoryExpenseBookRepository()
        let tracker = ExpenseTracker(repository: repository)

        let snapshot = try await tracker.snapshot(today: Day(year: 2026, month: 4, day: 17))

        XCTAssertEqual(snapshot.activeCategories.count, 6)
        XCTAssertEqual(snapshot.activeCategories.first?.name, "Groceries")
        XCTAssertTrue(snapshot.activeCategories.first { $0.name == "Groceries" }?.isEssential == true)
        XCTAssertTrue(snapshot.activeCategories.first { $0.name == "Wants" }?.isEssential == false)
    }

    func testSnapshotCountsMonthToDateStatuses() async throws {
        let repository = InMemoryExpenseBookRepository()
        let tracker = ExpenseTracker(repository: repository)
        let category = try await tracker.addCategory(name: "Food", colorHex: "#34C759")

        try await tracker.markNoSpend(day: Day(year: 2026, month: 4, day: 15))
        try await tracker.markNoSpend(day: Day(year: 2026, month: 4, day: 16))
        try await tracker.addExpense(
            day: Day(year: 2026, month: 4, day: 17),
            amount: Decimal(5),
            categoryID: category.id
        )

        let snapshot = try await tracker.snapshot(today: Day(year: 2026, month: 4, day: 17))

        XCTAssertEqual(snapshot.monthSummary.noSpendDays, 2)
        XCTAssertEqual(snapshot.monthSummary.spentDays, 1)
        XCTAssertEqual(snapshot.monthSummary.unloggedDays, 14)
        XCTAssertEqual(snapshot.monthSummary.currentNoSpendStreak, 0)
    }

    func testSnapshotIncludesUpdatedCurrencyCode() async throws {
        let repository = InMemoryExpenseBookRepository()
        let tracker = ExpenseTracker(repository: repository)

        try await tracker.updateCurrencyCode("usd")
        let snapshot = try await tracker.snapshot(today: Day(year: 2026, month: 4, day: 17))

        XCTAssertEqual(snapshot.settings.currencyCode, "USD")
    }

    func testSnapshotIncludesMonthCategoryBreakdown() async throws {
        let repository = InMemoryExpenseBookRepository()
        let tracker = ExpenseTracker(repository: repository)
        let groceries = try await tracker.addCategory(name: "Groceries", colorHex: "#34C759", isEssential: true)
        let transport = try await tracker.addCategory(name: "Transport", colorHex: "#0A84FF")

        try await tracker.addExpense(
            day: Day(year: 2026, month: 4, day: 5),
            amount: Decimal(12),
            categoryID: groceries.id
        )
        try await tracker.addExpense(
            day: Day(year: 2026, month: 4, day: 6),
            amount: Decimal(8),
            categoryID: groceries.id
        )
        try await tracker.addExpense(
            day: Day(year: 2026, month: 4, day: 7),
            amount: Decimal(5),
            categoryID: transport.id
        )
        try await tracker.addExpense(
            day: Day(year: 2026, month: 3, day: 31),
            amount: Decimal(99),
            categoryID: transport.id
        )

        let snapshot = try await tracker.snapshot(today: Day(year: 2026, month: 4, day: 17))

        XCTAssertEqual(snapshot.monthCategoryBreakdown.map(\.categoryName), ["Groceries", "Transport"])
        XCTAssertTrue(snapshot.monthCategoryBreakdown[0].isEssential)
        XCTAssertEqual(snapshot.monthCategoryBreakdown[0].totalSpent, Decimal(20))
        XCTAssertEqual(snapshot.monthCategoryBreakdown[0].expenseCount, 2)
        XCTAssertFalse(snapshot.monthCategoryBreakdown[1].isEssential)
        XCTAssertEqual(snapshot.monthCategoryBreakdown[1].totalSpent, Decimal(5))
        XCTAssertEqual(snapshot.monthCategoryBreakdown[1].expenseCount, 1)
    }
}

private actor InMemoryExpenseBookRepository: ExpenseBookRepository {
    private var book: ExpenseBook

    init(book: ExpenseBook = ExpenseBook()) {
        self.book = book
    }

    func load() async throws -> ExpenseBook {
        book
    }

    func save(_ book: ExpenseBook) async throws {
        self.book = book
    }
}
