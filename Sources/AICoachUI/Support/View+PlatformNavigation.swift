import SwiftUI

extension View {
    @ViewBuilder
    func aiCoachHiddenNavigationBar() -> some View {
        toolbar(.hidden, for: .navigationBar)
    }
}
