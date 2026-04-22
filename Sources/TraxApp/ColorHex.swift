import Foundation
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double

        if cleaned.count == 6 {
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        } else {
            red = 0.55
            green = 0.55
            blue = 0.58
        }

        self.init(red: red, green: green, blue: blue)
    }

    var hexString: String? {
        #if canImport(AppKit)
        let nsColor = NSColor(self)
        guard let deviceColor = nsColor.usingColorSpace(.deviceRGB) else {
            return nil
        }

        let red = Int((deviceColor.redComponent * 255).rounded())
        let green = Int((deviceColor.greenComponent * 255).rounded())
        let blue = Int((deviceColor.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
        #else
        return nil
        #endif
    }
}
