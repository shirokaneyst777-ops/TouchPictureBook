import SwiftUI

struct ToothSparkleView: View {
    @State private var isAnimating = false

    private let offsets: [CGSize] = [
        CGSize(width: -22, height: -12),
        CGSize(width: 18, height: -20),
        CGSize(width: 25, height: 15),
        CGSize(width: -16, height: 22),
        .zero
    ]

    var body: some View {
        ZStack {
            ForEach(Array(offsets.enumerated()), id: \.offset) { index, offset in
                Image(systemName: "sparkle")
                    .font(.system(size: index == 4 ? 20 : 13, weight: .bold))
                    .foregroundStyle(index.isMultiple(of: 2) ? .yellow : .white)
                    .offset(offset)
                    .scaleEffect(isAnimating ? 1.45 : 0.35)
                    .opacity(isAnimating ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                isAnimating = true
            }
        }
        .accessibilityHidden(true)
    }
}
