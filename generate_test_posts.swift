#!/usr/bin/env swift

//======================================================================
// MARK: - generate_test_posts.swift
// Purpose: Generate 100 test posts in Supabase database
// Usage: swift generate_test_posts.swift
//======================================================================

import Foundation

// Sample data for generating posts
let sampleTexts = [
    "Beautiful sunset today! 🌅",
    "Amazing view from here",
    "Love this place ❤️",
    "Great coffee spot ☕️",
    "Perfect weather for a walk",
    "Hidden gem in the city",
    "Delicious ramen 🍜",
    "Best sushi ever! 🍣",
    "Cherry blossoms are blooming 🌸",
    "Night view is spectacular ✨",
    "Peaceful morning here",
    "Street art is amazing 🎨",
    "Local market vibes",
    "Traditional temple visit 🏯",
    "Mountain hiking trail",
    "Beach day! 🏖",
    "City lights at night",
    "Cozy bookstore find 📚",
    "Fresh produce market",
    "Architecture appreciation"
]

let sampleUsernames = [
    "tokyo_explorer",
    "foodie_japan",
    "travel_lover",
    "photo_walker",
    "city_hunter",
    "nature_fan",
    "coffee_addict",
    "art_enthusiast",
    "street_photographer",
    "local_guide"
]

let tokyoLocations = [
    (35.6762, 139.6503, "東京タワー"),
    (35.6586, 139.7454, "渋谷"),
    (35.6812, 139.7671, "秋葉原"),
    (35.7148, 139.7967, "浅草"),
    (35.6938, 139.7036, "新宿"),
    (35.6284, 139.7387, "恵比寿"),
    (35.6959, 139.5706, "吉祥寺"),
    (35.6654, 139.7707, "銀座"),
    (35.7295, 139.7190, "池袋"),
    (35.6580, 139.7016, "原宿"),
    (35.6897, 139.6917, "中野"),
    (35.7060, 139.5130, "三鷹"),
    (35.6478, 139.7106, "六本木"),
    (35.7219, 139.7965, "北千住"),
    (35.6980, 139.7730, "上野"),
    (35.6300, 139.7400, "目黒"),
    (35.7100, 139.8100, "錦糸町"),
    (35.6950, 139.6500, "下北沢"),
    (35.7400, 139.7200, "赤羽"),
    (35.6200, 139.6800, "自由が丘")
]

print("🚀 Starting to generate 100 test posts...")
print("📍 Using Tokyo area locations")
print("")

// Get current user ID (you need to replace this with actual user ID)
print("⚠️  IMPORTANT: You need to get your user ID first")
print("Run this in your Swift app:")
print("print(AuthManager.shared.currentUser?.id ?? \"no user\")")
print("")
print("Enter your user ID:")

guard let userId = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !userId.isEmpty else {
    print("❌ No user ID provided. Exiting.")
    exit(1)
}

print("")
print("✅ Using user ID: \(userId)")
print("🔄 Generating SQL INSERT statements...")
print("")

// Generate SQL statements
var sqlStatements: [String] = []

for i in 0..<100 {
    let location = tokyoLocations[i % tokyoLocations.count]
    let text = sampleTexts[i % sampleTexts.count]
    let username = sampleUsernames[i % sampleUsernames.count]

    // Add some variation to coordinates
    let latVariation = Double.random(in: -0.01...0.01)
    let lonVariation = Double.random(in: -0.01...0.01)
    let lat = location.0 + latVariation
    let lon = location.1 + lonVariation

    // Random anonymous flag (20% chance)
    let isAnonymous = Int.random(in: 0...4) == 0

    let sql = """
    INSERT INTO posts (user_id, content, latitude, longitude, location_name, is_anonymous, is_public)
    VALUES ('\(userId)', '\(text)', \(lat), \(lon), '\(location.2)', \(isAnonymous), true);
    """

    sqlStatements.append(sql)
}

// Write to file
let outputPath = "/tmp/insert_test_posts.sql"
let fullSQL = sqlStatements.joined(separator: "\n\n")

do {
    try fullSQL.write(toFile: outputPath, atomically: true, encoding: .utf8)
    print("✅ SQL file generated: \(outputPath)")
    print("")
    print("📋 Next steps:")
    print("1. Copy the SQL file content")
    print("2. Go to Supabase SQL Editor")
    print("3. Paste and run the SQL statements")
    print("")
    print("Or run this command to see the SQL:")
    print("cat \(outputPath)")
} catch {
    print("❌ Failed to write SQL file: \(error)")
    exit(1)
}
