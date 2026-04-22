import SwiftUI
import UIKit

// MARK: - Colors

let DarkBg = Color(red: 0x0D / 255.0, green: 0x0D / 255.0, blue: 0x0D / 255.0)
let TextWhite = Color.white
let DimColor = Color(red: 0x99 / 255.0, green: 0x99 / 255.0, blue: 0x99 / 255.0)
let GoldColor = Color(red: 0xFF / 255.0, green: 0xD7 / 255.0, blue: 0x00 / 255.0)
let ButtonBg = Color(red: 0x1A / 255.0, green: 0x1A / 255.0, blue: 0x1A / 255.0)
let ButtonBgDisabled = Color(red: 0x11 / 255.0, green: 0x11 / 255.0, blue: 0x11 / 255.0)
let SettingsBg = Color(red: 0x16 / 255.0, green: 0x16 / 255.0, blue: 0x16 / 255.0)
let SettingsSurface = Color(red: 0x22 / 255.0, green: 0x22 / 255.0, blue: 0x22 / 255.0)
let RecordRed = Color(red: 0xFF / 255.0, green: 0x3B / 255.0, blue: 0x30 / 255.0)

// History card team colors
let Team1Blue = Color(red: 0x5B / 255.0, green: 0xA8 / 255.0, blue: 0xFF / 255.0)
let Team2Red = Color(red: 0xFF / 255.0, green: 0x7A / 255.0, blue: 0x7A / 255.0)

// MARK: - Adaptive Layout

/// Scale-based layout metrics. Reference: iPad Pro 11" landscape (1194×834).
///
/// On iPad, `scale` is width-only (original formula) — guarantees 100% visual parity
/// with the iPad-only release. On iPhone, `scale = min(widthScale, heightScale)` so
/// height-bound elements (score font) don't overflow the shorter landscape screen.
/// Small UI metrics are then clamped to minimum readable pt values so they stay
/// legible on iPhone SE without affecting iPad (where scale ≥ ~0.95, all clamps inactive).
struct LayoutMetrics {
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    let isPhone: Bool

    private var widthScale: CGFloat { screenWidth / 1194.0 }
    private var heightScale: CGFloat { screenHeight / 834.0 }

    var scale: CGFloat {
        isPhone ? min(widthScale, heightScale) : widthScale
    }

    // Score display — unclamped, dominates the screen
    var scoreFont: CGFloat { 520 * scale }
    var teamNameFont: CGFloat { max(16, 44 * scale) }
    var servingBadgeFont: CGFloat { max(14, 32 * scale) }
    var servingRacketSize: CGFloat { max(40, 72 * scale) }
    // L/R glyph paired with the racket in the court-side corner. Readable
    // from ~15m while staying proportionate to the racket it sits next to.
    var serveLetterFont: CGFloat { max(64, 130 * scale) }
    var servePanelGlowWidth: CGFloat { max(4, 6 * scale) }

    // Games box — unclamped, dominates the screen
    var gamesBoxWidth: CGFloat { 180 * scale }
    var gamesBoxHeight: CGFloat { 170 * scale }
    var gamesBoxCorner: CGFloat { 22 * scale }
    var gamesLabelFont: CGFloat { 18 * scale }
    var gamesNumberFont: CGFloat { 156 * scale }
    var gamesBoxTopPadding: CGFloat { 32 * scale }

    // Toolbar
    var toolbarIconSize: CGFloat { max(16, 20 * scale) }
    var toolbarLabelFont: CGFloat { max(11, 14 * scale) }
    var toolbarPaddingH: CGFloat { 16 * scale }
    var toolbarPaddingV: CGFloat { 10 * scale }
    var toolbarSpacing: CGFloat { 8 * scale }

    // Camera overlay
    var cameraWidth: CGFloat { max(140, 192 * scale) }
    var cameraHeight: CGFloat { max(78, 108 * scale) }
    var cameraCorner: CGFloat { 16 * scale }
    var cameraIconSize: CGFloat { max(12, 16 * scale) }
    var cameraButtonSize: CGFloat { max(24, 32 * scale) }
    var cameraRecordDot: CGFloat { 8 * scale }
    var cameraRecordIcon: CGFloat { max(12, 16 * scale) }

