import SwiftUI
import TraxApplication

struct SettingsView: View {
    @EnvironmentObject private var store: ExpenseStore
    let snapshot: ExpenseBookSnapshot
    @State private var customCurrencyCode = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PanelSection("Currency", detail: "Choose the currency Trax uses when showing amounts.") {
                VStack(alignment: .leading, spacing: 10) {
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

                    HStack {
                        TextField("ISO code", text: $customCurrencyCode)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 96)
                            .onSubmit(submitCustomCurrency)

                        Button("Set", action: submitCustomCurrency)
                            .disabled(canSubmitCustomCurrency == false)

                        Spacer()
                    }

                    Text("Example: \(AppFormatters.currency(Decimal(12.34), currencyCode: snapshot.settings.currencyCode))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            customCurrencyCode = snapshot.settings.currencyCode
        }
        .onChange(of: snapshot.settings.currencyCode) { _, currencyCode in
            customCurrencyCode = currencyCode
        }
    }

    private var canSubmitCustomCurrency: Bool {
        let cleanCode = customCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let letters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        return cleanCode.count == 3 && cleanCode.unicodeScalars.allSatisfy { letters.contains($0) }
    }

    private func submitCustomCurrency() {
        let currencyCode = customCurrencyCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        Task { await store.updateCurrencyCode(currencyCode) }
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
