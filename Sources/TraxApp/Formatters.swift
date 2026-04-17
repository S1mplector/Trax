import Foundation
import TraxDomain

enum AppFormatters {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = .current
        return formatter
    }()

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    private static let shortDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("EEE d")
        return formatter
    }()

    static func currency(_ amount: Decimal) -> String {
        currencyFormatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }

    static func day(_ day: Day) -> String {
        dayFormatter.string(from: day.date())
    }

    static func shortDay(_ day: Day) -> String {
        shortDayFormatter.string(from: day.date())
    }
}

enum AmountParser {
    static func decimal(from text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .current

        if let number = formatter.number(from: trimmed) {
            return number.decimalValue
        }

        let normalized = trimmed
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}
