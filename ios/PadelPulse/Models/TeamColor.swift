import SwiftUI

/// Preset color options for team customization.
struct TeamColor {
    let name: String
    let bg: Color
    let accent: Color
}

let teamColorPresets: [TeamColor] = [
    TeamColor(name: "Blue",   bg: Color(red: 0x15 / 255.0, green: 0x65 / 255.0, blue: 0xC0 / 255.0), accent: .white),
    TeamColor(name: "Red",    bg: Color(red: 0xC6 / 255.0, green: 0x28 / 255.0, blue: 0x28 / 255.0), accent: .white),
    TeamColor(name: "Green",  bg: Color(red: 0x2E / 255.0, green: 0x7D / 255.0, blue: 0x32 / 255.0), accent: .white),
    TeamColor(name: "Purple", bg: Color(red: 0x6A / 255.0, green: 0x1B / 255.0, blue: 0x9A / 255.0), accent: .white),
    TeamColor(name: "Orange", bg: Color(red: 0xE6 / 255.0, green: 0x51 / 255.0, blue: 0x00 / 255.0), accent: .white),
    TeamColor(name: "Cyan",   bg: Color(red: 0x00 / 255.0, green: 0x83 / 255.0, blue: 0x8F / 255.0), accent: .white),
    TeamColor(name: "Pink",   bg: Color(red: 0xAD / 255.0, green: 0x14 / 255.0, blue: 0x57 / 255.0), accent: .white),
    TeamColor(name: "Yellow", bg: Color(red: 0xC8 / 255.0, green: 0x86 / 255.0, blue: 0x00 / 255.0), accent: .white),
]
