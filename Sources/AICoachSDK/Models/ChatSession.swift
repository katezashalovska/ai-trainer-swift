import Foundation

/// Represents a chat session with an AI coach.
///
/// A session groups a conversation between a user and a specific coach.
/// Each session has its own message history and metadata.
public struct ChatSession: Codable, Identifiable, Sendable, Hashable {

    /// Unique identifier for this session.
    public let id: UUID

    /// The user who owns this session.
    public let userId: String?

    /// The coach ID associated with this session.
    public let coachId: String?

    /// The display name of the coach.
    public let coachName: String?

    /// The user's email, if provided.
    public let userEmail: String?

    /// The platform this session was created from (e.g., `"iOS"`).
    public let platform: String?

    /// A preview of the last message in the session.
    public let lastMessagePreview: String?

    /// The timestamp of the last message.
    public let lastMessageAt: Date?

    /// Total number of messages in this session.
    public let messageCount: Int?

    /// When this session was created.
    public let createdAt: Date?
    
    public init(id: UUID, userId: String?, coachId: String?, coachName: String?, userEmail: String?, platform: String?, lastMessagePreview: String?, lastMessageAt: Date?, messageCount: Int?, createdAt: Date?) {
        self.id = id
        self.userId = userId
        self.coachId = coachId
        self.coachName = coachName
        self.userEmail = userEmail
        self.platform = platform
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.messageCount = messageCount
        self.createdAt = createdAt
    }
}

// MARK: - CustomStringConvertible

extension ChatSession: CustomStringConvertible {
    public var description: String {
        "ChatSession(id: \(id), coach: \(coachName ?? "unknown"), messages: \(messageCount ?? 0))"
    }
}
