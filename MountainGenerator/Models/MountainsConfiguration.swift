import SwiftUI

@Observable
final class MountainsConfiguration {
    var numberOfMountains: Int
    var maxPointsPerDepth: Int
    var depth: Int

    var speed: CGFloat
    var zoomEffect2: CGFloat
    var zoomEffect: CGFloat
    var offsetEffect: CGFloat
    var offsetEffect2: CGFloat

    var backgroundColor1: Color
    var backgroundColor2: Color
    var backgroundColor3: Color
    var backgroundColorForVideo: Color

    var foregroundColor: Color
    var rounded: Bool

    var musicFileName: String
    var mountainPalette: [Color]

    init(
        numberOfMountains: Int = 10,
        maxPointsPerDepth: Int = 3,
        depth: Int = 2,
        speed: CGFloat = 0.01,
        zoomEffect2: CGFloat = 1.5,
        zoomEffect: CGFloat = 1,
        offsetEffect: CGFloat = 3,
        offsetEffect2: CGFloat = 1,
        backgroundColor1: Color = .random(),
        backgroundColor2: Color = .random(),
        backgroundColor3: Color = .white,
        backgroundColorForVideo: Color = .random(),
        foregroundColor: Color = .black,
        rounded: Bool = true,
        musicFileName: String = "",
        mountainPalette: [Color] = []
    ) {
        self.numberOfMountains = numberOfMountains
        self.maxPointsPerDepth = maxPointsPerDepth
        self.depth = depth
        self.speed = speed
        self.zoomEffect2 = zoomEffect2
        self.zoomEffect = zoomEffect
        self.offsetEffect = offsetEffect
        self.offsetEffect2 = offsetEffect2
        self.backgroundColor1 = backgroundColor1
        self.backgroundColor2 = backgroundColor2
        self.backgroundColor3 = backgroundColor3
        self.backgroundColorForVideo = backgroundColorForVideo
        self.foregroundColor = foregroundColor
        self.rounded = rounded
        self.musicFileName = musicFileName
        self.mountainPalette = mountainPalette
    }

    func mountainColor(seed: UInt64) -> Color {
        let palette = mountainPalette.isEmpty ? [foregroundColor] : mountainPalette
        let base = palette[Int(seed % UInt64(palette.count))]
        return base.toneVariant(seed: seed)
    }

    var backgroundGradient: Gradient {
        Gradient(stops: [
            .init(color: backgroundColor1, location: 0),
            .init(color: backgroundColor2, location: 0.5),
            .init(color: backgroundColor3, location: 1.0),
        ])
    }
}

extension MountainsConfiguration {
    static let appenzell = MountainsConfiguration(
        numberOfMountains: 10,
        maxPointsPerDepth: 1,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 4.22,
        zoomEffect: 2.69,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#089EFFFF"),
        backgroundColor2: Color(hex: "#C2FF3EFF"),
        backgroundColor3: Color(hex: "#FEFFFFFF"),
        backgroundColorForVideo: Color(hex: "#1F80A6FF"),
        foregroundColor: .black,
        rounded: true,
        musicFileName: "Appenzell",
        mountainPalette: [
            Color(hex: "#1C594EFF"),
            Color(hex: "#BBBF49FF"),
            Color(hex: "#BFBA69FF"),
        ]
    )

    static let yosemite = MountainsConfiguration(
        numberOfMountains: 10,
        maxPointsPerDepth: 1,
        depth: 7,
        speed: 0.005,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 5.8,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#29353FFF"),
        backgroundColor2: Color(hex: "#8D9FA6FF"),
        backgroundColor3: Color(hex: "#0D0B01FF"),
        backgroundColorForVideo: Color(hex: "#8E9EBFFF"),
        foregroundColor: .black,
        rounded: false,
        musicFileName: "Yosemite_Valley",
        mountainPalette: [
            Color(hex: "#F2DFE0FF"),
            Color(hex: "#734B43FF"),
            Color(hex: "#261615FF"),
        ]
    )

    static let dolomites = MountainsConfiguration(
        numberOfMountains: 4,
        maxPointsPerDepth: 3,
        depth: 4,
        speed: 0.0025,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 4.22,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#102225FF"),
        backgroundColor2: Color(hex: "#BFBFB9FF"),
        backgroundColor3: Color(hex: "#8C8B88FF"),
        backgroundColorForVideo: Color(hex: "#595959FF"),
        foregroundColor: .black,
        rounded: false,
        musicFileName: "Dolomiten",
        mountainPalette: [
            Color(hex: "#222326FF"),
            Color(hex: "#595959FF"),
            Color(hex: "#BFBFB9FF"),
            Color(hex: "#F2F2F2FF"),
        ]
    )

