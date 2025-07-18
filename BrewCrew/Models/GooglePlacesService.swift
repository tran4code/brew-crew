//
//  GooglePlacesService.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import Foundation
import CoreLocation

// MARK: - Google Places API Models
struct GooglePlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
}

struct GooglePlace: Codable {
    let place_id: String
    let name: String
    let geometry: GoogleGeometry
    let types: [String]
    let formatted_address: String?
    let rating: Double?
    let price_level: Int?
    let user_ratings_total: Int?
    let opening_hours: GoogleOpeningHours?
    let plus_code: GooglePlusCode?
    
    var toCoffeeShop: CoffeeShop {
        CoffeeShop(
            name: name,
            emoji: emoji,
            latitude: geometry.location.lat,
            longitude: geometry.location.lng,
            address: formatted_address ?? "Address not available",
            newnessBadge: isLikelyNew ? newnessBadge : nil,
            reviewCount: user_ratings_total,
            rating: rating
        )
    }
    
    var isLikelyNew: Bool {
        // Algorithm to determine if place is likely new with broader ranges
        let reviewCount = user_ratings_total ?? 0
        
        // New places typically have < 100 reviews
        // Very new places have < 50 reviews
        // Brand new places have < 10 reviews or no reviews yet
        
        return reviewCount < 100
    }
    
    var newnessBadge: String {
        let reviewCount = user_ratings_total ?? 0
        if reviewCount == 0 {
            return "NEW!"
        } else if reviewCount < 10 {
            return "BRAND NEW"
        } else if reviewCount < 50 {
            return "JUST OPENED"
        } else if reviewCount < 100 {
            return "RECENTLY OPENED"
        }
        return ""
    }
    
    var emoji: String {
        // Map Google Place types to emojis
        for type in types {
            switch type.lowercased() {
            case "cafe", "coffee_shop":
                return "☕"
            case "bakery":
                return "🥐"
            case "meal_takeaway", "restaurant":
                return "🍽️"
            case "store":
                return "🏪"
            default:
                continue
            }
        }
        return "☕" // Default for coffee-related places
    }
}

struct GoogleGeometry: Codable {
    let location: GoogleLocation
}

struct GoogleLocation: Codable {
    let lat: Double
    let lng: Double
}

struct GoogleOpeningHours: Codable {
    let open_now: Bool?
}

struct GooglePlusCode: Codable {
    let compound_code: String?
    let global_code: String?
}

