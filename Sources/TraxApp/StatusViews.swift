import SwiftUI
import TraxApplication

struct StatusPill: View {
    let status: DayStatus

    var body: some View {
        HStack(spacing: 6) {
            StatusDot(status: status)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var title: String {
        switch status {
        case .spent:
            return "Spent"
        case .noSpend:
            return "No spend"
        case .unlogged:
            return "Unlogged"
        }
    }

    private var color: Color {
        switch status {
        case .spent:
            return .red
        case .noSpend:
            return .green
        case .unlogged:
            return .secondary
        }
    }
}

struct StatusDot: View {
    let status: DayStatus

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private var color: Color {
        switch status {
        case .spent:
            return .red
        case .noSpend:
            return .green
        case .unlogged:
            return .secondary
        }
    }
}
