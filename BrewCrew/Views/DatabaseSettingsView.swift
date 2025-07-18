//
//  DatabaseSettingsView.swift
//  BrewCrew
//
//  Settings view for managing the coffee shop database
//

import SwiftUI
import CoreLocation

struct DatabaseSettingsView: View {
    @EnvironmentObject var databaseManager: CoffeeShopDatabaseManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedRadius: Double = 15000
    @State private var showClearAlert = false
    @State private var showPopulateAlert = false
    
    private let radiusOptions: [(String, Double)] = [
        ("5 km", 5000),
        ("10 km", 10000),
        ("15 km", 15000),
        ("25 km", 25000),
        ("50 km", 50000)
    ]
    
    private let triangleLocation = CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382)
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Label("Total Places", systemImage: "cup.and.saucer.fill")
                        Spacer()
                        Text("\(databaseManager.coffeeShops.count)")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if let lastSync = databaseManager.lastSync {
                        HStack {
                            Label("Last Updated", systemImage: "clock.fill")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                } header: {
                    Text("Database Info")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        Text("Search Radius")
                            .font(DesignSystem.Typography.headline)
                        
                        Picker("Radius", selection: $selectedRadius) {
                            ForEach(radiusOptions, id: \.1) { option in
                                Text(option.0).tag(option.1)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    Button(action: { showPopulateAlert = true }) {
                        HStack {
                            if databaseManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text("Populate Database")
                                .font(DesignSystem.Typography.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                .fill(DesignSystem.Colors.primary.opacity(0.1))
                        )
                    }
                    .disabled(databaseManager.isLoading)
                    .buttonStyle(PlainButtonStyle())
                } header: {
                    Text("Database Actions")
                } footer: {
                    Text("Fetches all coffee shops and bakeries within the selected radius of the Triangle area.")
                        .font(DesignSystem.Typography.caption)
                }
                
                Section {
                    Button(action: { showClearAlert = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                            Text("Clear Database")
                                .foregroundColor(.red)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } footer: {
                    Text("This will remove all coffee shops from your local database.")
                        .font(DesignSystem.Typography.caption)
                }
                
                if let error = databaseManager.errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(DesignSystem.Typography.caption)
                    }
                }
            }
            .navigationTitle("Database Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Populate Database", isPresented: $showPopulateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Populate") {
                Task {
                    await databaseManager.populateDatabase(
                        around: triangleLocation,
                        radius: selectedRadius
                    )
                }
            }
        } message: {
            Text("This will fetch all coffee shops and bakeries within \(Int(selectedRadius/1000))km of the Triangle area. This may take a moment and will use your Google Places API quota.")
        }
        .alert("Clear Database", isPresented: $showClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                databaseManager.clearDatabase()
            }
        } message: {
            Text("Are you sure you want to remove all coffee shops from your local database?")
        }
    }
}

#Preview {
    DatabaseSettingsView()
        .environmentObject(CoffeeShopDatabaseManager.shared)
}