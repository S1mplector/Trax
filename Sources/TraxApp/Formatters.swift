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

        let locale = Locale.current
        let decimalSeparator = locale.decimalSeparator ?? "."
        let groupingSeparator = locale.groupingSeparator ?? ","
        let normalized = trimmed
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: decimalSeparator, with: ".")
            .replacingOccurrences(of: " ", with: "")
        let amountPattern = #"^[0-9]+(\.[0-9]{1,2})?$"#

        guard normalized.range(of: amountPattern, options: .regularExpression) != nil else {
            return nil
        }

        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }
}
