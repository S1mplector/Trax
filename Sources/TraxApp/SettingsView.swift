import SwiftUI
import TraxApplication

struct SettingsView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot
    @State private var launchAtLoginStatus = LaunchAtLoginController.status()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PanelSection("Currency", detail: "Choose the currency Trax uses when showing amounts.") {
                Picker(
                    "Currency",
                    selection: Binding(
                        get: { snapshot.settings.currencyCode },
                        set: { currencyCode in
                            Task { await store.updateCurrencyCode(currencyCode) }
                        }
                    )
                ) {
                    ForEach(CurrencyOption.options(including: snapshot.settings.currencyCode)) { option in
                        Text(option.title).tag(option.code)
                    }
                }
                .pickerStyle(.menu)
            }

            PanelSection("Launch") {
                Toggle(
                    "Open Trax at login",
                    isOn: Binding(
                        get: { launchAtLoginStatus.isEnabled },
                        set: { isEnabled in
                            updateLaunchAtLogin(isEnabled)
                        }
                    )
                )
                .disabled(launchAtLoginStatus.canToggle == false)

                if let message = launchAtLoginStatus.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            launchAtLoginStatus = LaunchAtLoginController.status()
        }
    }

    private func updateLaunchAtLogin(_ isEnabled: Bool) {
        do {
            try LaunchAtLoginController.setEnabled(isEnabled)
            launchAtLoginStatus = LaunchAtLoginController.status()
        } catch {
            launchAtLoginStatus = LaunchAtLoginController.status()
            store.errorMessage = error.localizedDescription
        }
    }
}

private struct CurrencyOption: Identifiable, Equatable {
    let code: String
    let name: String

    var id: String { code }

    var title: String {
        "\(name) (\(code))"
    }

    static func options(including currencyCode: String) -> [CurrencyOption] {
        let cleanCode = currencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        var options = common

        if options.contains(where: { $0.code == cleanCode }) == false {
            options.insert(CurrencyOption(code: cleanCode, name: "Custom currency"), at: 0)
        }

        return options
    }

    private static let common = [
        CurrencyOption(code: "EUR", name: "Euro"),
        CurrencyOption(code: "USD", name: "US Dollar"),
        CurrencyOption(code: "GBP", name: "British Pound"),
        CurrencyOption(code: "TRY", name: "Turkish Lira"),
        CurrencyOption(code: "CAD", name: "Canadian Dollar"),
        CurrencyOption(code: "AUD", name: "Australian Dollar"),
        CurrencyOption(code: "CHF", name: "Swiss Franc"),
        CurrencyOption(code: "JPY", name: "Japanese Yen"),
        CurrencyOption(code: "SEK", name: "Swedish Krona"),
        CurrencyOption(code: "NOK", name: "Norwegian Krone"),
        CurrencyOption(code: "DKK", name: "Danish Krone"),
        CurrencyOption(code: "PLN", name: "Polish Zloty")
    ]
}
