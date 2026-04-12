import Foundation

/// Simple match storage using UserDefaults + Codable.
/// Mirrors the Android SharedPreferences + JSON approach.
final class MatchStorage {
    private let defaults = UserDefaults.standard
    private let matchesKey = "match_history"
    private let nextIdKey = "next_id"

    func save(_ match: SavedMatch) -> SavedMatch {
        var nextId = Int64(defaults.integer(forKey: nextIdKey))
        if nextId == 0 { nextId = 1 }

        var withId = match
        withId.id = nextId
        nextId += 1
        defaults.set(Int(nextId), forKey: nextIdKey)

        var matches = loadAll()
        matches.insert(withId, at: 0) // newest first
        persist(matches)
        return withId
    }

    func loadAll() -> [SavedMatch] {
        guard let data = defaults.data(forKey: matchesKey) else { return [] }
        return (try? JSONDecoder().decode([SavedMatch].self, from: data)) ?? []
    }

    func delete(id: Int64) {
        var matches = loadAll()
        matches.removeAll { $0.id == id }
        persist(matches)
    }

    func deleteAll() {
        defaults.removeObject(forKey: matchesKey)
    }

    private func persist(_ matches: [SavedMatch]) {
        if let data = try? JSONEncoder().encode(matches) {
            defaults.set(data, forKey: matchesKey)
        }
    }
}
