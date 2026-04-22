import SwiftUI
import TraxDomain

enum SpendKindColors {
    static let essential = Color.orange
    static let nonEssential = Color.red

    static func color(isEssential: Bool) -> Color {
        isEssential ? essential : nonEssential
    }

    static func label(isEssential: Bool) -> String {
        isEssential ? "Essential" : "Non-essential"
    }

    static func spentColor(for expenses: [Expense], categories: [ExpenseCategory]) -> Color {
        let categoriesByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        let includesNonEssentialSpend = expenses.contains { expense in
            categoriesByID[expense.categoryID]?.isEssential != true
        }

        return includesNonEssentialSpend ? nonEssential : essential
    }
}
