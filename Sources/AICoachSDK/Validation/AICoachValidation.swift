import Foundation

enum AICoachValidation {
    static let maxMessageLength = 8_000
    static let maxUserStateLength = 4_000
}

extension AICoachConfiguration {
    func validated() throws -> AICoachConfiguration {
        let trimmedAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw AICoachError.invalidConfiguration("apiKey must not be empty.")
        }

        let trimmedUserID = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUserID.isEmpty else {
            throw AICoachError.invalidConfiguration("userId must not be empty.")
        }

        let trimmedPlatform = platform.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPlatform.isEmpty else {
            throw AICoachError.invalidConfiguration("platform must not be empty.")
        }

        guard timeoutInterval.isFinite, timeoutInterval > 0 else {
            throw AICoachError.invalidConfiguration("timeoutInterval must be a positive finite number.")
        }

        guard let scheme = baseURL.scheme?.lowercased() else {
            throw AICoachError.invalidConfiguration("baseURL must include a URL scheme.")
        }

        guard let host = baseURL.host?.lowercased(), !host.isEmpty else {
            throw AICoachError.invalidConfiguration("baseURL must include a host.")
        }

        let allowsLoopbackHTTP = scheme == "http" && Self.isLoopbackHost(host)
        guard scheme == "https" || allowsLoopbackHTTP else {
            throw AICoachError.invalidConfiguration(
                "baseURL must use HTTPS. Plain HTTP is only allowed for localhost development."
            )
        }

        return self
    }

    private static func isLoopbackHost(_ host: String) -> Bool {
        host == "localhost" || host == "127.0.0.1" || host == "::1"
    }
}

extension CreateSessionRequest {
    func validateForTransport() throws {
        if let coachId {
            let trimmedCoachID = coachId.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedCoachID.isEmpty else {
                throw AICoachError.invalidRequest(field: "coachId", reason: "must not be empty when provided.")
            }
        }

        if let platform {
            let trimmedPlatform = platform.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPlatform.isEmpty else {
                throw AICoachError.invalidRequest(field: "platform", reason: "must not be empty when provided.")
            }
        }

        if let userState {
            let trimmedUserState = userState.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedUserState.isEmpty else {
                throw AICoachError.invalidRequest(field: "userState", reason: "must not be blank when provided.")
            }

            guard userState.count <= AICoachValidation.maxUserStateLength else {
                throw AICoachError.invalidRequest(
                    field: "userState",
                    reason: "must be \(AICoachValidation.maxUserStateLength) characters or fewer."
                )
            }
        }
    }
}

extension SendMessageRequest {
    func validateForTransport() throws {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            throw AICoachError.invalidRequest(field: "content", reason: "must not be empty.")
        }

        guard content.count <= AICoachValidation.maxMessageLength else {
            throw AICoachError.invalidRequest(
                field: "content",
                reason: "must be \(AICoachValidation.maxMessageLength) characters or fewer."
            )
        }

        if let photoUrl {
            let trimmedPhotoURL = photoUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedPhotoURL.isEmpty else {
                throw AICoachError.invalidRequest(field: "photoUrl", reason: "must not be blank when provided.")
            }

            guard URL(string: trimmedPhotoURL) != nil else {
                throw AICoachError.invalidRequest(field: "photoUrl", reason: "must be a valid URL.")
            }
        }
    }
}
