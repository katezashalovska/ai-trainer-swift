import Foundation

/// Represents a review shown on the coach details screen.
public struct CoachReview: Codable, Identifiable, Sendable, Hashable {
    public let reviewerName: String?
    public let rating: Int?
    public let title: String?
    public let subtitle: String?

    public var id: String {
        "\(reviewerName ?? "reviewer")-\(title ?? "title")-\(subtitle ?? "subtitle")"
    }

    public init(
        reviewerName: String?,
        rating: Int?,
        title: String?,
        subtitle: String?
    ) {
        self.reviewerName = reviewerName
        self.rating = rating
        self.title = title
        self.subtitle = subtitle
    }
}

/// Represents an AI coach profile.
///
/// Contains the coach's identity, personality configuration, and areas of expertise.
/// Used when displaying coach selection or chat headers.
public struct Coach: Codable, Identifiable, Sendable, Hashable {

    /// Unique identifier for this coach.
    public let id: UUID

    /// The display name of the coach (e.g., `"Jaxson Miller"`).
    public let name: String

    /// The coach's communication tone (e.g., `"motivational"`, `"calm"`).
    public let tone: String?

    /// The system prompt that defines the coach's behavior (admin-only detail, may be nil).
    public let systemPrompt: String?

    /// The coach's areas of specialty (e.g., `["strength training", "nutrition"]`).
    public let specialties: [String]?

    /// The coach's focus areas (e.g., `["muscle building", "fat loss"]`).
    public let focus: [String]?

    /// Optional public bio/description for the coach.
    public let bio: String?

    /// Optional list of achievements shown in the coach details screen.
    public let achievements: [String]?

    /// Optional list of client reviews shown in the coach details screen.
    public let reviews: [CoachReview]?

    /// Optional image URL for the coach card and details view.
    public let imageURL: String?

    /// Optional public rating (e.g. 4.8).
    public let rating: Double?

    /// Optional public count used for social proof in UI (e.g. 199 clients).
    public let clientsCount: Int?

    /// Whether this coach is currently active and available.
    public let isActive: Bool?

    /// When this coach was created.
    public let createdAt: Date?

    /// When this coach was last updated.
    public let updatedAt: Date?

    public init(
        id: UUID,
        name: String,
        tone: String?,
        systemPrompt: String?,
        specialties: [String]?,
        focus: [String]?,
        bio: String? = nil,
        achievements: [String]? = nil,
        reviews: [CoachReview]? = nil,
        imageURL: String? = nil,
        rating: Double? = nil,
        clientsCount: Int? = nil,
        isActive: Bool?,
        createdAt: Date?,
        updatedAt: Date?
    ) {
        self.id = id
        self.name = name
        self.tone = tone
        self.systemPrompt = systemPrompt
        self.specialties = specialties
        self.focus = focus
        self.bio = bio
        self.achievements = achievements
        self.reviews = reviews
        self.imageURL = imageURL
        self.rating = rating
        self.clientsCount = clientsCount
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case tone
        case systemPrompt
        case specialties
        case focus
        case bio
        case about
        case description
        case achievements
        case reviews
        case imageUrl
        case imageURL
        case avatarUrl
        case photoUrl
        case rating
        case clientsCount
        case clientCount
        case isActive
        case createdAt
        case updatedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tone = try container.decodeIfPresent(String.self, forKey: .tone)
        systemPrompt = try container.decodeIfPresent(String.self, forKey: .systemPrompt)
        specialties = try container.decodeIfPresent([String].self, forKey: .specialties)
        focus = try container.decodeIfPresent([String].self, forKey: .focus)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
            ?? container.decodeIfPresent(String.self, forKey: .about)
            ?? container.decodeIfPresent(String.self, forKey: .description)
        achievements = try container.decodeIfPresent([String].self, forKey: .achievements)
        reviews = try container.decodeIfPresent([CoachReview].self, forKey: .reviews)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageUrl)
            ?? container.decodeIfPresent(String.self, forKey: .imageURL)
            ?? container.decodeIfPresent(String.self, forKey: .avatarUrl)
            ?? container.decodeIfPresent(String.self, forKey: .photoUrl)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        clientsCount = try container.decodeIfPresent(Int.self, forKey: .clientsCount)
            ?? container.decodeIfPresent(Int.self, forKey: .clientCount)
        isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(tone, forKey: .tone)
        try container.encodeIfPresent(systemPrompt, forKey: .systemPrompt)
        try container.encodeIfPresent(specialties, forKey: .specialties)
        try container.encodeIfPresent(focus, forKey: .focus)
        try container.encodeIfPresent(bio, forKey: .bio)
        try container.encodeIfPresent(achievements, forKey: .achievements)
        try container.encodeIfPresent(reviews, forKey: .reviews)
        try container.encodeIfPresent(imageURL, forKey: .imageUrl)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(clientsCount, forKey: .clientsCount)
        try container.encodeIfPresent(isActive, forKey: .isActive)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }
}

// MARK: - CustomStringConvertible

extension Coach: CustomStringConvertible {
    public var description: String {
        "Coach(id: \(id), name: \(name), specialties: \(specialties ?? []))"
    }
}
