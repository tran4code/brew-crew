//
//  CoffeeShopEntity+CoreDataClass.swift
//  BrewCrew
//
//  Created for database storage of coffee shops
//

import Foundation
import CoreData
import CoreLocation

@objc(CoffeeShopEntity)
public class CoffeeShopEntity: NSManagedObject {
    
    // Convert to CoffeeShop model
    func toCoffeeShop() -> CoffeeShop {
        CoffeeShop(
            id: id ?? UUID(),
            name: name ?? "",
            emoji: placeType == "bakery" ? "🥐" : "☕",
            latitude: latitude,
            longitude: longitude,
            address: address ?? "",
            newnessBadge: nil,
            reviewCount: Int(reviewCount),
            rating: rating > 0 ? rating : nil
        )
    }
    
    // Update from Google Places data
    func updateFromPlaceData(_ data: [String: Any]) {
        if let geometry = data["geometry"] as? [String: Any],
           let location = geometry["location"] as? [String: Double] {
            self.latitude = location["lat"] ?? 0.0
            self.longitude = location["lng"] ?? 0.0
        }
        
        self.name = data["name"] as? String ?? ""
        self.address = data["vicinity"] as? String ?? data["formatted_address"] as? String ?? ""
        self.googlePlaceId = data["place_id"] as? String ?? ""
        self.rating = data["rating"] as? Double ?? 0.0
        self.reviewCount = Int32(data["user_ratings_total"] as? Int ?? 0)
        self.priceLevel = Int16(data["price_level"] as? Int ?? 0)
        
        if let types = data["types"] as? [String] {
            if types.contains("bakery") {
                self.placeType = "bakery"
            } else {
                self.placeType = "coffee_shop"
            }
        }
        
        if let photos = data["photos"] as? [[String: Any]] {
            self.photoReferences = photos.compactMap { $0["photo_reference"] as? String }
        }
        
        self.updatedAt = Date()
    }
}