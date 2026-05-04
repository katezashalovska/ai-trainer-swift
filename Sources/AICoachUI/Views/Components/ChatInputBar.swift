import SwiftUI

public struct ChatInputBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var isSending: Bool
    var onSend: () -> Void
    @Environment(\.aiCoachTheme) var theme

    public init(text: Binding<String>, isFocused: FocusState<Bool>.Binding, isSending: Bool = false, onSend: @escaping () -> Void) {
        self._text = text
        self.isFocused = isFocused
        self.isSending = isSending
        self.onSend = onSend
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            TextField(AICoachUIStrings.enterQuestion, text: $text)
                .font(theme.font)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .padding(.horizontal)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.userBubbleBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(theme.borderColor, lineWidth: 1)
                )
                .focused(isFocused)
                .animation(.easeInOut(duration: 0.2), value: isFocused.wrappedValue)
                .accessibilityLabel(AICoachUIStrings.enterQuestion)
            
            Button(action: {
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !isSending else { return }
                onSend()
                isFocused.wrappedValue = false
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(theme.primaryColor.opacity(0.1))
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(theme.primaryColor.opacity(0.5), lineWidth: 1)

                        Image("send_icon", bundle: .module)
                            .renderingMode(.template)
                            .foregroundColor(theme.primaryColor)
                }
                .frame(width: 44, height: 44)
                .scaleEffect(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 1 : 1.02)
                .animation(.spring(response: 0.26, dampingFraction: 0.72), value: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.7 : 1)
            .accessibilityLabel(AICoachUIStrings.send)
            .accessibilityHint(AICoachUIStrings.sendHint)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(theme.backgroundColor)
    }
}

struct ChatInputBar_Previews: PreviewProvider {
    struct Wrapper: View {
        @FocusState private var isFocused: Bool
        var body: some View {
            ChatInputBar(text: .constant(""), isFocused: $isFocused, onSend: {})
        }
    }
    static var previews: some View {
        Wrapper()
    }
}
