import Foundation

/// Service responsible for chat message operations.
///
/// Handles sending messages and retrieving message history. Used internally by `AICoach`.
final class ChatService: Sendable {

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// Retrieves the message history for a specific session.
    ///
    /// - Parameter sessionId: The UUID of the chat session.
    /// - Returns: An array of `ChatMessage` objects in chronological order.
    /// - Throws: `AICoachError` for any failure.
    func getMessages(sessionId: UUID) async throws -> [ChatMessage] {
        try await client.request(.getMessages(sessionId: sessionId), as: [ChatMessage].self)
    }

    /// Sends a message to the AI coach and returns the response.
    ///
    /// This is a synchronous request — the method will wait for the AI to
    /// generate its full response before returning. This may take several seconds
    /// depending on the response length and server load.
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the chat session.
    ///   - request: The message content to send.
    /// - Returns: The AI coach's response as a `ChatMessage`.
    /// - Throws: `AICoachError` for any failure.
    func sendMessage(sessionId: UUID, request: SendMessageRequest) async throws -> ChatMessage {
        try request.validateForTransport()

        let endpoint: Endpoint
        do {
            endpoint = try .sendMessage(sessionId: sessionId, request: request)
        } catch {
            throw AICoachError.encodingFailed(error)
        }

        return try await client.request(endpoint, as: ChatMessage.self)
    }
}
