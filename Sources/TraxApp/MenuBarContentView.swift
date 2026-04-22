import AppKit
import SwiftUI
import TraxApplication
import TraxDomain

struct MenuBarContentView: View {
    @EnvironmentObject private var store: ExpenseStore
    @State private var selectedSection = Section.today
    @State private var isShowingSpendingBreakdown = false
    @State private var selectedDayDetail: Day?

    var body: some View {
        Group {
            if let selectedDayDetail, let snapshot = store.snapshot {
                DayDetailView(
                    snapshot: snapshot,
                    day: selectedDayDetail,
                    showDay: { day in
                        self.selectedDayDetail = day
                    },
                    close: {
                        self.selectedDayDetail = nil
                    }
                )
            } else if isShowingSpendingBreakdown, let snapshot = store.snapshot {
                SpendingBreakdownView(snapshot: snapshot) {
                    isShowingSpendingBreakdown = false
                }
            } else {
                mainPanel
            }
        }
        .frame(width: 420)
        .alert(
            "Trax",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if $0 == false { store.errorMessage = nil } }
            ),
            actions: {
                Button("OK") {
                    store.errorMessage = nil
                }
            },
            message: {
                Text(store.errorMessage ?? "")
            }
        )
    }

    private var mainPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            Picker("Section", selection: $selectedSection) {
                ForEach(Section.allCases) { section in
                    Text(section.title).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Divider()

            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.trailing, 4)
            }
            .frame(height: 420)

            footer
        }
        .padding(14)
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = store.snapshot {
            switch selectedSection {
            case .today:
                TodayView(
                    snapshot: snapshot,
                    showSpendingBreakdown: {
                        isShowingSpendingBreakdown = true
                    },
                    showDayDetail: { day in
                        selectedDayDetail = day
                    }
                )
            case .expenses:
                ExpenseEntryView(snapshot: snapshot)
            case .categories:
                CategoriesView(snapshot: snapshot)
            case .settings:
                SettingsView(snapshot: snapshot)
            }
        } else if store.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("Trax could not load.")
                    .font(.headline)
                Button("Try again") {
                    Task { await store.load() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Trax")
                    .font(.title2.weight(.semibold))
                Text(selectedSection.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if store.isLoading {
                ProgressView()
                    .controlSize(.small)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Refresh") {
                Task { await store.load() }
            }

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .font(.caption)
    }
}

private enum Section: String, CaseIterable, Identifiable {
    case today
    case expenses
    case categories
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .expenses:
            return "Expenses"
        case .categories:
            return "Categories"
        case .settings:
            return "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .today:
            return "Daily no-buy check-in"
        case .expenses:
            return "Quick expense logging"
        case .categories:
            return "Keep spending buckets tidy"
        case .settings:
            return "Currency and preferences"
        }
    }
}
