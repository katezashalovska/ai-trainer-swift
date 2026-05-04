import SwiftUI
import AICoachSDK

@MainActor
public class CoachSelectionViewModel: ObservableObject {
    @Published public var coaches: [Coach] = []
    @Published public var isLoading: Bool = false
    @Published public var error: String? = nil
    @Published public var hasLoadedOnce: Bool = false
    
    public init() {}
    
    public func fetchCoaches() async {
        guard !isLoading else { return }
        
        guard AICoach.isConfigured else {
            self.error = AICoachUIStrings.sdkNotConfigured
            self.coaches = []
            return
        }

        isLoading = true
        error = nil
        defer {
            isLoading = false
            hasLoadedOnce = true
        }
        
        do {
            let loadedCoaches = try await AICoach.shared.getCoaches()
            self.coaches = loadedCoaches
                .filter { $0.isActive ?? true }
                .sorted {
                    $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                }
        } catch AICoachError.notFound {
            if coaches.isEmpty {
                self.coaches = []
                self.error = AICoachUIStrings.coachListUnavailable
            } else {
                self.error = AICoachUIStrings.coachRefreshFailed
            }
        } catch AICoachError.serverError {
            if coaches.isEmpty {
                self.coaches = []
                self.error = AICoachUIStrings.coachListTemporarilyUnavailable
            } else {
                self.error = AICoachUIStrings.coachRefreshFailed
            }
        } catch {
            if coaches.isEmpty {
                self.coaches = []
                self.error = error.localizedDescription
            } else {
                self.error = AICoachUIStrings.coachRefreshFailed
            }
        }
    }
}
