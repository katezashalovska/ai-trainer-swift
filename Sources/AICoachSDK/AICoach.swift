import Foundation

/// The main entry point for the AI Coach SDK.
///
/// `AICoach` provides a simple, high-level API for integrating AI coaching
/// into your iOS application. Configure it once at app startup, then use
/// the `shared` instance to interact with the AI Coach backend.
///
/// ## Quick Start
///
/// ```swift
/// // 1. Configure at app startup
/// let config = AICoachConfiguration(
///     apiKey: "your-api-key",
///     baseURL: URL(string: "https://your-backend.com")!,
///     userId: "user-123"
/// )
/// try AICoach.configure(config)
///
/// // 2. Create a session and start chatting
/// let session = try await AICoach.shared.createSession(coachId: "coach-uuid")
/// let response = try await AICoach.shared.sendMessage(
///     sessionId: session.id,
///     content: "How should I start my workout?"
/// )
/// print(response.content)
/// ```
///
/// ## Updating User ID
///
/// If your user logs in/out, update the user ID:
/// ```swift
/// AICoach.shared.updateUserId("new-user-id")
/// ```
public final class AICoach: @unchecked Sendable {

    // MARK: - Singleton

    /// The shared SDK instance. Only available after calling `configure(_:)`.
    ///
    /// - Important: You must call `AICoach.configure(_:)` before accessing this property.
    public private(set) static var shared: AICoach!

    /// Whether the SDK has been configured.
    public static var isConfigured: Bool {
        shared != nil
    }

    // MARK: - Properties

    /// The current SDK configuration.
    public private(set) var configuration: AICoachConfiguration

    private let client: APIClient
    private let coachService: CoachService
    private let sessionService: SessionService
    private let chatService: ChatService
    private let logger: Logger

    // MARK: - Initialization

    private init(configuration: AICoachConfiguration) {
        self.configuration = configuration
        self.client = APIClient(configuration: configuration)
        self.coachService = CoachService(client: client)
        self.sessionService = SessionService(client: client, configuration: configuration)
        self.chatService = ChatService(client: client)
        self.logger = Logger(enabled: configuration.enableLogging)
    }

    /// Configures the SDK with the provided configuration.
    ///
    /// Call this once at app startup (e.g., in `AppDelegate` or `App.init`).
    ///
    /// ```swift
    /// try AICoach.configure(AICoachConfiguration(
    ///     apiKey: "your-api-key",
    ///     baseURL: URL(string: "https://api.example.com")!,
    ///     userId: "user-123"
    /// ))
    /// ```
    ///
    /// - Parameter configuration: The SDK configuration.
    public static func configure(_ configuration: AICoachConfiguration) throws {
        let validatedConfiguration = try configuration.validated()
        shared = AICoach(configuration: validatedConfiguration)
        shared.logger.log("SDK configured — base URL: \(validatedConfiguration.baseURL.absoluteString)")
    }

    /// Convenience initializer that configures the SDK inline.
    ///
    /// ```swift
    /// try AICoach.configure(
    ///     apiKey: "your-api-key",
    ///     baseURL: URL(string: "https://api.example.com")!,
    ///     userId: "user-123"
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - apiKey: The tenant API key.
    ///   - baseURL: The backend base URL.
    ///   - userId: The current user's identifier.
    ///   - enableLogging: Whether to enable debug logging (defaults to `false`).
    public static func configure(
        apiKey: String,
        baseURL: URL,
        userId: String,
        enableLogging: Bool = false
    ) throws {
        let config = AICoachConfiguration(
            apiKey: apiKey,
            baseURL: baseURL,
            userId: userId,
            enableLogging: enableLogging
        )
        try configure(config)
    }

    // MARK: - User Management

    /// Updates the current user ID.
    ///
    /// Use this when the user logs in, logs out, or switches accounts.
    /// This will reconfigure the internal HTTP client with the new user ID.
    ///
    /// - Parameter userId: The new user identifier.
    public func updateUserId(_ userId: String) throws {
        var newConfig = configuration
        newConfig.userId = userId
        try AICoach.configure(newConfig)
        logger.log("User ID updated to: \(userId)")
    }

