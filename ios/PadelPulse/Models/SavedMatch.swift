import Foundation

/// A saved match record.
struct SavedMatch: Codable, Identifiable {
    /// Schema version for this record. Optional so legacy saves written before
    /// this field existed decode as v1. Bump + add a migration in MatchStorage
    /// when changing the shape of persisted fields.
    var schemaVersion: Int? = 1
    var id: Int64
    let timestamp: Int64          // milliseconds since epoch
    let team1Name: String
    let team2Name: String
    let team1Sets: Int
    let team2Sets: Int
    let team1Games: [Int]
    let team2Games: [Int]
    let winner: Int               // 1 = team1, 2 = team2
    let durationMs: Int64
    let goldenPoint: Bool
    let team1PointsWon: Int
    let team2PointsWon: Int

    /// Shared DateFormatter — DateFormatter is thread-safe for read access on iOS 7+,
    /// and rebuilding one per `formattedDate` access was measurable while scrolling
    /// the match history.
    private static let displayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM dd, yyyy  HH:mm"
        return df
    }()

    /// Formatted date string for display.
    var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(timestamp) / 1000.0)
        return Self.displayFormatter.string(from: date)
    }

    /// Duration as formatted string (M:SS).
    var formattedDuration: String {
        let min = durationMs / 60000
        let sec = (durationMs % 60000) / 1000
        return String(format: "%d:%02d", min, sec)
    }

    /// Winner's team name.
    var winnerName: String {
        winner == 1 ? team1Name : team2Name
    }

    /// Build a shareable text summary.
    func shareText() -> String {
        let dateStr = formattedDate
        let durationMin = durationMs / 60000
        let durationSec = (durationMs % 60000) / 1000

        let gameScores = team1Games.enumerated().map { (i, g1) in
            let g2 = i < team2Games.count ? team2Games[i] : 0
            return "  Set \(i + 1): \(g1)-\(g2)"
        }.joined(separator: "\n")

        let totalPoints = team1PointsWon + team2PointsWon
        let pointsLine: String
        if totalPoints > 0 {
            let pointsLabel = String(localized: "Points Won")
            pointsLine = "\n\(pointsLabel): \(team1Name) \(team1PointsWon) - \(team2PointsWon) \(team2Name)"
        } else {
            pointsLine = ""
        }

        let title = String(localized: "Padel Match Result")
        let gamesLabel = String(localized: "Game scores:")
        let winnerLabel = String(localized: "Winner")
        let durationLabel = String(localized: "Duration")

        var text = """
        \(title)
        \(dateStr)

        \(team1Name)  \(team1Sets) - \(team2Sets)  \(team2Name)

        \(gamesLabel)
        \(gameScores)

        \(winnerLabel): \(winnerName)
        \(durationLabel): \(durationMin)m \(durationSec)s\(pointsLine)
        """

        if goldenPoint {
            text += "\n\(String(localized: "Scoring: Golden Point"))"
        }

        return text
    }
}
