import Foundation

enum AICoachUIStrings {
    static var about: String { localized("aicoach.about", default: "About") }
    static var achievements: String { localized("aicoach.achievements", default: "Achievements") }
    static var askTheCoach: String { localized("aicoach.ask_the_coach", default: "Ask the coach") }
    static var back: String { localized("aicoach.back", default: "Back") }
    static var coach: String { localized("aicoach.coach", default: "Coach") }
    static var chatWithCoach: String { localized("aicoach.chat_with_coach", default: "Chat with coach") }
    static var choose: String { localized("aicoach.choose", default: "Choose") }
    static var chooseCoach: String { localized("aicoach.choose_coach", default: "Choose coach") }
    static var chooseTheCoach: String { localized("aicoach.choose_the_coach", default: "Choose the coach") }
    static var couldntDeleteChat: String { localized("aicoach.couldnt_delete_chat", default: "Couldn't delete chat") }
    static var delete: String { localized("aicoach.delete", default: "Delete") }
    static var emptyChatsBody: String { localized("aicoach.empty_chats_body", default: "Your recent conversations with coaches will appear here.") }
    static var emptyChatsTitle: String { localized("aicoach.empty_chats_title", default: "No active chats yet.") }
    static var emptyCoachesBody: String { localized("aicoach.empty_coaches_body", default: "Once the backend starts returning coaches, they will appear here automatically.") }
    static var emptyCoachesTitle: String { localized("aicoach.empty_coaches_title", default: "No coaches available yet.") }
    static var enterQuestion: String { localized("aicoach.enter_question", default: "Enter your question") }
    static var failedToSend: String { localized("aicoach.failed_to_send", default: "Failed to send") }
    static var hiThere: String { localized("aicoach.hi_there", default: "Hi there!") }
    static var loadingChats: String { localized("aicoach.loading_chats", default: "Loading chats") }
    static var loadingCoaches: String { localized("aicoach.loading_coaches", default: "Loading coaches") }
    static var myChats: String { localized("aicoach.my_chats", default: "My chats") }
    static var ok: String { localized("aicoach.ok", default: "OK") }
    static var refreshFailedPrefix: String { localized("aicoach.refresh_failed_prefix", default: "Refresh failed.") }
    static var retry: String { localized("aicoach.retry", default: "Retry") }
    static var reviews: String { localized("aicoach.reviews", default: "Reviews") }
    static var sdkNotConfigured: String { localized("aicoach.sdk_not_configured", default: "SDK not configured") }
    static var seeDetails: String { localized("aicoach.see_details", default: "See details") }
    static var send: String { localized("aicoach.send", default: "Send") }
    static var sendHint: String { localized("aicoach.send_hint", default: "Sends the message to your coach") }
    static var sending: String { localized("aicoach.sending", default: "Sending…") }
    static var sessionPreviewFallback: String { localized("aicoach.session_preview_fallback", default: "No messages yet.") }
    static var sessionRefreshFailed: String { localized("aicoach.session_refresh_failed", default: "Couldn't refresh chats. Showing the last loaded data.") }
    static var you: String { localized("aicoach.you", default: "You") }
    static var openChatsHint: String { localized("aicoach.open_chats_hint", default: "Opens the list of your recent chats") }
    static var openCoachesHint: String { localized("aicoach.open_coaches_hint", default: "Opens the list of available coaches") }
    static var retrySendHint: String { localized("aicoach.retry_send_hint", default: "Attempts to send the message again") }
    static var coachRefreshFailed: String { localized("aicoach.coach_refresh_failed", default: "Couldn't refresh coaches. Showing the last loaded data.") }
    static var coachListUnavailable: String { localized("aicoach.coach_list_unavailable", default: "Coach list endpoint is not available yet.") }
    static var coachListTemporarilyUnavailable: String { localized("aicoach.coach_list_temporarily_unavailable", default: "Coach list is temporarily unavailable.") }
    static var askCoachBody: String {
        localized(
            "aicoach.ask_the_coach_body",
            default: "You can ask your questions to one of our coaches at any time. They will help you with practical, personalized advice."
        )
    }
    static var coachSelectionBody: String {
        localized(
            "aicoach.coach_selection_body",
            default: "Learn about each coach's skills and choose the one best suited to help with your question."
        )
    }
    static var chatHeaderBody: String {
        localized(
            "aicoach.chat_header_body",
            default: "Write what interests you and I will be happy to help you move toward your goal."
        )
    }

    static func accessibilityMessageLabel(sender: String, content: String, status: String?) -> String {
        let format = localized(
            "aicoach.accessibility.message_label",
            default: "%1$@: %2$@%3$@"
        )
        let statusSuffix = status.map { ". \($0)" } ?? ""
        return String(format: format, sender, content, statusSuffix)
    }

    static func accessibilitySessionRow(name: String, preview: String) -> String {
        let format = localized(
            "aicoach.accessibility.session_row",
            default: "%1$@. %2$@"
        )
        return String(format: format, name, preview)
    }

    static func accessibilityCoachCard(name: String) -> String {
        let format = localized(
            "aicoach.accessibility.coach_card",
            default: "Coach card for %1$@"
        )
        return String(format: format, name)
    }

    static func messageSentRefreshFailed(_ errorDescription: String) -> String {
        let format = localized(
            "aicoach.message_sent_refresh_failed",
            default: "Your message was sent, but the conversation could not be refreshed: %1$@"
        )
        return String(format: format, errorDescription)
    }

    private static func localized(_ key: String, default defaultValue: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: .module, value: defaultValue, comment: "")
    }
}
