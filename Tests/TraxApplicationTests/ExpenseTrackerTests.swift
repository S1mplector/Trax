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
