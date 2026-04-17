import Foundation
import TraxDomain

public enum DayStatus: String, Codable, Equatable, Sendable {
    case unlogged
    case noSpend
    case spent
}

public struct DailySummary: Equatable, Identifiable, Sendable {
    public let day: Day
    public let totalSpent: Decimal
    public let expenseCount: Int
    public let status: DayStatus
    public let note: String

    public var id: Day.ID { day.id }

    public init(
        day: Day,
        totalSpent: Decimal,
        expenseCount: Int,
        status: DayStatus,
        note: String
    ) {
        self.day = day
        self.totalSpent = totalSpent
        self.expenseCount = expenseCount
        self.status = status
        self.note = note
    }
}

public struct MonthSummary: Equatable, Sendable {
    public let year: Int
    public let month: Int
    public let totalSpent: Decimal
    public let spentDays: Int
    public let noSpendDays: Int
    public let unloggedDays: Int
    public let currentNoSpendStreak: Int

    public init(
        year: Int,
        month: Int,
        totalSpent: Decimal,
        spentDays: Int,
        noSpendDays: Int,
        unloggedDays: Int,
        currentNoSpendStreak: Int
    ) {
        self.year = year
        self.month = month
        self.totalSpent = totalSpent
        self.spentDays = spentDays
        self.noSpendDays = noSpendDays
        self.unloggedDays = unloggedDays
        self.currentNoSpendStreak = currentNoSpendStreak
    }
}

public struct ExpenseBookSnapshot: Equatable, Sendable {
    public let categories: [ExpenseCategory]
    public let activeCategories: [ExpenseCategory]
    public let archivedCategories: [ExpenseCategory]
    public let expenses: [Expense]
    public let dailyLogs: [DailyLog]
    public let today: DailySummary
    public let recentDays: [DailySummary]
    public let monthSummary: MonthSummary

    public init(
        categories: [ExpenseCategory],
        activeCategories: [ExpenseCategory],
        archivedCategories: [ExpenseCategory],
        expenses: [Expense],
        dailyLogs: [DailyLog],
        today: DailySummary,
        recentDays: [DailySummary],
        monthSummary: MonthSummary
    ) {
        self.categories = categories
        self.activeCategories = activeCategories
        self.archivedCategories = archivedCategories
        self.expenses = expenses
        self.dailyLogs = dailyLogs
        self.today = today
        self.recentDays = recentDays
        self.monthSummary = monthSummary
    }
}
