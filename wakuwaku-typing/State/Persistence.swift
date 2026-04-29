import Foundation

enum Persistence {
    private static let key = "kanaTyper.v1"

    struct Storage: Codable {
        var settings: AppSettings
        var history: [HistoryEntry]
    }

    static func load() -> Storage? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Storage.self, from: data)
    }

    static func save(_ storage: Storage) {
        guard let data = try? JSONEncoder().encode(storage) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
