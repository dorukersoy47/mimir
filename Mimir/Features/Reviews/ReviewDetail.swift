import SwiftUI

struct ReviewDetail: View {
    @Bindable var review: Review
    @AppStorage(ReviewTheme.key) private var theme = ReviewTheme.classic

    /// Rating something sets the day it was finished; un-rating moves it back to the to-do list.
    private var level: Binding<Int?> {
        Binding(get: { review.level }, set: {
            review.level = $0
            review.finished = $0 == nil ? nil : review.finished ?? .now
        })
    }

    var body: some View {
        Form {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    ReviewCover(data: review.cover)
                        .frame(width: 100, height: 150)
                        .clipShape(.rect(cornerRadius: 8))
                    VStack(alignment: .leading) {
                        TextField("Title", text: $review.title, axis: .vertical)
                            .font(.title3.bold())
                        TextField("Details", text: $review.info, axis: .vertical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section("Rating") {
                Picker("Rating", selection: level) {
                    Text("To \(ReviewKind.named(review.kind).verb.capitalized)").tag(Int?.none)
                    ForEach(theme.levels.indices, id: \.self) { Text(theme.levels[$0]).tag(Int?.some($0)) }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
            if review.level != nil {
                Section {
                    DatePicker("Finished", selection: Binding(get: { review.finished ?? .now }, set: { review.finished = $0 }),
                               displayedComponents: .date)
                    TextField("Your review", text: $review.text, axis: .vertical)
                        .lineLimit(4...)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
