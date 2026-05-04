// BrandColors.swift
// Finance Toolkit — design-token layer & shared helpers

import SwiftUI

// MARK: - Currency Settings
struct CurrencySettings {
    static let supportedCurrencies: [(code: String, name: String, symbol: String)] = [
        ("INR", "Indian Rupee", "₹"),
        ("USD", "US Dollar", "$"),
        ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"),
        ("AED", "UAE Dirham", "د.إ"),
        ("SAR", "Saudi Riyal", "﷼"),
        ("CAD", "Canadian Dollar", "C$"),
        ("AUD", "Australian Dollar", "A$"),
        ("SGD", "Singapore Dollar", "S$"),
        ("JPY", "Japanese Yen", "¥"),
        ("DOP", "Dominican Peso", "RD$"),
    ]

    static var selectedCode: String {
        UserDefaults.standard.string(forKey: "selectedCurrency") ?? (Locale.current.currency?.identifier ?? "INR")
    }

    static func symbol(for code: String) -> String {
        supportedCurrencies.first(where: { $0.code == code })?.symbol ?? "₹"
    }

    /// Formats a value with the currency symbol always placed before the amount.
    /// This avoids locale-dependent symbol positioning from `.formatted(.currency(code:))`.
    static func formatCurrency(_ value: Double, code: String) -> String {
        let sym = symbol(for: code)
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.minimumFractionDigits = 2
        numberFormatter.maximumFractionDigits = 2
        let formatted = numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
        return "\(sym)\(formatted)"
    }
}

// MARK: - Hex initialiser
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Brand palette
extension Color {
    // Navy ramp
    static let navy      = Color(hex: "#185FA5")
    static let navyDark  = Color(hex: "#0C447C")
    static let navyDeep  = Color(hex: "#042C53")
    static let navyMid   = Color(hex: "#85B7EB")
    static let navySoft  = Color(hex: "#E6F1FB")
    static let navyLight = Color(hex: "#E6F1FB")

    // Gold ramp
    static let gold      = Color(hex: "#BA7517")
    static let goldLight = Color(hex: "#FAC775")
    static let goldSoft  = Color(hex: "#FAEEDA")

    // Teal (gain)
    static let teal      = Color(hex: "#1D9E75")
    static let tealLight = Color(hex: "#E1F5EE")

    // Aliases used in CalcItem color assignment
    static let brandAccent = Color(hex: "#B5D4F4")
}
