import SwiftUI
import AICoachSDK

public struct SessionListView: View {
    @Environment(\.aiCoachTheme) var theme
    @StateObject private var viewModel = SessionListViewModel()
    @State private var headerScrollOffset: CGFloat = 0

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            if let error = viewModel.error, viewModel.hasLoadedOnce, !viewModel.sessions.isEmpty {
                InlineErrorBanner(error: error, retryTitle: AICoachUIStrings.retry, retry: reloadSessions)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            content
        }
        .background(theme.backgroundColor.ignoresSafeArea())
        .aiCoachNavigationHeader(
            title: AICoachUIStrings.myChats,
            showBackButton: true,
            backgroundProgress: AICoachNavigationHeaderProgress.progress(for: headerScrollOffset)
        )
        .onAppear {
            reloadSessions()
        }
        .alert(AICoachUIStrings.couldntDeleteChat, isPresented: deletionErrorIsPresented) {
            Button(AICoachUIStrings.ok, role: .cancel) {
                viewModel.deletionErrorMessage = nil
            }
        } message: {
            Text(viewModel.deletionErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.sessions.isEmpty {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    AICoachHeaderSpacer()

                    if viewModel.isLoading {
                        SessionListLoadingState()
                            .padding(.top, 28)
                            .accessibilityLabel(AICoachUIStrings.loadingChats)
                    } else if let error = viewModel.error, !viewModel.hasLoadedOnce {
                        SessionListErrorState(error: error, retry: reloadSessions)
                            .padding(.top, 28)
                    } else {
                        SessionListEmptyState(theme: theme)
                            .padding(.top, 28)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .coordinateSpace(name: AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)
            .onPreferenceChange(AICoachHeaderScrollOffsetPreferenceKey.self) { newValue in
                headerScrollOffset = newValue
            }
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.fetchSessions()
            }
        } else {
            List {
                AICoachHeaderSpacer()
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(Array(viewModel.sessions.enumerated()), id: \.element.id) { index, session in
                    NavigationLink(
                        destination: ChatView(
                            sessionId: session.id,
                            coachName: sessionDisplayName(for: session),
                            imageUrl: coachImageURL(for: session) ?? ""
                        )
                    ) {
                        VStack(spacing: 0) {
                            SessionRow(
                                session: session,
                                coach: viewModel.coach(for: session),
                                accentColor: accentColor,
                                theme: theme
                            )

                            if index < viewModel.sessions.count - 1 {
                                Divider()
                                    .padding(.leading, 86)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(theme.backgroundColor)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .disabled(viewModel.isDeleting(session: session))
                    .opacity(viewModel.isDeleting(session: session) ? 0.55 : 1)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(session)
                        } label: {
                            Label(AICoachUIStrings.delete, systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .coordinateSpace(name: AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)
            .onPreferenceChange(AICoachHeaderScrollOffsetPreferenceKey.self) { newValue in
                headerScrollOffset = newValue
            }
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .refreshable {
                await viewModel.fetchSessions()
            }
            .animation(.spring(response: 0.42, dampingFraction: 0.9), value: viewModel.sessions.count)
        }
    }

    private var accentColor: Color {
        theme.primaryColor
    }

    private func reloadSessions() {
        Task {
            await viewModel.fetchSessions()
        }
    }

    private func delete(_ session: ChatSession) {
        Task {
            await viewModel.deleteSession(session)
        }
    }

    private func coachImageURL(for session: ChatSession) -> String? {
        viewModel.coach(for: session)?.imageURL
    }

    private func sessionDisplayName(for session: ChatSession) -> String {
        viewModel.coach(for: session)?.name ?? session.coachName ?? AICoachUIStrings.coach
    }


    private var deletionErrorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.deletionErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.deletionErrorMessage = nil
                }
            }
        )
    }
}

private struct SessionRow: View {
    let session: ChatSession
    let coach: Coach?
    let accentColor: Color
    let theme: AICoachTheme

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            SessionAvatarView(
                name: coach?.name ?? session.coachName ?? AICoachUIStrings.coach,
                imageURL: coach?.imageURL,
                accentColor: accentColor
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(coach?.name ?? session.coachName ?? AICoachUIStrings.coach)
                        .font(theme.font.weight(.medium))
                        .foregroundStyle(theme.textColor)
                        .lineLimit(1)
                }

                Text(session.lastMessagePreview ?? AICoachUIStrings.sessionPreviewFallback)
                    .font(theme.font)
                    .foregroundStyle(theme.secondaryTextColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            AICoachUIStrings.accessibilitySessionRow(
                name: coach?.name ?? session.coachName ?? AICoachUIStrings.coach,
                preview: session.lastMessagePreview ?? AICoachUIStrings.sessionPreviewFallback
            )
        )
    }
}

private struct SessionAvatarView: View {
    let name: String
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
                        fallbackAvatar
                    @unknown default:
                        fallbackAvatar
                    }
                }
            } else {
                fallbackAvatar
            }
        }
        .frame(width: 58, height: 58)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(accentColor.opacity(0.08), lineWidth: 1)
        )
    }

    private var fallbackAvatar: some View {
        Text(String(name.prefix(1)).uppercased())
            .font(.title3.weight(.medium))
            .foregroundStyle(theme.avatarForegroundColor)
    }
}

private struct SessionListLoadingState: View {
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        VStack(spacing: 22) {
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 14) {
                    Circle()
                        .fill(theme.shimmerColor)
                        .frame(width: 58, height: 58)

                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.shimmerColor)
                            .frame(height: 18)
                            .frame(maxWidth: 210)

                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(theme.shimmerColor.opacity(0.75))
                            .frame(height: 14)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SessionListErrorState: View {
    let error: String
    let retry: () -> Void
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(error)
                .font(.body.weight(.medium))
                .foregroundStyle(theme.errorColor)

            Button(AICoachUIStrings.retry, action: retry)
                .font(.body.weight(.semibold))
                .foregroundStyle(theme.primaryButtonTextColor)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(theme.primaryColor)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SessionListEmptyState: View {
    let theme: AICoachTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AICoachUIStrings.emptyChatsTitle)
                .font(.headline)
                .foregroundStyle(theme.textColor)

            Text(AICoachUIStrings.emptyChatsBody)
                .font(theme.font)
                .foregroundStyle(theme.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InlineErrorBanner: View {
    let error: String
    let retryTitle: String
    let retry: () -> Void
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(theme.errorColor)
                .accessibilityHidden(true)

            Text(error)
                .font(theme.font)
                .foregroundStyle(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(retryTitle, action: retry)
                .font(theme.font.weight(.semibold))
                .foregroundStyle(theme.primaryColor)
                .buttonStyle(.plain)
        }
        .padding(12)
        .background(theme.cardBackgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SessionListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SessionListView()
        }
    }
}
