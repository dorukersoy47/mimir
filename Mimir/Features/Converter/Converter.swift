import SwiftUI
import SwiftData

extension Feature {
    static let converter = Feature(name: "Converter", icon: "arrow.left.arrow.right",
                                   models: [ConverterFavorite.self], view: AnyView(ConverterList()))
}

@Model final class ConverterFavorite {
    var category = ""
    var from = ""  // unit ids
    var to = ""
    var created = Date.now

    init(category: String, from: String, to: String) {
        self.category = category
        self.from = from
        self.to = to
    }
}

struct ConverterList: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ConverterFavorite.created) private var favorites: [ConverterFavorite]
    @State private var search = ""
    @State private var opened: ConverterCategory?

    var body: some View {
        let groups = ConverterCategory.groups
            .map { (name: $0.name, categories: $0.categories.filter { $0.matches(search) }) }
            .filter { !$0.categories.isEmpty }

        List {
            if search.isEmpty && !favorites.isEmpty {
                Section("Favorites") {
                    ForEach(favorites) { favorite in
                        if let category = ConverterCategory.named(favorite.category) {
                            let names = [favorite.from, favorite.to].map { category.unit($0)?.name ?? $0 }
                            Button {
                                ConverterScreen.remember(favorite)
                                opened = category
                            } label: {
                                Label {
                                    Text(names.joined(separator: " → ")).foregroundStyle(.ink)
                                } icon: {
                                    Image(systemName: category.icon)
                                }
                            }
                        }
                    }
                    .onDelete { $0.forEach { context.delete(favorites[$0]) } }
                }
                .listRowBackground(Color.card)
            }
            ForEach(groups, id: \.name) { group in
                Section(group.name) {
                    ForEach(group.categories) { category in
                        NavigationLink { ConverterScreen(category: category) } label: {
                            Label(category.name, systemImage: category.icon)
                        }
                    }
                }
            }
            .listRowBackground(Color.card)
        }
        .labelStyle(.tile)
        .overlay {
            if groups.isEmpty { ContentUnavailableView.search(text: search) }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Units, currencies, cities")
        .navigationTitle("Converter")
        .containerBackground(.page, for: .navigation)
        .navigationDestination(item: $opened) { ConverterScreen(category: $0) }
    }
}

#Preview {
    NavigationStack { ConverterList() }
        .modelContainer(for: ConverterFavorite.self, inMemory: true)
}
