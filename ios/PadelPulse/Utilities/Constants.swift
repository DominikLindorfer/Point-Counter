import SwiftUI

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

/// Scale-based layout metrics. Reference: iPad Pro 11" landscape (1194pt width).
struct LayoutMetrics {
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    var scale: CGFloat { screenWidth / 1194.0 }

    // Score display
    var scoreFont: CGFloat { 400 * scale }
    var teamNameFont: CGFloat { 56 * scale }
    var servingBallSize: CGFloat { 28 * scale }

    // Games box
    var gamesBoxWidth: CGFloat { 140 * scale }
    var gamesBoxHeight: CGFloat { 170 * scale }
    var gamesBoxCorner: CGFloat { 18 * scale }
    var gamesLabelFont: CGFloat { 18 * scale }
    var gamesNumberFont: CGFloat { 110 * scale }

    // Toolbar
    var toolbarIconSize: CGFloat { 20 * scale }
    var toolbarLabelFont: CGFloat { 14 * scale }
    var toolbarPaddingH: CGFloat { 16 * scale }
    var toolbarPaddingV: CGFloat { 10 * scale }
    var toolbarSpacing: CGFloat { 8 * scale }

    // Camera overlay
    var cameraWidth: CGFloat { 192 * scale }
    var cameraHeight: CGFloat { 108 * scale }
    var cameraCorner: CGFloat { 16 * scale }
    var cameraIconSize: CGFloat { 16 * scale }
    var cameraButtonSize: CGFloat { 32 * scale }
    var cameraRecordDot: CGFloat { 8 * scale }
    var cameraRecordIcon: CGFloat { 16 * scale }

    // Serve indicator
    var serveArrowSize: CGFloat { 48 * scale }
    var serveBallSize: CGFloat { 44 * scale }
    var serveTextSize: CGFloat { 36 * scale }

    // Match over overlay
    var trophySize: CGFloat { 80 * scale }
    var matchOverTitleFont: CGFloat { 52 * scale }
    var matchOverSubtitleFont: CGFloat { 36 * scale }
    var matchOverButtonIcon: CGFloat { 24 * scale }
    var matchOverButtonFont: CGFloat { 20 * scale }

    // Settings sidebar
    var settingsWidth: CGFloat { min(420, screenWidth * 0.36) }
    var settingsHeaderIcon: CGFloat { 28 * scale }
    var settingsHeaderFont: CGFloat { 24 * scale }
    var settingsSectionFont: CGFloat { 18 * scale }
    var settingsRowIcon: CGFloat { 24 * scale }
    var settingsRowLabel: CGFloat { 16 * scale }
    var settingsRowValue: CGFloat { 14 * scale }

    // Match history
    var historyHeaderIcon: CGFloat { 28 * scale }
    var historyHeaderFont: CGFloat { 24 * scale }
    var historyEmptyIcon: CGFloat { 64 * scale }
    var historyEmptyTitle: CGFloat { 20 * scale }
    var historyEmptySubtitle: CGFloat { 14 * scale }
    var historyCardDate: CGFloat { 13 * scale }
    var historyCardAction: CGFloat { 22 * scale }
    var historyCardTeamName: CGFloat { 20 * scale }
    var historyCardScore: CGFloat { 32 * scale }
    var historyCardGameScore: CGFloat { 16 * scale }
    var historyStatIcon: CGFloat { 18 * scale }
    var historyStatLabel: CGFloat { 11 * scale }
    var historyStatValue: CGFloat { 14 * scale }

    // Timer
    var timerIcon: CGFloat { 20 * scale }
    var timerFont: CGFloat { 14 * scale }

    // Name field
    var nameFieldFont: CGFloat { 18 * scale }

    // Set score pill (bottom bar — legacy)
    var setScoreFont: CGFloat { 40 * scale }
    var setLabelFont: CGFloat { 16 * scale }
    var tiebreakFont: CGFloat { 18 * scale }

    // Compact set pill (top center between GAMES boxes)
    var compactSetLabelFont: CGFloat { 10 * scale }
    var compactSetScoreFont: CGFloat { 20 * scale }
    var compactTiebreakFont: CGFloat { 12 * scale }

    // Shared paddings
    var panelPadding: CGFloat { 16 * scale }
    var scorePaddingTop: CGFloat { 60 * scale }
    var serveAreaClearance: CGFloat { 90 * scale }
    var teamNameTopPadding: CGFloat { 125 * scale }
    var teamNameHorizontalPadding: CGFloat { 86 * scale }
}

private struct LayoutMetricsKey: EnvironmentKey {
    static let defaultValue = LayoutMetrics(screenWidth: 1194, screenHeight: 834)
}

extension EnvironmentValues {
    var layout: LayoutMetrics {
        get { self[LayoutMetricsKey.self] }
        set { self[LayoutMetricsKey.self] = newValue }
    }
}
