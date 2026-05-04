import Foundation

/// Errors that can occur when interacting with the AI Coach API.
public enum AICoachError: LocalizedError, Sendable {

    /// The SDK has not been configured. Call `AICoach.configure(_:)` first.
    case notConfigured

    /// The SDK configuration is invalid and cannot be used safely.
    case invalidConfiguration(String)

    /// The request payload is invalid and was rejected before it reached the network.
    case invalidRequest(field: String, reason: String)

    /// The request URL could not be constructed.
    case invalidURL(String)

    /// The request body could not be encoded.
    case encodingFailed(Error)

    /// The response body could not be decoded.
    case decodingFailed(Error)

    /// A network-level error occurred (no internet, DNS failure, timeout, etc.).
    case networkError(Error)

    /// The server returned an HTTP error status code.
    case httpError(statusCode: Int, data: Data?)

    /// The API key is invalid or expired. HTTP 401.
    case unauthorized

    /// The request was rate-limited. HTTP 429.
    case rateLimited

    /// The requested resource was not found. HTTP 404.
    case notFound

    /// The server encountered an internal error. HTTP 5xx.
    case serverError(statusCode: Int)

    /// An unknown or unexpected error occurred.
    case unknown(Error)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "[AICoachSDK] SDK is not configured. Call AICoach.configure(_:) before making requests."
        case .invalidConfiguration(let reason):
            return "[AICoachSDK] Invalid configuration: \(reason)"
        case .invalidRequest(let field, let reason):
            return "[AICoachSDK] Invalid request for \(field): \(reason)"
        case .invalidURL(let url):
            return "[AICoachSDK] Invalid URL: \(url)"
        case .encodingFailed(let error):
            return "[AICoachSDK] Failed to encode request body: \(error.localizedDescription)"
        case .decodingFailed(let error):
            return "[AICoachSDK] Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "[AICoachSDK] Network error: \(error.localizedDescription)"
        case .httpError(let code, _):
            return "[AICoachSDK] HTTP error \(code)"
        case .unauthorized:
            return "[AICoachSDK] Unauthorized — check your API key."
        case .rateLimited:
            return "[AICoachSDK] Rate limited — too many requests."
        case .notFound:
            return "[AICoachSDK] Resource not found."
        case .serverError(let code):
            return "[AICoachSDK] Server error \(code)"
        case .unknown(let error):
            return "[AICoachSDK] Unknown error: \(error.localizedDescription)"
        }
    }

    /// The raw response data for HTTP errors, if available.
    /// Useful for debugging server error messages.
    public var responseData: Data? {
        switch self {
        case .httpError(_, let data):
            return data
        default:
            return nil
        }
    }

    /// The response body as a UTF-8 string, if available.
    public var responseBody: String? {
        guard let data = responseData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
