import Foundation

public struct DailyLog: Codable, Equatable, Identifiable, Sendable {
    public var day: Day
    public var spentNothing: Bool
    public var note: String
    public var updatedAt: Date

    public var id: Day.ID { day.id }

    public init(
        day: Day,
        spentNothing: Bool,
        note: String = "",
        updatedAt: Date = Date()
    ) {
        self.day = day
        self.spentNothing = spentNothing
        self.note = note
        self.updatedAt = updatedAt
    }
}
