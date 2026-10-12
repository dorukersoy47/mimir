import SwiftUI
import SwiftData

/// One kind's tier list, plus what's still to watch/read/play.
struct ReviewList: View {
    let kind: ReviewKind

    @AppStorage(ReviewTheme.key) private var theme = ReviewTheme.classic
    @Query private var reviews: [Review]
    @State private var showingToDo = false
    @State private var adding = false

    init(kind: ReviewKind) {
        self.kind = kind
        let id = kind.id
        _reviews = Query(filter: #Predicate { $0.kind == id },
                         sort: [SortDescriptor(\.finished, order: .reverse), SortDescriptor(\.added, order: .reverse)])
    }

    var body: some View {
        let toDo = reviews.filter { $0.level == nil }
        List {
            Section {
                Picker("Show", selection: $showingToDo) {
                    Text("Reviewed").tag(false)
                    Text("To \(kind.verb.capitalized)").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            if showingToDo {
                Section { ForEach(toDo) { ReviewRow(review: $0) } }
                    .listRowBackground(Color.card)
            } else {
                ForEach(theme.levels.indices, id: \.self) { level in
                    let rated = reviews.filter { $0.level == level }
                    if !rated.isEmpty {
                        Section(theme.levels[level]) { ForEach(rated) { ReviewRow(review: $0) } }
                    }
                }
                .listRowBackground(Color.card)
            }
        }
        .overlay {
            if showingToDo ? toDo.isEmpty : toDo.count == reviews.count {
                ContentUnavailableView(showingToDo ? "Nothing to \(kind.verb.capitalized)" : "No Reviews",
                                       systemImage: kind.icon, description: Text("Tap + to add one."))
            }
        }
        .navigationTitle(kind.name)
        .containerBackground(.page, for: .navigation)
        .toolbar { Button("Add", systemImage: "plus") { adding = true } }
        .sheet(isPresented: $adding) { ReviewAdd(kind: kind) }
    }
}

private struct ReviewRow: View {
    let review: Review
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationLink { ReviewDetail(review: review) } label: {
            HStack {
                ReviewCover(data: review.cover)
                    .frame(width: 40, height: 60)
                    .clipShape(.rect(cornerRadius: 4))
                VStack(alignment: .leading) {
                    Text(review.title)
                    Text(review.info)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .swipeActions {
            Button("Delete", systemImage: "trash", role: .destructive) { context.delete(review) }
        }
    }
}

struct ReviewCover: View {
    let data: Data?

    var body: some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Rectangle().fill(.quaternary)
        }
    }
}
