import Foundation

/// Internal HTTP client that executes API requests.
///
/// Handles URLSession management, request execution, response validation,
/// and JSON decoding. All auth headers are injected via `Endpoint.urlRequest(with:)`.
final class APIClient: Sendable {

    private let session: URLSession
    private let configuration: AICoachConfiguration
    private let decoder: JSONDecoder
    private let logger: Logger

    init(configuration: AICoachConfiguration) {
        self.configuration = configuration
        self.session = URLSession(configuration: configuration.sessionConfiguration)
        self.decoder = JSONDecoder.apiDecoder
        self.logger = Logger(enabled: configuration.enableLogging)
    }

    /// Executes an endpoint and decodes the response into the given type.
    ///
    /// - Parameters:
    ///   - endpoint: The endpoint to execute.
    ///   - type: The expected response type.
    /// - Returns: The decoded response object.
    /// - Throws: `AICoachError` for any failure.
    func request<T: Decodable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest(with: configuration)
        } catch {
            throw error as? AICoachError ?? .invalidURL(endpoint.path)
        }

        logger.log("→ \(endpoint.method.rawValue) \(urlRequest.url?.absoluteString ?? endpoint.path)")
        if let body = endpoint.body {
            logger.logPayload("Request payload", data: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw AICoachError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AICoachError.unknown(
                NSError(domain: "AICoachSDK", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Response is not an HTTP response"
                ])
            )
        }

        logger.log("← \(httpResponse.statusCode) (\(data.count) bytes)")

        do {
            try validateResponse(httpResponse, data: data)
        } catch {
            logger.error("HTTP error \(httpResponse.statusCode)")
            logger.logPayload("Response payload", data: data)
            throw error
        }

        do {
            let decoded = try decoder.decode(T.self, from: data)
            return decoded
        } catch {
            logger.error("Decoding error: \(error.localizedDescription)")
            logger.logPayload("Response payload", data: data)
            throw AICoachError.decodingFailed(error)
        }
    }

    /// Executes an endpoint that returns no response body (e.g., DELETE).
    ///
    /// - Parameter endpoint: The endpoint to execute.
    /// - Throws: `AICoachError` for any failure.
    func requestVoid(_ endpoint: Endpoint) async throws {
        let urlRequest: URLRequest
        do {
            urlRequest = try endpoint.urlRequest(with: configuration)
        } catch {
            throw error as? AICoachError ?? .invalidURL(endpoint.path)
        }

        logger.log("→ \(endpoint.method.rawValue) \(urlRequest.url?.absoluteString ?? endpoint.path)")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw AICoachError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AICoachError.unknown(
                NSError(domain: "AICoachSDK", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Response is not an HTTP response"
                ])
            )
        }

        logger.log("← \(httpResponse.statusCode)")
        do {
            try validateResponse(httpResponse, data: data)
        } catch {
            logger.error("HTTP error \(httpResponse.statusCode)")
            logger.logPayload("Response payload", data: data)
            throw error
        }
    }

    // MARK: - Private

    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw AICoachError.unauthorized
        case 404:
            throw AICoachError.notFound
        case 429:
            throw AICoachError.rateLimited
        case 500...599:
            throw AICoachError.serverError(statusCode: response.statusCode)
        default:
            throw AICoachError.httpError(statusCode: response.statusCode, data: data)
        }
    }
}
