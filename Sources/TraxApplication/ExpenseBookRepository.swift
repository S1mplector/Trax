import TraxDomain

public protocol ExpenseBookRepository: Sendable {
    func load() async throws -> ExpenseBook
    func save(_ book: ExpenseBook) async throws
}
