import SwiftUI
import SwiftData

extension Feature {
    static let reviews = Feature(name: "Reviews", icon: "star.bubble", models: [Review.self],
                                 view: AnyView(ReviewKinds()), settings: AnyView(ReviewSettings()))
}

struct ReviewKinds: View {
    @Query private var reviews: [Review]

    var body: some View {
        List(ReviewKind.all) { kind in
            let mine = reviews.filter { $0.kind == kind.id }
            let rated = mine.filter { $0.level != nil }.count
            let counts = [rated > 0 ? "\(rated) reviewed" : nil, mine.count > rated ? "\(mine.count - rated) to \(kind.verb)" : nil]
            NavigationLink { ReviewList(kind: kind) } label: {
                LabeledContent {
                    Text(counts.compactMap { $0 }.joined(separator: " · "))
                } label: {
                    Label(kind.name, systemImage: kind.icon)
                }
            }
        }
        .navigationTitle("Reviews")
    }
}

private struct ReviewSettings: View {
    @AppStorage(ReviewTheme.key) private var theme = ReviewTheme.classic

    var body: some View {
        Section("Review Ratings") {
            Picker("Theme", selection: $theme) {
                ForEach(ReviewTheme.allCases, id: \.self) { theme in
                    VStack(alignment: .leading) {
                        Text(theme.rawValue.capitalized)
                        Text(theme.levels.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
    }
}

#Preview {
    NavigationStack { ReviewKinds() }
        .modelContainer(for: Review.self, inMemory: true)
}
