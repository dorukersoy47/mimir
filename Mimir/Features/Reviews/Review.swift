import Foundation
import SwiftData

@Model final class Review {
    var title = ""
    var kind = ""                      // ReviewKind id
    var info = ""                      // e.g. "2010 film by Christopher Nolan"
    @Attribute(.externalStorage) var cover: Data?
    var level: Int?                    // 0 = best; nil = still to watch/read/play
    var text = ""
    var finished: Date?
    var added = Date.now

    init(title: String, kind: ReviewKind, info: String = "") {
        self.title = title
        self.kind = kind.id
        self.info = info
    }
}

struct ReviewKind: Identifiable, Hashable {
    let id: String
    let name: String
    let single: String
    let icon: String
    let verb: String
    let hint: String  // added to Wikipedia searches so the right kind comes first

    static let all = [
        ReviewKind(id: "film", name: "Films", single: "Film", icon: "film", verb: "watch", hint: "film"),
        ReviewKind(id: "tv", name: "TV Shows", single: "TV Show", icon: "tv", verb: "watch", hint: "TV series"),
        ReviewKind(id: "book", name: "Books", single: "Book", icon: "book", verb: "read", hint: "book"),
        ReviewKind(id: "game", name: "Games", single: "Game", icon: "gamecontroller", verb: "play", hint: "video game"),
    ]

    static func named(_ id: String) -> ReviewKind { all.first { $0.id == id } ?? all[0] }
}

/// Names for the four rating levels, best first. Add a theme by adding a case.
enum ReviewTheme: String, CaseIterable {
    case classic, minecraft

    static let key = "reviews.theme"

    var levels: [String] {
        switch self {
        case .classic: ["Masterpiece", "Great", "Mid", "Bad"]
        case .minecraft: ["Netherite", "Diamond", "Iron", "Dirt"]
        }
    }
}

extension Review {
    /// Every title by kind and rating, plus what's still to watch/read/play, for Mímir.
    static func summary(_ context: ModelContext) -> String {
        let reviews = (try? context.fetch(FetchDescriptor<Review>(sortBy: [SortDescriptor(\.title)]))) ?? []
        let theme = ReviewTheme(rawValue: UserDefaults.standard.string(forKey: ReviewTheme.key) ?? "") ?? .classic
        let lines = ReviewKind.all.flatMap { kind in
            let mine = reviews.filter { $0.kind == kind.id }
            let groups = theme.levels.indices.map { level in (theme.levels[level], mine.filter { $0.level == level }) }
                + [("To \(kind.verb)", mine.filter { $0.level == nil })]
            return groups.filter { !$0.1.isEmpty }.map { "\(kind.name), \($0.0): \($0.1.map(\.title).joined(separator: ", "))" }
        }
        if lines.isEmpty { return "No reviews yet." }
        return "Rating levels, best first: \(theme.levels.joined(separator: ", ")).\n" + lines.joined(separator: "\n")
    }
}
