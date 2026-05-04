// AppLanguage.swift
// Finance Toolkit — localization manager with in-app language override

import SwiftUI
import Foundation
import Combine

// MARK: - Supported Languages
enum AppLanguageCode: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case hi = "hi"
    case es = "es"
    case fr = "fr"
    case ar = "ar"
    case pt = "pt-BR"
    case de = "de"
    case zh = "zh-Hans"
    case ja = "ja"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .en:     return "English"
        case .hi:     return "हिन्दी (Hindi)"
        case .es:     return "Español (Spanish)"
        case .fr:     return "Français (French)"
        case .ar:     return "العربية (Arabic)"
        case .pt:     return "Português (Portuguese)"
        case .de:     return "Deutsch (German)"
        case .zh:     return "中文 (Chinese)"
        case .ja:     return "日本語 (Japanese)"
        }
    }

    var flag: String {
        switch self {
        case .system: return "🌐"
        case .en:     return "🇺🇸"
        case .hi:     return "🇮🇳"
        case .es:     return "🇪🇸"
        case .fr:     return "🇫🇷"
        case .ar:     return "🇸🇦"
        case .pt:     return "🇧🇷"
        case .de:     return "🇩🇪"
        case .zh:     return "🇨🇳"
        case .ja:     return "🇯🇵"
        }
    }
}

// MARK: - Language Manager
@MainActor
final class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()

    @AppStorage("appLanguageOverride") private var storedLanguage: String = "system"

    @Published var currentLanguage: AppLanguageCode = .system
    @Published var locale: Locale = .current
    @Published var layoutDirection: LayoutDirection = .leftToRight

    private init() {
        let code = AppLanguageCode(rawValue: UserDefaults.standard.string(forKey: "appLanguageOverride") ?? "system") ?? .system
        currentLanguage = code
        applyLanguage(code)
    }

    func setLanguage(_ code: AppLanguageCode) {
        storedLanguage = code.rawValue
        currentLanguage = code
        applyLanguage(code)
    }

    private func applyLanguage(_ code: AppLanguageCode) {
        if code == .system {
            locale = .current
            let deviceLang = Locale.preferredLanguages.first ?? "en"
            layoutDirection = deviceLang.hasPrefix("ar") || deviceLang.hasPrefix("he") ? .rightToLeft : .leftToRight
        } else {
            locale = Locale(identifier: code.rawValue)
            layoutDirection = code == .ar ? .rightToLeft : .leftToRight
        }
    }

    /// The effective language code for Bundle lookup
    var effectiveLanguageCode: String {
        if currentLanguage == .system {
            return Locale.preferredLanguages.first ?? "en"
        }
        return currentLanguage.rawValue
    }

    /// The localization bundle for the current language
    var bundle: Bundle {
        let langCode = effectiveLanguageCode
        // Try exact match first, then base language
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        // Try just the language part (e.g. "pt" from "pt-BR")
        let baseCode = String(langCode.prefix(2))
        if let path = Bundle.main.path(forResource: baseCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }
}

// MARK: - Localized String Helper
/// Use this for strings that need runtime language switching
func L(_ key: String) -> String {
    AppLanguageManager.shared.bundle.localizedString(forKey: key, value: nil, table: nil)
}

/// Use this for strings with format arguments
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = AppLanguageManager.shared.bundle.localizedString(forKey: key, value: nil, table: nil)
    return String(format: format, arguments: args)
}
