import SwiftUI

struct Home: View {
    var body: some View {
        NavigationStack {
            List(features) { FeatureLink(feature: $0) }
                .navigationTitle("Mimir")
                .toolbar {
                    NavigationLink { Settings() } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                }
        }
    }
}

private struct FeatureLink: View {
    let feature: Feature
    @AppStorage private var isOn: Bool

    init(feature: Feature) {
        self.feature = feature
        _isOn = feature.isOn
    }

    var body: some View {
        if isOn {
            NavigationLink { feature.view } label: {
                Label(feature.name, systemImage: feature.icon)
            }
        }
    }
}

#Preview {
    Home()
}
