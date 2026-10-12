import SwiftUI
import SwiftData

/// Search Wikipedia, pick a match (or type it yourself), then rate it or save it for later.
struct ReviewAdd: View {
    let kind: ReviewKind

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var pages: [ReviewSearch.Page] = []
    @State private var picked: Review?
    @FocusState private var searching: Bool

    var body: some View {
        NavigationStack {
            List {
                ForEach(pages) { page in
                    Button { pick(page) } label: {
                        HStack {
                            AsyncImage(url: page.thumbnail?.source) { $0.resizable().scaledToFill() } placeholder: {
                                Rectangle().fill(.quaternary)
                            }
                            .frame(width: 40, height: 60)
                            .clipShape(.rect(cornerRadius: 4))
                            VStack(alignment: .leading) {
                                Text(page.title)
                                Text(page.description ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .tint(.ink)
                }
                .listRowBackground(Color.card)
                if !search.isEmpty {
                    Button("Add “\(search)” yourself") { picked = Review(title: search, kind: kind) }
                        .listRowBackground(Color.card)
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Wikipedia")
            .searchFocused($searching)
            .onAppear { searching = true }
            .task(id: search) {
                try? await Task.sleep(for: .milliseconds(300))
                if !Task.isCancelled { pages = await ReviewSearch.pages(search, kind: kind) }
            }
            .navigationTitle("Add \(kind.single)")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .presentationBackground(.page)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .navigationDestination(item: $picked) { review in
                ReviewDetail(review: review)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                context.insert(review)
                                dismiss()
                            }
                            .disabled(review.title.isEmpty)
                        }
                    }
            }
        }
    }

    private func pick(_ page: ReviewSearch.Page) {
        let review = Review(title: page.title.replacing(/\s\(.*\)$/, with: ""), kind: kind, info: page.description ?? "")
        picked = review
        if let url = page.thumbnail?.source {
            Task { review.cover = try? await URLSession.shared.data(from: url).0 }
        }
    }
}

/// Wikipedia search. Only the search words are sent.
enum ReviewSearch {
    struct Page: Decodable, Identifiable {
        struct Thumbnail: Decodable { let source: URL }

        let pageid: Int
        let index: Int
        let title: String
        var description: String?
        var thumbnail: Thumbnail?

        var id: Int { pageid }
    }

    private struct Response: Decodable {
        struct Query: Decodable { let pages: [Page] }
        var query: Query?
    }

    static func pages(_ search: String, kind: ReviewKind) async -> [Page] {
        guard !search.isEmpty else { return [] }
        var url = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        url.queryItems = [
            "action": "query", "format": "json", "formatversion": "2", "generator": "search",
            "gsrsearch": "\(search) \(kind.hint)", "gsrlimit": "10",
            "prop": "pageimages|description", "piprop": "thumbnail", "pithumbsize": "400", "pilicense": "any",
        ].map(URLQueryItem.init)
        var request = URLRequest(url: url.url!)
        request.setValue("Mimir/1.0 (https://github.com/dorukersoy47/mimir)", forHTTPHeaderField: "User-Agent")
        guard let data = try? await URLSession.shared.data(for: request).0,
              let response = try? JSONDecoder().decode(Response.self, from: data) else { return [] }
        return (response.query?.pages ?? []).sorted { $0.index < $1.index }
    }
}
