import Foundation

/// Simple match storage using UserDefaults + Codable.
/// Mirrors the Android SharedPreferences + JSON approach.
final class MatchStorage {
    private let defaults = UserDefaults.standard

    func save(_ match: SavedMatch) -> SavedMatch {
        var nextId = Int64(defaults.integer(forKey: DefaultsKey.nextId))
        if nextId == 0 { nextId = 1 }

        var withId = match
        withId.id = nextId
        nextId += 1
        defaults.set(Int(nextId), forKey: DefaultsKey.nextId)

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
