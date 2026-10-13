import SwiftUI

/// The world, each country filled by how much of it you've seen. Tapping a country opens it.
struct PlaceMap: View {
    let visited: Set<String>
    let open: (PlaceCountry) -> Void

    private static let size = CGSize(width: 2000, height: 986)  // Places.json's map: Miller projection, Antarctica cut off

    var body: some View {
        GeometryReader { geometry in
            let scale = geometry.size.width / Self.size.width
            Canvas { context, _ in
                context.scaleBy(x: scale, y: scale)
                for country in PlaceCountry.all {
                    let seen = country.visited(visited)
                    let color = seen == 0 ? Color.card : seen < country.provinces.count ? .accent.opacity(0.5) : .accent
                    context.fill(country.path, with: .color(color), style: FillStyle(eoFill: true))
                    context.stroke(country.path, with: .color(.page), lineWidth: 1.5)
                }
            }
            .onTapGesture { point in
                let point = CGPoint(x: point.x / scale, y: point.y / scale)
                if let country = PlaceCountry.all.first(where: { $0.path.contains(point, eoFill: true) }) { open(country) }
            }
        }
        .aspectRatio(Self.size, contentMode: .fit)
        .accessibilityHidden(true)  // the list below has the same
    }
}
