import XCTest
import TraxDomain

final class ExpenseBookTests: XCTestCase {
    func testMarkNoSpendFailsWhenDayHasExpenses() throws {
        var book = ExpenseBook()
        let category = try book.addCategory(name: "Groceries", colorHex: "#34C759")
        let day = Day(year: 2026, month: 4, day: 17)

        try book.addExpense(day: day, amount: Decimal(12), categoryID: category.id)

        XCTAssertThrowsError(try book.markNoSpend(day: day)) { error in
            XCTAssertEqual(error as? ExpenseBookError, .cannotMarkNoSpendDayWithExpenses)
        }
    }

    func testAddingExpenseClearsNoSpendLogForThatDay() throws {
        var book = ExpenseBook()
        let category = try book.addCategory(name: "Transport", colorHex: "#0A84FF")
        let day = Day(year: 2026, month: 4, day: 17)

        try book.markNoSpend(day: day)
        try book.addExpense(day: day, amount: Decimal(4), categoryID: category.id)

        XCTAssertTrue(book.dailyLogs.isEmpty)
    }

    func testUsedCategoryIsArchivedInsteadOfRemoved() throws {
        var book = ExpenseBook()
        let category = try book.addCategory(name: "Wants", colorHex: "#FF453A")
        try book.addExpense(day: Day(year: 2026, month: 4, day: 17), amount: Decimal(9), categoryID: category.id)

        try book.removeCategory(id: category.id)

        XCTAssertEqual(book.categories.count, 1)
        XCTAssertTrue(book.categories[0].isArchived)
    }

    func testDuplicateCategoryNamesAreRejectedCaseInsensitively() throws {
        var book = ExpenseBook()
        try book.addCategory(name: "Groceries", colorHex: "#34C759")

        XCTAssertThrowsError(try book.addCategory(name: "groceries", colorHex: "#34C759")) { error in
            XCTAssertEqual(error as? ExpenseBookError, .duplicateCategoryName)
        }
    }

    func testCategoryColorIsValidatedAndNormalized() throws {
        var book = ExpenseBook()

        let category = try book.addCategory(name: "Health", colorHex: "64d2ff")

        XCTAssertEqual(category.colorHex, "#64D2FF")
        XCTAssertThrowsError(try book.addCategory(name: "Other", colorHex: "not-a-color")) { error in
            XCTAssertEqual(error as? ExpenseBookError, .invalidCategoryColor)
        }
    }
}
