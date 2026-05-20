import XCTest
@testable import PadelPulse

/// Guards against localization drift: whenever a new key is added to the English
/// strings file, DE and ES must follow. Without this test a contributor could
/// ship a new `.accessibilityLabel("Foo")` that falls back to the key name in
/// non-English locales — VoiceOver users would hear raw English.
///
/// Runs at unit-test time so CI catches missing translations before release.
final class LocalizationParityTests: XCTestCase {

    func testDeAndEsCoverEveryEnglishKey() throws {
        let en = try loadStrings(locale: "en")
        let de = try loadStrings(locale: "de")
        let es = try loadStrings(locale: "es")

        XCTAssertFalse(en.isEmpty, "en.lproj/Localizable.strings must not be empty")

        let missingInDe = Set(en.keys).subtracting(de.keys).sorted()
        let missingInEs = Set(en.keys).subtracting(es.keys).sorted()

        XCTAssertTrue(missingInDe.isEmpty,
                      "DE is missing keys: \(missingInDe.joined(separator: ", "))")
        XCTAssertTrue(missingInEs.isEmpty,
                      "ES is missing keys: \(missingInEs.joined(separator: ", "))")
    }

    /// Loads the Localizable.strings file for a given locale directly from the
    /// app bundle. Avoids Bundle.localizedString lookups, which silently fall
    /// back to the key when a translation is missing — we want the real dict.
    private func loadStrings(locale: String) throws -> [String: String] {
        let bundle = Bundle(for: MatchViewModel.self)
        guard let path = bundle.path(forResource: "Localizable", ofType: "strings", inDirectory: nil, forLocalization: locale),
              let dict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            XCTFail("Could not load \(locale).lproj/Localizable.strings from app bundle")
            return [:]
        }
        return dict
    }
}
