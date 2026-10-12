import SwiftUI
import SwiftData

struct ConverterScreen: View {
    let category: ConverterCategory

    @AppStorage private var from: String
    @AppStorage private var to: String
    @State private var amount = "1"
    @State private var time = Date.now
    @State private var rates = ConverterRates.saved

    @Environment(\.modelContext) private var context
    @Query private var favorites: [ConverterFavorite]

    init(category: ConverterCategory) {
        self.category = category
        _from = AppStorage(wrappedValue: category.from, Self.key(category.name, "from"))
        _to = AppStorage(wrappedValue: category.to, Self.key(category.name, "to"))
        let name = category.name
        _favorites = Query(filter: #Predicate { $0.category == name })
    }

    /// Opening a favorite makes it the pair this screen remembers.
    static func remember(_ favorite: ConverterFavorite) {
        UserDefaults.standard.set(favorite.from, forKey: key(favorite.category, "from"))
        UserDefaults.standard.set(favorite.to, forKey: key(favorite.category, "to"))
    }

    private static func key(_ category: String, _ side: String) -> String { "converter.\(category).\(side)" }

    private var favorite: ConverterFavorite? { favorites.first { $0.from == from && $0.to == to } }

    var body: some View {
        Form {
            Section("From") {
                if category.kind == .time {
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                        .environment(\.timeZone, TimeZone(identifier: from) ?? .current)
                } else {
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.title2)
                }
                ConverterUnitPicker(title: "From", units: category.units, selection: $from)
            }
            Section {
                Text(result)
                    .font(.title2)
                    .textSelection(.enabled)
                ConverterUnitPicker(title: "To", units: category.units, selection: $to)
            } header: {
                Text("To")
            } footer: {
                if category.kind == .currency { Text(rates.note) }
            }
        }
        .navigationTitle(category.name)
        .toolbar {
            Button("Swap", systemImage: "arrow.up.arrow.down") { (from, to) = (to, from) }
            Button("Favorite", systemImage: favorite == nil ? "star" : "star.fill") {
                if let favorite {
                    context.delete(favorite)
                } else {
                    context.insert(ConverterFavorite(category: category.name, from: from, to: to))
                }
            }
        }
        .task {
            if category.kind == .currency, let latest = await ConverterRates.fetch() { rates = latest }
        }
    }

    private var result: String {
        let value = (try? Double(amount, format: .number)) ?? 0
        switch category.kind {
        case .time:
            var style = Date.FormatStyle.dateTime.weekday().hour().minute()
            style.timeZone = TimeZone(identifier: to) ?? .current
            return time.formatted(style)
        case .currency:
            return rates.convert(value, from: from, to: to)?.formatted(.currency(code: to)) ?? "—"
        case .units:
            guard let a = category.unit(from)?.converter, let b = category.unit(to)?.converter else { return "—" }
            return b.value(fromBaseUnitValue: a.baseUnitValue(fromValue: value)).formatted(.number.precision(.significantDigits(1...8)))
        }
    }
}

/// Shows the chosen unit. Tapping it opens a searchable list of all units.
private struct ConverterUnitPicker: View {
    let title: String
    let units: [ConverterUnit]
    @Binding var selection: String

    var body: some View {
        let unit = units.first { $0.id == selection }
        NavigationLink {
            ConverterUnitList(units: units, selection: $selection)
                .navigationTitle(title)
        } label: {
            LabeledContent(unit?.name ?? selection, value: unit?.symbol ?? "")
        }
    }
}

private struct ConverterUnitList: View {
    let units: [ConverterUnit]
    @Binding var selection: String
    @State private var search = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(units.filter { $0.matches(search) }) { unit in
            Button {
                selection = unit.id
                dismiss()
            } label: {
                HStack {
                    LabeledContent(unit.name, value: unit.symbol)
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                        .opacity(unit.id == selection ? 1 : 0)
                }
            }
            .tint(.primary)
        }
        .searchable(text: $search)
        .navigationBarTitleDisplayMode(.inline)
    }
}
