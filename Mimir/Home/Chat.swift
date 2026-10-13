import SwiftUI
import SwiftData

/// A saved conversation with Mímir.
@Model final class Chat {
    var title = ""  // the first question
    var messages: [ChatMessage] = []
    var updated = Date.now

    init(title: String) { self.title = title }
}

struct ChatMessage: Codable, Hashable {
    var text: String
    var fromMimir: Bool
}

/// Every saved chat, newest first. Tap one to continue it, swipe to delete.
struct ChatList: View {
    let current: Chat?
    let open: (Chat?) -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Chat.updated, order: .reverse) private var chats: [Chat]

    var body: some View {
        NavigationStack {
            List {
                ForEach(chats) { chat in
                    Button {
                        open(chat)
                        dismiss()
                    } label: {
                        LabeledContent {
                            Text(chat.updated, format: .relative(presentation: .named))
                        } label: {
                            Text(chat.title).lineLimit(1)
                        }
                    }
                    .tint(.ink)
                }
                .onDelete { offsets in
                    for i in offsets {
                        if chats[i] == current { open(nil) }
                        context.delete(chats[i])
                    }
                }
                .listRowBackground(Color.card)
            }
            .overlay {
                if chats.isEmpty {
                    ContentUnavailableView("No Chats", systemImage: "bubble.left.and.bubble.right",
                                           description: Text("Your chats with Mímir are saved here."))
                }
            }
            .navigationTitle("Chats")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .presentationBackground(.page)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", systemImage: "xmark") { dismiss() } }
            }
        }
    }
}
