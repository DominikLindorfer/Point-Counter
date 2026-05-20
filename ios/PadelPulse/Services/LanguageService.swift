import Foundation

/// Runtime language switching by swizzling `Bundle.main`'s localized-string lookup.
///
/// Stores the user's choice in UserDefaults under `selected_language`. Values:
/// `"system"` (fallback to system locale) or a specific code: `"en"`, `"de"`, `"es"`.
/// Views re-render when the `@AppStorage("selected_language")` value changes via
/// a `.id(...)` modifier on the root ContentView.
enum LanguageService {
    static let storageKey = DefaultsKey.selectedLanguage
    static let supportedLanguages = ["en", "de", "es"]

    /// Apply the stored language choice to `Bundle.main` at app launch.
    static func applyStoredLanguage() {
        let stored = UserDefaults.standard.string(forKey: storageKey) ?? "system"
        apply(languageCode: stored)
    }

    /// Switch the app's localized-string lookup to the given code.
    /// Pass `"system"` to fall back to the device's language.
    static func apply(languageCode: String) {
        if languageCode == "system" {
            Bundle.resetLanguageOverride()
        } else {
            Bundle.overrideLanguage(languageCode)
        }
    }
}

private var bundleKey: UInt8 = 0

private class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let path = objc_getAssociatedObject(self, &bundleKey) as? String,
           let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    fileprivate static func overrideLanguage(_ language: String) {
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj") else { return }
        object_setClass(Bundle.main, LocalizedBundle.self)
        objc_setAssociatedObject(Bundle.main, &bundleKey, path, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    fileprivate static func resetLanguageOverride() {
        object_setClass(Bundle.main, Bundle.self)
        objc_setAssociatedObject(Bundle.main, &bundleKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
