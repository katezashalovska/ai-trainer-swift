import XCTest
@testable import AICoachSDK

final class AICoachTests: XCTestCase {

    // MARK: - Configuration

    func testConfigureSDK() throws {
        try AICoach.configure(
            apiKey: "test-key",
            baseURL: URL(string: "https://api.example.com")!,
            userId: "user-123"
        )

        XCTAssertTrue(AICoach.isConfigured)
        XCTAssertNotNil(AICoach.shared)
        XCTAssertEqual(AICoach.shared.configuration.apiKey, "test-key")
        XCTAssertEqual(AICoach.shared.configuration.userId, "user-123")
        XCTAssertEqual(AICoach.shared.configuration.platform, "iOS")
    }

    func testConfigureWithCustomOptions() throws {
        let config = AICoachConfiguration(
            apiKey: "custom-key",
            baseURL: URL(string: "http://localhost:8080")!,
            userId: "user-456",
            platform: "iPadOS",
            timeoutInterval: 120,
            enableLogging: true
        )
        try AICoach.configure(config)

        XCTAssertEqual(AICoach.shared.configuration.apiKey, "custom-key")
        XCTAssertEqual(AICoach.shared.configuration.platform, "iPadOS")
        XCTAssertEqual(AICoach.shared.configuration.timeoutInterval, 120)
        XCTAssertEqual(AICoach.shared.configuration.enableLogging, true)
    }

    func testDefaultConfiguration() {
        let config = AICoachConfiguration(
            apiKey: "key",
            baseURL: URL(string: "https://api.example.com")!,
            userId: "user"
        )

        XCTAssertEqual(config.platform, "iOS")
        XCTAssertEqual(config.timeoutInterval, 60)
        XCTAssertEqual(config.enableLogging, false)
    }

    func testConfigureRejectsInsecureRemoteBaseURL() {
        let config = AICoachConfiguration(
            apiKey: "key",
            baseURL: URL(string: "http://api.example.com")!,
            userId: "user"
        )

        XCTAssertThrowsError(try AICoach.configure(config)) { error in
            guard case AICoachError.invalidConfiguration = error else {
                XCTFail("Expected invalidConfiguration error, got \(error)")
                return
            }
        }
    }

    func testUpdateUserIDValidatesNewValue() throws {
        try AICoach.configure(
            apiKey: "test-key",
            baseURL: URL(string: "https://api.example.com")!,
            userId: "user-123"
        )

        XCTAssertThrowsError(try AICoach.shared.updateUserId("   "))
    }

    // MARK: - Errors

    func testErrorDescriptions() {
        let errors: [AICoachError] = [
            .notConfigured,
            .invalidURL("bad-url"),
            .unauthorized,
            .rateLimited,
            .notFound,
            .serverError(statusCode: 500),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have a description")
            XCTAssertTrue(error.errorDescription!.contains("[AICoachSDK]"))
        }
    }

    func testHTTPErrorResponseData() {
        let data = "Error details".data(using: .utf8)
        let error = AICoachError.httpError(statusCode: 422, data: data)

        XCTAssertEqual(error.responseBody, "Error details")
    }

    func testHTTPErrorWithoutData() {
        let error = AICoachError.unauthorized

        XCTAssertNil(error.responseData)
        XCTAssertNil(error.responseBody)
    }

    // MARK: - ChatMessage Convenience

    func testMessageIsFromUser() throws {
        let json = """
        {"id": "11111111-2222-3333-4444-555555555555", "sender": "user", "content": "hi"}
        """.data(using: .utf8)!
        let msg = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertTrue(msg.isFromUser)
        XCTAssertFalse(msg.isFromCoach)
    }

    func testMessageIsFromCoach() throws {
        let json = """
        {"id": "11111111-2222-3333-4444-555555555555", "sender": "assistant", "content": "hello"}
        """.data(using: .utf8)!
        let msg = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertFalse(msg.isFromUser)
        XCTAssertTrue(msg.isFromCoach)
    }

    func testMessageHasNoPhoto() throws {
        let json = """
        {"id": "11111111-2222-3333-4444-555555555555", "content": "test"}
        """.data(using: .utf8)!
        let msg = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertFalse(msg.hasPhoto)
    }

    func testMessageHasEmptyPhotoUrl() throws {
        let json = """
        {"id": "11111111-2222-3333-4444-555555555555", "content": "test", "photoUrl": ""}
        """.data(using: .utf8)!
        let msg = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertFalse(msg.hasPhoto)
    }
}
