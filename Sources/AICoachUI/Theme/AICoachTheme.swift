import SwiftUI

/// A theme definition for the AI Coach UI components.
/// You can customize colors and fonts to match your app's brand.
public struct AICoachTheme: Sendable {
    public var primaryColor: Color
    public var backgroundColor: Color
    public var secondaryBackgroundColor: Color
    public var cardBackgroundColor: Color
    public var borderColor: Color
    public var textColor: Color
    public var secondaryTextColor: Color
    public var errorColor: Color
    public var primaryButtonTextColor: Color
    public var coachBubbleBackground: Color
    public var coachBubbleBorder: Color
    public var userBubbleBackground: Color
    public var avatarBackgroundColor: Color
    public var avatarForegroundColor: Color
    public var shadowColor: Color
    public var shimmerColor: Color
    public var tagBackgroundColor: Color
    public var tagForegroundColor: Color
    public var font: Font
    
    public init(
        primaryColor: Color = Color(red: 0.5, green: 0.4, blue: 1.0), // Purple from design
        backgroundColor: Color = .white,
        secondaryBackgroundColor: Color = Color(red: 0.96, green: 0.96, blue: 0.98),
        cardBackgroundColor: Color = .white,
        borderColor: Color = Color.black.opacity(0.12),
        textColor: Color = .primary,
        secondaryTextColor: Color = .secondary,
        errorColor: Color = .red,
        primaryButtonTextColor: Color = .white,
        coachBubbleBackground: Color = Color(red: 0.95, green: 0.94, blue: 1.0),
        coachBubbleBorder: Color = Color(red: 0.5, green: 0.4, blue: 1.0).opacity(0.5),
        userBubbleBackground: Color = .white,
        avatarBackgroundColor: Color = .black,
        avatarForegroundColor: Color = .white,
        shadowColor: Color = Color.black.opacity(0.06),
        shimmerColor: Color = Color.black.opacity(0.08),
        tagBackgroundColor: Color = Color.black.opacity(0.28),
        tagForegroundColor: Color = .white,
        font: Font = .body
    ) {
        self.primaryColor = primaryColor
        self.backgroundColor = backgroundColor
        self.secondaryBackgroundColor = secondaryBackgroundColor
        self.cardBackgroundColor = cardBackgroundColor
        self.borderColor = borderColor
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.errorColor = errorColor
        self.primaryButtonTextColor = primaryButtonTextColor
        self.coachBubbleBackground = coachBubbleBackground
        self.coachBubbleBorder = coachBubbleBorder
        self.userBubbleBackground = userBubbleBackground
        self.avatarBackgroundColor = avatarBackgroundColor
        self.avatarForegroundColor = avatarForegroundColor
        self.shadowColor = shadowColor
        self.shimmerColor = shimmerColor
        self.tagBackgroundColor = tagBackgroundColor
        self.tagForegroundColor = tagForegroundColor
        self.font = font
    }
}

/// Environment key for the theme
private struct AICoachThemeKey: EnvironmentKey {
    static let defaultValue = AICoachTheme()
}

public extension EnvironmentValues {
    var aiCoachTheme: AICoachTheme {
        get { self[AICoachThemeKey.self] }
        set { self[AICoachThemeKey.self] = newValue }
    }
}

public extension View {
    /// Applies a custom theme to the AI Coach UI components in this view hierarchy.
    func aiCoachTheme(_ theme: AICoachTheme) -> some View {
        environment(\.aiCoachTheme, theme)
    }
}
