import Foundation

struct ConverterUnit: Identifiable, Hashable {
    let id: String           // saved in favorites, so it must never change
    let name: String
    var symbol = ""
    var converter: UnitConverter?  // nil for currencies and time zones

    func matches(_ search: String) -> Bool {
        search.isEmpty || [id, name, symbol].contains { $0.localizedStandardContains(search) }
    }
}

struct ConverterCategory: Identifiable, Hashable {
    enum Kind { case units, currency, time }

    let name: String
    let icon: String
    var kind = Kind.units
    let units: [ConverterUnit]
    let from: String  // default pair
    let to: String

    var id: String { name }

    func unit(_ id: String) -> ConverterUnit? { units.first { $0.id == id } }

    func matches(_ search: String) -> Bool {
        search.isEmpty || name.localizedStandardContains(search) || units.contains { $0.matches(search) }
    }

    static func named(_ name: String) -> ConverterCategory? { groups.flatMap(\.categories).first { $0.name == name } }
}

extension ConverterCategory {
    /// The first two units are the default pair.
    init<T: Dimension>(_ name: String, _ icon: String, _ units: KeyValuePairs<String, T>) {
        self.init(name: name, icon: icon,
                  units: units.map { ConverterUnit(id: $0.key, name: $0.key, symbol: $0.value.symbol, converter: $0.value.converter) },
                  from: units[0].key, to: units[1].key)
    }

    static let groups: [(name: String, categories: [ConverterCategory])] = [
        ("Everyday", [length, weight, temperature, volume, area, speed, duration]),
        ("Money & Time", [currency, timeZones]),
        ("More", [data, energy, power, pressure, angle, fuelEconomy]),
    ]

    static let length = ConverterCategory("Length", "ruler", [
        "Kilometers": UnitLength.kilometers, "Miles": .miles, "Meters": .meters, "Centimeters": .centimeters,
        "Millimeters": .millimeters, "Feet": .feet, "Inches": .inches, "Yards": .yards, "Nautical miles": .nauticalMiles,
    ])

    static let weight = ConverterCategory("Weight", "scalemass", [
        "Kilograms": UnitMass.kilograms, "Pounds": .pounds, "Grams": .grams, "Milligrams": .milligrams,
        "Ounces": .ounces, "Stones": .stones, "Tonnes": .metricTons, "Tons (US)": .shortTons,
    ])

    static let temperature = ConverterCategory("Temperature", "thermometer.medium", [
        "Celsius": UnitTemperature.celsius, "Fahrenheit": .fahrenheit, "Kelvin": .kelvin,
    ])

    static let volume = ConverterCategory("Volume", "drop", [
        "Liters": UnitVolume.liters, "Gallons (US)": .gallons, "Milliliters": .milliliters, "Cubic meters": .cubicMeters,
        "Cups (US)": .cups, "Cups (metric)": .metricCups, "Tablespoons": .tablespoons, "Teaspoons": .teaspoons,
        "Fluid ounces (US)": .fluidOunces, "Fluid ounces (UK)": .imperialFluidOunces,
        "Pints (US)": .pints, "Pints (UK)": .imperialPints, "Gallons (UK)": .imperialGallons,
    ])

    static let area = ConverterCategory("Area", "square.dashed", [
        "Square meters": UnitArea.squareMeters, "Square feet": .squareFeet, "Square kilometers": .squareKilometers,
        "Square miles": .squareMiles, "Hectares": .hectares, "Acres": .acres, "Square centimeters": .squareCentimeters,
        "Square inches": .squareInches, "Square yards": .squareYards,
    ])

    static let speed = ConverterCategory("Speed", "gauge.with.dots.needle.67percent", [
        "Kilometers per hour": UnitSpeed.kilometersPerHour, "Miles per hour": .milesPerHour,
        "Meters per second": .metersPerSecond, "Knots": .knots,
    ])

    static let duration = ConverterCategory("Duration", "timer", [
        "Hours": UnitDuration.hours, "Minutes": .minutes, "Seconds": .seconds, "Milliseconds": .milliseconds,
        "Days": UnitDuration(symbol: "d", converter: UnitConverterLinear(coefficient: 86_400)),
        "Weeks": UnitDuration(symbol: "wk", converter: UnitConverterLinear(coefficient: 604_800)),
    ])

    static let data = ConverterCategory("Data", "externaldrive", [
        "Gigabytes": UnitInformationStorage.gigabytes, "Megabytes": .megabytes, "Bytes": .bytes, "Kilobytes": .kilobytes,
        "Terabytes": .terabytes, "Bits": .bits, "Megabits": .megabits, "Gigabits": .gigabits,
        "Kibibytes": .kibibytes, "Mebibytes": .mebibytes, "Gibibytes": .gibibytes, "Tebibytes": .tebibytes,
    ])

    static let energy = ConverterCategory("Energy", "flame", [
        "Kilocalories": UnitEnergy.kilocalories, "Kilojoules": .kilojoules, "Joules": .joules,
        "Calories": .calories, "Kilowatt-hours": .kilowattHours,
    ])

    static let power = ConverterCategory("Power", "bolt", [
        "Kilowatts": UnitPower.kilowatts, "Horsepower": .horsepower, "Watts": .watts, "Megawatts": .megawatts,
    ])

    static let pressure = ConverterCategory("Pressure", "barometer", [
        "Bars": UnitPressure.bars, "Pounds per square inch": .poundsForcePerSquareInch, "Kilopascals": .kilopascals,
        "Hectopascals": .hectopascals, "Millibars": .millibars, "Pascals": .newtonsPerMetersSquared,
        "Atmospheres": UnitPressure(symbol: "atm", converter: UnitConverterLinear(coefficient: 101_325)),
        "Millimeters of mercury": .millimetersOfMercury, "Inches of mercury": .inchesOfMercury,
    ])

    static let angle = ConverterCategory("Angle", "angle", [
        "Degrees": UnitAngle.degrees, "Radians": .radians, "Gradians": .gradians, "Revolutions": .revolutions,
        "Arc minutes": .arcMinutes, "Arc seconds": .arcSeconds,
    ])

    static let fuelEconomy = ConverterCategory("Fuel Economy", "fuelpump", [
        "Liters per 100 km": UnitFuelEfficiency.litersPer100Kilometers,
        "Miles per gallon (US)": .milesPerGallon, "Miles per gallon (UK)": .milesPerImperialGallon,
    ])

    static let currency: ConverterCategory = {
        let local = Locale.current.currency?.identifier ?? "EUR"
        return ConverterCategory(
            name: "Currency", icon: "banknote", kind: .currency,
            units: ConverterRates.codes.map { ConverterUnit(id: $0, name: Locale.current.localizedString(forCurrencyCode: $0) ?? $0, symbol: $0) }
                .sorted { $0.name < $1.name },
            from: local, to: local == "USD" ? "EUR" : "USD")
    }()

    static let timeZones = ConverterCategory(
        name: "Time Zones", icon: "globe", kind: .time,
        units: TimeZone.knownTimeZoneIdentifiers.map { id in
            ConverterUnit(id: id, name: id.components(separatedBy: "/").last!.replacing("_", with: " "),
                          symbol: TimeZone(identifier: id)?.abbreviation() ?? "")
        }.sorted { $0.name < $1.name },
        from: TimeZone.current.identifier, to: "America/New_York")
}
