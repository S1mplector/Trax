import Foundation
import TraxApplication
import TraxDomain

public actor FileExpenseBookRepository: ExpenseBookRepository {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public static func live(fileManager: FileManager = .default) throws -> FileExpenseBookRepository {
        let directory = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("Trax", isDirectory: true)

        return FileExpenseBookRepository(
            fileURL: directory.appendingPathComponent("expense-book.json")
        )
    }

    public func load() async throws -> ExpenseBook {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return ExpenseBook()
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(ExpenseBook.self, from: data)
    }

    public func save(_ book: ExpenseBook) async throws {
        let data = try encoder.encode(book)
        let directoryURL = fileURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try backupCurrentFileIfNeeded()
        try data.write(to: fileURL, options: [.atomic])
    }

    public func exportJSON(_ book: ExpenseBook, to destinationURL: URL) async throws {
        let data = try encoder.encode(book)
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destinationURL, options: [.atomic])
    }

    public func exportCSV(_ book: ExpenseBook, currencyCode: String, to destinationURL: URL) async throws {
        let categoriesByID = Dictionary(uniqueKeysWithValues: book.categories.map { ($0.id, $0) })
        let lines = [
            "date,amount,currency,category,essential,note,created_at"
        ] + book.expenses.map { expense in
            let category = categoriesByID[expense.categoryID]
            return [
                expense.day.id,
                "\(expense.amount)",
                currencyCode,
                category?.name ?? "Unknown",
                category?.isEssential == true ? "yes" : "no",
                expense.note,
                ISO8601DateFormatter().string(from: expense.createdAt)
            ]
            .map(csvField)
            .joined(separator: ",")
        }

        let data = Data(lines.joined(separator: "\n").utf8)
        try fileManager.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destinationURL, options: [.atomic])
    }

    public func importBook(from sourceURL: URL) async throws -> ExpenseBook {
        let data = try Data(contentsOf: sourceURL)
        return try decoder.decode(ExpenseBook.self, from: data)
    }

    public var storageDirectoryURL: URL {
        fileURL.deletingLastPathComponent()
    }

    private func backupCurrentFileIfNeeded() throws {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        let backupURL = fileURL.appendingPathExtension("bak")
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        try fileManager.copyItem(at: fileURL, to: backupURL)
    }

    private func csvField(_ value: String) -> String {
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedValue)\""
    }

    private var fileManager: FileManager {
        FileManager.default
    }
}
