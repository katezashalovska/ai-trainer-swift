import SwiftUI
import AICoachSDK

struct MessageBubbleShape: Shape {
    let isFromUser: Bool
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        if isFromUser {
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(center: CGPoint(x: width - radius, y: radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: width, y: height - 18))
            path.addCurve(
                to: CGPoint(x: width + 6, y: height),
                control1: CGPoint(x: width, y: height - 9),
                control2: CGPoint(x: width + 6, y: height - 4)
            )
            path.addArc(center: CGPoint(x: width + 4, y: height), radius: 2, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addCurve(
                to: CGPoint(x: width - 16, y: height),
                control1: CGPoint(x: width, y: height + 2),
                control2: CGPoint(x: width - 8, y: height)
            )
            path.addLine(to: CGPoint(x: radius, y: height))
            path.addArc(center: CGPoint(x: radius, y: height - radius), radius: radius, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        } else {
            path.move(to: CGPoint(x: radius, y: 0))
            path.addLine(to: CGPoint(x: width - radius, y: 0))
            path.addArc(center: CGPoint(x: width - radius, y: radius), radius: radius, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
            path.addLine(to: CGPoint(x: width, y: height - radius))
            path.addArc(center: CGPoint(x: width - radius, y: height - radius), radius: radius, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
            path.addLine(to: CGPoint(x: 16, y: height))
            path.addCurve(
                to: CGPoint(x: -4, y: height + 2),
                control1: CGPoint(x: 8, y: height),
                control2: CGPoint(x: 0, y: height + 2)
            )
            path.addArc(center: CGPoint(x: -4, y: height), radius: 2, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
            path.addCurve(
                to: CGPoint(x: 0, y: height - 16),
                control1: CGPoint(x: -6, y: height - 4),
                control2: CGPoint(x: 0, y: height - 9)
            )
            path.addLine(to: CGPoint(x: 0, y: radius))
            path.addArc(center: CGPoint(x: radius, y: radius), radius: radius, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}

public struct MessageBubble: View {
    let message: ChatMessage
    let deliveryState: MessageDeliveryState
    let onRetry: (() -> Void)?
    @Environment(\.aiCoachTheme) var theme

    let bubbleRadius: CGFloat = 16
    let tailSize: CGFloat = 6

    init(
        message: ChatMessage,
        deliveryState: MessageDeliveryState = .sent,
        onRetry: (() -> Void)? = nil
    ) {
        self.message = message
        self.deliveryState = deliveryState
        self.onRetry = onRetry
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 30)

                VStack(alignment: .trailing, spacing: 6) {
                    bubbleContent(isFromUser: true)
                    MessageStatusLabel(
                        createdAt: message.createdAt,
                        deliveryState: deliveryState,
                        retry: onRetry
                    )
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    bubbleContent(isFromUser: false)
                    MessageStatusLabel(createdAt: message.createdAt, deliveryState: .sent)
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accentColor: Color {
        theme.primaryColor
    }

    @ViewBuilder
    private func bubbleContent(isFromUser: Bool) -> some View {
        MarkdownRenderer(content: message.content ?? "")
            .padding(14)
            .padding(isFromUser ? .trailing : .leading, tailSize)
            .background(
                MessageBubbleShape(isFromUser: isFromUser, radius: bubbleRadius)
                    .fill(isFromUser ? theme.userBubbleBackground : theme.coachBubbleBackground)
            )
            .overlay(
                MessageBubbleShape(isFromUser: isFromUser, radius: bubbleRadius)
                    .stroke(
                        isFromUser
                            ? theme.borderColor
                            : theme.coachBubbleBorder,
                        lineWidth: 1
                    )
            )
            .shadow(color: theme.shadowColor.opacity(0.5), radius: 10, x: 0, y: 5)
    }

    private var accessibilityLabel: String {
        let sender = message.isFromUser ? AICoachUIStrings.you : AICoachUIStrings.coach
        let status: String?
        switch deliveryState {
        case .sent:
            status = nil
        case .sending:
            status = AICoachUIStrings.sending
        case .failed:
            status = AICoachUIStrings.failedToSend
        }

        return AICoachUIStrings.accessibilityMessageLabel(
            sender: sender,
            content: message.content ?? "",
            status: status
        )
    }
}

private struct MessageStatusLabel: View {
    let createdAt: Date?
    let deliveryState: MessageDeliveryState
    var retry: (() -> Void)? = nil

    @Environment(\.aiCoachTheme) private var theme

    var body: some View {
        switch deliveryState {
        case .sent:
            if let createdAt {
                Text(createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(theme.secondaryTextColor)
            }
        case .sending:
            EmptyView()
        case .failed:
            HStack(spacing: 8) {
                Text(AICoachUIStrings.failedToSend)
                    .font(.caption)
                    .foregroundStyle(theme.errorColor)

                if let retry {
                    Button(AICoachUIStrings.retry, action: retry)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.primaryColor)
                        .buttonStyle(.plain)
                        .accessibilityHint(AICoachUIStrings.retrySendHint)
                }
            }
        }
    }
}

struct MessageBubble_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MessageBubble(
                message: ChatMessage(
                    id: UUID(),
                    sessionId: UUID(),
                    sender: "user",
                    content: "What helps muscles recover faster after intense workouts?",
                    photoUrl: nil,
                    rating: nil,
                    createdAt: Date()
                ),
                deliveryState: .failed
            )
            MessageBubble(
                message: ChatMessage(
                    id: UUID(),
                    sessionId: UUID(),
                    sender: "coach",
                    content: "Rest, nutrition and hydration are the biggest levers for faster recovery.",
                    photoUrl: nil,
                    rating: nil,
                    createdAt: Date()
                )
            )
        }
        .padding()
        .background(Color.white)
    }
}