    // Serve indicator — unclamped
    var serveArrowSize: CGFloat { 48 * scale }
    var serveBallSize: CGFloat { 44 * scale }
    var serveTextSize: CGFloat { 36 * scale }

    // Match over overlay
    var trophySize: CGFloat { max(48, 80 * scale) }
    var matchOverTitleFont: CGFloat { max(26, 52 * scale) }
    var matchOverSubtitleFont: CGFloat { max(20, 36 * scale) }
    var matchOverButtonIcon: CGFloat { max(16, 24 * scale) }
    var matchOverButtonFont: CGFloat { max(14, 20 * scale) }

    // Settings sidebar — iPhone needs a wider percentage + floor so text stays readable
    var settingsWidth: CGFloat {
        isPhone
            ? min(420, max(320, screenWidth * 0.45))
            : min(420, screenWidth * 0.36)
    }
    var settingsHeaderIcon: CGFloat { max(20, 28 * scale) }
    var settingsHeaderFont: CGFloat { max(18, 24 * scale) }
    var settingsSectionFont: CGFloat { max(14, 18 * scale) }
    var settingsRowIcon: CGFloat { max(18, 24 * scale) }
    var settingsRowLabel: CGFloat { max(13, 16 * scale) }
    var settingsRowValue: CGFloat { max(12, 14 * scale) }

    // Match history
    var historyHeaderIcon: CGFloat { max(20, 28 * scale) }
    var historyHeaderFont: CGFloat { max(18, 24 * scale) }
    var historyEmptyIcon: CGFloat { max(40, 64 * scale) }
    var historyEmptyTitle: CGFloat { max(15, 20 * scale) }
    var historyEmptySubtitle: CGFloat { max(11, 14 * scale) }
    var historyCardDate: CGFloat { max(11, 13 * scale) }
    var historyCardAction: CGFloat { max(16, 22 * scale) }
    var historyCardTeamName: CGFloat { max(14, 20 * scale) }
    var historyCardScore: CGFloat { max(22, 32 * scale) }
    var historyCardGameScore: CGFloat { max(12, 16 * scale) }
    var historyStatIcon: CGFloat { max(14, 18 * scale) }
    var historyStatLabel: CGFloat { max(10, 11 * scale) }
    var historyStatValue: CGFloat { max(11, 14 * scale) }

    // Timer
    var timerIcon: CGFloat { max(14, 20 * scale) }
    var timerFont: CGFloat { max(11, 14 * scale) }

    // Name field
    var nameFieldFont: CGFloat { max(13, 18 * scale) }

    // Set score pill (bottom bar — legacy)
    var setScoreFont: CGFloat { 40 * scale }
    var setLabelFont: CGFloat { 16 * scale }
    var tiebreakFont: CGFloat { 18 * scale }

    // Compact set pill (top center between GAMES boxes)
    var compactSetLabelFont: CGFloat { max(8, 10 * scale) }
    var compactSetScoreFont: CGFloat { max(14, 20 * scale) }
    var compactTiebreakFont: CGFloat { max(9, 12 * scale) }

    // Shared paddings — unclamped
    var panelPadding: CGFloat { 16 * scale }
    var scorePaddingTop: CGFloat { 60 * scale }
    var serveAreaClearance: CGFloat { 90 * scale }
    var teamNameTopPadding: CGFloat { 125 * scale }
    var teamNameHorizontalPadding: CGFloat { 86 * scale }
}

extension LayoutMetrics {
    /// Convenience initializer that auto-detects the device idiom.
    init(screenWidth: CGFloat, screenHeight: CGFloat) {
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.isPhone = UIDevice.current.userInterfaceIdiom == .phone
    }
}

private struct LayoutMetricsKey: EnvironmentKey {
    /// Fallback only — the real value is injected by `PadelPulseApp`'s
    /// `GeometryReader` at runtime. This default fires in Xcode Previews and
    /// any edge case where a view is rendered outside the geometry-aware root.
    /// The reference size (iPad Pro 11" landscape, 1194×834) keeps
    /// `scale ≈ 1.0` so preview layouts mirror the hand-tuned baseline.
    /// Picking something device-adaptive here (e.g. UIScreen.main.bounds) is
    /// tempting but backfires in previews, which don't run on a real screen.
    static let defaultValue = LayoutMetrics(screenWidth: 1194, screenHeight: 834)
}

extension EnvironmentValues {
    var layout: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}
