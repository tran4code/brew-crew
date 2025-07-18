//
//  Config-Sample.swift
//  BrewCrew
//
//  This is a template file. Copy this to Config.swift and add your API key.
//  NEVER commit Config.swift to version control!
//

import Foundation

//struct Config {
//    // Replace with your actual Google Places API key
//    // Get one at: https://console.cloud.google.com/apis/credentials
//    static let googlePlacesAPIKey = "YOUR_GOOGLE_PLACES_API_KEY_HERE"
//    
//    // Development settings
//    static let useMockData = false // Set to false when using real API
//    static let discoveryRadius = 15000 // meters (15km to cover Triangle area)
//    static let maxCoffeeShopsToShow = 20
//}

// MARK: - Instructions for getting Google Places API Key
/*
 To get your Google Places API key:
 
 1. Go to https://console.cloud.google.com/
 2. Create a new project or select existing one
 3. Enable the "Places API" in APIs & Services
 4. Go to "Credentials" and create an API key
 5. Restrict the key to "Places API" for security
 6. Copy this file to Config.swift
 7. Replace "YOUR_GOOGLE_PLACES_API_KEY_HERE" with your actual key
 8. Set Config.useMockData = false to use real API
 
 The free tier includes:
 - $200 credit per month
 - Nearby Search: $32 per 1000 requests
 - Much more comprehensive place data
 
 IMPORTANT: Config.swift is in .gitignore and should NEVER be committed!
 */
