//======================================================================
// MARK: - CountryData.swift
// Purpose: Country data with landmarks for user profile setup
// Path: GLOBE/Core/Location/CountryData.swift
//======================================================================

import Foundation
import CoreLocation

struct Country: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let countryCode: String
    let coordinate: CLLocationCoordinate2D
    let landmarkName: String
    let emoji: String

    // Codable conformance for CLLocationCoordinate2D
    enum CodingKeys: String, CodingKey {
        case name, countryCode, landmarkName, emoji
        case latitude, longitude
    }

    init(name: String, countryCode: String, coordinate: CLLocationCoordinate2D, landmarkName: String, emoji: String) {
        self.name = name
        self.countryCode = countryCode
        self.coordinate = coordinate
        self.landmarkName = landmarkName
        self.emoji = emoji
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        countryCode = try container.decode(String.self, forKey: .countryCode)
        landmarkName = try container.decode(String.self, forKey: .landmarkName)
        emoji = try container.decode(String.self, forKey: .emoji)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(countryCode, forKey: .countryCode)
        try container.encode(landmarkName, forKey: .landmarkName)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.countryCode == rhs.countryCode
    }
}

struct CountryData {

    /// 主要国リスト（国連加盟193ヶ国から人口上位・主要国を抜粋）
    static let popularCountries: [Country] = [

        // アジア
        Country(name: "Japan", countryCode: "JP",
                coordinate: CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454),
                landmarkName: "Tokyo Tower", emoji: "🇯🇵"),

        Country(name: "China", countryCode: "CN",
                coordinate: CLLocationCoordinate2D(latitude: 31.2397, longitude: 121.4995),
                landmarkName: "Oriental Pearl Tower, Shanghai", emoji: "🇨🇳"),

        Country(name: "South Korea", countryCode: "KR",
                coordinate: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
                landmarkName: "N Seoul Tower", emoji: "🇰🇷"),

