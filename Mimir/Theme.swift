import SwiftUI

/// The app's two looks, picked in Settings. Each color in Assets has a light value (Beige) and a dark one (Dark Green).
enum Theme: String, CaseIterable {
    case darkGreen, beige

    static let key = "theme"

    var name: String { self == .beige ? "Beige" : "Dark Green" }
    var scheme: ColorScheme { self == .beige ? .light : .dark }

    /// Bold serif navigation titles in the theme's ink.
    static func styleTitles() {
        let bar = UINavigationBar.appearance()
        bar.largeTitleTextAttributes = [.font: serif(.largeTitle), .foregroundColor: UIColor(resource: .ink)]
        bar.titleTextAttributes = [.font: serif(.headline), .foregroundColor: UIColor(resource: .ink)]
    }

    private static func serif(_ style: UIFont.TextStyle) -> UIFont {
        let font = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style).withDesign(.serif)!
        return UIFont(descriptor: font.withSymbolicTraits(.traitBold)!, size: 0)
    }
}

/// A label whose icon sits in a small green tile.
struct TileLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
        } icon: {
            configuration.icon
                .foregroundStyle(.beige)
                .frame(width: 32, height: 32)
                .background(.tile, in: .rect(cornerRadius: 9))
        }
    }
}

extension LabelStyle where Self == TileLabelStyle {
    static var tile: Self { .init() }
}
