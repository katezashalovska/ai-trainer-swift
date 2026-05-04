import Foundation

/// Represents a single message in a chat session.
///
/// Messages can be from the user or from the AI coach, determined by the `sender` field.
public struct ChatMessage: Codable, Identifiable, Sendable, Hashable {

    /// Unique identifier for this message.
    public let id: UUID

    /// The session this message belongs to.
    public let sessionId: UUID?

    /// Who sent this message. Typically `"user"` or `"assistant"`.
    public let sender: String?

    /// The text content of the message.
    public let content: String?

    /// URL of an attached photo, if any.
    public let photoUrl: String?

    /// User rating of this message (e.g., `"up"`, `"down"`), if any.
    public let rating: String?

    /// When this message was created.
    public let createdAt: Date?
    
    public init(id: UUID, sessionId: UUID?, sender: String?, content: String?, photoUrl: String?, rating: String?, createdAt: Date?) {
        self.id = id
        self.sessionId = sessionId
        self.sender = sender
        self.content = content
        self.photoUrl = photoUrl
        self.rating = rating
        self.createdAt = createdAt
    }

    // MARK: - Convenience

    /// Whether this message was sent by the user.
    public var isFromUser: Bool {
        sender?.lowercased() == "user"
    }

    /// Whether this message was sent by the AI coach.
    public var isFromCoach: Bool {
        sender?.lowercased() == "assistant" || sender?.lowercased() == "coach"
    }

    /// Whether this message has a photo attachment.
    public var hasPhoto: Bool {
        guard let url = photoUrl else { return false }
        return !url.isEmpty
    }
}

// MARK: - CustomStringConvertible

extension ChatMessage: CustomStringConvertible {
    public var description: String {
        let preview = (content ?? "").prefix(50)
        return "ChatMessage(id: \(id), sender: \(sender ?? "?"), content: \"\(preview)...\")"
    }
}