        Country(name: "India", countryCode: "IN",
                coordinate: CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090),
                landmarkName: "India Gate", emoji: "🇮🇳"),

        Country(name: "Indonesia", countryCode: "ID",
                coordinate: CLLocationCoordinate2D(latitude: -6.1751, longitude: 106.8650),
                landmarkName: "Monas", emoji: "🇮🇩"),

        Country(name: "Thailand", countryCode: "TH",
                coordinate: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018),
                landmarkName: "Grand Palace", emoji: "🇹🇭"),

        Country(name: "Vietnam", countryCode: "VN",
                coordinate: CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542),
                landmarkName: "Hoan Kiem Lake", emoji: "🇻🇳"),

        Country(name: "Philippines", countryCode: "PH",
                coordinate: CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842),
                landmarkName: "Rizal Park", emoji: "🇵🇭"),

        Country(name: "Singapore", countryCode: "SG",
                coordinate: CLLocationCoordinate2D(latitude: 1.2868, longitude: 103.8545),
                landmarkName: "Marina Bay Sands", emoji: "🇸🇬"),

        Country(name: "Malaysia", countryCode: "MY",
                coordinate: CLLocationCoordinate2D(latitude: 3.1579, longitude: 101.7116),
                landmarkName: "Petronas Towers", emoji: "🇲🇾"),

        Country(name: "Taiwan", countryCode: "TW",
                coordinate: CLLocationCoordinate2D(latitude: 25.0330, longitude: 121.5654),
                landmarkName: "Taipei 101", emoji: "🇹🇼"),

        Country(name: "Hong Kong", countryCode: "HK",
                coordinate: CLLocationCoordinate2D(latitude: 22.3193, longitude: 114.1694),
                landmarkName: "Victoria Peak", emoji: "🇭🇰"),

        // 北米
        Country(name: "United States", countryCode: "US",
                coordinate: CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855),
                landmarkName: "Times Square", emoji: "🇺🇸"),

        Country(name: "Canada", countryCode: "CA",
                coordinate: CLLocationCoordinate2D(latitude: 43.6426, longitude: -79.3871),
                landmarkName: "CN Tower", emoji: "🇨🇦"),

        Country(name: "Mexico", countryCode: "MX",
                coordinate: CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332),
                landmarkName: "Zócalo", emoji: "🇲🇽"),

        // 南米
        Country(name: "Brazil", countryCode: "BR",
                coordinate: CLLocationCoordinate2D(latitude: -22.9519, longitude: -43.2105),
                landmarkName: "Christ the Redeemer", emoji: "🇧🇷"),

        Country(name: "Argentina", countryCode: "AR",
                coordinate: CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816),
                landmarkName: "Obelisco", emoji: "🇦🇷"),

        Country(name: "Chile", countryCode: "CL",
                coordinate: CLLocationCoordinate2D(latitude: -33.4489, longitude: -70.6693),
                landmarkName: "Plaza de Armas", emoji: "🇨🇱"),

        // ヨーロッパ
        Country(name: "United Kingdom", countryCode: "GB",
                coordinate: CLLocationCoordinate2D(latitude: 51.5007, longitude: -0.1246),
                landmarkName: "Big Ben", emoji: "🇬🇧"),

        Country(name: "France", countryCode: "FR",
                coordinate: CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945),
                landmarkName: "Eiffel Tower", emoji: "🇫🇷"),

        Country(name: "Germany", countryCode: "DE",
                coordinate: CLLocationCoordinate2D(latitude: 52.5163, longitude: 13.3777),
                landmarkName: "Brandenburg Gate", emoji: "🇩🇪"),

        Country(name: "Italy", countryCode: "IT",
                coordinate: CLLocationCoordinate2D(latitude: 41.8902, longitude: 12.4922),
                landmarkName: "Colosseum", emoji: "🇮🇹"),

        Country(name: "Spain", countryCode: "ES",
                coordinate: CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038),
                landmarkName: "Royal Palace", emoji: "🇪🇸"),

        Country(name: "Netherlands", countryCode: "NL",
                coordinate: CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952),
                landmarkName: "Dam Square", emoji: "🇳🇱"),

        Country(name: "Switzerland", countryCode: "CH",
                coordinate: CLLocationCoordinate2D(latitude: 47.3769, longitude: 8.5417),
                landmarkName: "Lake Zurich", emoji: "🇨🇭"),

        Country(name: "Sweden", countryCode: "SE",
                coordinate: CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686),
                landmarkName: "Vasa Museum", emoji: "🇸🇪"),

        Country(name: "Norway", countryCode: "NO",
                coordinate: CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522),
                landmarkName: "Royal Palace", emoji: "🇳🇴"),

        Country(name: "Denmark", countryCode: "DK",
                coordinate: CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683),
                landmarkName: "Little Mermaid", emoji: "🇩🇰"),

        Country(name: "Russia", countryCode: "RU",
                coordinate: CLLocationCoordinate2D(latitude: 55.7539, longitude: 37.6208),
                landmarkName: "Red Square", emoji: "🇷🇺"),

        Country(name: "Poland", countryCode: "PL",
                coordinate: CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122),
                landmarkName: "Palace of Culture", emoji: "🇵🇱"),

        Country(name: "Turkey", countryCode: "TR",
                coordinate: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
                landmarkName: "Hagia Sophia", emoji: "🇹🇷"),

        // オセアニア
        Country(name: "Australia", countryCode: "AU",
                coordinate: CLLocationCoordinate2D(latitude: -33.8568, longitude: 151.2153),
                landmarkName: "Sydney Opera House", emoji: "🇦🇺"),

        Country(name: "New Zealand", countryCode: "NZ",
                coordinate: CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633),
                landmarkName: "Sky Tower", emoji: "🇳🇿"),

        // 中東
        Country(name: "Saudi Arabia", countryCode: "SA",
                coordinate: CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262),
                landmarkName: "Masjid al-Haram", emoji: "🇸🇦"),

        Country(name: "United Arab Emirates", countryCode: "AE",
                coordinate: CLLocationCoordinate2D(latitude: 25.1972, longitude: 55.2744),
                landmarkName: "Burj Khalifa", emoji: "🇦🇪"),

        Country(name: "Israel", countryCode: "IL",
                coordinate: CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137),
                landmarkName: "Western Wall", emoji: "🇮🇱"),

        // アフリカ
        Country(name: "Egypt", countryCode: "EG",
                coordinate: CLLocationCoordinate2D(latitude: 29.9792, longitude: 31.1342),
                landmarkName: "Great Pyramid of Giza", emoji: "🇪🇬"),

        Country(name: "South Africa", countryCode: "ZA",
                coordinate: CLLocationCoordinate2D(latitude: -33.9249, longitude: 18.4241),
                landmarkName: "Table Mountain", emoji: "🇿🇦"),

        Country(name: "Nigeria", countryCode: "NG",
                coordinate: CLLocationCoordinate2D(latitude: 9.0765, longitude: 7.3986),
                landmarkName: "Aso Rock", emoji: "🇳🇬"),

        Country(name: "Kenya", countryCode: "KE",
                coordinate: CLLocationCoordinate2D(latitude: -1.2921, longitude: 36.8219),
                landmarkName: "Kenyatta Convention Centre", emoji: "🇰🇪"),
    ]

    /// 検索文字列に基づいて国を絞り込む
    static func searchCountries(query: String) -> [Country] {
        guard !query.isEmpty else {
            return popularCountries.sorted { $0.name < $1.name }
        }

        let lowercaseQuery = query.lowercased()
        return popularCountries.filter { country in
            country.name.lowercased().contains(lowercaseQuery) ||
            country.emoji.contains(query)
        }.sorted { $0.name < $1.name }
    }

    /// 国コードから国情報を取得
    static func country(for countryCode: String) -> Country? {
        popularCountries.first { $0.countryCode.uppercased() == countryCode.uppercased() }
    }
}
