import SwiftUI
import AICoachSDK

public struct ChatView: View {
    @Environment(\.aiCoachTheme) var theme
    @StateObject private var viewModel: ChatViewModel
    @State private var inputText: String = ""
    @State private var hasAnimatedIn = false
    @State private var hasPerformedInitialScroll: Bool
    @State private var headerScrollOffset: CGFloat = 0
    @FocusState private var isInputFocused: Bool
    let coachName: String
    let imageUrl: String
    private let opensExistingSession: Bool
    private let bottomAnchorID = "chat-bottom-anchor"
    private let scrollAnimation = Animation.easeInOut(duration: 0.5)

    public init(coach: Coach) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(coachId: coach.id.uuidString))
        _hasPerformedInitialScroll = State(initialValue: true)
        self.coachName = coach.name
        self.imageUrl = coach.imageURL ?? ""
        self.opensExistingSession = false
    }

    public init(sessionId: UUID, coachName: String, imageUrl: String) {
        _viewModel = StateObject(
            wrappedValue: ChatViewModel(
                coachId: "",
                session: ChatSession(
                    id: sessionId,
                    userId: nil,
                    coachId: nil,
                    coachName: coachName,
                    userEmail: nil,
                    platform: nil,
                    lastMessagePreview: nil,
                    lastMessageAt: nil,
                    messageCount: nil,
                    createdAt: nil
                )
            )
        )
        _hasPerformedInitialScroll = State(initialValue: false)
        self.coachName = coachName
        self.imageUrl = imageUrl
        self.opensExistingSession = true
    }

    public var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        AICoachHeaderSpacer()

                        ChatHeader(coachName: coachName, imageURL: imageUrl)
                            .padding(.horizontal, 16)
                            .padding(.top, 4)
                            .offset(y: hasAnimatedIn ? 0 : 12)
                            .opacity(hasAnimatedIn ? 1 : 0)

                        if let error = viewModel.error {
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(theme.errorColor)
                                .padding(.horizontal, 16)
                        }

                        if viewModel.isLoading && viewModel.messages.isEmpty {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                            .padding(.top, 32)
                        } else {
                            LazyVStack(spacing: 18) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(
                                        message: message,
                                        deliveryState: viewModel.deliveryState(for: message),
                                        onRetry: viewModel.deliveryState(for: message) == .failed
                                            ? { retry(message) }
                                            : nil
                                    )
                                        .id(message.id)
                                        .transition(
                                            .asymmetric(
                                                insertion: .move(edge: message.isFromUser ? .trailing : .leading).combined(with: .opacity),
                                                removal: .opacity
                                            )
                                        )
                                }

                                if shouldShowTypingIndicator {
                                    CoachTypingIndicator(accentColor: accentColor)
                                        .transition(.move(edge: .leading).combined(with: .opacity))
                                }

                                Color.clear
                                    .frame(height: 1)
                                    .id(bottomAnchorID)
                            }
                            .padding(.horizontal, 16)
                            .animation(.spring(response: 0.38, dampingFraction: 0.86), value: viewModel.messages.map(\.id))
                            .animation(.easeInOut(duration: 0.2), value: shouldShowTypingIndicator)
                        }
                    }
                    .padding(.bottom, 18)
                }
                .coordinateSpace(name: AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)
                .onPreferenceChange(AICoachHeaderScrollOffsetPreferenceKey.self) { newValue in
                    headerScrollOffset = newValue
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                .onChange(of: viewModel.messages.map(\.id)) { _ in
                    guard !viewModel.messages.isEmpty else { return }
                    if hasPerformedInitialScroll {
                        scheduleScrollToBottom(proxy: proxy, animated: true)
                    } else {
                        hasPerformedInitialScroll = true
                        scheduleScrollToBottom(proxy: proxy, animated: false)
                    }
                }
                .onChange(of: shouldShowTypingIndicator) { _ in
                    if hasPerformedInitialScroll {
                        scheduleScrollToBottom(proxy: proxy, animated: true)
                    }
                }
                .onChange(of: isInputFocused) { focused in
                    if focused && hasPerformedInitialScroll {
                        scheduleScrollToBottom(proxy: proxy, animated: true)
                    }
                }
            }

            ChatInputBar(text: $inputText, isFocused: $isInputFocused, isSending: viewModel.isSending) {
                Task {
                    let textToSend = inputText
                    inputText = ""
                    await viewModel.sendMessage(textToSend)
                }
            }
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .aiCoachNavigationHeader(
            title: coachName,
            showBackButton: true,
            backgroundProgress: AICoachNavigationHeaderProgress.progress(for: headerScrollOffset)
        )
        .task {
            if !hasAnimatedIn {
                withAnimation(.easeOut(duration: 0.38)) {
                    hasAnimatedIn = true
                }
            }

            if !opensExistingSession {
                hasPerformedInitialScroll = true
            }

            await viewModel.fetchMessages()
        }
    }

    private var accentColor: Color {
        theme.primaryColor
    }

    private var shouldShowTypingIndicator: Bool {
        viewModel.isSending && !(viewModel.messages.last?.isFromCoach ?? false)
    }

    private func scheduleScrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        Task { @MainActor in
            await Task.yield()
            scrollToBottom(proxy: proxy, animated: animated)
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(scrollAnimation) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }
    }
}

struct ChatHeader: View {
    let coachName: String
    let imageURL: String?
    @Environment(\.aiCoachTheme) var theme

    private var accentColor: Color {
        theme.primaryColor
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ChatHeaderAvatar(imageURL: imageURL, accentColor: accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(AICoachUIStrings.hiThere)
                    .font(.headline)
                    .foregroundStyle(theme.textColor)

                Text(AICoachUIStrings.chatHeaderBody)
                    .font(theme.font)
                    .foregroundStyle(theme.secondaryTextColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct ChatHeaderAvatar: View {
    let imageURL: String?
    let accentColor: Color
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.avatarBackgroundColor)

            if let imageURL,
               let url = URL(string: imageURL),
               !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .tint(theme.avatarForegroundColor.opacity(0.9))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholderContent
                    @unknown default:
                        placeholderContent
                    }
                }
            } else {
                placeholderContent
            }
        }
        .frame(width: 66, height: 66)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(accentColor, lineWidth: 2)
        )
    }

    private var placeholderContent: some View {
        Image(systemName: "photo")
            .resizable()
            .scaledToFit()
            .foregroundStyle(theme.avatarForegroundColor.opacity(0.72))
            .padding(18)
            .accessibilityHidden(true)
    }
}

private struct CoachTypingIndicator: View {
    let accentColor: Color
    @State private var animateDots = false

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(accentColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateDots ? 1 : 0.6)
                        .opacity(animateDots ? 1 : 0.4)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.12),
                            value: animateDots
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .id("typing-indicator")

            Spacer()
        }
        .task {
            animateDots = true
        }
    }
}

private extension ChatView {
    func retry(_ message: ChatMessage) {
        Task {
            await viewModel.retryMessage(message)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ChatView(
                coach: Coach(
                    id: UUID(),
                    name: "Jaxson",
                    tone: "motivational",
                    systemPrompt: nil,
                    specialties: ["Fitness"],
                    focus: ["Weight Loss"],
                    isActive: true,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            )
        }
    }
}
