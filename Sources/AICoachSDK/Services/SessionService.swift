import Foundation

/// Service responsible for chat session operations.
///
/// Handles creating and listing chat sessions. Used internally by `AICoach`.
final class SessionService: Sendable {

    private let client: APIClient
    private let configuration: AICoachConfiguration

    init(client: APIClient, configuration: AICoachConfiguration) {
        self.client = client
        self.configuration = configuration
    }

    /// Retrieves all chat sessions for the current user.
    ///
    /// - Returns: An array of `ChatSession` objects, ordered by the server.
    /// - Throws: `AICoachError` for any failure.
    func getSessions() async throws -> [ChatSession] {
        try await client.request(.getSessions(), as: [ChatSession].self)
    }

    /// Creates a new chat session with a specific coach.
    ///
    /// - Parameter request: The session creation parameters.
    /// - Returns: The newly created `ChatSession`.
    /// - Throws: `AICoachError` for any failure.
    func createSession(_ request: CreateSessionRequest) async throws -> ChatSession {
        // Inject platform from configuration if not provided
        let finalRequest: CreateSessionRequest
        if request.platform == nil {
            finalRequest = CreateSessionRequest(
                coachId: request.coachId,
                platform: configuration.platform,
                userState: request.userState
            )
        } else {
            finalRequest = request
        }

        try finalRequest.validateForTransport()

        let endpoint: Endpoint
        do {
            endpoint = try .createSession(finalRequest)
        } catch {
            throw AICoachError.encodingFailed(error)
        }

        return try await client.request(endpoint, as: ChatSession.self)
    }

    /// Deletes a chat session.
    ///
    /// - Parameter sessionId: The UUID of the chat session to delete.
    /// - Throws: `AICoachError` for any failure.
    func deleteSession(sessionId: UUID) async throws {
        try await client.requestVoid(.deleteSession(sessionId: sessionId))
    }
}
