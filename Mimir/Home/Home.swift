import SwiftUI
import SwiftData
import FoundationModels

extension Feature {
    /// Mímir's own tab; the bar shows Mímir's face instead of the icon. It's not in `features`, so it can't be switched off.
    static let home = Feature(name: "Mímir", icon: "house", models: [Chat.self], view: AnyView(Home()))
}

/// Mímir's face and a greeting; once you ask something, the chat.
struct Home: View {
    @Environment(\.modelContext) private var context
    @AppStorage(MimirBrain.key) private var brain = MimirBrain.apple
    @State private var chat: Chat?  // nil until the first question
    @State private var draft = ""
    @State private var reply: String?  // Mímir's answer while he writes it
    @State private var problem: String?
    @State private var session: LanguageModelSession?
    @State private var thinking: Task<Void, Never>?
    @State private var showingChats = false
    @FocusState private var typing: Bool

    var body: some View {
        Group {
            if let chat { messages(chat) } else { welcome }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(.rect)
        .onTapGesture { typing = false }  // tap anywhere off the field to put the keyboard away
        .safeAreaInset(edge: .bottom) { input }
        .containerBackground(.page, for: .navigation)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Chats", systemImage: "line.3.horizontal") { showingChats = true }
            }
            ToolbarItem(placement: .principal) {
                Menu {
                    Picker("Model", selection: $brain) {
                        ForEach(MimirBrain.allCases, id: \.self) { brain in
                            VStack {
                                Text(brain.name)
                                Text(brain.detail)  // shown as the subtitle
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(brain.name)
                        Image(systemName: "chevron.down").font(.caption.bold())
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.ink)
                }
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if chat != nil {
                    Button("New Chat", systemImage: "square.and.pencil") { open(nil) }
                }
                NavigationLink { Settings() } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingChats) { ChatList(current: chat, open: open) }
    }

    private var welcome: some View {
        VStack(spacing: 18) {
            Image(.mimir)
                .resizable()
                .scaledToFit()
                .frame(width: 232)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
            Text(greeting)
                .font(.system(.title, design: .serif, weight: .semibold))
            if let unavailable = MimirMind.unavailable {
                Text(unavailable)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }

    private func messages(_ chat: Chat) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(chat.messages.indices, id: \.self) { ChatBubble(message: chat.messages[$0]) }
                if let reply {
                    if reply.isEmpty { ProgressView() } else { ChatBubble(message: ChatMessage(text: reply, fromMimir: true)) }
                }
                if let problem { Text(problem).foregroundStyle(.secondary) }
            }
            .padding()
        }
        .contentMargins(.bottom, 0, for: .scrollContent)
        .defaultScrollAnchor(.bottom)
        .scrollDismissesKeyboard(.interactively)
    }

    private var input: some View {
        HStack(alignment: .bottom) {
            TextField("Ask Mímir", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($typing)
                .padding(.vertical, 7)
            if thinking != nil || !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button {
                    if let thinking { thinking.cancel() } else { send() }
                } label: {
                    Image(systemName: thinking == nil ? "arrow.up" : "stop.fill")
                        .font(.body.bold())
                        .foregroundStyle(.page)
                        .frame(width: 34, height: 34)
                        .background(.accent, in: .circle)
                }
                .accessibilityLabel(thinking == nil ? "Send" : "Stop")
            }
        }
        .frame(minHeight: 34)
        .padding(.leading, 16)
        .padding([.trailing, .vertical], 6)
        .background(.card, in: .rect(cornerRadius: 23))
        .padding(.horizontal)
        .padding(.bottom, typing ? 8 : 72)  // above the tab bar, which hides behind the keyboard
        .disabled(MimirMind.unavailable != nil)
    }

    private var greeting: String {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<18: "Good afternoon"
        default: "Good evening"
        }
    }

    private func open(_ chat: Chat?) {
        thinking?.cancel()
        self.chat = chat
        session = nil
        problem = nil
    }

    private func send() {
        let question = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        let chat = self.chat ?? Chat(title: question)
        if self.chat == nil {
            context.insert(chat)
            self.chat = chat
        }
        let history = chat.messages
        chat.messages.append(ChatMessage(text: question, fromMimir: false))
        chat.updated = .now
        draft = ""
        problem = nil
        reply = ""
        thinking = Task {
            do {
                try await answer(question, remembering: history)
            } catch {
                session = nil
                if !(error is CancellationError) { problem = MimirMind.problem(error) }
            }
            if let reply, !reply.isEmpty { chat.messages.append(ChatMessage(text: reply, fromMimir: true)) }
            reply = nil
            thinking = nil
        }
    }

    /// Streams Mímir's answer into `reply`. If the chat grew too long for him, he keeps only the last exchange and tries again.
    private func answer(_ question: String, remembering history: [ChatMessage]) async throws {
        let session = self.session ?? MimirMind.session(remembering: history, container: context.container)
        self.session = session
        do {
            for try await partial in session.streamResponse(to: question) { reply = partial.content }
        } catch LanguageModelError.contextSizeExceeded where history.count > 2 {
            self.session = nil
            try await answer(question, remembering: Array(history.suffix(2)))
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        if message.fromMimir {
            let markdown = try? AttributedString(markdown: message.text, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace))
            Text(markdown ?? AttributedString(message.text))
                .textSelection(.enabled)
        } else {
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.card, in: .rect(cornerRadius: 20))
                .padding(.leading, 48)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationStack { Home() }
        .modelContainer(for: Chat.self, inMemory: true)
}
