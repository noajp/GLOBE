//======================================================================
// MARK: - LandmarkCoordinates.swift
// Purpose: Define landmark coordinates for all 193 UN member countries
// Path: GLOBE/Core/Location/LandmarkCoordinates.swift
//======================================================================

import Foundation
import CoreLocation

struct LandmarkCoordinates {

    /// 国・地域ごとのランドマーク座標を返す（国連加盟193ヶ国対応）
    static func getInitialCoordinate(for countryCode: String) -> CLLocationCoordinate2D {
        switch countryCode.uppercased() {

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - アジア (Asia)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        case "AF": // Afghanistan - アフガニスタン
            return CLLocationCoordinate2D(latitude: 34.5553, longitude: 69.2075) // Darul Aman Palace

        case "AM": // Armenia - アルメニア
            return CLLocationCoordinate2D(latitude: 40.1792, longitude: 44.4991) // Republic Square, Yerevan

        case "AZ": // Azerbaijan - アゼルバイジャン
            return CLLocationCoordinate2D(latitude: 40.4093, longitude: 49.8671) // Flame Towers, Baku

        case "BH": // Bahrain - バーレーン
            return CLLocationCoordinate2D(latitude: 26.2235, longitude: 50.5876) // Bahrain Fort

        case "BD": // Bangladesh - バングラデシュ
            return CLLocationCoordinate2D(latitude: 23.7104, longitude: 90.4074) // National Martyrs' Memorial

        case "BT": // Bhutan - ブータン
            return CLLocationCoordinate2D(latitude: 27.4728, longitude: 89.6393) // Tiger's Nest Monastery

        case "BN": // Brunei - ブルネイ
            return CLLocationCoordinate2D(latitude: 4.9431, longitude: 114.9425) // Omar Ali Saifuddien Mosque

        case "KH": // Cambodia - カンボジア
            return CLLocationCoordinate2D(latitude: 13.4125, longitude: 103.8670) // Angkor Wat

        case "CN": // China - 中国
            return CLLocationCoordinate2D(latitude: 31.2397, longitude: 121.4995) // Oriental Pearl Tower, Shanghai

        case "CY": // Cyprus - キプロス
            return CLLocationCoordinate2D(latitude: 35.1856, longitude: 33.3823) // Nicosia Old Town

        case "GE": // Georgia - ジョージア
            return CLLocationCoordinate2D(latitude: 41.6938, longitude: 44.8015) // Narikala Fortress, Tbilisi

        case "IN": // India - インド
            return CLLocationCoordinate2D(latitude: 28.6139, longitude: 77.2090) // India Gate

        case "ID": // Indonesia - インドネシア
            return CLLocationCoordinate2D(latitude: -6.1751, longitude: 106.8650) // Monas, Jakarta

        case "IR": // Iran - イラン
            return CLLocationCoordinate2D(latitude: 35.6892, longitude: 51.3890) // Azadi Tower, Tehran

        case "IQ": // Iraq - イラク
            return CLLocationCoordinate2D(latitude: 33.3128, longitude: 44.3615) // Al-Shaheed Monument, Baghdad

        case "IL": // Israel - イスラエル
            return CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137) // Western Wall, Jerusalem

        case "JP": // Japan - 日本
            return CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454) // Tokyo Tower

        case "JO": // Jordan - ヨルダン
            return CLLocationCoordinate2D(latitude: 30.3285, longitude: 35.4444) // Petra

        case "KZ": // Kazakhstan - カザフスタン
            return CLLocationCoordinate2D(latitude: 51.1694, longitude: 71.4491) // Bayterek Tower, Nur-Sultan

        case "KW": // Kuwait - クウェート
            return CLLocationCoordinate2D(latitude: 29.3759, longitude: 47.9774) // Kuwait Towers

        case "KG": // Kyrgyzstan - キルギス
            return CLLocationCoordinate2D(latitude: 42.8746, longitude: 74.5698) // Ala-Too Square, Bishkek

        case "LA": // Laos - ラオス
            return CLLocationCoordinate2D(latitude: 17.9757, longitude: 102.6331) // Pha That Luang, Vientiane

        case "LB": // Lebanon - レバノン
            return CLLocationCoordinate2D(latitude: 33.8938, longitude: 35.5018) // Raouche Rocks, Beirut