    // MARK: - Sessions

    /// Retrieves all coaches available to the current client app.
    ///
    /// - Returns: An array of `Coach` objects.
    /// - Throws: `AICoachError` if the request fails.
    public func getCoaches() async throws -> [Coach] {
        try ensureConfigured()
        return try await coachService.getCoaches()
    }

    /// Retrieves a single coach profile by its identifier.
    ///
    /// - Parameter id: The coach UUID.
    /// - Returns: The full `Coach` profile.
    /// - Throws: `AICoachError` if the request fails.
    public func getCoach(id: UUID) async throws -> Coach {
        try ensureConfigured()
        return try await coachService.getCoach(id: id)
    }

    /// Retrieves all chat sessions for the current user.
    ///
    /// - Returns: An array of `ChatSession` objects.
    /// - Throws: `AICoachError` if the request fails.
    public func getSessions() async throws -> [ChatSession] {
        try ensureConfigured()
        return try await sessionService.getSessions()
    }

    /// Creates a new chat session with a coach.
    ///
    /// - Parameter request: The session creation parameters.
    /// - Returns: The newly created `ChatSession`.
    /// - Throws: `AICoachError` if the request fails.
    public func createSession(_ request: CreateSessionRequest) async throws -> ChatSession {
        try ensureConfigured()
        return try await sessionService.createSession(request)
    }

    /// Creates a new chat session with a coach (convenience method).
    ///
    /// ```swift
    /// let session = try await AICoach.shared.createSession(
    ///     coachId: "coach-uuid",
    ///     userState: "Beginner, wants to build muscle"
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - coachId: The ID of the coach to chat with.
    ///   - userState: Optional context about the user (max 4000 chars).
    /// - Returns: The newly created `ChatSession`.
    /// - Throws: `AICoachError` if the request fails.
    public func createSession(coachId: String, userState: String? = nil) async throws -> ChatSession {
        let request = CreateSessionRequest(coachId: coachId, userState: userState)
        return try await createSession(request)
    }

    /// Deletes an existing chat session.
    ///
    /// - Parameter sessionId: The UUID of the chat session to delete.
    /// - Throws: `AICoachError` if the request fails.
    public func deleteSession(sessionId: UUID) async throws {
        try ensureConfigured()
        try await sessionService.deleteSession(sessionId: sessionId)
    }

    // MARK: - Messages

    /// Retrieves the message history for a specific session.
    ///
    /// - Parameter sessionId: The UUID of the chat session.
    /// - Returns: An array of `ChatMessage` objects in chronological order.
    /// - Throws: `AICoachError` if the request fails.
    public func getMessages(sessionId: UUID) async throws -> [ChatMessage] {
        try ensureConfigured()
        return try await chatService.getMessages(sessionId: sessionId)
    }

    /// Sends a message to the AI coach and returns the response.
    ///
    /// This method waits for the AI to generate its full response before returning.
    /// This may take several seconds depending on server load and response length.
    ///
    /// ```swift
    /// let response = try await AICoach.shared.sendMessage(
    ///     sessionId: session.id,
    ///     content: "What exercises should I do today?"
    /// )
    /// print(response.content ?? "No response")
    /// ```
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the chat session.
    ///   - content: The message text (max 8000 characters).
    /// - Returns: The AI coach's response as a `ChatMessage`.
    /// - Throws: `AICoachError` if the request fails.
    public func sendMessage(sessionId: UUID, content: String) async throws -> ChatMessage {
        let request = SendMessageRequest(content: content)
        return try await sendMessage(sessionId: sessionId, request: request)
    }

    /// Sends a message with full request options.
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the chat session.
    ///   - request: The message request with content and optional photo URL.
    /// - Returns: The AI coach's response as a `ChatMessage`.
    /// - Throws: `AICoachError` if the request fails.
    public func sendMessage(sessionId: UUID, request: SendMessageRequest) async throws -> ChatMessage {
        try ensureConfigured()
        return try await chatService.sendMessage(sessionId: sessionId, request: request)
    }

    // MARK: - Private

    private func ensureConfigured() throws {
        guard AICoach.isConfigured else {
            throw AICoachError.notConfigured
        }
    }
}
