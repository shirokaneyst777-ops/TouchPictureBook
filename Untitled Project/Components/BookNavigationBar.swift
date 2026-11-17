import SwiftUI

struct BookNavigationBar: View {
    let onPrevious: () -> Void
    let onHome: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NavigationButton(
                title: "前へ",
                systemImage: "chevron.left",
                playsClickSound: false,
                action: onPrevious
            )
            NavigationButton(
                title: "ホーム",
                systemImage: "house.fill",
                playsClickSound: true,
                action: onHome
            )
            NavigationButton(
                title: "次へ",
                systemImage: "chevron.right",
                playsClickSound: false,
                action: onNext
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

private struct NavigationButton: View {
    let title: LocalizedStringResource
    let systemImage: String
    let playsClickSound: Bool
    let action: () -> Void

    var body: some View {
        Button {
            if playsClickSound {
                SoundManager.shared.playClick()
            }
            action()
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .foregroundStyle(Color.primary)
            .background(Color.cyan.opacity(0.82))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
