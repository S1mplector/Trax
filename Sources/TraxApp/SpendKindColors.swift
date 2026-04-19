import SwiftUI

enum SpendKindColors {
    static let essential = Color.orange
    static let nonEssential = Color.red

    static func color(isEssential: Bool) -> Color {
        isEssential ? essential : nonEssential
    }

    static func label(isEssential: Bool) -> String {
        isEssential ? "Essential" : "Non-essential"
    }
}
