import Foundation

public struct ExpenseCategory: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isArchived = isArchived
    }
}
