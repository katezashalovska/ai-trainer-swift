import SwiftUI

enum AICoachNavigationHeaderMetrics {
    static let barHeight: CGFloat = 44
    static let bottomPadding: CGFloat = 8
    static let topPadding: CGFloat = 2
    static let contentTopInset: CGFloat = 64
}

struct AICoachHeaderSpacer: View {
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(
                    key: AICoachHeaderScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named(AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)).minY
                )
        }
        .frame(height: AICoachNavigationHeaderMetrics.contentTopInset)
    }
}

struct AICoachNavigationHeader: View {
    @Environment(\.aiCoachTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let title: String
    let showBackButton: Bool
    let backgroundProgress: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text(title)
                    .font(theme.font.weight(.medium))
                    .foregroundStyle(theme.textColor)
                    .lineLimit(1)
                    .padding(.horizontal, 56)

                HStack {
                    if showBackButton {
                        Button(action: dismiss.callAsFunction) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(theme.textColor)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(AICoachUIStrings.back)
                    } else {
                        Color.clear
                            .frame(width: 36, height: 36)
                            .accessibilityHidden(true)
                    }

                    Spacer()
                }
            }
            .frame(height: AICoachNavigationHeaderMetrics.barHeight)
            .padding(.top, AICoachNavigationHeaderMetrics.topPadding)
            .padding(.horizontal, 16)
            .padding(.bottom, AICoachNavigationHeaderMetrics.bottomPadding)
            .background(headerBackground)
        }
    }

    private var headerBackground: some View {
        ZStack(alignment: .bottom) {
            Rectangle()
                .fill(theme.backgroundColor.opacity(1 - backgroundProgress))

            Rectangle()
                .fill(.bar)
                .opacity(backgroundProgress)

            Divider()
                .opacity(backgroundProgress)
        }
        .ignoresSafeArea(edges: .top)
    }
}

struct AICoachHeaderScrollOffsetPreferenceKey: PreferenceKey {
    static let coordinateSpaceName = "aicoach.navigation.scroll"
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

enum AICoachNavigationHeaderProgress {
    static func progress(for offset: CGFloat) -> CGFloat {
        min(max(-offset / 18, 0), 1)
    }
}

extension View {
    func aiCoachNavigationHeader(
        title: String,
        showBackButton: Bool,
        backgroundProgress: CGFloat
    ) -> some View {
        overlay(alignment: .top) {
            AICoachNavigationHeader(
                title: title,
                showBackButton: showBackButton,
                backgroundProgress: backgroundProgress
            )
        }
        .aiCoachHiddenNavigationBar()
    }
}
