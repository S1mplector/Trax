import Foundation

public struct Day: Codable, Hashable, Identifiable, Comparable, Sendable {
    public let year: Int
    public let month: Int
    public let day: Int

    public var id: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    public init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    public init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        self.year = components.year ?? 1970
        self.month = components.month ?? 1
        self.day = components.day ?? 1
    }

    public func date(calendar: Calendar = .current) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? Date(timeIntervalSince1970: 0)
    }

    public func addingDays(_ value: Int, calendar: Calendar = .current) -> Day {
        let nextDate = calendar.date(byAdding: .day, value: value, to: date(calendar: calendar)) ?? date(calendar: calendar)
        return Day(date: nextDate, calendar: calendar)
    }

    public static func < (lhs: Day, rhs: Day) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        if lhs.month != rhs.month { return lhs.month < rhs.month }
        return lhs.day < rhs.day
    }
}
