import SwiftUI

/// Every section is a tab, switched with the floating bar at the bottom.
struct Tabs: View {
    @AppStorage(Theme.key) private var theme = Theme.darkGreen
    @State private var selected = Feature.home.id
    @State private var typing = false

    /// Mímir sits in the middle of the bar.
    private var tabs: [Feature] {
        var tabs = features
        tabs.insert(.home, at: (tabs.count + 1) / 2)
        return tabs
    }

    var body: some View {
        TabView(selection: $selected) {
            ForEach(tabs) { feature in
                Tab(feature.name, systemImage: feature.icon, value: feature.id) {
                    NavigationStack { feature.view }
                        .toolbar(.hidden, for: .tabBar)
                        .contentMargins(.bottom, 72, for: .scrollContent)  // room to scroll past the bar (safe area insets don't reach NavigationStack screens)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if !typing { bar }  // hidden while the keyboard is up, which would push it over text boxes
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in typing = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in typing = false }
        .preferredColorScheme(theme.scheme)  // here, not in MimirApp: there it stops switching back
    }

    private var bar: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { TabButton(feature: $0, selected: $selected) }
        }
        .padding(5)
        .background(.card, in: .capsule)
        .shadow(color: .black.opacity(0.25), radius: 14, y: 8)
        .environment(\.colorScheme, .dark)  // the bar is dark green in both themes
    }
}

/// One button in the bar. A feature's button hides while the feature is off.
private struct TabButton: View {
    let feature: Feature
    @Binding var selected: String
    @AppStorage private var isOn: Bool

    init(feature: Feature, selected: Binding<String>) {
        self.feature = feature
        _selected = selected
        _isOn = feature.isOn
    }

    var body: some View {
        let isSelected = selected == feature.id
        if isOn {
            Button { selected = feature.id } label: {
                Group {
                    if feature.id == Feature.home.id {
                        Image(.mimir).resizable().frame(width: 34, height: 34)
                    } else {
                        Image(systemName: feature.icon).font(.title2)
                    }
                }
                .foregroundStyle(isSelected ? Color.page : Color.inkSoft)
                .frame(width: 64, height: 50)
                .background(isSelected ? Color.accent : .clear, in: .capsule)
            }
            .accessibilityLabel(feature.name)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}

#Preview {
    Tabs()
}
