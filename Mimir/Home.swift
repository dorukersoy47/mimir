import SwiftUI

extension Feature {
    /// Mímir's own tab; the bar shows Mímir's face instead of the icon. It's not in `features`, so it can't be switched off.
    static let home = Feature(name: "Mímir", icon: "house", view: AnyView(Home()))
}

/// Mímir's face and a greeting. The AI chat will live here later.
struct Home: View {
    var body: some View {
        VStack(spacing: 18) {
            Image(.mimir)
                .resizable()
                .scaledToFit()
                .frame(width: 232)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(greeting)
                .font(.system(.title, design: .serif, weight: .semibold))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.page, for: .navigation)
        .toolbar {
            NavigationLink { Settings() } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }
}

#Preview {
    NavigationStack { Home() }
}
