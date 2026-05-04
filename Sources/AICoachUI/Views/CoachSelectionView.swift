import SwiftUI
import AICoachSDK

public struct CoachSelectionView: View {
    @Environment(\.aiCoachTheme) var theme
    @StateObject private var viewModel = CoachSelectionViewModel()
    @State private var headerScrollOffset: CGFloat = 0
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                AICoachHeaderSpacer()

                Text(AICoachUIStrings.chooseTheCoach)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.textColor)
                    .padding(.horizontal)
                
                Text(AICoachUIStrings.coachSelectionBody)
                    .font(theme.font)
                    .foregroundStyle(theme.secondaryTextColor)
                    .tracking(0.5)
                    .padding(.horizontal)

                if let error = viewModel.error, !viewModel.coaches.isEmpty {
                    CoachRefreshBanner(error: error, retry: reload)
                        .padding(.horizontal)
                }
                
                if viewModel.isLoading && viewModel.coaches.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 120)
                        .accessibilityLabel(AICoachUIStrings.loadingCoaches)
                } else if let error = viewModel.error, viewModel.coaches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(error)
                            .font(theme.font.weight(.medium))
                            .foregroundStyle(theme.errorColor)

                        Button(AICoachUIStrings.retry, action: reload)
                        .font(theme.font.weight(.semibold))
                        .foregroundStyle(theme.primaryButtonTextColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(accentColor)
                        .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 24)
                } else if viewModel.coaches.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AICoachUIStrings.emptyCoachesTitle)
                            .font(.headline)
                            .foregroundStyle(theme.textColor)
                        Text(AICoachUIStrings.emptyCoachesBody)
                            .font(theme.font)
                            .foregroundStyle(theme.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 24)
                } else {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.coaches) { coach in
                            CoachCard(coach: coach)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top, 10)
        }
        .coordinateSpace(name: AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)
        .onPreferenceChange(AICoachHeaderScrollOffsetPreferenceKey.self) { newValue in
            headerScrollOffset = newValue
        }
        .scrollIndicators(.hidden)
        .background(theme.secondaryBackgroundColor.ignoresSafeArea())
        .aiCoachNavigationHeader(
            title: AICoachUIStrings.chatWithCoach,
            showBackButton: true,
            backgroundProgress: AICoachNavigationHeaderProgress.progress(for: headerScrollOffset)
        )
        .task {
            if !viewModel.hasLoadedOnce {
                await viewModel.fetchCoaches()
            }
        }
        .refreshable {
            await viewModel.fetchCoaches()
        }
    }

    private var accentColor: Color {
        theme.primaryColor
    }

    private func reload() {
        Task {
            await viewModel.fetchCoaches()
        }
    }
}

struct CoachCard: View {
    let coach: Coach
    @Environment(\.aiCoachTheme) var theme
    
    private var accentColor: Color {
        theme.primaryColor
    }
    
    private var topTags: [CoachTag] {
        var tags: [CoachTag] = []

        if let rating = coach.formattedRating {
            tags.append(CoachTag(text: rating, iconImage: "like_icon"))
        }
        if let clients = coach.formattedClientsCount {
            tags.append(CoachTag(text: clients, iconImage: "user_icon"))
        }

        if let focus = coach.focus?.first {
            tags.append(CoachTag(text: focus))
        }

        return tags
    }

