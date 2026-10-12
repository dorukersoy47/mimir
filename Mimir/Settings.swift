import SwiftUI

struct Settings: View {
    @AppStorage(Theme.key) private var theme = Theme.darkGreen

    var body: some View {
        List {
            Section("Appearance") {
                Picker("Appearance", selection: $theme) {
                    ForEach(Theme.allCases, id: \.self) { Text($0.name) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            .listRowBackground(Color.card)
            Section {
                ForEach(features) { FeatureToggle(feature: $0) }
            } header: {
                Text("Features")
            } footer: {
                Text("Turned-off features are hidden. Their data is kept.")
            }
            .listRowBackground(Color.card)
            ForEach(features) { $0.settings }
                .listRowBackground(Color.card)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .containerBackground(.page, for: .navigation)
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
                .labelStyle(.tile)
        }
    }
}

#Preview {
    NavigationStack { Settings() }
}
