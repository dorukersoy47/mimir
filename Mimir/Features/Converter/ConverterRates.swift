import Foundation

/// Exchange rates from the European Central Bank, via the free Frankfurter service.
/// The download sends no user data. The last rates are saved, so currency works offline.
struct ConverterRates: Codable {
    var date = ""                      // e.g. "2026-10-09"
    var rates: [String: Double] = [:]  // per 1 euro

    static let codes = "AUD BRL CAD CHF CNY CZK DKK EUR GBP HKD HUF IDR ILS INR ISK JPY KRW MXN MYR NOK NZD PHP PLN RON SEK SGD THB TRY USD ZAR"
        .split(separator: " ").map(String.init)

    private static let key = "converter.rates"

    static var saved: ConverterRates {
        UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(Self.self, from: $0) } ?? ConverterRates()
    }

    static func fetch() async -> ConverterRates? {
        guard let data = try? await URLSession.shared.data(from: URL(string: "https://api.frankfurter.dev/v1/latest")!).0,
              let latest = try? JSONDecoder().decode(Self.self, from: data) else { return nil }
        UserDefaults.standard.set(data, forKey: key)
        return latest
    }

    func convert(_ amount: Double, from: String, to: String) -> Double? {
        guard let a = rate(from), let b = rate(to) else { return nil }
        return amount / a * b
    }

    var note: String {
        guard let day = try? Date(date, strategy: .iso8601.year().month().day()) else {
            return "Connect to the internet to load exchange rates."
        }
        return "Rates from \(day.formatted(date: .abbreviated, time: .omitted)), European Central Bank."
    }

    private func rate(_ code: String) -> Double? { code == "EUR" ? 1 : rates[code] }
}
