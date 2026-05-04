import XCTest
@testable import AICoachSDK

final class ModelDecodingTests: XCTestCase {

    // MARK: - ChatSession

    func testDecodeChatSession() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "userId": "user-123",
            "coachId": "coach-456",
            "coachName": "Jaxson Miller",
            "userEmail": "user@example.com",
            "platform": "iOS",
            "lastMessagePreview": "How should I start?",
            "lastMessageAt": "2024-06-15T10:30:00Z",
            "messageCount": 5,
            "createdAt": "2024-06-15T09:00:00Z"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder.apiDecoder.decode(ChatSession.self, from: json)

        XCTAssertEqual(session.id, UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"))
        XCTAssertEqual(session.userId, "user-123")
        XCTAssertEqual(session.coachId, "coach-456")
        XCTAssertEqual(session.coachName, "Jaxson Miller")
        XCTAssertEqual(session.userEmail, "user@example.com")
        XCTAssertEqual(session.platform, "iOS")
        XCTAssertEqual(session.lastMessagePreview, "How should I start?")
        XCTAssertEqual(session.messageCount, 5)
        XCTAssertNotNil(session.lastMessageAt)
        XCTAssertNotNil(session.createdAt)
    }

    func testDecodeChatSessionMinimalFields() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder.apiDecoder.decode(ChatSession.self, from: json)

        XCTAssertEqual(session.id, UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"))
        XCTAssertNil(session.userId)
        XCTAssertNil(session.coachName)
        XCTAssertNil(session.messageCount)
    }

    func testDecodeChatSessionArray() throws {
        let json = """
        [
            {
                "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
                "coachName": "Jaxson Miller",
                "messageCount": 3
            },
            {
                "id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
                "coachName": "Robert Henderson",
                "messageCount": 7
            }
        ]
        """.data(using: .utf8)!

        let sessions = try JSONDecoder.apiDecoder.decode([ChatSession].self, from: json)

        XCTAssertEqual(sessions.count, 2)
        XCTAssertEqual(sessions[0].coachName, "Jaxson Miller")
        XCTAssertEqual(sessions[1].coachName, "Robert Henderson")
    }

    // MARK: - ChatMessage

    func testDecodeChatMessage() throws {
        let json = """
        {
            "id": "11111111-2222-3333-4444-555555555555",
            "sessionId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "sender": "user",
            "content": "What exercises should I do for my chest?",
            "photoUrl": null,
            "rating": null,
            "createdAt": "2024-06-15T10:30:00.123Z"
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertEqual(message.id, UUID(uuidString: "11111111-2222-3333-4444-555555555555"))
        XCTAssertEqual(message.sessionId, UUID(uuidString: "a1b2c3d4-e5f6-7890-abcd-ef1234567890"))
        XCTAssertEqual(message.sender, "user")
        XCTAssertEqual(message.content, "What exercises should I do for my chest?")
        XCTAssertTrue(message.isFromUser)
        XCTAssertFalse(message.isFromCoach)
        XCTAssertFalse(message.hasPhoto)
        XCTAssertNil(message.rating)
    }

    func testDecodeChatMessageFromCoach() throws {
        let json = """
        {
            "id": "22222222-3333-4444-5555-666666666666",
            "sessionId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "sender": "assistant",
            "content": "Great question! Here are some effective chest exercises...",
            "createdAt": "2024-06-15T10:30:05Z"
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertEqual(message.sender, "assistant")
        XCTAssertFalse(message.isFromUser)
        XCTAssertTrue(message.isFromCoach)
    }

    func testDecodeChatMessageWithPhoto() throws {
        let json = """
        {
            "id": "33333333-4444-5555-6666-777777777777",
            "sender": "user",
            "content": "Is my form correct?",
            "photoUrl": "https://storage.example.com/photos/form-check.jpg"
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)

        XCTAssertTrue(message.hasPhoto)
        XCTAssertEqual(message.photoUrl, "https://storage.example.com/photos/form-check.jpg")
    }

    // MARK: - Coach

    func testDecodeCoach() throws {
        let json = """
        {
            "id": "c0ac4444-1111-2222-3333-444444444444",
            "name": "Jaxson Miller",
            "tone": "motivational",
            "specialties": ["strength training", "nutrition"],
            "focus": ["muscle building", "fat loss"],
            "bio": "Helps people build strength with sustainable habits.",
            "imageUrl": "https://cdn.example.com/coaches/jaxson.jpg",
            "rating": 4.8,
            "clientsCount": 199,
            "isActive": true,
            "createdAt": "2024-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let coach = try JSONDecoder.apiDecoder.decode(Coach.self, from: json)

        XCTAssertEqual(coach.name, "Jaxson Miller")
        XCTAssertEqual(coach.tone, "motivational")
        XCTAssertEqual(coach.specialties, ["strength training", "nutrition"])
        XCTAssertEqual(coach.focus, ["muscle building", "fat loss"])
        XCTAssertEqual(coach.bio, "Helps people build strength with sustainable habits.")
        XCTAssertEqual(coach.imageURL, "https://cdn.example.com/coaches/jaxson.jpg")
        XCTAssertEqual(coach.rating, 4.8)
        XCTAssertEqual(coach.clientsCount, 199)
        XCTAssertEqual(coach.isActive, true)
    }

    func testDecodeCoachWithFallbackKeys() throws {
        let json = """
        {
            "id": "f0ac4444-1111-2222-3333-444444444444",
            "name": "Robert Henderson",
            "description": "Nutrition-first coach",
            "avatarUrl": "https://cdn.example.com/coaches/bob.jpg",
            "clientCount": 87
        }
        """.data(using: .utf8)!

        let coach = try JSONDecoder.apiDecoder.decode(Coach.self, from: json)

        XCTAssertEqual(coach.bio, "Nutrition-first coach")
        XCTAssertEqual(coach.imageURL, "https://cdn.example.com/coaches/bob.jpg")
        XCTAssertEqual(coach.clientsCount, 87)
    }

    func testDecodeCoachWithAboutField() throws {
        let json = """
        {
            "id": "719b1144-6408-4f18-90c6-374b96e0e3d6",
            "name": "jack hanma",
            "about": "Backend-provided coach description",
            "achievements": [
                "Helped over 300+ clients significantly increase strength and muscle mass through personalized training programs"
            ],
            "reviews": [
                {
                    "reviewerName": "Larry D.",
                    "rating": 5,
                    "title": "90 days in, and my chest finally looks flat.",
                    "subtitle": "Total transformation."
                }
            ],
            "photoUrl": "https://cdn.example.com/coaches/jack.jpg",
            "isActive": true,
            "createdAt": "2026-04-28T15:07:13.205025",
            "updatedAt": "2026-04-28T15:07:13.205025"
        }
        """.data(using: .utf8)!

        let coach = try JSONDecoder.apiDecoder.decode(Coach.self, from: json)

        XCTAssertEqual(coach.bio, "Backend-provided coach description")
        XCTAssertEqual(coach.imageURL, "https://cdn.example.com/coaches/jack.jpg")
        XCTAssertEqual(coach.achievements?.count, 1)
        XCTAssertEqual(coach.reviews?.first?.reviewerName, "Larry D.")
        XCTAssertEqual(coach.reviews?.first?.rating, 5)
        XCTAssertEqual(coach.isActive, true)
        XCTAssertNotNil(coach.createdAt)
        XCTAssertNotNil(coach.updatedAt)
    }

    // MARK: - Request Encoding

    func testEncodeCreateSessionRequest() throws {
        let request = CreateSessionRequest(
            coachId: "coach-uuid",
            platform: "iOS",
            userState: "Beginner, wants to build muscle"
        )

        let data = try JSONEncoder.apiEncoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["coachId"] as? String, "coach-uuid")
        XCTAssertEqual(dict["platform"] as? String, "iOS")
        XCTAssertEqual(dict["userState"] as? String, "Beginner, wants to build muscle")
    }

    func testEncodeCreateSessionRequestMinimal() throws {
        let request = CreateSessionRequest(coachId: "coach-123")

        let data = try JSONEncoder.apiEncoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["coachId"] as? String, "coach-123")
    }

