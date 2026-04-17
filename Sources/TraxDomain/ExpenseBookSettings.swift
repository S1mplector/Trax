import Foundation

public struct ExpenseBookSettings: Codable, Equatable, Sendable {
    public static let defaultCurrencyCode = Locale.current.currency?.identifier ?? "EUR"

    public var currencyCode: String

    public init(currencyCode: String = ExpenseBookSettings.defaultCurrencyCode) {
        self.currencyCode = currencyCode
    }
}
