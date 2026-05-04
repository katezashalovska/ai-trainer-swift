import Foundation

/// HTTP methods supported by the API.
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Defines an API endpoint with its path, method, and optional body.
struct Endpoint {
    let path: String
    let method: HTTPMethod
    let body: Data?

    init(path: String, method: HTTPMethod, body: Data? = nil) {
        self.path = path
        self.method = method
        self.body = body
    }

    /// Builds a full `URLRequest` from this endpoint and configuration.
    ///
    /// - Parameter configuration: The SDK configuration containing base URL and auth.
    /// - Returns: A configured `URLRequest`.
    /// - Throws: `AICoachError.invalidURL` if the URL cannot be constructed.
    func urlRequest(with configuration: AICoachConfiguration) throws -> URLRequest {
        let validatedConfiguration = try configuration.validated()

        guard let url = URL(string: path, relativeTo: validatedConfiguration.baseURL) else {
            throw AICoachError.invalidURL("\(configuration.baseURL.absoluteString)\(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = validatedConfiguration.timeoutInterval

        // Auth headers
        request.setValue(validatedConfiguration.apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue(validatedConfiguration.userId, forHTTPHeaderField: "X-User-Id")

        // Content type
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        request.setValue("application/json", forHTTPHeaderField: "Accept")

        return request
    }
}

// MARK: - Client Chat API Endpoints

extension Endpoint {

    /// `GET /v1/coaches` — List all coaches available to the current client app.
    static func getCoaches() -> Endpoint {
        Endpoint(path: "/v1/coaches", method: .get)
    }

    /// `GET /v1/coaches/{id}` — Get a single coach profile.
    ///
    /// - Parameter id: The UUID of the coach.
    static func getCoach(id: UUID) -> Endpoint {
        Endpoint(path: "/v1/coaches/\(id.uuidString)", method: .get)
    }

    /// `GET /v1/chat/sessions` — List all chat sessions for the current user.
    static func getSessions() -> Endpoint {
        Endpoint(path: "/v1/chat/sessions", method: .get)
    }

    /// `POST /v1/chat/sessions` — Create a new chat session.
    ///
    /// - Parameter request: The session creation parameters.
    /// - Throws: `AICoachError.encodingFailed` if the body cannot be encoded.
    static func createSession(_ request: CreateSessionRequest) throws -> Endpoint {
        let body = try JSONEncoder.apiEncoder.encode(request)
        return Endpoint(path: "/v1/chat/sessions", method: .post, body: body)
    }

    /// `DELETE /v1/chat/sessions/{sessionId}` — Delete a chat session.
    ///
    /// - Parameter sessionId: The UUID of the chat session.
    static func deleteSession(sessionId: UUID) -> Endpoint {
        Endpoint(path: "/v1/chat/sessions/\(sessionId.uuidString)", method: .delete)
    }

    /// `GET /v1/chat/sessions/{sessionId}/messages` — Get message history.
    ///
    /// - Parameter sessionId: The UUID of the chat session.
    static func getMessages(sessionId: UUID) -> Endpoint {
        Endpoint(path: "/v1/chat/sessions/\(sessionId.uuidString)/messages", method: .get)
    }

    /// `POST /v1/chat/sessions/{sessionId}/messages` — Send a message and get AI response.
    ///
    /// - Parameters:
    ///   - sessionId: The UUID of the chat session.
    ///   - request: The message content.
    /// - Throws: `AICoachError.encodingFailed` if the body cannot be encoded.
    static func sendMessage(sessionId: UUID, request: SendMessageRequest) throws -> Endpoint {
        let body = try JSONEncoder.apiEncoder.encode(request)
        return Endpoint(path: "/v1/chat/sessions/\(sessionId.uuidString)/messages", method: .post, body: body)
    }
}