    static let zhangjiajie = MountainsConfiguration(
        numberOfMountains: 23,
        maxPointsPerDepth: 7,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 4.22,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#F2AC85FF"),
        backgroundColor2: Color(hex: "#83A605FF"),
        backgroundColor3: Color(hex: "#5A7304FF"),
        backgroundColorForVideo: Color(hex: "#ADC5D9FF"),
        foregroundColor: .black,
        rounded: true,
        musicFileName: "Zhangjiajie_National_Forest_Park",
        mountainPalette: [
            Color(hex: "#698C58FF"),
            Color(hex: "#262314FF"),
            Color(hex: "#F2E8B6FF"),
        ]
    )

    static let torresDelPaine = MountainsConfiguration(
        numberOfMountains: 7,
        maxPointsPerDepth: 8,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 2.8899999999999997,
        zoomEffect: 4.22,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#5E6573FF"),
        backgroundColor2: Color(hex: "#F2984BFF"),
        backgroundColor3: Color(hex: "#F2845CFF"),
        backgroundColorForVideo: Color(hex: "#5D6C8CFF"),
        foregroundColor: .black,
        rounded: false,
        musicFileName: "Torres_del_Paine",
        mountainPalette: [
            Color(hex: "#72493BFF"),
            Color(hex: "#F2C6A0FF"),
            Color(hex: "#BF6550FF"),
        ]
    )

    static let scottishHighlands = MountainsConfiguration(
        numberOfMountains: 7,
        maxPointsPerDepth: 3,
        depth: 2,
        speed: 0.005,
        zoomEffect2: 0.37,
        zoomEffect: 2.3,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#A68D9CFF"),
        backgroundColor2: Color(hex: "#F2CC88FF"),
        backgroundColor3: Color(hex: "#898C2AFF"),
        backgroundColorForVideo: Color(hex: "#F2CC88FF"),
        foregroundColor: .black,
        rounded: true,
        musicFileName: "Schottische_Highlands",
        mountainPalette: [
            Color(hex: "#898C2AFF"),
            Color(hex: "#593A37FF"),
            Color(hex: "#A65D5DFF"),
        ]
    )

    static let tassiliNAjjer = MountainsConfiguration(
        numberOfMountains: 6,
        maxPointsPerDepth: 3,
        depth: 5,
        speed: 0.005,
        zoomEffect2: 1.29,
        zoomEffect: 5.1499999999999995,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#250303FF"),
        backgroundColor2: Color(hex: "#E32413FF"),
        backgroundColor3: Color(hex: "#89A1B2FF"),
        backgroundColorForVideo: Color(hex: "#E32413FF"),
        foregroundColor: .black,
        rounded: true,
        musicFileName: "Tassili_n_Ajjer",
        mountainPalette: [
            Color(hex: "#0D0D0DFF"),
            Color(hex: "#F2BC57FF"),
            Color(hex: "#F2542DFF"),
            Color(hex: "#F2F2F2FF"),
        ]
    )

    static let himalaya = MountainsConfiguration(
        numberOfMountains: 16,
        maxPointsPerDepth: 4,
        depth: 4,
        speed: 0.004,
        zoomEffect2: 5.03,
        zoomEffect: 24.900000000000002,
        offsetEffect: 10,
        offsetEffect2: 10,
        backgroundColor1: Color(hex: "#224459FF"),
        backgroundColor2: Color(hex: "#95C6D9FF"),
        backgroundColor3: Color(hex: "#AFE8FFFF"),
        backgroundColorForVideo: Color(hex: "#424659FF"),
        foregroundColor: .black,
        rounded: true,
        musicFileName: "Himalaya",
        mountainPalette: [
            Color(hex: "#C4C1D9FF"),
            Color(hex: "#8688A6FF"),
            Color(hex: "#686D8CFF"),
            Color(hex: "#00010DFF"),
        ]
    )

    static let background = MountainsConfiguration(
        numberOfMountains: 4,
        maxPointsPerDepth: 1,
        depth: 2,
        speed: 0.001,
        zoomEffect2: 4.22,
        zoomEffect: 2.69,
        offsetEffect: 3.13,
        offsetEffect2: 0.59,
        backgroundColor1: Color(hex: "#FEFFFFFF"),
        backgroundColor2: Color(hex: "#FEFFFFFF"),
        backgroundColor3: Color(hex: "#FEFFFFFF"),
        backgroundColorForVideo: Color(hex: "#FEFFFFFF"),
        foregroundColor: .black,
        rounded: true,
        musicFileName: "Background"
    )
}
