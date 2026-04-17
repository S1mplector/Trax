import SwiftUI

struct PrimaryInlineButton: View {
    let title: String
    var minWidth: CGFloat = 72
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.callout.weight(.semibold))
                .foregroundStyle(isEnabled ? Color.white : Color.white.opacity(0.45))
                .frame(minWidth: minWidth)
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
        .background(isEnabled ? Color.accentColor.opacity(0.92) : Color.primary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .help(title)
    }
}
