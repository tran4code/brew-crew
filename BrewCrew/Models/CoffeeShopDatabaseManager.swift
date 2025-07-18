//
//  CoffeeShopDatabaseManager.swift
//  BrewCrew
//
//  Manages Core Data operations for coffee shops and bakeries
//

import Foundation
import CoreData
import CoreLocation
import SwiftUI

@MainActor
class CoffeeShopDatabaseManager: ObservableObject {
    static let shared = CoffeeShopDatabaseManager()
    
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var isLoading = false
    @Published var lastSync: Date?
    @Published var errorMessage: String?
    
    private let container: NSPersistentContainer
    private let placesService: CoffeeShopDiscoveryService
    
    init() {
        container = NSPersistentContainer(name: "BrewCrew")
        placesService = CoffeeShopDiscoveryService()
        
        // Check if we should use pre-populated database
        setupPersistentStore()
        
        loadCoffeeShops()
    }
    
    private func setupPersistentStore() {
        let storeURL = NSPersistentContainer.defaultDirectoryURL()
            .appendingPathComponent("BrewCrew.sqlite")
        
        // Check if store already exists
        if !FileManager.default.fileExists(atPath: storeURL.path) {
            // Try to copy pre-populated database from bundle
            if let bundledDatabaseURL = Bundle.main.url(forResource: "BrewCrew-Prepopulated", withExtension: "sqlite") {
                do {
                    try FileManager.default.copyItem(at: bundledDatabaseURL, to: storeURL)
                    print("Pre-populated database copied successfully")
                } catch {
                    print("Failed to copy pre-populated database: \(error)")
                }
            }
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    func populateDatabase(around location: CLLocationCoordinate2D, radius: Double = 15000) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch coffee shops
            let coffeeShopData = try await fetchPlacesFromAPI(
                location: location,
                radius: radius,
                types: ["cafe", "coffee_shop"]
            )
            
            // Fetch bakeries
            let bakeryData = try await fetchPlacesFromAPI(
                location: location,
                radius: radius,
                types: ["bakery"]
            )
            
            // Import to Core Data
            await importPlacesToDatabase(coffeeShopData + bakeryData)
            
            // Reload from database
            loadCoffeeShops()
            
            lastSync = Date()
            isLoading = false
            
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func loadCoffeeShops() {
        let request: NSFetchRequest<CoffeeShopEntity> = CoffeeShopEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \CoffeeShopEntity.rating, ascending: false),
            NSSortDescriptor(keyPath: \CoffeeShopEntity.reviewCount, ascending: false)
        ]
        
        do {
            let entities = try container.viewContext.fetch(request)
            coffeeShops = entities.map { $0.toCoffeeShop() }
        } catch {
            print("Error fetching coffee shops: \(error)")
        }
    }
    
    func searchCoffeeShops(query: String) -> [CoffeeShop] {
        guard !query.isEmpty else { return coffeeShops }
        
        return coffeeShops.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.address.localizedCaseInsensitiveContains(query)
        }
    }
    
    func nearbyCoffeeShops(location: CLLocationCoordinate2D, radius: Double = 5000) -> [CoffeeShop] {
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        return coffeeShops.filter { shop in
            let shopLocation = CLLocation(latitude: shop.location.latitude, longitude: shop.location.longitude)
            return userLocation.distance(from: shopLocation) <= radius
        }.sorted { shop1, shop2 in
            let location1 = CLLocation(latitude: shop1.location.latitude, longitude: shop1.location.longitude)
            let location2 = CLLocation(latitude: shop2.location.latitude, longitude: shop2.location.longitude)
            return userLocation.distance(from: location1) < userLocation.distance(from: location2)
        }
    }
    
    // MARK: - Private Methods
    
    private func fetchPlacesFromAPI(location: CLLocationCoordinate2D, radius: Double, types: [String]) async throws -> [[String: Any]] {
        let apiKey = Config.googlePlacesAPIKey
        guard !apiKey.isEmpty else {
            throw PlacesError.missingAPIKey
        }
        
        let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        let typeString = types.joined(separator: "|")
        
        var allResults: [[String: Any]] = []
        var nextPageToken: String?
        
        repeat {
            var components = URLComponents(string: baseURL)!
            components.queryItems = [
                URLQueryItem(name: "location", value: "\(location.latitude),\(location.longitude)"),
                URLQueryItem(name: "radius", value: "\(Int(radius))"),
                URLQueryItem(name: "type", value: typeString),
                URLQueryItem(name: "key", value: apiKey)
            ]
            
            if let token = nextPageToken {
                components.queryItems?.append(URLQueryItem(name: "pagetoken", value: token))
                // Google requires a short delay before using page tokens
                try await Task.sleep(nanoseconds: 2_000_000_000)
            }
            
            guard let url = components.url else {
                throw PlacesError.invalidURL
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let results = json?["results"] as? [[String: Any]] {
                allResults.append(contentsOf: results)
            }
            
            nextPageToken = json?["next_page_token"] as? String
            
        } while nextPageToken != nil && allResults.count < 100 // Limit to 100 places
        
        return allResults
    }
    
    private func importPlacesToDatabase(_ placesData: [[String: Any]]) async {
        let context = container.viewContext
        
        for placeData in placesData {
            guard let placeId = placeData["place_id"] as? String else { continue }
            
            // Check if already exists
            let request: NSFetchRequest<CoffeeShopEntity> = CoffeeShopEntity.fetchRequest()
            request.predicate = NSPredicate(format: "googlePlaceId == %@", placeId)
            
            do {
                let existing = try context.fetch(request).first
                let entity = existing ?? CoffeeShopEntity(context: context)
                
                if existing == nil {
                    entity.id = UUID()
                    entity.createdAt = Date()
                }
                
                entity.updateFromPlaceData(placeData)
                
            } catch {
                print("Error checking for existing place: \(error)")
            }
        }
        
        // Save context
        do {
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("Error saving to Core Data: \(error)")
        }
    }
    
    func clearDatabase() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = CoffeeShopEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try container.viewContext.execute(deleteRequest)
            coffeeShops = []
        } catch {
            print("Error clearing database: \(error)")
        }
    }
}

enum PlacesError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case noData
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Google Places API key is missing. Please add it to APIKeys.plist"
        case .invalidURL:
            return "Invalid URL for API request"
        case .noData:
            return "No data received from API"
        }
    }
}