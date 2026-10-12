import SwiftUI

struct Settings: View {
    var body: some View {
        List {
            Section {
                ForEach(features) { FeatureToggle(feature: $0) }
            } header: {
                Text("Features")
            } footer: {
                Text("Turned-off features are hidden. Their data is kept.")
            }
            ForEach(features) { $0.settings }
        }
        .navigationTitle("Settings")
    }
}

private struct FeatureToggle: View {
    let feature: Feature
    @AppStorage private var isOn: Bool

    init(feature: Feature) {
        self.feature = feature
        _isOn = feature.isOn
    }

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(feature.name, systemImage: feature.icon)
        }
    }
}

#Preview {
    NavigationStack { Settings() }
}
