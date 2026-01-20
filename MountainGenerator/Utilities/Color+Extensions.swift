import SwiftUI

#if canImport(UIKit)
import UIKit
typealias PlatformColor = UIColor
#elseif canImport(AppKit)
import AppKit
typealias PlatformColor = NSColor
#endif

extension Color {
    static func random(randomOpacity: Bool = false) -> Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1),
            opacity: randomOpacity ? .random(in: 0...1) : 1
        )
    }
}

extension PlatformColor {
    convenience init?(hex: String) {
        let r, g, b, a: CGFloat

        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.removeFirst()
        }

        guard hexString.count == 8,
              let hexNumber = UInt64(hexString, radix: 16)
        else {
            return nil
        }

        r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
        g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
        b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
        a = CGFloat(hexNumber & 0x000000ff) / 255

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

extension PlatformColor {
    func toHex(includeAlpha: Bool = true) -> String? {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        #else
        guard let rgbColor = self.usingColorSpace(.deviceRGB) else {
            return nil
        }

        let red = rgbColor.redComponent
        let green = rgbColor.greenComponent
        let blue = rgbColor.blueComponent
        let alpha = rgbColor.alphaComponent
        #endif

        if includeAlpha {
            return String(
                format: "#%02X%02X%02X%02X",
                Int(red * 255),
                Int(green * 255),
                Int(blue * 255),
                Int(alpha * 255)
            )
        } else {
            return String(
                format: "#%02X%02X%02X",
                Int(red * 255),
                Int(green * 255),
                Int(blue * 255)
            )
        }
    }
}


extension Color {
    init(hex: String) {
        let uiColor = PlatformColor(hex: hex)
        self.init(uiColor!)
    }
}

extension Color {
    func toHex(includeAlpha: Bool = true) -> String? {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        return uiColor.toHex(includeAlpha: includeAlpha)
        #else
        let nsColor = NSColor(self)
        return nsColor.toHex(includeAlpha: includeAlpha)
        #endif
    }
}

extension Color {
    fileprivate func hsbaComponents() -> (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat)? {
        #if canImport(UIKit)
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        let uiColor = UIColor(self)
        guard uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else {
            return nil
        }
        return (h: h, s: s, b: b, a: a)
        #else
        let nsColor = NSColor(self)
        guard let rgbColor = nsColor.usingColorSpace(.deviceRGB) else {
            return nil
        }
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        rgbColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h: h, s: s, b: b, a: a)
        #endif
    }

    fileprivate static func clamp01(_ value: CGFloat) -> CGFloat {
        min(max(value, 0), 1)
    }

    func toneVariant(seed: UInt64) -> Color {
        guard let hsba = hsbaComponents() else { return self }

        var rng = SeededGenerator(seed: seed ^ 0x9E3779B97F4A7C15)

        let hueJitter = CGFloat.random(in: -0.035...0.035, using: &rng)
        let saturationMult = CGFloat.random(in: 0.75...1.15, using: &rng)
        let brightnessMult = CGFloat.random(in: 0.75...1.12, using: &rng)
        let brightnessAdd = CGFloat.random(in: -0.06...0.06, using: &rng)

        var h = hsba.h + hueJitter
        if h < 0 { h += 1 }
        if h > 1 { h -= 1 }

        let s = Self.clamp01(hsba.s * saturationMult)
        let b = Self.clamp01(hsba.b * brightnessMult + brightnessAdd)

        return Color(hue: h, saturation: s, brightness: b, opacity: hsba.a)
    }
}
