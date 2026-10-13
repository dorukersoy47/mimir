import SwiftUI
import SwiftData

struct Feature: Identifiable {
    let name: String
    let icon: String  // SF Symbol name
    var models: [any PersistentModel.Type] = []
    let view: AnyView
    var settings: AnyView?  // the feature's own section in Settings, if it has one

    var id: String { name }

    /// Whether the feature is turned on in Settings. Saved on the device; on by default.
    var isOn: AppStorage<Bool> { AppStorage(wrappedValue: true, "feature.\(id)") }
}

let features: [Feature] = [.habits, .converter, .reviews, .places]
