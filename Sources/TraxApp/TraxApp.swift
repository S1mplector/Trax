import SwiftUI
import TraxApplication
import TraxFilePersistence

@main
struct TraxApp: App {
    @StateObject private var store: ExpenseStore

    init() {
        let repository: FileExpenseBookRepository

        do {
            repository = try FileExpenseBookRepository.live()
        } catch {
            let fallbackURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Trax", isDirectory: true)
                .appendingPathComponent("expense-book.json")
            repository = FileExpenseBookRepository(fileURL: fallbackURL)
        }

        let tracker = ExpenseTracker(repository: repository)
        _store = StateObject(wrappedValue: ExpenseStore(tracker: tracker, fileRepository: repository))
    }

    var body: some Scene {
        MenuBarExtra("Trax", systemImage: "creditcard") {
            MenuBarContentView()
                .environmentObject(store)
                .task {
                    await store.load()
                }
        }
        .menuBarExtraStyle(.window)
    }
}
