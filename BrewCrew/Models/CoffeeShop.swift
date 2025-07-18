//
//  CoffeeShop.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import Foundation
import CoreLocation

struct CoffeeShop: Identifiable, Codable {
    let id: UUID
    let name: String
    let emoji: String
    let latitude: Double
    let longitude: Double
    let address: String
    let newnessBadge: String?
    let reviewCount: Int?
    let rating: Double?
    
    // Convenience initializer for sample shops (without newness data)
    init(name: String, emoji: String, latitude: Double, longitude: Double, address: String) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.newnessBadge = nil
        self.reviewCount = nil
        self.rating = nil
    }
    
    // Full initializer for discovered places (with newness data)
    init(name: String, emoji: String, latitude: Double, longitude: Double, address: String, newnessBadge: String?, reviewCount: Int?, rating: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.newnessBadge = newnessBadge
        self.reviewCount = reviewCount
        self.rating = rating
    }
    
    // Complete initializer with ID (for Core Data)
    init(id: UUID, name: String, emoji: String, latitude: Double, longitude: Double, address: String, newnessBadge: String?, reviewCount: Int?, rating: Double?) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.newnessBadge = newnessBadge
        self.reviewCount = reviewCount
        self.rating = rating
    }
    
    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    static let sampleShops = [
        // Raleigh Coffee Shops
        CoffeeShop(
            name: "Sola Coffee",
            emoji: "☕",
            latitude: 35.7796,
            longitude: -78.6382,
            address: "119 E Hargett St, Raleigh, NC"
        ),
        CoffeeShop(
            name: "Jubala Village",
            emoji: "🥐",
            latitude: 35.7831,
            longitude: -78.6811,
            address: "4450 Glen Forest Dr, Raleigh, NC"
        ),
        CoffeeShop(
            name: "Black Dog Coffee",
            emoji: "🐕",
            latitude: 35.7721,
            longitude: -78.6388,
            address: "3800 Glenwood Ave, Raleigh, NC"
        ),
        CoffeeShop(
            name: "Café Helios",
            emoji: "🌿",
            latitude: 35.7866,
            longitude: -78.6445,
            address: "413 Glenwood Ave, Raleigh, NC"
        ),
        CoffeeShop(
            name: "Morning Times",
            emoji: "🌅",
            latitude: 35.7887,
            longitude: -78.6576,
            address: "10 E Martin St, Raleigh, NC"
        ),
        CoffeeShop(
            name: "Cup A Joe",
            emoji: "📚",
            latitude: 35.7943,
            longitude: -78.6564,
            address: "2801 Hillsborough St, Raleigh, NC"
        ),
        
        // Durham Coffee Shops
        CoffeeShop(
            name: "Bean Traders",
            emoji: "🫘",
            latitude: 35.9940,
            longitude: -78.8986,
            address: "1010 9th St, Durham, NC"
        ),
        CoffeeShop(
            name: "Cocoa Cinnamon",
            emoji: "🍫",
            latitude: 35.9965,
            longitude: -78.9017,
            address: "420 W Geer St, Durham, NC"
        ),
        CoffeeShop(
            name: "Joe Van Gogh",
            emoji: "🎨",
            latitude: 36.0014,
            longitude: -78.9106,
            address: "236 W Main St, Durham, NC"
        ),
        CoffeeShop(
            name: "Dune Coffee",
            emoji: "🏔️",
            latitude: 35.9876,
            longitude: -78.9051,
            address: "305 E Chapel Hill St, Durham, NC"
        ),
        
        // Chapel Hill Coffee Shops
        CoffeeShop(
            name: "Carolina Coffee Shop",
            emoji: "🐏",
            latitude: 35.9132,
            longitude: -79.0558,
            address: "138 E Franklin St, Chapel Hill, NC"
        ),
        CoffeeShop(
            name: "Caffe Driade",
            emoji: "🧚‍♀️",
            latitude: 35.9101,
            longitude: -79.0625,
            address: "1215 E Franklin St, Chapel Hill, NC"
        ),
        
        // Cary Coffee Shops
        CoffeeShop(
            name: "Global Village Coffee",
            emoji: "🌍",
            latitude: 35.7596,
            longitude: -78.7767,
            address: "230 E Chatham St, Cary, NC"
        )
    ]
}