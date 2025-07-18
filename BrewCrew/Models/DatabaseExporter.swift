//
//  DatabaseExporter.swift
//  BrewCrew
//
//  Handles exporting and importing Core Data stores
//

import Foundation
import CoreData

class DatabaseExporter {
    
    // MARK: - Export Database
    
    static func exportDatabase(from container: NSPersistentContainer) throws -> URL {
        guard let storeURL = container.persistentStoreCoordinator.persistentStores.first?.url else {
            throw ExportError.noStoreFound
        }
        
        let exportURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrewCrew-Export-\(Date().timeIntervalSince1970)")
            .appendingPathExtension("sqlite")
        
        // Create a new coordinator for export
        let exportCoordinator = NSPersistentStoreCoordinator(managedObjectModel: container.managedObjectModel)
        
        // Add source store
        let sourceStore = try exportCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: [NSReadOnlyPersistentStoreOption: true]
        )
        
        // Migrate to export location
        try exportCoordinator.migratePersistentStore(
            sourceStore,
            to: exportURL,
            options: nil,
            withType: NSSQLiteStoreType
        )
        
        print("Database exported to: \(exportURL)")
        return exportURL
    }
    
    // MARK: - Save to Documents
    
    static func saveExportToDocuments() throws -> URL {
        let container = NSPersistentContainer(name: "BrewCrew")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Failed to load store: \(error)")
            }
        }
        
        let exportURL = try exportDatabase(from: container)
        
        // Copy to documents directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsURL.appendingPathComponent("BrewCrew-Prepopulated.sqlite")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: destinationURL)
        
        // Copy to documents
        try FileManager.default.copyItem(at: exportURL, to: destinationURL)
        
        print("Database saved to Documents: \(destinationURL)")
        return destinationURL
    }
    
    // MARK: - Create Seed Data Store
    
    static func createSeedDataStore(with coffeeShops: [CoffeeShop]) throws -> URL {
        // Create a temporary container
        let container = NSPersistentContainer(name: "BrewCrew")
        
        // Use a unique store URL
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("BrewCrew-Seed")
            .appendingPathExtension("sqlite")
        
        // Remove if exists
        try? FileManager.default.removeItem(at: storeURL)
        
        // Configure for our custom location
        let description = NSPersistentStoreDescription(url: storeURL)
        container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        container.loadPersistentStores { _, error in
            loadError = error
        }
        
        if let error = loadError {
            throw error
        }
        
        // Import coffee shops
        let context = container.viewContext
        
        for shop in coffeeShops {
            let entity = CoffeeShopEntity(context: context)
            entity.id = shop.id
            entity.googlePlaceId = UUID().uuidString // Use as placeholder
            entity.name = shop.name
            entity.address = shop.address
            entity.latitude = shop.latitude
            entity.longitude = shop.longitude
            entity.rating = shop.rating ?? 0
            entity.reviewCount = Int32(shop.reviewCount ?? 0)
            entity.placeType = shop.emoji == "🥐" ? "bakery" : "coffee_shop"
            entity.createdAt = Date()
            entity.updatedAt = Date()
        }
        
        try context.save()
        
        // Export this populated store
        return try exportDatabase(from: container)
    }
}

enum ExportError: LocalizedError {
    case noStoreFound
    
    var errorDescription: String? {
        switch self {
        case .noStoreFound:
            return "No Core Data store found to export"
        }
    }
}