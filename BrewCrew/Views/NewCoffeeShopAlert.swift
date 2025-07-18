//
//  NewCoffeeShopAlert.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI
import CoreLocation

struct NewCoffeeShopAlert: View {
    let coffeeShop: CoffeeShop
    let onVisit: () -> Void
    let onDismiss: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Alert banner
            HStack(spacing: 12) {
                // Coffee shop emoji with animation
                ZStack {
                    Circle()
                        .fill(Color("CoffeeOrange").opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(coffeeShop.emoji)
                        .font(.title2)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                }
                
                // Coffee shop info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("New Coffee Shop!")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("CoffeeOrange"))
                        
                        Spacer()
                        
                        // Dismiss button
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                                .font(.system(size: 16))
                        }
                    }
                    
                    Text(coffeeShop.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(coffeeShop.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Visit button
                Button(action: onVisit) {
                    Text("Visit")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color("CoffeeOrange"))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct NewCoffeeShopsView: View {
    @StateObject private var discoveryService = CoffeeShopDiscoveryService()
    @State private var userLocation = CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382) // Raleigh
    @State private var showFilters = false
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedLocation: LocationFilter = .all
    @State private var sortOption: SortOption = .newness
    @State private var discoveryMode: DiscoveryMode = .newPlaces
    
    enum DiscoveryMode: String, CaseIterable {
        case newPlaces = "New Places"
        case bestReviewed = "Best Reviewed"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Places"
        case brandNew = "Brand New"
        case justOpened = "Just Opened"  
        case recentlyOpened = "Recently Opened"
        case noReviews = "No Reviews Yet"
    }
    
    enum LocationFilter: String, CaseIterable {
        case all = "All Cities"
        case raleigh = "Raleigh"
        case durham = "Durham"
        case chapelHill = "Chapel Hill"
        case cary = "Cary"
    }
    
    enum SortOption: String, CaseIterable {
        case newness = "Newness"
        case reviewCount = "Review Count"
        case rating = "Rating"
        case alphabetical = "A-Z"
    }
    
    var filteredAndSortedShops: [CoffeeShop] {
        let shops = discoveryMode == .newPlaces ? discoveryService.newCoffeeShops : discoveryService.bestReviewedShops
        let filtered = shops.filter { shop in
            // Filter by newness (only for new places mode)
            let passesNewnessFilter: Bool
            if discoveryMode == .newPlaces {
                switch selectedFilter {
                case .all:
                    passesNewnessFilter = true
                case .brandNew:
                    passesNewnessFilter = shop.newnessBadge == "BRAND NEW"
                case .justOpened:
                    passesNewnessFilter = shop.newnessBadge == "JUST OPENED"
                case .recentlyOpened:
                    passesNewnessFilter = shop.newnessBadge == "RECENTLY OPENED"
                case .noReviews:
                    passesNewnessFilter = shop.newnessBadge == "NEW!" || (shop.reviewCount ?? 0) == 0
                }
            } else {
                passesNewnessFilter = true // Skip newness filter for best reviewed mode
            }
            
            // Filter by location
            let passesLocationFilter: Bool
            switch selectedLocation {
            case .all:
                passesLocationFilter = true
            case .raleigh:
                passesLocationFilter = shop.address.lowercased().contains("raleigh")
            case .durham:
                passesLocationFilter = shop.address.lowercased().contains("durham")
            case .chapelHill:
                passesLocationFilter = shop.address.lowercased().contains("chapel hill")
            case .cary:
                passesLocationFilter = shop.address.lowercased().contains("cary")
            }
            
            return passesNewnessFilter && passesLocationFilter
        }
        
        return filtered.sorted { shop1, shop2 in
            switch sortOption {
            case .newness:
                let priority1 = newnessPriority(shop1.newnessBadge)
                let priority2 = newnessPriority(shop2.newnessBadge)
                if priority1 != priority2 {
                    return priority1 > priority2
                }
                return (shop1.reviewCount ?? 0) < (shop2.reviewCount ?? 0)
            case .reviewCount:
                return (shop1.reviewCount ?? 0) > (shop2.reviewCount ?? 0)
            case .rating:
                let rating1 = shop1.rating ?? 0.0
                let rating2 = shop2.rating ?? 0.0
                if rating1 != rating2 {
                    return rating1 > rating2
                }
                return (shop1.reviewCount ?? 0) > (shop2.reviewCount ?? 0)
            case .alphabetical:
                return shop1.name < shop2.name
            }
        }
    }
    
    private func newnessPriority(_ badge: String?) -> Int {
        switch badge {
        case "NEW!": return 4
        case "BRAND NEW": return 3
        case "JUST OPENED": return 2
        case "RECENTLY OPENED": return 1
        default: return 0
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with discovery button
                VStack(spacing: 16) {
                    // Mode toggle
                    Picker("Discovery Mode", selection: $discoveryMode) {
                        ForEach(DiscoveryMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 20)
                    .onChange(of: discoveryMode) { _ in
                        // Change default sort when switching modes
                        if discoveryMode == .bestReviewed {
                            sortOption = .reviewCount
                        } else {
                            sortOption = .newness
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Discover Coffee")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(discoveryMode == .newPlaces ? "Find new coffee shops near you" : "Find the best-reviewed coffee shops")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 8) {
                            // Filter button
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showFilters.toggle()
                                }
                            }) {
                                HStack(spacing: 2) {
                                    Image(systemName: showFilters ? "xmark" : "line.3.horizontal.decrease.circle")
                                        .font(.system(size: 14))
                                    Text(showFilters ? "Hide" : "Filter")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(Color("CoffeeOrange"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .stroke(Color("CoffeeOrange"), lineWidth: 1)
                                )
                            }
                            
                            // Discover button
                            Button(action: {
                                Task {
                                    if discoveryMode == .newPlaces {
                                        await discoveryService.discoverNewCoffeeShops(near: userLocation)
                                    } else {
                                        await discoveryService.discoverBestReviewedCoffeeShops(near: userLocation)
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    if discoveryService.isLoading {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .tint(.white)
                                    } else {
                                        Image(systemName: "location.magnifyingglass")
                                            .font(.system(size: 14))
                                    }
                                    
                                    Text(discoveryService.isLoading ? "Searching..." : "Discover")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color("CoffeeOrange"))
                                )
                            }
                            .disabled(discoveryService.isLoading)
                        }
                    }
                }
                .padding(20)
                .background(Color("BackgroundCream"))
                
                // Expandable filter section
                if showFilters {
                    VStack(spacing: 16) {
                        // Filter by location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Filter by Location")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(LocationFilter.allCases, id: \.self) { location in
                                        Button(action: {
                                            selectedLocation = location
                                        }) {
                                            Text(location.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                                .foregroundColor(selectedLocation == location ? .white : Color("CoffeeOrange"))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(selectedLocation == location ? Color("CoffeeOrange") : Color.clear)
                                                        .stroke(Color("CoffeeOrange"), lineWidth: 1)
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        
                        // Filter by newness (only for new places mode)
                        if discoveryMode == .newPlaces {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Filter by Newness")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(FilterOption.allCases, id: \.self) { filter in
                                            Button(action: {
                                                selectedFilter = filter
                                            }) {
                                                Text(filter.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(selectedFilter == filter ? .white : Color("CoffeeOrange"))
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .background(
                                                        Capsule()
                                                            .fill(selectedFilter == filter ? Color("CoffeeOrange") : Color.clear)
                                                            .stroke(Color("CoffeeOrange"), lineWidth: 1)
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                        
                        // Sort options
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sort by")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(SortOption.allCases, id: \.self) { sort in
                                    Button(action: {
                                        sortOption = sort
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: sortOption == sort ? "checkmark.circle.fill" : "circle")
                                                .font(.system(size: 12))
                                            Text(sort.rawValue)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(sortOption == sort ? Color("CoffeeOrange") : .secondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(sortOption == sort ? Color("CoffeeOrange").opacity(0.1) : Color.clear)
                                        )
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // New coffee shops list
                if filteredAndSortedShops.isEmpty && !discoveryService.isLoading {
                    VStack(spacing: 16) {
                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        if let errorMessage = discoveryService.errorMessage {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.red)
                            
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("No new coffee shops found")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Try discovering in a different area or check back later!")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("BackgroundCream"))
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAndSortedShops) { shop in
                                NewCoffeeShopCard(
                                    coffeeShop: shop,
                                    onVisit: {
                                        discoveryService.markAsVisited(shop)
                                    },
                                    onDismiss: {
                                        discoveryService.dismissShop(shop)
                                    }
                                )
                            }
                        }
                        .padding(20)
                    }
                    .background(Color("BackgroundCream"))
                }
                
                Spacer()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .background(Color("BackgroundCream"))
        }
    }
}

struct NewCoffeeShopCard: View {
    let coffeeShop: CoffeeShop
    let onVisit: () -> Void
    let onDismiss: () -> Void
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Coffee shop emoji with animation
            ZStack {
                Circle()
                    .fill(Color("CoffeeOrange").opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Text(coffeeShop.emoji)
                    .font(.title)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
            
            // Coffee shop details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(coffeeShop.name)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if let newnessBadge = coffeeShop.newnessBadge, !newnessBadge.isEmpty {
                        Text(newnessBadge)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(badgeColor(for: newnessBadge))
                            )
                    }
                }
                
                Text(coffeeShop.address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Show rating and review count if available
                HStack(spacing: 8) {
                    if let rating = coffeeShop.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let reviewCount = coffeeShop.reviewCount {
                        Text("• \(reviewCount) reviews")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Action buttons
                HStack(spacing: 12) {
                    Button(action: onVisit) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("Add Visit")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color("CoffeeOrange"))
                        )
                    }
                    
                    Button(action: onDismiss) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                            Text("Dismiss")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .onAppear {
            isAnimating = true
        }
    }
    
    private func badgeColor(for badge: String) -> Color {
        switch badge {
        case "NEW!":
            return Color.red
        case "BRAND NEW":
            return Color.purple
        case "JUST OPENED":
            return Color.orange
        case "RECENTLY OPENED":
            return Color.blue
        default:
            return Color.gray
        }
    }
}

#Preview {
    NewCoffeeShopsView()
}