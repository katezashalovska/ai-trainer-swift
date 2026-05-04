import SwiftUI

/// Standalone root entry point for the AI Coach UI.
///
/// Use `AICoachEmbeddedEntryView` when the host application already owns the
/// navigation container and only needs embeddable content.
public struct AICoachEntryView: View {
    private let showBackButton: Bool

    public init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }

    public var body: some View {
        NavigationStack {
            AICoachEmbeddedEntryView(showBackButton: showBackButton)
        }
    }
}

/// Embeddable entry content for host apps that already provide a `NavigationStack`.
public struct AICoachEmbeddedEntryView: View {
    @Environment(\.aiCoachTheme) private var theme

    private let showBackButton: Bool
    @State private var headerScrollOffset: CGFloat = 0
    private let contentSpacing: CGFloat = 20

    public init(showBackButton: Bool = false) {
        self.showBackButton = showBackButton
    }

    public var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: contentSpacing) {
                    AICoachHeaderSpacer()

                    NavigationLink(destination: SessionListView()) {
                        HStack {
                            Image("chats_icon", bundle: .module)
                                .foregroundStyle(theme.primaryColor)
                                .accessibilityHidden(true)

                            Text(AICoachUIStrings.myChats)
                                .font(theme.font.weight(.medium))
                                .foregroundStyle(theme.textColor)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(theme.secondaryTextColor)
                                .accessibilityHidden(true)
                        }
                        .padding()
                        .background(theme.cardBackgroundColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(theme.borderColor, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(AICoachUIStrings.openChatsHint)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(AICoachUIStrings.askTheCoach)
                            .font(.title2.weight(.semibold))
                            .tracking(0.5)
                            .foregroundStyle(theme.textColor)

                        Text(AICoachUIStrings.askCoachBody)
                            .font(theme.font)
                            .tracking(0.25)
                            .lineSpacing(1.25)
                            .foregroundStyle(theme.secondaryTextColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 6)

                    NavigationLink(destination: CoachSelectionView()) {
                        Text(AICoachUIStrings.chooseCoach)
                            .font(theme.font.weight(.semibold))
                            .foregroundStyle(theme.primaryButtonTextColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(theme.primaryColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(AICoachUIStrings.openCoachesHint)

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(
                    minHeight: max(proxy.size.height - AICoachNavigationHeaderMetrics.contentTopInset, 0),
                    alignment: .top
                )
            }
            .coordinateSpace(name: AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)
            .onPreferenceChange(AICoachHeaderScrollOffsetPreferenceKey.self) { newValue in
                headerScrollOffset = newValue
            }
            .background(theme.backgroundColor.ignoresSafeArea())
            .aiCoachNavigationHeader(
                title: AICoachUIStrings.chatWithCoach,
                showBackButton: showBackButton,
                backgroundProgress: AICoachNavigationHeaderProgress.progress(for: headerScrollOffset)
            )
        }
    }
}

struct AICoachEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AICoachEntryView()
            AICoachEntryView(showBackButton: true)
        }
    }
}
