import SwiftUI

struct HomeView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    @State private var isInteractiveBookPresented = false

    var body: some View {
        NavigationStack {
            ZStack {
                HomeBackgroundView()

                VStack(spacing: 20) {
                    Text("どの絵本で遊ぶ？")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(BookType.allCases) { book in
                            BookSelectionButton(
                                title: book.title,
                                imageName: book.imageName,
                                isEnabled: book.isEnabled,
                                action: {
                                    isInteractiveBookPresented = true
                                }
                            )
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                    .frame(maxWidth: 500)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationDestination(isPresented: $isInteractiveBookPresented) {
                InteractiveBookView()
            }
        }
    }
}

private struct HomeBackgroundView: View {
    var body: some View {
        ZStack {
            Color.cyan.opacity(0.08)

            GeometryReader { geometry in
                Image("home_background")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .clipped()
            }
        }
        .ignoresSafeArea()
    }
}