        case "MY": // Malaysia - マレーシア
            return CLLocationCoordinate2D(latitude: 3.1579, longitude: 101.7116) // Petronas Towers

        case "MV": // Maldives - モルディブ
            return CLLocationCoordinate2D(latitude: 4.1755, longitude: 73.5093) // Male City

        case "MN": // Mongolia - モンゴル
            return CLLocationCoordinate2D(latitude: 47.9197, longitude: 106.9178) // Genghis Khan Statue, Ulaanbaatar

        case "MM": // Myanmar - ミャンマー
            return CLLocationCoordinate2D(latitude: 16.7967, longitude: 96.1610) // Shwedagon Pagoda, Yangon

        case "NP": // Nepal - ネパール
            return CLLocationCoordinate2D(latitude: 27.7172, longitude: 85.3240) // Boudhanath Stupa, Kathmandu

        case "KP": // North Korea - 北朝鮮
            return CLLocationCoordinate2D(latitude: 39.0392, longitude: 125.7625) // Juche Tower, Pyongyang

        case "OM": // Oman - オマーン
            return CLLocationCoordinate2D(latitude: 23.5880, longitude: 58.3829) // Sultan Qaboos Grand Mosque

        case "PK": // Pakistan - パキスタン
            return CLLocationCoordinate2D(latitude: 33.7294, longitude: 73.0931) // Faisal Mosque, Islamabad

        case "PS": // Palestine - パレスチナ
            return CLLocationCoordinate2D(latitude: 31.9522, longitude: 35.2332) // Al-Aqsa Mosque

        case "PH": // Philippines - フィリピン
            return CLLocationCoordinate2D(latitude: 14.5995, longitude: 120.9842) // Rizal Park, Manila

        case "QA": // Qatar - カタール
            return CLLocationCoordinate2D(latitude: 25.2854, longitude: 51.5310) // Museum of Islamic Art, Doha

        case "SA": // Saudi Arabia - サウジアラビア
            return CLLocationCoordinate2D(latitude: 21.4225, longitude: 39.8262) // Masjid al-Haram, Mecca

        case "SG": // Singapore - シンガポール
            return CLLocationCoordinate2D(latitude: 1.2868, longitude: 103.8545) // Merlion Park

        case "KR": // South Korea - 韓国
            return CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // Gwanghwamun Gate

        case "LK": // Sri Lanka - スリランカ
            return CLLocationCoordinate2D(latitude: 6.9271, longitude: 79.8612) // Gangaramaya Temple, Colombo

        case "SY": // Syria - シリア
            return CLLocationCoordinate2D(latitude: 33.5138, longitude: 36.2765) // Umayyad Mosque, Damascus

        case "TJ": // Tajikistan - タジキスタン
            return CLLocationCoordinate2D(latitude: 38.5598, longitude: 68.7738) // Dushanbe Flagpole