    private var bottomTags: [CoachTag] {
        Array(coach.specialties?.prefix(2) ?? []).map { CoachTag(text: $0) }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(coach.name)
                .font(theme.font.weight(.medium))
                .foregroundStyle(theme.textColor)
                .padding(.horizontal, 2)
            
            ZStack(alignment: .bottomLeading) {
                CoachMediaView(imageURL: coach.imageURL)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(topTags) { tag in
                            TagView(tag: tag, accentColor: accentColor)
                        }
                    }

                    if !bottomTags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(bottomTags) { tag in
                                TagView(tag: tag, accentColor: accentColor)
                            }
                        }
                    }
                }
                .padding(.leading, 10)
                .padding(.bottom, 10)
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            
            HStack(spacing: 16) {
                NavigationLink(destination: CoachDetailsView(coach: coach)) {
                    Text(AICoachUIStrings.seeDetails)
                        .font(theme.font.weight(.medium))
                        .foregroundStyle(theme.textColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.backgroundColor)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(theme.primaryColor.opacity(0.85), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                NavigationLink(destination: ChatView(coach: coach)) {
                    Text(AICoachUIStrings.choose)
                        .font(theme.font.weight(.medium))
                        .foregroundStyle(theme.primaryButtonTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(theme.primaryColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(theme.borderColor, lineWidth: 1)
        )
        .shadow(color: theme.shadowColor, radius: 14, x: 0, y: 6)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AICoachUIStrings.accessibilityCoachCard(name: coach.name))
    }
}

private struct CoachMediaView: View {
    let imageURL: String?
    @State private var shouldShowPlaceholder = false
    @Environment(\.aiCoachTheme) private var theme
    
    var body: some View {
        ZStack {
            theme.primaryColor.opacity(0.24)

            if let imageURL,
               let url = URL(string: imageURL),
               !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderLayer
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .transition(.opacity)
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
        .frame(height: 160)
        .clipped()
        .task {
            shouldShowPlaceholder = false
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            shouldShowPlaceholder = true
        }
    }

    @ViewBuilder
    private var placeholderLayer: some View {
        if shouldShowPlaceholder {
            placeholderContent
        } else {
            ProgressView()
                .tint(theme.avatarForegroundColor.opacity(0.9))
                .controlSize(.regular)
                .padding(.bottom)
        }
    }

    private var placeholderContent: some View {
        Image(systemName: "photo")
            .font(.system(size: 26, weight: .regular))
            .foregroundStyle(theme.avatarForegroundColor.opacity(0.72))
            .padding(.bottom)
            .accessibilityHidden(true)
    }
}

private struct CoachTag: Identifiable {
    let id: String
    let text: String
    var iconImage: String? = nil
    
    init(text: String, iconImage: String? = nil) {
        self.id = "\(iconImage ?? "text")-\(text)"
        self.text = text
        self.iconImage = iconImage
    }
}

private struct TagView: View {
    let tag: CoachTag
    let accentColor: Color
    @Environment(\.aiCoachTheme) private var theme
    
    var body: some View {
        HStack(spacing: 4) {
            if let iconImage = tag.iconImage {
                Image(iconImage, bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(theme.tagForegroundColor)
            }
            Text(tag.text)
        }
        .font(.caption.weight(.medium))
        .foregroundStyle(theme.tagForegroundColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(theme.tagBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accentColor.opacity(0.95), lineWidth: 1)
        )
    }
}

private struct CoachDetailsView: View {
    let coach: Coach
    @Environment(\.aiCoachTheme) var theme
    @State private var selectedTab: CoachDetailsTab = .about
    @State private var headerScrollOffset: CGFloat = 0

    private var accentColor: Color {
        theme.primaryColor
    }

    private var detailTags: [CoachTag] {
        var tags: [CoachTag] = []

        if let rating = coach.formattedRating {
            tags.append(CoachTag(text: rating, iconImage: "like_icon"))
        }
        if let clients = coach.formattedClientsCount {
            tags.append(CoachTag(text: clients, iconImage: "user_icon"))
        }

        let focusTags = (coach.focus ?? []).prefix(3).map { CoachTag(text: $0) }
        tags.append(contentsOf: focusTags)
        return tags
    }

    private var achievements: [String] {
        coach.achievements ?? []
    }

    private var reviews: [CoachReview] {
        coach.reviews ?? []
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                AICoachHeaderSpacer()

                Text(coach.name)
                    .font(theme.font.weight(.medium))
                    .foregroundStyle(theme.textColor)

                CoachDetailsHeroView(imageURL: coach.imageURL)

                CoachTagFlow(spacing: 8) {
                    ForEach(detailTags) { tag in
                        CoachDetailsTagView(
                            tag: tag,
                            accentColor: accentColor
                        )
                    }
                }

                HStack(spacing: 16) {
                    CoachDetailsTabButton(
                        title: AICoachUIStrings.about,
                        isSelected: selectedTab == .about,
                        accentColor: accentColor
                    ) {
                        selectedTab = .about
                    }

                    CoachDetailsTabButton(
                        title: AICoachUIStrings.reviews,
                        isSelected: selectedTab == .reviews,
                        accentColor: accentColor
                    ) {
                        selectedTab = .reviews
                    }
                }

                if selectedTab == .about {
                    VStack(alignment: .leading, spacing: 14) {
                        if let bio = coach.bio, !bio.isEmpty, achievements.isEmpty {
                            Text(bio)
                                .font(theme.font)
                                .foregroundStyle(theme.secondaryTextColor)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !achievements.isEmpty {
                            Text(AICoachUIStrings.achievements)
                                .font(.headline)
                                .foregroundStyle(theme.textColor)

                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(Array(achievements.enumerated()), id: \.offset) { _, achievement in
                                    AchievementRow(
                                        text: achievement,
                                        accentColor: accentColor
                                    )
                                }
                            }
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(reviews) { review in
                            ReviewRow(
                                review: review,
                                accentColor: accentColor,
                                textColor: theme.textColor,
                                secondaryTextColor: theme.secondaryTextColor
                            )
                        }
                    }
                }

                NavigationLink(destination: ChatView(coach: coach)) {
                    Text(AICoachUIStrings.choose)
                        .font(theme.font.weight(.medium))
                        .foregroundStyle(theme.primaryButtonTextColor)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(theme.primaryColor)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding()
        }
        .coordinateSpace(name: AICoachHeaderScrollOffsetPreferenceKey.coordinateSpaceName)
        .onPreferenceChange(AICoachHeaderScrollOffsetPreferenceKey.self) { newValue in
            headerScrollOffset = newValue
        }
        .scrollIndicators(.hidden)
        .background(theme.backgroundColor.ignoresSafeArea())
        .aiCoachNavigationHeader(
            title: AICoachUIStrings.chatWithCoach,
            showBackButton: true,
            backgroundProgress: AICoachNavigationHeaderProgress.progress(for: headerScrollOffset)
        )
    }
}

private enum CoachDetailsTab {
    case about
    case reviews
}

private struct CoachDetailsHeroView: View {
    let imageURL: String?
    @State private var shouldShowPlaceholder = false
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            theme.primaryColor.opacity(0.24)

            if let imageURL,
               let url = URL(string: imageURL),
               !imageURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderLayer
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .task {
            shouldShowPlaceholder = false
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            shouldShowPlaceholder = true
        }
    }

    @ViewBuilder
    private var placeholderLayer: some View {
        if shouldShowPlaceholder {
            placeholderContent
        } else {
            ProgressView()
                .tint(theme.avatarForegroundColor.opacity(0.9))
        }
    }

    private var placeholderContent: some View {
        Image(systemName: "photo")
            .font(.system(size: 28, weight: .regular))
            .foregroundStyle(theme.avatarForegroundColor.opacity(0.72))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityHidden(true)
    }
}

private struct CoachDetailsTagView: View {
    let tag: CoachTag
    let accentColor: Color
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            if let iconImage = tag.iconImage {
                Image(iconImage, bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                    .foregroundStyle(accentColor)
            }

            Text(tag.text)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(theme.textColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(accentColor.opacity(0.08)))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(accentColor.opacity(0.9), lineWidth: 1)
        )
    }
}

private struct CoachDetailsTabButton: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.font)
                .foregroundStyle(theme.textColor)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? accentColor.opacity(0.1) : theme.cardBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            isSelected
                            ? accentColor.opacity(0.95)
                            : theme.borderColor,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

private struct AchievementRow: View {
    let text: String
    let accentColor: Color
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.circle")
                .font(.body)
                .foregroundStyle(accentColor)
                .padding(.top, 2)

            Text(text)
                .font(theme.font)
                .foregroundStyle(theme.secondaryTextColor)
                .lineSpacing(1.25)
                .tracking(0.5)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ReviewRow: View {
    let review: CoachReview
    let accentColor: Color
    let textColor: Color
    let secondaryTextColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.body.weight(.medium))
                    .foregroundStyle(accentColor)

                if let rating = review.rating {
                    Text("\(rating)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(textColor)
                }

                if let reviewerName = review.reviewerName {
                    Text(reviewerName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(textColor)
                }
            }

            if let title = review.title, !title.isEmpty {
                Text("“\(title)”")
                    .font(.headline)
                    .foregroundStyle(textColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let subtitle = review.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(secondaryTextColor)
                    .lineSpacing(1.5)
                    .tracking(0.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct CoachTagFlow: Layout {
    let spacing: CGFloat

    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentRowWidth: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let shouldWrap = currentRowWidth > 0 && currentRowWidth + spacing + size.width > maxWidth

            if shouldWrap {
                totalHeight += currentRowHeight + spacing
                maxRowWidth = max(maxRowWidth, currentRowWidth)
                currentRowWidth = size.width
                currentRowHeight = size.height
            } else {
                currentRowWidth += currentRowWidth > 0 ? spacing + size.width : size.width
                currentRowHeight = max(currentRowHeight, size.height)
            }
        }

        totalHeight += currentRowHeight
        maxRowWidth = max(maxRowWidth, currentRowWidth)

        return CGSize(width: min(maxWidth, maxRowWidth), height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var origin = bounds.origin
        var currentRowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let shouldWrap = origin.x > bounds.minX && origin.x + size.width > bounds.maxX

            if shouldWrap {
                origin.x = bounds.minX
                origin.y += currentRowHeight + spacing
                currentRowHeight = 0
            }

            subview.place(
                at: origin,
                proposal: ProposedViewSize(width: size.width, height: size.height)
            )

            origin.x += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
    }
}



private struct CoachRefreshBanner: View {
    let error: String
    let retry: () -> Void
    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .foregroundStyle(theme.errorColor)
                .accessibilityHidden(true)

            Text(error)
                .font(theme.font)
                .foregroundStyle(theme.textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(AICoachUIStrings.retry, action: retry)
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

private extension Coach {
    var formattedRating: String? {
        guard let rating else { return nil }
        if rating == floor(rating) {
            return String(format: "%.0f", rating)
        }
        return String(format: "%.1f", rating)
    }

    var formattedClientsCount: String? {
        guard let clientsCount else { return nil }
        return clientsCount >= 100 ? "\(clientsCount)+" : "\(clientsCount)"
    }
}

struct CoachSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            CoachSelectionView()
        }
    }
}
