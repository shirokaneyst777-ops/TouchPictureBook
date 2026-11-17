import Foundation

enum BookType: CaseIterable, Identifiable {
    case interactive
    case pointing
    case learning
    case story

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .interactive:
            "しかけ絵本"
        case .pointing:
            "ゆびさし絵本"
        case .learning:
            "いろ・かたち絵本"
        case .story:
            "おはなし絵本"
        }
    }

    var imageName: String? {
        nil
    }

    var isEnabled: Bool {
        self == .interactive
    }
}