        case "TH": // Thailand - タイ
            return CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018) // Grand Palace, Bangkok

        case "TL": // Timor-Leste - 東ティモール
            return CLLocationCoordinate2D(latitude: -8.5569, longitude: 125.5603) // Cristo Rei, Dili

        case "TR": // Turkey - トルコ
            return CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784) // Blue Mosque, Istanbul

        case "TM": // Turkmenistan - トルクメニスタン
            return CLLocationCoordinate2D(latitude: 37.9601, longitude: 58.3261) // Neutrality Monument, Ashgabat

        case "AE": // United Arab Emirates - UAE
            return CLLocationCoordinate2D(latitude: 25.1972, longitude: 55.2744) // Burj Khalifa, Dubai

        case "UZ": // Uzbekistan - ウズベキスタン
            return CLLocationCoordinate2D(latitude: 39.6542, longitude: 66.9597) // Registan Square, Samarkand

        case "VN": // Vietnam - ベトナム
            return CLLocationCoordinate2D(latitude: 21.0285, longitude: 105.8542) // Hoan Kiem Lake, Hanoi

        case "YE": // Yemen - イエメン
            return CLLocationCoordinate2D(latitude: 15.3694, longitude: 44.1910) // Old City of Sana'a

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - ヨーロッパ (Europe)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        case "AL": // Albania - アルバニア
            return CLLocationCoordinate2D(latitude: 41.3275, longitude: 19.8187) // Skanderbeg Square, Tirana

        case "AD": // Andorra - アンドラ
            return CLLocationCoordinate2D(latitude: 42.5063, longitude: 1.5218) // Andorra la Vella

        case "AT": // Austria - オーストリア
            return CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738) // Schönbrunn Palace, Vienna

        case "BY": // Belarus - ベラルーシ
            return CLLocationCoordinate2D(latitude: 53.9045, longitude: 27.5615) // Independence Square, Minsk

        case "BE": // Belgium - ベルギー
            return CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517) // Grand Place, Brussels

        case "BA": // Bosnia and Herzegovina - ボスニア・ヘルツェゴビナ
            return CLLocationCoordinate2D(latitude: 43.8564, longitude: 18.4131) // Latin Bridge, Sarajevo

        case "BG": // Bulgaria - ブルガリア
            return CLLocationCoordinate2D(latitude: 42.6977, longitude: 23.3219) // Alexander Nevsky Cathedral, Sofia

        case "HR": // Croatia - クロアチア
            return CLLocationCoordinate2D(latitude: 45.8150, longitude: 15.9819) // Zagreb Cathedral

        case "CZ": // Czech Republic - チェコ
            return CLLocationCoordinate2D(latitude: 50.0875, longitude: 14.4213) // Charles Bridge, Prague

        case "DK": // Denmark - デンマーク
            return CLLocationCoordinate2D(latitude: 55.6761, longitude: 12.5683) // Little Mermaid, Copenhagen

        case "EE": // Estonia - エストニア
            return CLLocationCoordinate2D(latitude: 59.4370, longitude: 24.7536) // Tallinn Old Town

        case "FI": // Finland - フィンランド
            return CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384) // Helsinki Cathedral

        case "FR": // France - フランス
            return CLLocationCoordinate2D(latitude: 48.8584, longitude: 2.2945) // Eiffel Tower, Paris

        case "DE": // Germany - ドイツ
            return CLLocationCoordinate2D(latitude: 52.5163, longitude: 13.3777) // Brandenburg Gate, Berlin

        case "GR": // Greece - ギリシャ
            return CLLocationCoordinate2D(latitude: 37.9715, longitude: 23.7267) // Acropolis, Athens

        case "HU": // Hungary - ハンガリー
            return CLLocationCoordinate2D(latitude: 47.5079, longitude: 19.0402) // Parliament Building, Budapest

        case "IS": // Iceland - アイスランド
            return CLLocationCoordinate2D(latitude: 64.1466, longitude: -21.9426) // Hallgrímskirkja, Reykjavik

        case "IE": // Ireland - アイルランド
            return CLLocationCoordinate2D(latitude: 53.3498, longitude: -6.2603) // Trinity College, Dublin

        case "IT": // Italy - イタリア
            return CLLocationCoordinate2D(latitude: 41.8902, longitude: 12.4922) // Colosseum, Rome

        case "XK": // Kosovo - コソボ
            return CLLocationCoordinate2D(latitude: 42.6629, longitude: 21.1655) // Newborn Monument, Pristina

        case "LV": // Latvia - ラトビア
            return CLLocationCoordinate2D(latitude: 56.9496, longitude: 24.1052) // Freedom Monument, Riga

        case "LI": // Liechtenstein - リヒテンシュタイン
            return CLLocationCoordinate2D(latitude: 47.1410, longitude: 9.5209) // Vaduz Castle

        case "LT": // Lithuania - リトアニア
            return CLLocationCoordinate2D(latitude: 54.6872, longitude: 25.2797) // Gediminas Tower, Vilnius

        case "LU": // Luxembourg - ルクセンブルク
            return CLLocationCoordinate2D(latitude: 49.6116, longitude: 6.1319) // Grand Ducal Palace

        case "MT": // Malta - マルタ
            return CLLocationCoordinate2D(latitude: 35.8989, longitude: 14.5146) // Valletta City Gate

        case "MD": // Moldova - モルドバ
            return CLLocationCoordinate2D(latitude: 47.0105, longitude: 28.8638) // Nativity Cathedral, Chisinau

        case "MC": // Monaco - モナコ
            return CLLocationCoordinate2D(latitude: 43.7384, longitude: 7.4246) // Prince's Palace

        case "ME": // Montenegro - モンテネグロ
            return CLLocationCoordinate2D(latitude: 42.4304, longitude: 19.2594) // Lake Skadar

        case "NL": // Netherlands - オランダ
            return CLLocationCoordinate2D(latitude: 52.3702, longitude: 4.8952) // Royal Palace, Amsterdam

        case "MK": // North Macedonia - 北マケドニア
            return CLLocationCoordinate2D(latitude: 41.9973, longitude: 21.4280) // Stone Bridge, Skopje

        case "NO": // Norway - ノルウェー
            return CLLocationCoordinate2D(latitude: 59.9139, longitude: 10.7522) // Royal Palace, Oslo

        case "PL": // Poland - ポーランド
            return CLLocationCoordinate2D(latitude: 52.2297, longitude: 21.0122) // Palace of Culture, Warsaw

        case "PT": // Portugal - ポルトガル
            return CLLocationCoordinate2D(latitude: 38.6916, longitude: -9.2160) // Belém Tower, Lisbon

        case "RO": // Romania - ルーマニア
            return CLLocationCoordinate2D(latitude: 44.4268, longitude: 26.1025) // Palace of Parliament, Bucharest

        case "RU": // Russia - ロシア
            return CLLocationCoordinate2D(latitude: 55.7539, longitude: 37.6208) // Red Square, Moscow

        case "SM": // San Marino - サンマリノ
            return CLLocationCoordinate2D(latitude: 43.9424, longitude: 12.4578) // Guaita Tower

        case "RS": // Serbia - セルビア
            return CLLocationCoordinate2D(latitude: 44.8176, longitude: 20.4633) // Kalemegdan Fortress, Belgrade

        case "SK": // Slovakia - スロバキア
            return CLLocationCoordinate2D(latitude: 48.1486, longitude: 17.1077) // Bratislava Castle

        case "SI": // Slovenia - スロベニア
            return CLLocationCoordinate2D(latitude: 46.0569, longitude: 14.5058) // Ljubljana Castle

        case "ES": // Spain - スペイン
            return CLLocationCoordinate2D(latitude: 40.4168, longitude: -3.7038) // Royal Palace, Madrid

        case "SE": // Sweden - スウェーデン
            return CLLocationCoordinate2D(latitude: 59.3293, longitude: 18.0686) // Vasa Museum, Stockholm

        case "CH": // Switzerland - スイス
            return CLLocationCoordinate2D(latitude: 46.9480, longitude: 7.4474) // Swiss Parliament, Bern

        case "UA": // Ukraine - ウクライナ
            return CLLocationCoordinate2D(latitude: 50.4501, longitude: 30.5234) // Maidan Nezalezhnosti, Kyiv

        case "GB": // United Kingdom - イギリス
            return CLLocationCoordinate2D(latitude: 51.5007, longitude: -0.1246) // Big Ben, London

        case "VA": // Vatican City - バチカン市国
            return CLLocationCoordinate2D(latitude: 41.9029, longitude: 12.4534) // St. Peter's Basilica

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - アフリカ (Africa)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        case "DZ": // Algeria - アルジェリア
            return CLLocationCoordinate2D(latitude: 36.7538, longitude: 3.0588) // Martyrs' Memorial, Algiers

        case "AO": // Angola - アンゴラ
            return CLLocationCoordinate2D(latitude: -8.8383, longitude: 13.2344) // Fortress of São Miguel, Luanda

        case "BJ": // Benin - ベナン
            return CLLocationCoordinate2D(latitude: 6.4969, longitude: 2.6289) // Ouidah Museum of History

        case "BW": // Botswana - ボツワナ
            return CLLocationCoordinate2D(latitude: -24.6282, longitude: 25.9231) // Three Chiefs' Monument, Gaborone

        case "BF": // Burkina Faso - ブルキナファソ
            return CLLocationCoordinate2D(latitude: 12.3714, longitude: -1.5197) // Place des Nations Unies, Ouagadougou

        case "BI": // Burundi - ブルンジ
            return CLLocationCoordinate2D(latitude: -3.3614, longitude: 29.3599) // Prince Louis Rwagasore Stadium

        case "CV": // Cape Verde - カーボベルデ
            return CLLocationCoordinate2D(latitude: 14.9159, longitude: -23.5087) // Praia City Center

        case "CM": // Cameroon - カメルーン
            return CLLocationCoordinate2D(latitude: 3.8480, longitude: 11.5021) // Reunification Monument, Yaounde

        case "CF": // Central African Republic - 中央アフリカ
            return CLLocationCoordinate2D(latitude: 4.3947, longitude: 18.5582) // Bangui Cathedral

        case "TD": // Chad - チャド
            return CLLocationCoordinate2D(latitude: 12.1348, longitude: 15.0557) // N'Djamena Grand Mosque

        case "KM": // Comoros - コモロ
            return CLLocationCoordinate2D(latitude: -11.6986, longitude: 43.2551) // Moroni Medina

        case "CG": // Congo - コンゴ共和国
            return CLLocationCoordinate2D(latitude: -4.2634, longitude: 15.2429) // Basilique Sainte-Anne, Brazzaville

        case "CD": // Democratic Republic of the Congo - コンゴ民主共和国
            return CLLocationCoordinate2D(latitude: -4.3276, longitude: 15.3136) // Palais de la Nation, Kinshasa

        case "CI": // Côte d'Ivoire - コートジボワール
            return CLLocationCoordinate2D(latitude: 5.3600, longitude: -4.0083) // St. Paul's Cathedral, Abidjan

        case "DJ": // Djibouti - ジブチ
            return CLLocationCoordinate2D(latitude: 11.5721, longitude: 43.1456) // Hamoudi Mosque

        case "EG": // Egypt - エジプト
            return CLLocationCoordinate2D(latitude: 29.9792, longitude: 31.1342) // Great Pyramid of Giza

        case "GQ": // Equatorial Guinea - 赤道ギニア
            return CLLocationCoordinate2D(latitude: 3.7504, longitude: 8.7371) // Malabo Cathedral

        case "ER": // Eritrea - エリトリア
            return CLLocationCoordinate2D(latitude: 15.3229, longitude: 38.9251) // Fiat Tagliero Building, Asmara

        case "SZ": // Eswatini - エスワティニ
            return CLLocationCoordinate2D(latitude: -26.3054, longitude: 31.1367) // Sibebe Rock

        case "ET": // Ethiopia - エチオピア
            return CLLocationCoordinate2D(latitude: 9.0320, longitude: 38.7469) // National Palace, Addis Ababa

        case "GA": // Gabon - ガボン
            return CLLocationCoordinate2D(latitude: 0.4162, longitude: 9.4673) // Presidential Palace, Libreville

        case "GM": // Gambia - ガンビア
            return CLLocationCoordinate2D(latitude: 13.4549, longitude: -16.5790) // Arch 22, Banjul

        case "GH": // Ghana - ガーナ
            return CLLocationCoordinate2D(latitude: 5.6037, longitude: -0.1870) // Independence Arch, Accra

        case "GN": // Guinea - ギニア
            return CLLocationCoordinate2D(latitude: 9.6412, longitude: -13.5784) // Grand Mosque, Conakry

        case "GW": // Guinea-Bissau - ギニアビサウ
            return CLLocationCoordinate2D(latitude: 11.8636, longitude: -15.5982) // Bissau Presidential Palace

        case "KE": // Kenya - ケニア
            return CLLocationCoordinate2D(latitude: -1.2921, longitude: 36.8219) // Kenyatta International Convention Centre

        case "LS": // Lesotho - レソト
            return CLLocationCoordinate2D(latitude: -29.3167, longitude: 27.4833) // Maseru City Center

        case "LR": // Liberia - リベリア
            return CLLocationCoordinate2D(latitude: 6.3156, longitude: -10.8074) // Providence Island, Monrovia

        case "LY": // Libya - リビア
            return CLLocationCoordinate2D(latitude: 32.8872, longitude: 13.1913) // Red Castle Museum, Tripoli

        case "MG": // Madagascar - マダガスカル
            return CLLocationCoordinate2D(latitude: -18.8792, longitude: 47.5079) // Queen's Palace, Antananarivo

        case "MW": // Malawi - マラウイ
            return CLLocationCoordinate2D(latitude: -13.9626, longitude: 33.7741) // Parliament Building, Lilongwe

        case "ML": // Mali - マリ
            return CLLocationCoordinate2D(latitude: 12.6392, longitude: -8.0029) // Great Mosque of Djenné

        case "MR": // Mauritania - モーリタニア
            return CLLocationCoordinate2D(latitude: 18.0735, longitude: -15.9582) // Port de Pêche, Nouakchott

        case "MU": // Mauritius - モーリシャス
            return CLLocationCoordinate2D(latitude: -20.1609, longitude: 57.5012) // Le Morne Brabant

        case "MA": // Morocco - モロッコ
            return CLLocationCoordinate2D(latitude: 33.9716, longitude: -6.8498) // Hassan Tower, Rabat

        case "MZ": // Mozambique - モザンビーク
            return CLLocationCoordinate2D(latitude: -25.9655, longitude: 32.5832) // Fortaleza de Maputo

        case "NA": // Namibia - ナミビア
            return CLLocationCoordinate2D(latitude: -22.5609, longitude: 17.0658) // Christuskirche, Windhoek

        case "NE": // Niger - ニジェール
            return CLLocationCoordinate2D(latitude: 13.5127, longitude: 2.1128) // Grand Mosque, Niamey

        case "NG": // Nigeria - ナイジェリア
            return CLLocationCoordinate2D(latitude: 9.0765, longitude: 7.3986) // Aso Rock, Abuja

        case "RW": // Rwanda - ルワンダ
            return CLLocationCoordinate2D(latitude: -1.9403, longitude: 29.8739) // Kigali Genocide Memorial

        case "ST": // São Tomé and Príncipe - サントメ・プリンシペ
            return CLLocationCoordinate2D(latitude: 0.3365, longitude: 6.7273) // Presidential Palace, São Tomé

        case "SN": // Senegal - セネガル
            return CLLocationCoordinate2D(latitude: 14.7167, longitude: -17.4677) // African Renaissance Monument, Dakar

        case "SC": // Seychelles - セーシェル
            return CLLocationCoordinate2D(latitude: -4.6191, longitude: 55.4513) // Victoria Clock Tower

        case "SL": // Sierra Leone - シエラレオネ
            return CLLocationCoordinate2D(latitude: 8.4657, longitude: -13.2317) // Cotton Tree, Freetown

        case "SO": // Somalia - ソマリア
            return CLLocationCoordinate2D(latitude: 2.0469, longitude: 45.3182) // Mogadishu Cathedral

        case "ZA": // South Africa - 南アフリカ
            return CLLocationCoordinate2D(latitude: -33.9249, longitude: 18.4241) // Table Mountain, Cape Town

        case "SS": // South Sudan - 南スーダン
            return CLLocationCoordinate2D(latitude: 4.8517, longitude: 31.5825) // John Garang Mausoleum, Juba

        case "SD": // Sudan - スーダン
            return CLLocationCoordinate2D(latitude: 15.5007, longitude: 32.5599) // Confluence of Niles, Khartoum

        case "TZ": // Tanzania - タンザニア
            return CLLocationCoordinate2D(latitude: -6.7924, longitude: 39.2083) // National Museum, Dar es Salaam

        case "TG": // Togo - トーゴ
            return CLLocationCoordinate2D(latitude: 6.1375, longitude: 1.2123) // Independence Monument, Lomé

        case "TN": // Tunisia - チュニジア
            return CLLocationCoordinate2D(latitude: 36.8065, longitude: 10.1815) // Carthage Ruins

        case "UG": // Uganda - ウガンダ
            return CLLocationCoordinate2D(latitude: 0.3476, longitude: 32.5825) // Independence Monument, Kampala

        case "ZM": // Zambia - ザンビア
            return CLLocationCoordinate2D(latitude: -15.4167, longitude: 28.2833) // Lusaka City Center

        case "ZW": // Zimbabwe - ジンバブエ
            return CLLocationCoordinate2D(latitude: -17.8252, longitude: 31.0335) // Great Zimbabwe Monument

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - 北アメリカ (North America)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        case "AG": // Antigua and Barbuda - アンティグア・バーブーダ
            return CLLocationCoordinate2D(latitude: 17.1274, longitude: -61.8468) // St. John's Cathedral

        case "BS": // Bahamas - バハマ
            return CLLocationCoordinate2D(latitude: 25.0443, longitude: -77.3504) // Queen's Staircase, Nassau

        case "BB": // Barbados - バルバドス
            return CLLocationCoordinate2D(latitude: 13.1132, longitude: -59.6090) // Parliament Buildings, Bridgetown

        case "BZ": // Belize - ベリーズ
            return CLLocationCoordinate2D(latitude: 17.4991, longitude: -88.1874) // Belize City Museum

        case "CA": // Canada - カナダ
            return CLLocationCoordinate2D(latitude: 43.6426, longitude: -79.3871) // CN Tower, Toronto

        case "CR": // Costa Rica - コスタリカ
            return CLLocationCoordinate2D(latitude: 9.9281, longitude: -84.0907) // National Theatre, San José

        case "CU": // Cuba - キューバ
            return CLLocationCoordinate2D(latitude: 23.1136, longitude: -82.3666) // Capitolio, Havana

        case "DM": // Dominica - ドミニカ国
            return CLLocationCoordinate2D(latitude: 15.3092, longitude: -61.3794) // Morne Bruce, Roseau

        case "DO": // Dominican Republic - ドミニカ共和国
            return CLLocationCoordinate2D(latitude: 18.4861, longitude: -69.9312) // Alcázar de Colón, Santo Domingo

        case "SV": // El Salvador - エルサルバドル
            return CLLocationCoordinate2D(latitude: 13.6929, longitude: -89.2182) // Metropolitan Cathedral, San Salvador

        case "GD": // Grenada - グレナダ
            return CLLocationCoordinate2D(latitude: 12.0561, longitude: -61.7488) // Fort George, St. George's

        case "GT": // Guatemala - グアテマラ
            return CLLocationCoordinate2D(latitude: 14.6349, longitude: -90.5069) // National Palace, Guatemala City

        case "HT": // Haiti - ハイチ
            return CLLocationCoordinate2D(latitude: 18.5944, longitude: -72.3074) // Citadelle Laferrière

        case "HN": // Honduras - ホンジュラス
            return CLLocationCoordinate2D(latitude: 14.0723, longitude: -87.1921) // National Identity House, Tegucigalpa

        case "JM": // Jamaica - ジャマイカ
            return CLLocationCoordinate2D(latitude: 18.0179, longitude: -76.8099) // Emancipation Park, Kingston

        case "MX": // Mexico - メキシコ
            return CLLocationCoordinate2D(latitude: 19.4326, longitude: -99.1332) // Zócalo, Mexico City

        case "NI": // Nicaragua - ニカラグア
            return CLLocationCoordinate2D(latitude: 12.1364, longitude: -86.2514) // Old Cathedral, Managua

        case "PA": // Panama - パナマ
            return CLLocationCoordinate2D(latitude: 8.9824, longitude: -79.5199) // Panama Canal

        case "KN": // Saint Kitts and Nevis - セントクリストファー・ネイビス
            return CLLocationCoordinate2D(latitude: 17.3026, longitude: -62.7177) // Brimstone Hill Fortress

        case "LC": // Saint Lucia - セントルシア
            return CLLocationCoordinate2D(latitude: 13.9094, longitude: -60.9789) // Pitons, Soufrière

        case "VC": // Saint Vincent and the Grenadines - セントビンセント・グレナディーン
            return CLLocationCoordinate2D(latitude: 13.1579, longitude: -61.2248) // Fort Charlotte, Kingstown

        case "TT": // Trinidad and Tobago - トリニダード・トバゴ
            return CLLocationCoordinate2D(latitude: 10.6596, longitude: -61.5019) // Queen's Park Savannah, Port of Spain

        case "US": // United States - アメリカ
            return CLLocationCoordinate2D(latitude: 40.7580, longitude: -73.9855) // Times Square, New York

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - 南アメリカ (South America)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        case "AR": // Argentina - アルゼンチン
            return CLLocationCoordinate2D(latitude: -34.6037, longitude: -58.3816) // Obelisco, Buenos Aires

        case "BO": // Bolivia - ボリビア
            return CLLocationCoordinate2D(latitude: -16.4897, longitude: -68.1193) // Plaza Murillo, La Paz

        case "BR": // Brazil - ブラジル
            return CLLocationCoordinate2D(latitude: -22.9519, longitude: -43.2105) // Christ the Redeemer, Rio

        case "CL": // Chile - チリ
            return CLLocationCoordinate2D(latitude: -33.4489, longitude: -70.6693) // Plaza de Armas, Santiago

        case "CO": // Colombia - コロンビア
            return CLLocationCoordinate2D(latitude: 4.7110, longitude: -74.0721) // Bolívar Square, Bogotá

        case "EC": // Ecuador - エクアドル
            return CLLocationCoordinate2D(latitude: -0.1807, longitude: -78.4678) // Mitad del Mundo, Quito

        case "GY": // Guyana - ガイアナ
            return CLLocationCoordinate2D(latitude: 6.8013, longitude: -58.1551) // St. George's Cathedral, Georgetown

        case "PY": // Paraguay - パラグアイ
            return CLLocationCoordinate2D(latitude: -25.2637, longitude: -57.5759) // Palacio de López, Asunción

        case "PE": // Peru - ペルー
            return CLLocationCoordinate2D(latitude: -13.1631, longitude: -72.5450) // Machu Picchu

        case "SR": // Suriname - スリナム
            return CLLocationCoordinate2D(latitude: 5.8520, longitude: -55.2038) // Presidential Palace, Paramaribo

        case "UY": // Uruguay - ウルグアイ
            return CLLocationCoordinate2D(latitude: -34.9011, longitude: -56.1645) // Independence Plaza, Montevideo

        case "VE": // Venezuela - ベネズエラ
            return CLLocationCoordinate2D(latitude: 10.4806, longitude: -66.9036) // Bolívar Square, Caracas

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - オセアニア (Oceania)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        case "AU": // Australia - オーストラリア
            return CLLocationCoordinate2D(latitude: -33.8568, longitude: 151.2153) // Sydney Opera House

        case "FJ": // Fiji - フィジー
            return CLLocationCoordinate2D(latitude: -18.1416, longitude: 178.4419) // Suva Municipal Market

        case "KI": // Kiribati - キリバス
            return CLLocationCoordinate2D(latitude: 1.3382, longitude: 173.0176) // Tarawa Atoll

        case "MH": // Marshall Islands - マーシャル諸島
            return CLLocationCoordinate2D(latitude: 7.1315, longitude: 171.1845) // Capitol Building, Majuro

        case "FM": // Micronesia - ミクロネシア連邦
            return CLLocationCoordinate2D(latitude: 6.9248, longitude: 158.1610) // Pohnpei State Capitol

        case "NR": // Nauru - ナウル
            return CLLocationCoordinate2D(latitude: -0.5228, longitude: 166.9315) // Government House, Yaren

        case "NZ": // New Zealand - ニュージーランド
            return CLLocationCoordinate2D(latitude: -36.8485, longitude: 174.7633) // Sky Tower, Auckland

        case "PW": // Palau - パラオ
            return CLLocationCoordinate2D(latitude: 7.5150, longitude: 134.5825) // Rock Islands

        case "PG": // Papua New Guinea - パプアニューギニア
            return CLLocationCoordinate2D(latitude: -9.4438, longitude: 147.1803) // Parliament House, Port Moresby

        case "WS": // Samoa - サモア
            return CLLocationCoordinate2D(latitude: -13.8333, longitude: -171.7500) // To Sua Ocean Trench

        case "SB": // Solomon Islands - ソロモン諸島
            return CLLocationCoordinate2D(latitude: -9.4280, longitude: 159.9550) // Parliament House, Honiara

        case "TO": // Tonga - トンガ
            return CLLocationCoordinate2D(latitude: -21.1789, longitude: -175.1982) // Royal Palace, Nuku'alofa

        case "TV": // Tuvalu - ツバル
            return CLLocationCoordinate2D(latitude: -8.5211, longitude: 179.1962) // Funafuti Atoll

        case "VU": // Vanuatu - バヌアツ
            return CLLocationCoordinate2D(latitude: -17.7334, longitude: 168.3219) // Port Vila Harbor

        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: - デフォルト (Default)
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        default:
            return CLLocationCoordinate2D(latitude: 35.6586, longitude: 139.7454) // Tokyo Tower
        }
    }

    /// ユーザーの現在地から国コードを取得
    static func getCountryCode(from locale: Locale = .current) -> String {
        return locale.region?.identifier ?? "JP"
    }

    /// 現在のロケールに基づいた初期座標を取得
    static func getCurrentLocaleCoordinate() -> CLLocationCoordinate2D {
        let countryCode = getCountryCode()
        return getInitialCoordinate(for: countryCode)
    }
}

