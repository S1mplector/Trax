import Foundation

public enum ExpenseBookError: Error, Equatable, LocalizedError, Sendable {
    case categoryNameRequired
    case duplicateCategoryName
    case invalidCategoryColor
    case categoryNotFound
    case archivedCategory
    case amountMustBePositive
    case expenseNotFound
    case cannotMarkNoSpendDayWithExpenses

    public var errorDescription: String? {
        switch self {
        case .categoryNameRequired:
            return "Category name is required."
        case .duplicateCategoryName:
            return "A category with that name already exists."
        case .invalidCategoryColor:
            return "Category color must be a 6-digit hex color."
        case .categoryNotFound:
            return "Category could not be found."
        case .archivedCategory:
            return "Archived categories cannot be used for new expenses."
        case .amountMustBePositive:
            return "Expense amount must be greater than zero."
        case .expenseNotFound:
            return "Expense could not be found."
        case .cannotMarkNoSpendDayWithExpenses:
            return "A day with expenses cannot be marked as no-spend."
        }
    }
}
