import Foundation

/// Request body for creating a new chat session.
///
/// ```swift
/// let request = CreateSessionRequest(coachId: "coach-uuid")
/// let session = try await AICoach.shared.createSession(request)
/// ```
public struct CreateSessionRequest: Codable, Sendable {

    /// The ID of the coach to chat with. May be a UUID string or a custom identifier.
    public let coachId: String?

    /// The platform identifier (e.g., `"iOS"`, `"Android"`).
    /// If `nil`, the SDK will use the platform from `AICoachConfiguration`.
    public let platform: String?

    /// Optional context about the user's current state.
    /// This is sent to the AI to provide personalized responses.
    /// Maximum 4000 characters.
    ///
    /// Example: `"User is 25yo male, beginner, goal: lose weight"`
    public let userState: String?

    /// Creates a new session request.
    ///
    /// - Parameters:
    ///   - coachId: The coach ID to start a session with.
    ///   - platform: Platform identifier (defaults to `nil`, SDK fills from config).
    ///   - userState: Optional user context for the AI (max 4000 chars).
    public init(
        coachId: String? = nil,
        platform: String? = nil,
        userState: String? = nil
    ) {
        self.coachId = coachId
        self.platform = platform
        self.userState = userState
    }

    /// Validates the request before it is sent to the backend.
    public func validate() throws {
        try validateForTransport()
    }
}

/// Request body for sending a message in a chat session.
///
/// ```swift
/// let request = SendMessageRequest(content: "How do I improve my form?")
/// let response = try await AICoach.shared.sendMessage(sessionId: session.id, request: request)
/// ```
public struct SendMessageRequest: Codable, Sendable {

    /// The text content of the message. Required. Maximum 8000 characters.
    public let content: String

    /// Optional URL to a photo attachment.
    /// The client app is responsible for uploading the photo and providing the URL.
    public let photoUrl: String?

    /// Creates a new message request.
    ///
    /// - Parameters:
    ///   - content: The message text (max 8000 characters).
    ///   - photoUrl: Optional photo URL.
    public init(content: String, photoUrl: String? = nil) {
        self.content = content
        self.photoUrl = photoUrl
    }

    /// Validates the request before it is sent to the backend.
    public func validate() throws {
        try validateForTransport()
    }
}
