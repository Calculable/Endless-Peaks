//
//  Color+Extension.swift
//  MontainGenerator
//
//  Created by Jan Huber on 03.01.2026.
//
import SwiftUI

#if canImport(UIKit)
    import UIKit
    typealias PlatformColor = UIColor
#elseif canImport(AppKit)
    import AppKit
    typealias PlatformColor = NSColor
#endif

extension Color {

    public static func random(randomOpacity: Bool = false) -> Color {
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
