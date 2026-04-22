import Foundation

public enum SpendingBreakdownMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case list
    case bars
    case donut

    public var id: String { rawValue }
}

public struct ExpenseBookSettings: Codable, Equatable, Sendable {
    public static let defaultCurrencyCode = Locale.current.currency?.identifier ?? "EUR"

    public var currencyCode: String
    public var spendingBreakdownMode: SpendingBreakdownMode
    public var lastUsedCategoryID: ExpenseCategory.ID?

    public init(
        currencyCode: String = ExpenseBookSettings.defaultCurrencyCode,
        spendingBreakdownMode: SpendingBreakdownMode = .list,
        lastUsedCategoryID: ExpenseCategory.ID? = nil
    ) {
        self.currencyCode = currencyCode
        self.spendingBreakdownMode = spendingBreakdownMode
        self.lastUsedCategoryID = lastUsedCategoryID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.currencyCode = try container.decodeIfPresent(String.self, forKey: .currencyCode) ?? ExpenseBookSettings.defaultCurrencyCode
        self.spendingBreakdownMode = try container.decodeIfPresent(SpendingBreakdownMode.self, forKey: .spendingBreakdownMode) ?? .list
        self.lastUsedCategoryID = try container.decodeIfPresent(ExpenseCategory.ID.self, forKey: .lastUsedCategoryID)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(currencyCode, forKey: .currencyCode)
        try container.encode(spendingBreakdownMode, forKey: .spendingBreakdownMode)
        try container.encodeIfPresent(lastUsedCategoryID, forKey: .lastUsedCategoryID)
    }

    private enum CodingKeys: String, CodingKey {
        case currencyCode
        case spendingBreakdownMode
        case lastUsedCategoryID
    }
}
