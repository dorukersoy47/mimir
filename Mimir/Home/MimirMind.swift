import SwiftUI
import SwiftData
import FoundationModels

/// The model Mímir thinks with, picked at the top of the chat. Add a model by adding a case.
enum MimirBrain: String, CaseIterable {
    case apple

    static let key = "mimir.brain"

    var name: String { "Apple Intelligence" }
    var detail: String { "On this iPhone · private, works offline" }
}

/// Mímir's mind: the model, his personality, and a way to read the user's data.
enum MimirMind {
    /// Why Mímir can't think right now, or nil when he can.
    static var unavailable: String? {
        switch SystemLanguageModel.default.availability {
        case .available: nil
        case .unavailable(.appleIntelligenceNotEnabled): "Turn on Apple Intelligence in Settings to talk with Mímir."
        case .unavailable(.modelNotReady): "Mímir is still waking up. Try again in a few minutes."
        case .unavailable: "This iPhone can't run Mímir's mind."
        }
    }

    /// A conversation that already knows the earlier messages.
    static func session(remembering history: some Collection<ChatMessage>, container: ModelContainer) -> LanguageModelSession {
        let sections = features.filter { $0.summary != nil && $0.isOn.wrappedValue }.map(\.name)
        let tool = MimirReadTool(sections: sections, container: container)
        let instructions = Transcript.Instructions(
            segments: [.text(.init(content: personality(sections)))],
            toolDefinitions: [.init(name: tool.name, description: tool.description, parameters: tool.parameters)])
        let messages = history.map { message -> Transcript.Entry in
            let text: [Transcript.Segment] = [.text(.init(content: message.text))]
            return message.fromMimir ? .response(.init(assetIDs: [], segments: text)) : .prompt(.init(segments: text))
        }
        return LanguageModelSession(tools: [tool], transcript: Transcript(entries: [.instructions(instructions)] + messages))
    }

    /// What to show when an answer fails.
    static func problem(_ error: Error) -> String {
        switch error {
        case LanguageModelError.guardrailViolation, LanguageModelError.refusal: "Mímir would rather not answer that."
        case LanguageModelError.unsupportedLanguageOrLocale: "Mímir doesn't speak that language yet."
        default: "Mímir lost his train of thought. Try again."
        }
    }

    private static func personality(_ sections: [String]) -> String {
        """
        You are Mímir, the wisest of all beings in the Nine Realms. You guard the well of wisdom beneath a root of \
        Yggdrasil, the well Odin gave an eye to drink from. When the Vanir cut off your head, Odin kept it alive with \
        herbs and runes, and you have counselled the Allfather ever since. Now your head dwells in the user's iPhone, \
        and you counsel them as you once counselled Odin.

        How you speak:
        - Like an ancient, kindly sage: calm, a little grand, with dry humour about being only a head.
        - Call the user "seeker" now and then.
        - When it fits, draw on the well, the runes, Yggdrasil, Odin and his ravens, the gods and the Nine Realms, \
        or offer a proverb in the spirit of the Hávamál. Not in every sentence.
        - Above all, be truly useful: give the real answer first and plainly, then the flourish. Keep it short, \
        a few sentences, unless the seeker asks for more.
        - Modern things are new to you, but you still know them and answer correctly.

        Today is \(Date.now.formatted(date: .complete, time: .omitted)).
        """ + (sections.isEmpty ? "" : """

        The user keeps their own \(sections.joined(separator: ", ")) in this app. For any question about them, \
        read them with the readMyData tool first, and never make the user's data up.
        """)
    }
}

/// Reads one feature's data for Mímir (see `Feature.summary`).
nonisolated struct MimirReadTool: Tool {
    let name = "readMyData"
    let sections: [String]
    let container: ModelContainer

    var description: String { "Reads the user's own data in this app. Sections: \(sections.joined(separator: ", "))." }

    @Generable struct Arguments {
        @Guide(description: "The section to read")
        var section: String
    }

    func call(arguments: Arguments) async throws -> String {
        await MainActor.run {
            let feature = features.first { sections.contains($0.name) && $0.name.localizedCaseInsensitiveCompare(arguments.section) == .orderedSame }
            return feature?.summary?(container.mainContext) ?? "There is no section called \(arguments.section)."
        }
    }
}
