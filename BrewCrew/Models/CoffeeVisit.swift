//
//  CoffeeVisit.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import Foundation

struct CoffeeVisit: Identifiable, Codable {
    let id = UUID()
    let user: User
    let coffeeShop: CoffeeShop
    let order: String
    let rating: Int // 1-5 stars
    let emoji: String // Mood/reaction emoji
    let timestamp: Date
    let photoURL: String?
    
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    var isLeftAligned: Bool {
        // Alternate left/right based on user ID for visual variety
        return user.id.hashValue % 2 == 0
    }
    
    static let sampleVisits = [
        CoffeeVisit(
            user: User.sampleUsers[0],
            coffeeShop: CoffeeShop.sampleShops[0],
            order: "Oat Milk Cortado",
            rating: 5,
            emoji: "✨",
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            photoURL: nil
        ),
        CoffeeVisit(
            user: User.sampleUsers[1],
            coffeeShop: CoffeeShop.sampleShops[1],
            order: "Espresso & Almond Croissant",
            rating: 4,
            emoji: "📱",
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            photoURL: nil
        ),
        CoffeeVisit(
            user: User.sampleUsers[2],
            coffeeShop: CoffeeShop.sampleShops[7], // Bean Traders Durham
            order: "Ethiopian Single Origin",
            rating: 5,
            emoji: "⚡",
            timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            photoURL: nil
        ),
        CoffeeVisit(
            user: User.sampleUsers[3],
            coffeeShop: CoffeeShop.sampleShops[8], // Cocoa Cinnamon
            order: "Mocha & Cinnamon Roll",
            rating: 5,
            emoji: "🍫",
            timestamp: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
            photoURL: nil
        ),
        CoffeeVisit(
            user: User.sampleUsers[0],
            coffeeShop: CoffeeShop.sampleShops[4], // Morning Times
            order: "Sunrise Blend",
            rating: 4,
            emoji: "🌅",
            timestamp: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
            photoURL: nil
        ),
        CoffeeVisit(
            user: User.sampleUsers[1],
            coffeeShop: CoffeeShop.sampleShops[10], // Carolina Coffee Shop
            order: "Tar Heel Latte",
            rating: 5,
            emoji: "🐏",
            timestamp: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            photoURL: nil
        )
    ]
}