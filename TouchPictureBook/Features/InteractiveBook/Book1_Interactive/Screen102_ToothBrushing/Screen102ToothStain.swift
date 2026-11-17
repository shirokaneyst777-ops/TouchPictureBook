import Foundation
import CoreGraphics

enum ToothJaw: String {
    case upper
    case lower
}

struct ToothRegion: Identifiable, Equatable {
    let id: String
    let jaw: ToothJaw
    let normalizedFrame: CGRect

    var normalizedCenter: CGPoint {
        CGPoint(x: normalizedFrame.midX, y: normalizedFrame.midY)
    }

    var normalizedStainFrame: CGRect {
        normalizedFrame.insetBy(
            dx: normalizedFrame.width * 0.2,
            dy: normalizedFrame.height * 0.2
        )
    }

    static let all: [ToothRegion] = [
        tooth("upper_01", .upper, x: 226, y: 866, width: 65, height: 83),
        tooth("upper_02", .upper, x: 260, y: 840, width: 67, height: 86),
        tooth("upper_03", .upper, x: 306, y: 822, width: 87, height: 84),
        tooth("upper_04", .upper, x: 381, y: 817, width: 89, height: 77),
        tooth("upper_05", .upper, x: 469, y: 817, width: 86, height: 78),
        tooth("upper_06", .upper, x: 543, y: 825, width: 87, height: 82),
        tooth("upper_07", .upper, x: 615, y: 844, width: 64, height: 84),
        tooth("upper_08", .upper, x: 665, y: 875, width: 47, height: 74),
        tooth("lower_01", .lower, x: 234, y: 1027, width: 63, height: 73),
        tooth("lower_02", .lower, x: 264, y: 1053, width: 76, height: 81),
        tooth("lower_03", .lower, x: 318, y: 1077, width: 83, height: 81),
        tooth("lower_04", .lower, x: 388, y: 1090, width: 82, height: 83),
        tooth("lower_05", .lower, x: 469, y: 1089, width: 83, height: 85),
        tooth("lower_06", .lower, x: 541, y: 1076, width: 83, height: 83),
        tooth("lower_07", .lower, x: 610, y: 1051, width: 65, height: 84),
        tooth("lower_08", .lower, x: 659, y: 1027, width: 43, height: 77)
    ]

    private static func tooth(
        _ id: String,
        _ jaw: ToothJaw,
        x: CGFloat,
        y: CGFloat,
        width: CGFloat,
        height: CGFloat
    ) -> ToothRegion {
        let imageSize = CGSize(width: 937, height: 1678)

        return ToothRegion(
            id: id,
            jaw: jaw,
            normalizedFrame: CGRect(
                x: x / imageSize.width,
                y: y / imageSize.height,
                width: width / imageSize.width,
                height: height / imageSize.height
            )
        )
    }
}

struct Screen102ToothStain: Identifiable, Equatable {
    let id = UUID()
    let imageName: String
    let toothID: String
    let normalizedPosition: CGPoint
    let normalizedWidth: CGFloat
    var effectiveBrushingTime: TimeInterval = 0
    var brushingProgress: Double = 0

    var isRemoved: Bool {
        brushingProgress >= 1
    }
}
