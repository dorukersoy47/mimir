import SwiftUI
import SwiftData

extension Feature {
    static let reviews = Feature(name: "Reviews", icon: "star.bubble", models: [Review.self],
                                 view: AnyView(ReviewKinds()), settings: AnyView(ReviewSettings()), summary: Review.summary)
}

struct ReviewKinds: View {
    @Query private var reviews: [Review]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(spacing: 12), GridItem()], spacing: 12) {
                ForEach(ReviewKind.all) { kind in
                    let mine = reviews.filter { $0.kind == kind.id }
                    let rated = mine.filter { $0.level != nil }.count
                    let counts = [rated > 0 ? "\(rated) reviewed" : nil, mine.count > rated ? "\(mine.count - rated) to \(kind.verb)" : nil]
                    NavigationLink { ReviewList(kind: kind) } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Image(systemName: kind.icon)
                                .font(.title2)
                                .foregroundStyle(.beige)
                                .frame(width: 44, height: 44)
                                .background(.tile, in: .rect(cornerRadius: 12))
                            Spacer()
                            Text(kind.name)
                                .font(.system(.title2, design: .serif, weight: .semibold))
                            Text(counts.compactMap { $0 }.joined(separator: "\n"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 144)
                        .padding()
                        .background(.card, in: .rect(cornerRadius: 24))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Reviews")
        .containerBackground(.page, for: .navigation)
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
