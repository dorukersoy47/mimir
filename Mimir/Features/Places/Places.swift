import SwiftUI
import SwiftData

extension Feature {
    static let places = Feature(name: "Places", icon: "globe.europe.africa", models: [PlaceVisit.self], view: AnyView(PlaceList()),
                                summary: PlaceVisit.summary)
}

struct PlaceList: View {
    @Query private var visits: [PlaceVisit]
    @State private var search = ""
    @State private var opened: PlaceCountry?

    var body: some View {
        let visited = Set(visits.map(\.province))
        let groups = PlaceCountry.continents
            .map { (name: $0.key, countries: $0.value.filter { $0.matches(search) }) }
            .filter { !$0.countries.isEmpty }

        List {
            if search.isEmpty {
                Section {
                    PlaceMap(visited: visited) { opened = $0 }
                } footer: {
                    Text(summary(visited))
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }
            ForEach(groups, id: \.name) { group in
                Section {
                    ForEach(group.countries) { country in
                        NavigationLink { PlaceProvinces(country: country) } label: {
                            LabeledContent("\(country.flag)  \(country.name)") { PlaceProgress(country: country, visited: visited) }
                        }
                    }
                } header: {
                    HStack {
                        Text(group.name)
                        Spacer()
                        Text("\(group.countries.count { $0.visited(visited) > 0 })/\(group.countries.count)")
                    }
                }
            }
            .listRowBackground(Color.card)
            if !groups.isEmpty {
                Section {} footer: { Text("Provinces from GeoNames (CC BY 4.0). Map from Natural Earth.") }
            }
        }
        .overlay {
            if groups.isEmpty { ContentUnavailableView.search(text: search) }
        }
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Countries, provinces")
        .navigationTitle("Places")
        .containerBackground(.page, for: .navigation)
        .navigationDestination(item: $opened) { PlaceProvinces(country: $0) }
    }

    private func summary(_ visited: Set<String>) -> String {
        let seen = PlaceCountry.all.map { (visited: $0.visited(visited), all: $0.provinces.count) }.filter { $0.visited > 0 }
        if seen.isEmpty { return "Open a country and tick the provinces you've been to." }
        return "\(seen.count) countries · \(seen.count { $0.visited == $0.all }) complete · \(visited.count) provinces"
    }
}

/// "3/81" once started, a tick once complete.
private struct PlaceProgress: View {
    let country: PlaceCountry
    let visited: Set<String>

    var body: some View {
        let seen = country.visited(visited)
        if seen == country.provinces.count {
            Image(systemName: "checkmark.seal.fill").foregroundStyle(.accent)
        } else if seen > 0 {
            Text("\(seen)/\(country.provinces.count)")
        }
    }
}

/// One country's provinces; tap one to tick it.
private struct PlaceProvinces: View {
    let country: PlaceCountry

    @Environment(\.modelContext) private var context
    @Query private var visits: [PlaceVisit]
    @State private var search = ""

    var body: some View {
        let visited = Set(visits.map(\.province))
        List {
            Section {
                ForEach(country.provinces.filter { search.isEmpty || $0.name.localizedStandardContains(search) }) { province in
                    Button { toggle(province) } label: {
                        Label {
                            Text(province.name).foregroundStyle(.ink)
                        } icon: {
                            Image(systemName: visited.contains(province.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            } header: {
                Text("Visited \(country.visited(visited)) of \(country.provinces.count)")
            }
            .listRowBackground(Color.card)
        }
        .searchable(text: $search, prompt: "Provinces")
        .navigationTitle(country.name)
        .containerBackground(.page, for: .navigation)
    }

    private func toggle(_ province: PlaceProvince) {
        if let visit = visits.first(where: { $0.province == province.id }) {
            context.delete(visit)
        } else {
            context.insert(PlaceVisit(province: province.id))
        }
    }
}

#Preview {
    NavigationStack { PlaceList() }
        .modelContainer(for: PlaceVisit.self, inMemory: true)
}
