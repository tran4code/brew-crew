//
//  CoffeeShopEntity+CoreDataProperties.swift
//  BrewCrew
//
//  Created for database storage of coffee shops
//

import Foundation
import CoreData

extension CoffeeShopEntity {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoffeeShopEntity> {
        return NSFetchRequest<CoffeeShopEntity>(entityName: "CoffeeShopEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var googlePlaceId: String?
    @NSManaged public var name: String?
    @NSManaged public var address: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var rating: Double
    @NSManaged public var reviewCount: Int32
    @NSManaged public var priceLevel: Int16
    @NSManaged public var placeType: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var website: String?
    @NSManaged public var photoReferences: [String]?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var visits: NSSet?
    
}

// MARK: Generated accessors for visits
extension CoffeeShopEntity {
    
    @objc(addVisitsObject:)
    @NSManaged public func addToVisits(_ value: VisitEntity)
    
    @objc(removeVisitsObject:)
    @NSManaged public func removeFromVisits(_ value: VisitEntity)
    
    @objc(addVisits:)
    @NSManaged public func addToVisits(_ values: NSSet)
    
    @objc(removeVisits:)
    @NSManaged public func removeFromVisits(_ values: NSSet)
    
}