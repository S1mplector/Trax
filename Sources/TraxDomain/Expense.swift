import Foundation

public struct Expense: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var day: Day
    public var amount: Decimal
    public var categoryID: ExpenseCategory.ID
    public var note: String
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        day: Day,
        amount: Decimal,
        categoryID: ExpenseCategory.ID,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.day = day
        self.amount = amount
        self.categoryID = categoryID
        self.note = note
        self.createdAt = createdAt
    }
}
