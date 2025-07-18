//
//  BrewCrewApp.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI

@main
struct BrewCrewApp: App {
    @StateObject private var databaseManager = CoffeeShopDatabaseManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(databaseManager)
        }
    }
}
