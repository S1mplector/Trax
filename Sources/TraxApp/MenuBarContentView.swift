import AppKit
import SwiftUI
import TraxApplication
import TraxDomain

struct MenuBarContentView: View {
    @EnvironmentObject private var store: ExpenseStore
    @State private var selectedSection = Section.today

    var body: some View {
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

            content
                .frame(minHeight: 380, alignment: .top)

            footer
        }
        .padding(14)
        .frame(width: 390)
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

    @ViewBuilder
    private var content: some View {
        if let snapshot = store.snapshot {
            switch selectedSection {
            case .today:
                TodayView(snapshot: snapshot)
            case .expenses:
                ExpenseEntryView(snapshot: snapshot)
            case .categories:
                CategoriesView(snapshot: snapshot)
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
                Text("Daily spending check-in")
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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .expenses:
            return "Expenses"
        case .categories:
            return "Categories"
        }
    }
}
