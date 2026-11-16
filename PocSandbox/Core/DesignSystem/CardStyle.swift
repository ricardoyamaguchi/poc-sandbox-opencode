import SwiftUI

struct CardStyle: ViewModifier {
    let background: Color
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(background)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle(background: Theme.card, radius: 20))
    }

    func mutedCardStyle() -> some View {
        modifier(CardStyle(background: Theme.mutedCard, radius: 20))
    }
}
