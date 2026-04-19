import Foundation

public struct ExpenseCategory: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    public var isEssential: Bool
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String,
        isEssential: Bool = false,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.isEssential = isEssential
        self.isArchived = isArchived
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.colorHex = try container.decode(String.self, forKey: .colorHex)
        self.isEssential = try container.decodeIfPresent(Bool.self, forKey: .isEssential) ?? Self.defaultEssentialNames.contains(name.lowercased())
        self.isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(colorHex, forKey: .colorHex)
        try container.encode(isEssential, forKey: .isEssential)
        try container.encode(isArchived, forKey: .isArchived)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case colorHex
        case isEssential
        case isArchived
    }

    private static let defaultEssentialNames: Set<String> = [
        "groceries",
        "transport",
        "home",
        "health"
    ]
}
