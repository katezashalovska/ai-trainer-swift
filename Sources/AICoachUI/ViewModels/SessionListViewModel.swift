import SwiftUI
import AICoachSDK

@MainActor
public class SessionListViewModel: ObservableObject {
    @Published public var sessions: [ChatSession] = []
    @Published public var coachesById: [String: Coach] = [:]
    @Published public var isLoading: Bool = false
    @Published public var error: String? = nil
    @Published public var deletionErrorMessage: String? = nil
    @Published public var hasLoadedOnce: Bool = false
    @Published public private(set) var deletingSessionIDs: Set<UUID> = []
    
    public init() {}
    
    public func fetchSessions() async {
        guard !isLoading else { return }

        guard AICoach.isConfigured else {
            self.error = AICoachUIStrings.sdkNotConfigured
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedSessions = try await AICoach.shared.getSessions()
            self.sessions = fetchedSessions.sorted(by: Self.sortPredicate)
            self.hasLoadedOnce = true

            do {
                let fetchedCoaches = try await AICoach.shared.getCoaches()
                self.coachesById = Dictionary(
                    uniqueKeysWithValues: fetchedCoaches.map { ($0.id.uuidString.lowercased(), $0) }
                )
            } catch {
                // Preserve the last known coach metadata if the refresh fails.
            }
        } catch {
            self.error = sessions.isEmpty ? error.localizedDescription : AICoachUIStrings.sessionRefreshFailed
        }
        
        isLoading = false
    }

    public func coach(for session: ChatSession) -> Coach? {
        guard let coachId = session.coachId?.lowercased() else { return nil }
        return coachesById[coachId]
    }

    public func isDeleting(session: ChatSession) -> Bool {
        deletingSessionIDs.contains(session.id)
    }

    public func deleteSession(_ session: ChatSession) async {
        guard !isDeleting(session: session) else { return }
        guard AICoach.isConfigured else {
            deletionErrorMessage = AICoachUIStrings.sdkNotConfigured
            return
        }

        let originalIndex = sessions.firstIndex(where: { $0.id == session.id })
        deletingSessionIDs.insert(session.id)

        withAnimation(.spring(response: 0.34, dampingFraction: 0.88)) {
            sessions.removeAll { $0.id == session.id }
        }

        do {
            try await AICoach.shared.deleteSession(sessionId: session.id)
        } catch {
            if !sessions.contains(session), let originalIndex {
                let safeIndex = min(originalIndex, sessions.count)
                sessions.insert(session, at: safeIndex)
                sessions.sort(by: Self.sortPredicate)
            }
            deletionErrorMessage = error.localizedDescription
        }

        deletingSessionIDs.remove(session.id)
    }

    private static func sortPredicate(_ lhs: ChatSession, _ rhs: ChatSession) -> Bool {
        (lhs.lastMessageAt ?? lhs.createdAt ?? .distantPast) > (rhs.lastMessageAt ?? rhs.createdAt ?? .distantPast)
    }
}
