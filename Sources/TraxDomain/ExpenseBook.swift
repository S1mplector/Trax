import Foundation

public struct ExpenseBook: Codable, Equatable, Sendable {
    public private(set) var categories: [ExpenseCategory]
    public private(set) var expenses: [Expense]
    public private(set) var dailyLogs: [DailyLog]
    public private(set) var settings: ExpenseBookSettings

    public init(
        categories: [ExpenseCategory] = [],
        expenses: [Expense] = [],
        dailyLogs: [DailyLog] = [],
        settings: ExpenseBookSettings = ExpenseBookSettings()
    ) {
        self.categories = categories
        self.expenses = expenses
        self.dailyLogs = dailyLogs
        self.settings = settings
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.categories = try container.decodeIfPresent([ExpenseCategory].self, forKey: .categories) ?? []
        self.expenses = try container.decodeIfPresent([Expense].self, forKey: .expenses) ?? []
        self.dailyLogs = try container.decodeIfPresent([DailyLog].self, forKey: .dailyLogs) ?? []
        self.settings = try container.decodeIfPresent(ExpenseBookSettings.self, forKey: .settings) ?? ExpenseBookSettings()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(categories, forKey: .categories)
        try container.encode(expenses, forKey: .expenses)
        try container.encode(dailyLogs, forKey: .dailyLogs)
        try container.encode(settings, forKey: .settings)
    }

    public mutating func updateCurrencyCode(_ currencyCode: String) throws {
        settings.currencyCode = try normalizedCurrencyCode(currencyCode)
    }

    public mutating func updateSpendingBreakdownMode(_ mode: SpendingBreakdownMode) {
        settings.spendingBreakdownMode = mode
    }

    @discardableResult
    public mutating func addCategory(name: String, colorHex: String, isEssential: Bool = false) throws -> ExpenseCategory {
        let cleanName = try normalizedCategoryName(name)
        let cleanColorHex = try normalizedColorHex(colorHex)
        try ensureCategoryNameIsUnique(cleanName)

        let category = ExpenseCategory(name: cleanName, colorHex: cleanColorHex, isEssential: isEssential)
        categories.append(category)
        sortCategories()
        return category
    }

    public mutating func renameCategory(id: ExpenseCategory.ID, name: String) throws {
        let cleanName = try normalizedCategoryName(name)
        try ensureCategoryNameIsUnique(cleanName, ignoring: id)

        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw ExpenseBookError.categoryNotFound
        }

        categories[index].name = cleanName
        sortCategories()
    }

    public mutating func updateCategoryColor(id: ExpenseCategory.ID, colorHex: String) throws {
        let cleanColorHex = try normalizedColorHex(colorHex)

        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw ExpenseBookError.categoryNotFound
        }

        categories[index].colorHex = cleanColorHex
    }

    public mutating func updateCategoryEssential(id: ExpenseCategory.ID, isEssential: Bool) throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw ExpenseBookError.categoryNotFound
        }

        categories[index].isEssential = isEssential
    }

    public mutating func archiveCategory(id: ExpenseCategory.ID) throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw ExpenseBookError.categoryNotFound
        }

        categories[index].isArchived = true
    }

    public mutating func restoreCategory(id: ExpenseCategory.ID) throws {
        guard let index = categories.firstIndex(where: { $0.id == id }) else {
            throw ExpenseBookError.categoryNotFound
        }

        categories[index].isArchived = false
    }

    public mutating func removeCategory(id: ExpenseCategory.ID) throws {
        guard categories.contains(where: { $0.id == id }) else {
            throw ExpenseBookError.categoryNotFound
        }

        if expenses.contains(where: { $0.categoryID == id }) {
            try archiveCategory(id: id)
            return
        }

        categories.removeAll { $0.id == id }
    }

    @discardableResult
    public mutating func addExpense(day: Day, amount: Decimal, categoryID: ExpenseCategory.ID, note: String = "") throws -> Expense {
        guard amount > 0 else {
            throw ExpenseBookError.amountMustBePositive
        }

        guard let category = categories.first(where: { $0.id == categoryID }) else {
            throw ExpenseBookError.categoryNotFound
        }

        guard category.isArchived == false else {
            throw ExpenseBookError.archivedCategory
        }

        let expense = Expense(
            day: day,
            amount: amount,
            categoryID: categoryID,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        expenses.append(expense)
        dailyLogs.removeAll { $0.day == day && $0.spentNothing }
        sortExpenses()
        return expense
    }

    public mutating func deleteExpense(id: Expense.ID) throws {
        guard let index = expenses.firstIndex(where: { $0.id == id }) else {
            throw ExpenseBookError.expenseNotFound
        }

        expenses.remove(at: index)
    }

    public mutating func markNoSpend(day: Day, note: String = "") throws {
        guard expenses.contains(where: { $0.day == day }) == false else {
            throw ExpenseBookError.cannotMarkNoSpendDayWithExpenses
        }

        let log = DailyLog(
            day: day,
            spentNothing: true,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        if let index = dailyLogs.firstIndex(where: { $0.day == day }) {
            dailyLogs[index] = log
        } else {
            dailyLogs.append(log)
        }

        sortDailyLogs()
    }

    public mutating func clearDailyLog(day: Day) {
        dailyLogs.removeAll { $0.day == day }
    }

    public func expenses(on day: Day) -> [Expense] {
        expenses
            .filter { $0.day == day }
            .sorted { lhs, rhs in
                if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
                return lhs.id.uuidString < rhs.id.uuidString
            }
    }

    public func totalSpent(on day: Day) -> Decimal {
        expenses(on: day).reduce(Decimal.zero) { $0 + $1.amount }
    }

    public func category(id: ExpenseCategory.ID) -> ExpenseCategory? {
        categories.first { $0.id == id }
    }

    private func normalizedCategoryName(_ name: String) throws -> String {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleanName.isEmpty == false else {
            throw ExpenseBookError.categoryNameRequired
        }
        return cleanName
    }

    private func normalizedColorHex(_ colorHex: String) throws -> String {
        let rawHex = colorHex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let hexDigits = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        let isHex = rawHex.unicodeScalars.allSatisfy { hexDigits.contains($0) }

        guard rawHex.count == 6, isHex else {
            throw ExpenseBookError.invalidCategoryColor
        }

        return "#\(rawHex.uppercased())"
    }

    private func normalizedCurrencyCode(_ currencyCode: String) throws -> String {
        let cleanCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let letters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let isCode = cleanCode.unicodeScalars.allSatisfy { letters.contains($0) }

        guard cleanCode.count == 3, isCode else {
            throw ExpenseBookError.invalidCurrencyCode
        }

        return cleanCode
    }

    private func ensureCategoryNameIsUnique(_ name: String, ignoring id: ExpenseCategory.ID? = nil) throws {
        let lowercasedName = name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let duplicate = categories.contains { category in
            let existingName = category.name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            return category.id != id && existingName == lowercasedName
        }

        if duplicate {
            throw ExpenseBookError.duplicateCategoryName
        }
    }

    private mutating func sortCategories() {
        categories.sort { lhs, rhs in
            if lhs.isArchived != rhs.isArchived {
                return rhs.isArchived
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    private mutating func sortExpenses() {
        expenses.sort { lhs, rhs in
            if lhs.day != rhs.day { return lhs.day > rhs.day }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }

    private mutating func sortDailyLogs() {
        dailyLogs.sort { $0.day > $1.day }
    }

    private enum CodingKeys: String, CodingKey {
        case categories
        case expenses
        case dailyLogs
        case settings
    }
}
