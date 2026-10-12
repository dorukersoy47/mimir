import SwiftUI
import SwiftData

@main struct MimirApp: App {
    init() { Theme.styleTitles() }

    var body: some Scene {
        WindowGroup {
            Tabs()
                .foregroundStyle(.ink, .inkSoft)
                .tint(.accent)
                .scrollContentBackground(.hidden)
        }
        .modelContainer(for: features.flatMap(\.models))
    }
}
