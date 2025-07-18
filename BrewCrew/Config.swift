//
//  Config.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import Foundation

struct Config {
    // API key loaded from APIKeys.plist (not committed to git)
    static let googlePlacesAPIKey: String = {
        guard let path = Bundle.main.path(forResource: "APIKeys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path),
              let apiKey = dict["GooglePlacesAPIKey"] as? String,
              apiKey != "YOUR_GOOGLE_PLACES_API_KEY_HERE" else {
            print("⚠️ WARNING: Google Places API key not found in APIKeys.plist")
            print("Please add your API key to APIKeys.plist")
            return ""
        }
        return apiKey
    }()
    
    // Development settings
    static let useMockData = false // Set to false when using real API
    static let discoveryRadius = 15000 // meters (15km to cover Triangle area)
    static let maxCoffeeShopsToShow = 20
}

// MARK: - Instructions for getting Google Places API Key
/*
 To get your Google Places API key:
 
 1. Go to https://console.cloud.google.com/
 2. Create a new project or select existing one
 3. Enable the "Places API" in APIs & Services
 4. Go to "Credentials" and create an API key
 5. Restrict the key to "Places API" for security
 6. Replace "YOUR_GOOGLE_PLACES_API_KEY_HERE" with your actual key
 7. Set Config.useMockData = false to use real API
 
 The free tier includes:
 - $200 credit per month
 - Nearby Search: $32 per 1000 requests
 - Much more comprehensive place data
 */
