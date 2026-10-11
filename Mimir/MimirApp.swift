import SwiftUI
import SwiftData

@main struct MimirApp: App {
    var body: some Scene {
        WindowGroup {
            Home()
        }
        .modelContainer(for: features.flatMap(\.models))
    }
}
