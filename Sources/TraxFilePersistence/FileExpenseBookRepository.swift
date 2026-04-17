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
        try data.write(to: fileURL, options: [.atomic])
    }

    private var fileManager: FileManager {
        FileManager.default
    }
}
