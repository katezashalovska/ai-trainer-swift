import Foundation

/// JSON encoder/decoder extensions configured for the API's date format.
extension JSONEncoder {

    /// Encoder configured for the AI Coach API.
    /// Uses ISO 8601 date encoding with fractional seconds.
    static let apiEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.keyEncodingStrategy = .useDefaultKeys
        return encoder
    }()
}

extension JSONDecoder {

    /// Decoder configured for the AI Coach API.
    /// Handles ISO 8601 dates with and without fractional seconds.
    static let apiDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            for candidate in DateParser.candidates(for: dateString) {
                if let date = ISO8601DateFormatter.withFractionalSeconds.date(from: candidate) {
                    return date
                }

                if let date = ISO8601DateFormatter.standard.date(from: candidate) {
                    return date
                }
            }

            for formatter in DateFormatter.apiDateFormatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }
        decoder.keyDecodingStrategy = .useDefaultKeys
        return decoder
    }()
}

// MARK: - ISO8601 Formatters

extension ISO8601DateFormatter {

    /// ISO 8601 formatter with fractional seconds (e.g., `2024-01-15T10:30:00.123Z`).
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// Standard ISO 8601 formatter (e.g., `2024-01-15T10:30:00Z`).
    static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

// MARK: - Date Parsing Helpers

private enum DateParser {

    static func candidates(for dateString: String) -> [String] {
        var candidates = [dateString]

        // Some backend responses omit the timezone entirely.
        // In that case we treat the timestamp as UTC for client-side decoding.
        if !hasExplicitTimezone(dateString) {
            candidates.append("\(dateString)Z")
        }

        return candidates
    }

    private static func hasExplicitTimezone(_ dateString: String) -> Bool {
        dateString.hasSuffix("Z")
            || dateString.range(
                of: #"[+-]\d{2}:?\d{2}$"#,
                options: .regularExpression
            ) != nil
    }
}

extension DateFormatter {

    static let apiDateFormatters: [DateFormatter] = [
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSSXXXXX"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ssXXXXX"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSSSSS"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSSSSS"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss.SSS"),
        makeAPIDateFormatter("yyyy-MM-dd'T'HH:mm:ss")
    ]

    private static func makeAPIDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = format
        return formatter
    }
}
