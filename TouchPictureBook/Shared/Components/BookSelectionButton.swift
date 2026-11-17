import SwiftUI

struct BookSelectionButton: View {
    let title: LocalizedStringResource
    let imageName: String?
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button {
            SoundManager.shared.playClick()
            action()
        } label: {
            VStack(spacing: 8) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "book.closed.fill")
                        .font(.largeTitle)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                if !isEnabled {
                    Text("準備中")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(isEnabled ? Color.primary : Color.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
            .background(Color.cyan.opacity(isEnabled ? 0.28 : 0.14))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyan.opacity(0.45), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityHint(isEnabled ? "絵本を開きます" : "この絵本は準備中です")
    }
}
