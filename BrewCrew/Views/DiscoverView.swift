//
//  DiscoverView.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI
import CoreLocation

struct DiscoverView: View {
    @StateObject private var discoveryService = CoffeeShopDiscoveryService()
    @State private var userLocation = CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382)
    @State private var selectedFilter: FilterOption = .all
    @State private var selectedLocation: LocationFilter = .all
    @State private var sortOption: SortOption = .newness
    @State private var discoveryMode: DiscoveryMode = .newPlaces
    @State private var showDetailSheet: CoffeeShop?
    
    enum DiscoveryMode: String, CaseIterable {
        case newPlaces = "New Places"
        case bestReviewed = "Top Rated"
        
        var icon: String {
            switch self {
            case .newPlaces: return "sparkle.magnifyingglass"
            case .bestReviewed: return "star.fill"
            }
        }
        
        var description: String {
            switch self {
            case .newPlaces: return "Discover fresh coffee spots"
            case .bestReviewed: return "Find the best-reviewed cafes"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case brandNew = "Brand New"
        case justOpened = "Just Opened"
        case recentlyOpened = "Recent"
        case noReviews = "Unreviewed"
    }
    
    enum LocationFilter: String, CaseIterable {
        case all = "All Cities"
        case raleigh = "Raleigh"
        case durham = "Durham"
        case chapelHill = "Chapel Hill"
        case cary = "Cary"
    }
    
    enum SortOption: String, CaseIterable {
        case newness = "Newest"
        case reviewCount = "Popular"
        case rating = "Top Rated"
        case alphabetical = "A-Z"
    }
    
    var filteredAndSortedShops: [CoffeeShop] {
        let shops = discoveryMode == .newPlaces ? discoveryService.newCoffeeShops : discoveryService.bestReviewedShops
        let filtered = shops.filter { shop in
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
                passesNewnessFilter = true
            }
            
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
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    DiscoverHeaderView(
                        discoveryMode: $discoveryMode,
                        isLoading: discoveryService.isLoading
                    ) {
                        Task {
                            if discoveryMode == .newPlaces {
                                await discoveryService.discoverNewCoffeeShops(near: userLocation)
                            } else {
                                await discoveryService.discoverBestReviewedCoffeeShops(near: userLocation)
                            }
                        }
                    }
                    
                    FilterBarView(
                        selectedLocation: $selectedLocation,
                        selectedFilter: $selectedFilter,
                        sortOption: $sortOption,
                        discoveryMode: discoveryMode
                    )
                    
                    if filteredAndSortedShops.isEmpty && !discoveryService.isLoading {
                        DiscoverEmptyStateView(
                            errorMessage: discoveryService.errorMessage
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.Spacing.md) {
                                ForEach(filteredAndSortedShops) { shop in
                                    ModernCoffeeShopDiscoveryCard(
                                        coffeeShop: shop,
                                        onTap: {
                                            showDetailSheet = shop
                                        },
                                        onVisit: {
                                            discoveryService.markAsVisited(shop)
                                        },
                                        onDismiss: {
                                            withAnimation(DesignSystem.Animation.spring) {
                                                discoveryService.dismissShop(shop)
                                            }
                                        }
                                    )
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(item: $showDetailSheet) { shop in
            CoffeeShopDetailSheet(coffeeShop: shop)
        }
        .onAppear {
            Task {
                await discoveryService.discoverNewCoffeeShops(near: userLocation)
            }
        }
    }
}

struct DiscoverHeaderView: View {
    @Binding var discoveryMode: DiscoverView.DiscoveryMode
    let isLoading: Bool
    let onDiscover: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Discover Coffee")
                        .font(DesignSystem.Typography.largeTitle)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(discoveryMode.description)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                Button(action: onDiscover) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.gradientStart, DesignSystem.Colors.gradientEnd],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)
            
            Picker("Discovery Mode", selection: $discoveryMode) {
                ForEach(DiscoverView.DiscoveryMode.allCases, id: \.self) { mode in
                    Label(mode.rawValue, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
        }
        .background(DesignSystem.Colors.cardBackground)
        .shadow(
            color: DesignSystem.Colors.cardShadow,
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

struct FilterBarView: View {
    @Binding var selectedLocation: DiscoverView.LocationFilter
    @Binding var selectedFilter: DiscoverView.FilterOption
    @Binding var sortOption: DiscoverView.SortOption
    let discoveryMode: DiscoverView.DiscoveryMode
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Menu {
                        ForEach(DiscoverView.LocationFilter.allCases, id: \.self) { location in
                            Button(action: { selectedLocation = location }) {
                                Label(
                                    location.rawValue,
                                    systemImage: selectedLocation == location ? "checkmark" : ""
                                )
                            }
                        }
                    } label: {
                        FilterChip(
                            title: selectedLocation.rawValue,
                            icon: "location",
                            isActive: selectedLocation != .all
                        )
                    }
                    
                    if discoveryMode == .newPlaces {
                        Menu {
                            ForEach(DiscoverView.FilterOption.allCases, id: \.self) { filter in
                                Button(action: { selectedFilter = filter }) {
                                    Label(
                                        filter.rawValue,
                                        systemImage: selectedFilter == filter ? "checkmark" : ""
                                    )
                                }
                            }
                        } label: {
                            FilterChip(
                                title: selectedFilter.rawValue,
                                icon: "sparkles",
                                isActive: selectedFilter != .all
                            )
                        }
                    }
                    
                    Menu {
                        ForEach(DiscoverView.SortOption.allCases, id: \.self) { sort in
                            Button(action: { sortOption = sort }) {
                                Label(
                                    sort.rawValue,
                                    systemImage: sortOption == sort ? "checkmark" : ""
                                )
                            }
                        }
                    } label: {
                        FilterChip(
                            title: "Sort: \(sortOption.rawValue)",
                            icon: "arrow.up.arrow.down",
                            isActive: true
                        )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .background(DesignSystem.Colors.cardBackground.opacity(0.5))
    }
}

struct FilterChip: View {
    let title: String
    let icon: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
            
            Text(title)
                .font(DesignSystem.Typography.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(isActive ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                .fill(isActive ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.textTertiary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                        .stroke(isActive ? DesignSystem.Colors.primary : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct ModernCoffeeShopDiscoveryCard: View {
    let coffeeShop: CoffeeShop
    let onTap: () -> Void
    let onVisit: () -> Void
    let onDismiss: () -> Void
    
    @State private var isPressed = false
    @State private var showVisitAdded = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.secondary.opacity(0.2), DesignSystem.Colors.secondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                        
                        Text(coffeeShop.emoji)
                            .font(.system(size: 36))
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        HStack {
                            Text(coffeeShop.name)
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let badge = coffeeShop.newnessBadge {
                                NewnessBadge(text: badge)
                            }
                        }
                        
                        Text(coffeeShop.address)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .lineLimit(2)
                        
                        HStack(spacing: DesignSystem.Spacing.md) {
                            if let rating = coffeeShop.rating {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", rating))
                                        .font(DesignSystem.Typography.caption)
                                        .fontWeight(.semibold)
                                }
                            }
                            
                            if let reviewCount = coffeeShop.reviewCount {
                                Text("\(reviewCount) reviews")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                        }
                    }
                }
                .padding(DesignSystem.Spacing.md)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Button(action: {
                        withAnimation(DesignSystem.Animation.spring) {
                            showVisitAdded = true
                            onVisit()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showVisitAdded = false
                        }
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: showVisitAdded ? "checkmark" : "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                            Text(showVisitAdded ? "Added!" : "Add Visit")
                                .font(DesignSystem.Typography.callout)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            LinearGradient(
                                colors: showVisitAdded ? 
                                    [DesignSystem.Colors.success, DesignSystem.Colors.success] :
                                    [DesignSystem.Colors.gradientStart, DesignSystem.Colors.gradientEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(DesignSystem.CornerRadius.small)
                    }
                    .disabled(showVisitAdded)
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .fill(DesignSystem.Colors.textTertiary.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.bottom, DesignSystem.Spacing.md)
            }
            .cardStyle()
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = pressing
            }
        } perform: {}
    }
}

struct NewnessBadge: View {
    let text: String
    
    var badgeColor: Color {
        switch text {
        case "NEW!": return .red
        case "BRAND NEW": return .purple
        case "JUST OPENED": return DesignSystem.Colors.secondary
        case "RECENTLY OPENED": return .blue
        default: return .gray
        }
    }
    
    var body: some View {
        Text(text)
            .font(DesignSystem.Typography.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(badgeColor)
            )
    }
}

struct DiscoverEmptyStateView: View {
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "location.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(errorMessage != nil ? "Error" : "No coffee shops found")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(errorMessage != nil ? .red : DesignSystem.Colors.textPrimary)
                
                Text(errorMessage ?? "Try discovering in a different area or check back later!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(errorMessage != nil ? .red : DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

struct CoffeeShopDetailSheet: View {
    let coffeeShop: CoffeeShop
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [DesignSystem.Colors.secondary.opacity(0.2), DesignSystem.Colors.secondary.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Text(coffeeShop.emoji)
                            .font(.system(size: 60))
                    }
                    .padding(.top, DesignSystem.Spacing.xl)
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text(coffeeShop.name)
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if let badge = coffeeShop.newnessBadge {
                            NewnessBadge(text: badge)
                        }
                    }
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        if let rating = coffeeShop.rating, let reviewCount = coffeeShop.reviewCount {
                            HStack(spacing: DesignSystem.Spacing.lg) {
                                VStack {
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                        Text(String(format: "%.1f", rating))
                                            .font(DesignSystem.Typography.title2)
                                            .fontWeight(.bold)
                                    }
                                    Text("Rating")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                
                                Divider()
                                    .frame(height: 40)
                                
                                VStack {
                                    Text("\(reviewCount)")
                                        .font(DesignSystem.Typography.title2)
                                        .fontWeight(.bold)
                                    Text("Reviews")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(DesignSystem.Colors.textTertiary.opacity(0.05))
                            )
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Label(coffeeShop.address, systemImage: "location.fill")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        VStack(spacing: DesignSystem.Spacing.md) {
                            Button(action: {}) {
                                Label("Add Visit", systemImage: "plus.circle.fill")
                            }
                            .primaryButtonStyle()
                            
                            HStack(spacing: DesignSystem.Spacing.sm) {
                                Button(action: {}) {
                                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                                }
                                .secondaryButtonStyle()
                                
                                Button(action: {}) {
                                    Label("Share", systemImage: "square.and.arrow.up")
                                }
                                .secondaryButtonStyle()
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.top, DesignSystem.Spacing.md)
                    }
                }
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
            .background(DesignSystem.Colors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.primary)
                }
            }
        }
    }
}

#Preview {
    DiscoverView()
}