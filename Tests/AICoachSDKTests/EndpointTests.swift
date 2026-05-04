import XCTest
@testable import AICoachSDK

final class EndpointTests: XCTestCase {

    private let testConfig = AICoachConfiguration(
        apiKey: "test-api-key-123",
        baseURL: URL(string: "https://api.example.com")!,
        userId: "test-user-456"
    )

    // MARK: - GET Sessions

    func testGetCoachesEndpoint() throws {
        let endpoint = Endpoint.getCoaches()
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/coaches")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
    }

    func testGetCoachEndpoint() throws {
        let coachId = UUID(uuidString: "c0ac4444-1111-2222-3333-444444444444")!
        let endpoint = Endpoint.getCoach(id: coachId)
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.example.com/v1/coaches/C0AC4444-1111-2222-3333-444444444444"
        )
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
    }

    func testGetSessionsEndpoint() throws {
        let endpoint = Endpoint.getSessions()
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/chat/sessions")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "test-api-key-123")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-User-Id"), "test-user-456")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertNil(request.httpBody)
    }

    // MARK: - POST Create Session

    func testCreateSessionEndpoint() throws {
        let createRequest = CreateSessionRequest(
            coachId: "coach-789",
            platform: "iOS",
            userState: "Beginner user"
        )
        let endpoint = try Endpoint.createSession(createRequest)
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(request.url?.absoluteString, "https://api.example.com/v1/chat/sessions")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(request.httpBody)

        // Verify body content
        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        XCTAssertEqual(body["coachId"] as? String, "coach-789")
        XCTAssertEqual(body["platform"] as? String, "iOS")
        XCTAssertEqual(body["userState"] as? String, "Beginner user")
    }

    // MARK: - GET Messages

    func testGetMessagesEndpoint() throws {
        let sessionId = UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890")!
        let endpoint = Endpoint.getMessages(sessionId: sessionId)
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.example.com/v1/chat/sessions/A1B2C3D4-E5F6-7890-ABCD-EF1234567890/messages"
        )
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertNil(request.httpBody)
    }

    // MARK: - DELETE Session

    func testDeleteSessionEndpoint() throws {
        let sessionId = UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890")!
        let endpoint = Endpoint.deleteSession(sessionId: sessionId)
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(
            request.url?.absoluteString,
            "https://api.example.com/v1/chat/sessions/A1B2C3D4-E5F6-7890-ABCD-EF1234567890"
        )
        XCTAssertEqual(request.httpMethod, "DELETE")
        XCTAssertNil(request.httpBody)
    }

    // MARK: - POST Send Message

    func testSendMessageEndpoint() throws {
        let sessionId = UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890")!
        let messageRequest = SendMessageRequest(content: "Hello coach!")
        let endpoint = try Endpoint.sendMessage(sessionId: sessionId, request: messageRequest)
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertTrue(request.url!.absoluteString.contains("/v1/chat/sessions/"))
        XCTAssertTrue(request.url!.absoluteString.contains("/messages"))
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        XCTAssertEqual(body["content"] as? String, "Hello coach!")
    }

    // MARK: - Auth Headers

    func testAuthHeadersPresent() throws {
        let endpoint = Endpoint.getSessions()
        let request = try endpoint.urlRequest(with: testConfig)

        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "test-api-key-123")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-User-Id"), "test-user-456")
    }

    // MARK: - Timeout

    func testTimeoutInterval() throws {
        var config = testConfig
        config = AICoachConfiguration(
            apiKey: testConfig.apiKey,
            baseURL: testConfig.baseURL,
            userId: testConfig.userId,
            timeoutInterval: 120
        )

        let endpoint = Endpoint.getSessions()
        let request = try endpoint.urlRequest(with: config)

        XCTAssertEqual(request.timeoutInterval, 120)
    }

    // MARK: - Base URL Variants

    func testBaseURLWithTrailingSlash() throws {
        let config = AICoachConfiguration(
            apiKey: "key",
            baseURL: URL(string: "https://api.example.com/")!,
            userId: "user"
        )
        let endpoint = Endpoint.getSessions()
        let request = try endpoint.urlRequest(with: config)

        XCTAssertNotNil(request.url)
        XCTAssertTrue(request.url!.absoluteString.contains("/v1/chat/sessions"))
    }

    func testBaseURLWithPort() throws {
        let config = AICoachConfiguration(
            apiKey: "key",
            baseURL: URL(string: "http://localhost:8080")!,
            userId: "user"
        )
        let endpoint = Endpoint.getSessions()
        let request = try endpoint.urlRequest(with: config)

        XCTAssertTrue(request.url!.absoluteString.starts(with: "http://localhost:8080"))
    }
}