    func testEncodeSendMessageRequest() throws {
        let request = SendMessageRequest(content: "Hello coach!")

        let data = try JSONEncoder.apiEncoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["content"] as? String, "Hello coach!")
    }

    func testEncodeSendMessageRequestWithPhoto() throws {
        let request = SendMessageRequest(
            content: "Check my form",
            photoUrl: "https://example.com/photo.jpg"
        )

        let data = try JSONEncoder.apiEncoder.encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(dict["content"] as? String, "Check my form")
        XCTAssertEqual(dict["photoUrl"] as? String, "https://example.com/photo.jpg")
    }

    func testCreateSessionRequestRejectsBlankCoachID() {
        let request = CreateSessionRequest(coachId: "   ")
        XCTAssertThrowsError(try request.validate())
    }

    func testCreateSessionRequestRejectsUserStateOverLimit() {
        let request = CreateSessionRequest(
            coachId: "coach-123",
            userState: String(repeating: "a", count: 4_001)
        )

        XCTAssertThrowsError(try request.validate())
    }

    func testSendMessageRequestRejectsBlankContent() {
        let request = SendMessageRequest(content: "   ")
        XCTAssertThrowsError(try request.validate())
    }

    func testSendMessageRequestRejectsOversizedContent() {
        let request = SendMessageRequest(content: String(repeating: "a", count: 8_001))
        XCTAssertThrowsError(try request.validate())
    }

    // MARK: - Date Handling

    func testDecodeDateWithFractionalSeconds() throws {
        let json = """
        {
            "id": "11111111-2222-3333-4444-555555555555",
            "sender": "user",
            "content": "test",
            "createdAt": "2024-06-15T10:30:00.123Z"
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)
        XCTAssertNotNil(message.createdAt)
    }

    func testDecodeDateWithoutFractionalSeconds() throws {
        let json = """
        {
            "id": "11111111-2222-3333-4444-555555555555",
            "sender": "user",
            "content": "test",
            "createdAt": "2024-06-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder.apiDecoder.decode(ChatMessage.self, from: json)
        XCTAssertNotNil(message.createdAt)
    }

    func testDecodeDateWithoutTimezoneAndNanoseconds() throws {
        let json = """
        {
            "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
            "createdAt": "2026-04-28T15:11:20.593202008"
        }
        """.data(using: .utf8)!

        let session = try JSONDecoder.apiDecoder.decode(ChatSession.self, from: json)
        XCTAssertNotNil(session.createdAt)
    }

    // MARK: - Identifiable & Hashable

    func testChatSessionHashable() {
        let id = UUID()
        let json1 = """
        {"id": "\(id.uuidString)", "coachName": "Coach A"}
        """.data(using: .utf8)!
        let json2 = """
        {"id": "\(id.uuidString)", "coachName": "Coach A"}
        """.data(using: .utf8)!

        let session1 = try! JSONDecoder.apiDecoder.decode(ChatSession.self, from: json1)
        let session2 = try! JSONDecoder.apiDecoder.decode(ChatSession.self, from: json2)

        XCTAssertEqual(session1, session2)

        var set = Set<ChatSession>()
        set.insert(session1)
        set.insert(session2)
        XCTAssertEqual(set.count, 1)
    }
}