// MARK: - Coffee Shop Discovery Service
@MainActor
class CoffeeShopDiscoveryService: ObservableObject {
    @Published var newCoffeeShops: [CoffeeShop] = []
    @Published var bestReviewedShops: [CoffeeShop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiKey = Config.googlePlacesAPIKey
    private let nearbyURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
    private let textSearchURL = "https://maps.googleapis.com/maps/api/place/textsearch/json"
    
    // Known coffee shops to filter out duplicates
    private var knownShops: Set<String> = Set(CoffeeShop.sampleShops.map { $0.name.lowercased() })
    
    func discoverNewCoffeeShops(near location: CLLocationCoordinate2D, radius: Int = 15000) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Search multiple locations to cover Triangle area
            let _ = [
                (35.7796, -78.6382),  // Raleigh downtown
                (35.9940, -78.8986),  // Durham downtown  
                (35.7596, -78.7767),  // Cary downtown
                (location.latitude, location.longitude) // User location
            ]
            
            var allPlaces: [GooglePlace] = []
            
            // Use comprehensive text search for Triangle area
            let textSearchTerms = [
                // Coffee shops
                "coffee shops Raleigh NC",
                "coffee shops Durham NC", 
                "coffee shops Cary NC",
                "coffee shops Chapel Hill NC",
                "espresso Raleigh NC",
                "cafe Raleigh NC",
                "cafe Durham NC",
                "cafe Cary NC",
                
                // Dessert and bakery places
                "dessert shops Raleigh NC",
                "dessert shops Durham NC",
                "dessert shops Cary NC", 
                "bakery Raleigh NC",
                "bakery Durham NC",
                "bakery Cary NC",
                "cupcakes Raleigh NC",
                "ice cream Raleigh NC",
                "donuts Raleigh NC",
                "pastry shops Raleigh NC"
            ]
            
            for term in textSearchTerms {
                let textPlaces = try await searchGooglePlacesText(query: term)
                allPlaces.append(contentsOf: textPlaces)
            }
            
            // Remove duplicates based on place_id
            let uniquePlaces = Array(Dictionary(grouping: allPlaces, by: { $0.place_id }).values)
                .compactMap { $0.first }
            
            // Debug: Print all place names to see what's found
            print("All places found: \(uniquePlaces.map { $0.name })")
            
            // Filter and prioritize new places
            let filteredPlaces = uniquePlaces.filter { place in
                let name = place.name.lowercased()
                
                // Exclude obviously unrelated places
                let excludeTerms = ["hotel", "hospital", "bank", "gas station", "pharmacy", "grocery", 
                                   "walmart", "target", "cvs", "walgreens", "airport", "mall"]
                let shouldExclude = excludeTerms.contains { name.contains($0) }
                
                return !shouldExclude
            }
            
            // Sort by newness first, then by rating
            let sortedPlaces = filteredPlaces.sorted { place1, place2 in
                // Prioritize new places
                if place1.isLikelyNew && !place2.isLikelyNew {
                    return true
                } else if !place1.isLikelyNew && place2.isLikelyNew {
                    return false
                } else {
                    // If both new or both old, sort by rating
                    return (place1.rating ?? 0) > (place2.rating ?? 0)
                }
            }
            
            let coffeeShops = sortedPlaces.map { $0.toCoffeeShop }
            
            print("Filtered coffee/dessert places: \(coffeeShops.map { $0.name })")
            
            // Debug: Print newness info
            let newPlaces = sortedPlaces.filter { $0.isLikelyNew }
            print("NEW places found: \(newPlaces.map { "\($0.name) (\($0.user_ratings_total ?? 0) reviews)" })")
            
            let unknownShops = coffeeShops.filter { shop in
                !knownShops.contains(shop.name.lowercased())
            }
            
            self.newCoffeeShops = unknownShops
            
            // Add newly discovered shops to known shops
            unknownShops.forEach { shop in
                knownShops.insert(shop.name.lowercased())
            }
            
        } catch {
            self.errorMessage = "Failed to discover coffee shops: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func searchGooglePlacesNearby(latitude: Double, longitude: Double, radius: Int) async throws -> [GooglePlace] {
        var components = URLComponents(string: nearbyURL)!
        components.queryItems = [
            URLQueryItem(name: "location", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "radius", value: "\(radius)"),
            URLQueryItem(name: "type", value: "restaurant"), // Broader search
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GooglePlacesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GooglePlacesError.httpError(httpResponse.statusCode)
        }
        
        // Debug: Print the raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("Google Places API Response: \(responseString)")
        }
        
        let googleResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        
        guard googleResponse.status == "OK" || googleResponse.status == "ZERO_RESULTS" else {
            throw GooglePlacesError.apiError(googleResponse.status)
        }
        
