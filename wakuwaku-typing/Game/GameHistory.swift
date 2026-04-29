import Foundation

struct HistoryEntry: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var date: Date
    var wpm: Int
    var acc: Int
    var combo: Int
    var words: Int
    var time: Int
    var course: String
    var score: Int
}

struct GameResult: Equatable {
    var wpm: Int
    var acc: Int
    var combo: Int
    var words: Int
    var time: Int
    var course: String
}
