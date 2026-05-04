import SwiftUI
import AICoachSDK

enum MessageDeliveryState: Sendable {
    case sent
    case sending
    case failed
}

@MainActor
public class ChatViewModel: ObservableObject {
    @Published public var messages: [ChatMessage] = []
    @Published public var session: ChatSession?
    @Published public var isLoading: Bool = false
    @Published public var isSending: Bool = false
    @Published public var error: String? = nil
    @Published private var deliveryStates: [UUID: MessageDeliveryState] = [:]
    
    public let coachId: String
    private var sessionId: UUID? { session?.id }
    
    public init(coachId: String, session: ChatSession? = nil) {
        self.coachId = coachId
        self.session = session
    }
    
    public func fetchMessages() async {
        guard AICoach.isConfigured else {
            self.error = AICoachUIStrings.sdkNotConfigured
            return
        }

        isLoading = true
        error = nil

        do {
            // If we don't have a session yet (e.g. opened from Coach list),
            // check if there's already an existing session with this coach to resume it.
            if session == nil {
                let allSessions = try await AICoach.shared.getSessions()
                if let existingSession = allSessions.first(where: { $0.coachId == coachId }) {
                    self.session = existingSession
                }
            }

            // If we have a session (either passed in or just found), fetch its messages
            if let sessionId = sessionId {
                let fetchedMessages = try await AICoach.shared.getMessages(sessionId: sessionId)
                self.messages = fetchedMessages
                self.deliveryStates = Dictionary(
                    uniqueKeysWithValues: fetchedMessages.map { ($0.id, .sent) }
                )
            }
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func sendMessage(_ content: String) async {
        await sendMessage(content, retryingMessageID: nil)
    }

    func retryMessage(_ message: ChatMessage) async {
        guard message.isFromUser,
              deliveryState(for: message) == .failed,
              let content = message.content else {
            return
        }

        await sendMessage(content, retryingMessageID: message.id)
    }

    func deliveryState(for message: ChatMessage) -> MessageDeliveryState {
        deliveryStates[message.id] ?? .sent
    }

    private func sendMessage(_ content: String, retryingMessageID: UUID?) async {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isSending else { return }

        guard AICoach.isConfigured else {
            self.error = AICoachUIStrings.sdkNotConfigured
            return
        }
        
        withAnimation(.easeInOut(duration: 0.18)) {
            isSending = true
        }
        defer {
            withAnimation(.easeInOut(duration: 0.18)) {
                isSending = false
            }
        }
        error = nil
        
        do {
            // Create session if it doesn't exist
            if session == nil {
                session = try await AICoach.shared.createSession(coachId: coachId)
            }
            
            guard let sid = session?.id else {
                throw AICoachError.unknown(NSError(domain: "ChatViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "Session creation failed"]))
            }
            
            let optimisticMessageID: UUID
            if let retryingMessageID {
                optimisticMessageID = retryingMessageID
                deliveryStates[retryingMessageID] = .sending
            } else {
                let optimisticUserMessage = ChatMessage(
                    id: UUID(),
                    sessionId: sid,
                    sender: "user",
                    content: content,
                    photoUrl: nil,
                    rating: nil,
                    createdAt: Date()
                )
                optimisticMessageID = optimisticUserMessage.id

                withAnimation(.spring(response: 0.34, dampingFraction: 0.84)) {
                    messages.append(optimisticUserMessage)
                }
            }
            deliveryStates[optimisticMessageID] = .sending
            
            let aiResponse = try await AICoach.shared.sendMessage(sessionId: sid, content: content)

            do {
                let fetchedMessages = try await AICoach.shared.getMessages(sessionId: sid)
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    self.messages = fetchedMessages
                }
                self.deliveryStates = Dictionary(
                    uniqueKeysWithValues: fetchedMessages.map { ($0.id, .sent) }
                )
            } catch {
                deliveryStates[optimisticMessageID] = .sent
                deliveryStates[aiResponse.id] = .sent

                if !messages.contains(where: { $0.id == aiResponse.id }) {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        self.messages.append(aiResponse)
                    }
                }

                self.error = AICoachUIStrings.messageSentRefreshFailed(error.localizedDescription)
            }
        } catch {
            self.error = error.localizedDescription
            if let retryingMessageID {
                deliveryStates[retryingMessageID] = .failed
            } else if let lastUserMessage = messages.last(where: { $0.isFromUser && $0.content == content }) {
                deliveryStates[lastUserMessage.id] = .failed
            }
        }
    }
}
