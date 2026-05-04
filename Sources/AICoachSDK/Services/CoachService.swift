import Foundation

/// Service responsible for coach directory operations.
///
/// Handles fetching the coach list and individual coach profiles.
/// Used internally by `AICoach`.
final class CoachService: Sendable {

    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    /// Retrieves all coaches available to the current client app.
    ///
    /// - Returns: An array of `Coach` objects.
    /// - Throws: `AICoachError` for any failure.
    func getCoaches() async throws -> [Coach] {
        try await client.request(.getCoaches(), as: [Coach].self)
    }

    /// Retrieves a single coach profile.
    ///
    /// - Parameter id: The UUID of the coach.
    /// - Returns: The `Coach` matching the provided identifier.
    /// - Throws: `AICoachError` for any failure.
    func getCoach(id: UUID) async throws -> Coach {
        try await client.request(.getCoach(id: id), as: Coach.self)
    }
}
