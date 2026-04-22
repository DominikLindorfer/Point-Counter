import Foundation

/// Simple match storage using UserDefaults + Codable.
/// Mirrors the Android SharedPreferences + JSON approach.
final class MatchStorage {
    private let defaults = UserDefaults.standard

    func save(_ match: SavedMatch) -> SavedMatch {
        // Random Int64 instead of a monotonic counter in UserDefaults: the old
        // read-modify-write pattern on `next_id` would corrupt if two saves ever
        // interleaved. Collision odds at realistic match counts (<10k/user) are
        // below 10^-13, and SavedMatch.id stays Int64 so existing records decode
        // unchanged. See DefaultsKey.nextId — kept as a legacy key for older
        // installs but no longer written to.
        var withId = match
        withId.id = Int64.random(in: 1...Int64.max)

        var matches = loadAll()
        matches.insert(withId, at: 0) // newest first
        persist(matches)
        return withId
    }

    func loadAll() -> [SavedMatch] {
        guard let data = defaults.data(forKey: DefaultsKey.matchHistory) else { return [] }
        do {
            return try JSONDecoder().decode([SavedMatch].self, from: data)
        } catch {
            // Don't silently drop on decode failure — quarantine the bytes so they
            // can be inspected post-mortem, then clear the key so the app stays usable.
            Self.quarantine(data: data, label: "matches", error: error)
            defaults.removeObject(forKey: DefaultsKey.matchHistory)
            return []
        }
    }

    func delete(id: Int64) {
        var matches = loadAll()
        matches.removeAll { $0.id == id }
        persist(matches)
    }

    func deleteAll() {
        defaults.removeObject(forKey: DefaultsKey.matchHistory)
    }

    private func persist(_ matches: [SavedMatch]) {
        if let data = try? JSONEncoder().encode(matches) {
            defaults.set(data, forKey: DefaultsKey.matchHistory)
        }
    }

    /// Writes corrupt bytes to `Documents/<label>_corrupt_<ts>.json` so a user
    /// can recover via Files.app / iTunes file sharing (UIFileSharingEnabled is off
    /// today but the file is still accessible via sysdiagnose and future support flows).
    /// Failures here are logged but never thrown — quarantine is best-effort.
    static func quarantine(data: Data, label: String, error: Error) {
        let ts = Int(Date().timeIntervalSince1970)
        let filename = "\(label)_corrupt_\(ts).json"
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("MatchStorage: quarantine failed (no documents dir). \(label) decode error: \(error)")
            return
        }
        let url = docs.appendingPathComponent(filename)
        do {
            try data.write(to: url, options: .atomic)
            print("MatchStorage: quarantined corrupt \(label) to \(filename). Decode error: \(error)")
        } catch let writeError {
            print("MatchStorage: quarantine write failed for \(label): \(writeError). Original decode error: \(error)")
        }
    }
}
