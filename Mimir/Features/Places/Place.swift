import SwiftUI
import SwiftData

/// A province the user has been to.
@Model final class PlaceVisit {
    var province = ""  // PlaceProvince id, e.g. "TR.34"
    var added = Date.now

    init(province: String) { self.province = province }
}

/// A country and its provinces, from Places.json. A country is complete once every province is visited.
struct PlaceCountry: Decodable, Identifiable, Hashable {
    let id: String  // ISO code, e.g. "TR"
    let provinces: [PlaceProvince]
    let shape: [[Int]]  // outlines, each a flat list of x, y on the map (see PlaceMap)

    static let all = try! JSONDecoder()
        .decode([PlaceCountry].self, from: Data(contentsOf: Bundle.main.url(forResource: "Places", withExtension: "json")!))
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

    static let continents = Dictionary(grouping: all, by: \.continent).sorted { $0.key < $1.key }

    var name: String { Locale.current.localizedString(forRegionCode: id) ?? id }

    var continent: String {
        Locale.Region(id).continent.flatMap { Locale.current.localizedString(forRegionCode: $0.identifier) } ?? "Other"
    }

    var flag: String {
        String(String.UnicodeScalarView(id.unicodeScalars.compactMap { UnicodeScalar(127397 + $0.value) }))
    }

    var path: Path {
        Path { path in
            for ring in shape {
                path.addLines(stride(from: 0, to: ring.count, by: 2).map { CGPoint(x: ring[$0], y: ring[$0 + 1]) })
                path.closeSubpath()
            }
        }
    }

    func visited(_ visits: Set<String>) -> Int { provinces.count { visits.contains($0.id) } }

    func matches(_ search: String) -> Bool {
        search.isEmpty || name.localizedStandardContains(search) || provinces.contains { $0.name.localizedStandardContains(search) }
    }
}

struct PlaceProvince: Decodable, Identifiable, Hashable {
    let id: String  // GeoNames code; a country without provinces is its own one
    let name: String
}

extension PlaceVisit {
    /// Each started country's visited and missing provinces, for Mímir.
    static func summary(_ context: ModelContext) -> String {
        let visited = Set(((try? context.fetch(FetchDescriptor<PlaceVisit>())) ?? []).map(\.province))
        let lines = PlaceCountry.all.compactMap { country -> String? in
            let seen = country.provinces.filter { visited.contains($0.id) }.map(\.name)
            let missing = country.provinces.filter { !visited.contains($0.id) }.map(\.name)
            if seen.isEmpty { return nil }
            if missing.isEmpty { return "\(country.name): complete, all \(seen.count) provinces" }
            return "\(country.name): \(seen.count) of \(country.provinces.count) provinces. "
                + "Visited: \(seen.joined(separator: ", ")). Not yet: \(missing.joined(separator: ", "))"
        }
        if lines.isEmpty { return "No places visited yet." }
        return "Countries the user has been to (any other country: not visited):\n" + lines.joined(separator: "\n")
    }
}