        return googleResponse.results
    }
    
    private func searchGooglePlacesText(query: String) async throws -> [GooglePlace] {
        var components = URLComponents(string: textSearchURL)!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        var request = URLRequest(url: components.url!)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GooglePlacesError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw GooglePlacesError.httpError(httpResponse.statusCode)
        }
        
        let googleResponse = try JSONDecoder().decode(GooglePlacesResponse.self, from: data)
        
        guard googleResponse.status == "OK" || googleResponse.status == "ZERO_RESULTS" else {
            throw GooglePlacesError.apiError(googleResponse.status)
        }
        
        return googleResponse.results
    }
    
    func markAsVisited(_ shop: CoffeeShop) {
        newCoffeeShops.removeAll { $0.id == shop.id }
    }
    
    func dismissShop(_ shop: CoffeeShop) {
        newCoffeeShops.removeAll { $0.id == shop.id }
        knownShops.insert(shop.name.lowercased())
    }
    
    func discoverBestReviewedCoffeeShops(near location: CLLocationCoordinate2D, radius: Int = 15000) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Search multiple locations to cover Triangle area
            let _ = [
                (35.7796, -78.6382),  // Raleigh downtown
                (35.9940, -78.8986),  // Durham downtown  
                (35.7596, -78.7767),  // Cary downtown
                (location.latitude, location.longitude) // User location
            ]
            
            var allPlaces: [GooglePlace] = []
            
            // Use comprehensive text search for Triangle area
            let textSearchTerms = [
                // Coffee shops
                "best coffee shops Raleigh NC",
                "top rated coffee shops Durham NC", 
                "popular coffee shops Cary NC",
                "best coffee shops Chapel Hill NC",
                "highest rated espresso Raleigh NC",
                "best cafe Raleigh NC",
                "popular cafe Durham NC",
                
                // Dessert and bakery places
                "best bakery Raleigh NC",
                "top rated bakery Durham NC",
                "popular bakery Cary NC",
                "best cupcakes Raleigh NC",
                "top rated ice cream Raleigh NC",
                "best donuts Raleigh NC",
                "popular pastry shops Raleigh NC"
            ]
            
            for term in textSearchTerms {
                let textPlaces = try await searchGooglePlacesText(query: term)
                allPlaces.append(contentsOf: textPlaces)
            }
            
            // Remove duplicates based on place_id
            let uniquePlaces = Array(Dictionary(grouping: allPlaces, by: { $0.place_id }).values)
                .compactMap { $0.first }
            
            // Filter for highly reviewed places
            let highlyReviewedPlaces = uniquePlaces.filter { place in
                let name = place.name.lowercased()
                
                // Exclude obviously unrelated places
                let excludeTerms = ["hotel", "hospital", "bank", "gas station", "pharmacy", "grocery", 
                                   "walmart", "target", "cvs", "walgreens", "airport", "mall"]
                let shouldExclude = excludeTerms.contains { name.contains($0) }
                
                // Include places with high review counts or ratings
                let reviewCount = place.user_ratings_total ?? 0
                let rating = place.rating ?? 0.0
                
                return !shouldExclude && (reviewCount >= 100 || rating >= 4.0)
            }
            
            // Sort by review count and rating
            let sortedPlaces = highlyReviewedPlaces.sorted { place1, place2 in
                // First prioritize by review count (more reviews = more popular)
                let reviews1 = place1.user_ratings_total ?? 0
                let reviews2 = place2.user_ratings_total ?? 0
                
                if reviews1 != reviews2 {
                    return reviews1 > reviews2
                }
                
                // If review counts are equal, sort by rating
                let rating1 = place1.rating ?? 0.0
                let rating2 = place2.rating ?? 0.0
                return rating1 > rating2
            }
            
            let coffeeShops = sortedPlaces.map { $0.toCoffeeShop }
            
            print("Found \(coffeeShops.count) highly-reviewed coffee/dessert places")
            
            self.bestReviewedShops = coffeeShops
            
        } catch {
            self.errorMessage = "Failed to discover coffee shops: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

enum GooglePlacesError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Google Places API"
        case .httpError(let statusCode):
            return "HTTP Error \(statusCode): \(httpStatusMessage(statusCode))"
        case .apiError(let status):
            return "Google Places API Error: \(status)"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
    
    private func httpStatusMessage(_ statusCode: Int) -> String {
        switch statusCode {
        case 401:
            return "Unauthorized - Check API key"
        case 403:
            return "Forbidden - API key may be invalid or missing"
        case 429:
            return "Rate limit exceeded"
        case 500...599:
            return "Server error"
        default:
            return "Unknown error"
        }
    }
}

// MARK: - Mock Service for Development
class MockCoffeeShopDiscoveryService: CoffeeShopDiscoveryService {
    override func discoverNewCoffeeShops(near location: CLLocationCoordinate2D, radius: Int = 5000) async {
        isLoading = true
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Mock new coffee shops
        let mockShops = [
            CoffeeShop(
                name: "The Daily Grind",
                emoji: "⚙️",
                latitude: location.latitude + 0.001,
                longitude: location.longitude + 0.001,
                address: "123 New Coffee St, Raleigh, NC"
            ),
            CoffeeShop(
                name: "Brew & Bytes",
                emoji: "💻",
                latitude: location.latitude - 0.002,
                longitude: location.longitude + 0.003,
                address: "456 Tech Ave, Durham, NC"
            ),
            CoffeeShop(
                name: "Roast & Toast",
                emoji: "🍞",
                latitude: location.latitude + 0.003,
                longitude: location.longitude - 0.001,
                address: "789 Morning Blvd, Chapel Hill, NC"
            )
        ]
        
        self.newCoffeeShops = mockShops
        isLoading = false
    }
}
