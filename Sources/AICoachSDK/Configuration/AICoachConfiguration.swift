import Foundation

/// Configuration for the AICoachSDK.
///
/// Create a configuration with your API key and base URL, then pass it to `AICoach.configure(_:)`.
///
/// ```swift
/// let config = AICoachConfiguration(
///     apiKey: "your-api-key",
///     baseURL: URL(string: "https://your-backend.com")!,
///     userId: "user-123"
/// )
/// try AICoach.configure(config)
/// ```
public struct AICoachConfiguration: Sendable {

    /// The API key issued from the admin panel. Sent as `X-API-Key` header.
    public let apiKey: String

    /// The base URL of the AI Coach backend (e.g., `https://api.example.com`).
    public let baseURL: URL

    /// The current user's identifier. Sent as `X-User-Id` header.
    public var userId: String

    /// Platform identifier sent with new sessions (defaults to `"iOS"`).
    public var platform: String

    /// Request timeout interval in seconds. Defaults to 60 seconds
    /// to accommodate AI response generation time.
    public var timeoutInterval: TimeInterval

    /// Whether to enable verbose debug logging. Defaults to `false`.
    public var enableLogging: Bool

    /// The URLSession configuration to use. Defaults to `.default`.
    public var sessionConfiguration: URLSessionConfiguration

    /// Creates a new SDK configuration.
    ///
    /// - Parameters:
    ///   - apiKey: The tenant API key from the admin panel.
    ///   - baseURL: The backend base URL.
    ///   - userId: The current user's identifier.
    ///   - platform: Platform identifier (defaults to `"iOS"`).
    ///   - timeoutInterval: Request timeout in seconds (defaults to `60`).
    ///   - enableLogging: Enable debug logging (defaults to `false`).
    ///   - sessionConfiguration: URLSession configuration (defaults to `.default`).
    ///
    /// - Important: Production configurations must use HTTPS. Plain HTTP is only
    ///   accepted for loopback development hosts such as `localhost`.
    public init(
        apiKey: String,
        baseURL: URL,
        userId: String,
        platform: String = "iOS",
        timeoutInterval: TimeInterval = 60,
        enableLogging: Bool = false,
        sessionConfiguration: URLSessionConfiguration = .default
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.userId = userId
        self.platform = platform
        self.timeoutInterval = timeoutInterval
        self.enableLogging = enableLogging
        self.sessionConfiguration = sessionConfiguration
    }
}
