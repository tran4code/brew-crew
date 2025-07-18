//
//  ExploreView.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI
import MapKit

struct ExploreView: View {
    @EnvironmentObject var databaseManager: CoffeeShopDatabaseManager
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.7796, longitude: -78.6382), // Raleigh, NC
        span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3) // Wider view to show Triangle area
    )
    @State private var selectedShop: CoffeeShop?
    @State private var showListView = false
    @State private var mapStyle = 0
    @State private var showPopulateAlert = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ModernMapView(
                        region: $region,
                        coffeeShops: databaseManager.coffeeShops,
                        selectedShop: $selectedShop,
                        mapStyle: mapStyle
                    )
                    .ignoresSafeArea(edges: .top)
                    
                    VStack(spacing: 0) {
                        MapControlsView(
                            showListView: $showListView,
                            mapStyle: $mapStyle,
                            coffeeShopCount: databaseManager.coffeeShops.count,
                            onPopulate: {
                                showPopulateAlert = true
                            },
                            isLoading: databaseManager.isLoading
                        )
                        
                        if showListView {
                            ScrollView {
                                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                                    ForEach(databaseManager.coffeeShops) { shop in
                                        ModernCoffeeShopCard(
                                            shop: shop,
                                            isSelected: selectedShop?.id == shop.id
                                        ) {
                                            withAnimation(DesignSystem.Animation.spring) {
                                                selectedShop = shop
                                                region.center = shop.location
                                                region.span = MKCoordinateSpan(
                                                    latitudeDelta: 0.05,
                                                    longitudeDelta: 0.05
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .frame(height: 300)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .bottom).combined(with: .opacity)
                            ))
                        }
                    }
                }
                
                if let selected = selectedShop {
                    VStack {
                        Spacer()
                        SelectedShopDetailView(shop: selected) {
                            withAnimation(DesignSystem.Animation.standard) {
                                selectedShop = nil
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .padding(.bottom, showListView ? 316 : 80)
                    }
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }
            }
            .navigationBarHidden(true)
        }
        .alert("Populate Database", isPresented: $showPopulateAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Populate") {
                Task {
                    await databaseManager.populateDatabase(
                        around: region.center,
                        radius: 15000
                    )
                }
            }
        } message: {
            Text("This will fetch all coffee shops and bakeries within 15km and save them to your local database. This may take a moment.")
        }
        .sheet(isPresented: $showSettings) {
            DatabaseSettingsView()
                .environmentObject(databaseManager)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(DesignSystem.Spacing.md)
                    .background(
                        Circle()
                            .fill(DesignSystem.Colors.cardBackground)
                            .shadow(
                                color: DesignSystem.Colors.cardShadow,
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                    )
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
}

struct ModernMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let coffeeShops: [CoffeeShop]
    @Binding var selectedShop: CoffeeShop?
    let mapStyle: Int
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = false
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.setRegion(region, animated: true)
        
        switch mapStyle {
        case 0:
            mapView.mapType = .standard
        case 1:
            mapView.mapType = .hybrid
        case 2:
            mapView.mapType = .satellite
        default:
            mapView.mapType = .standard
        }
        
        let currentAnnotations = mapView.annotations.compactMap { $0 as? CoffeeShopAnnotation }
        let currentIds = Set(currentAnnotations.map { $0.shop.id })
        let newIds = Set(coffeeShops.map { $0.id })
        
        if currentIds != newIds {
            mapView.removeAnnotations(mapView.annotations)
            let annotations = coffeeShops.map { CoffeeShopAnnotation(shop: $0) }
            mapView.addAnnotations(annotations)
        }
        
        if let selected = selectedShop {
            if let annotation = mapView.annotations.first(where: { ($0 as? CoffeeShopAnnotation)?.shop.id == selected.id }) {
                mapView.selectAnnotation(annotation, animated: true)
            }
        } else {
            mapView.selectedAnnotations.forEach { mapView.deselectAnnotation($0, animated: true) }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: ModernMapView
        
        init(_ parent: ModernMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let shopAnnotation = annotation as? CoffeeShopAnnotation else { return nil }
            
            let identifier = "CoffeeShop"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            }
            
            let isSelected = parent.selectedShop?.id == shopAnnotation.shop.id
            let pinView = ModernMapPin(shop: shopAnnotation.shop, isSelected: isSelected)
            let hostingController = UIHostingController(rootView: pinView)
            hostingController.view.backgroundColor = .clear
            hostingController.view.frame = CGRect(x: -30, y: -30, width: 60, height: 60)
            
            annotationView?.subviews.forEach { $0.removeFromSuperview() }
            annotationView?.addSubview(hostingController.view)
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let shopAnnotation = view.annotation as? CoffeeShopAnnotation else { return }
            withAnimation(DesignSystem.Animation.spring) {
                parent.selectedShop = shopAnnotation.shop
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            withAnimation(DesignSystem.Animation.standard) {
                parent.selectedShop = nil
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            parent.region = mapView.region
        }
    }
}

class CoffeeShopAnnotation: NSObject, MKAnnotation {
    let shop: CoffeeShop
    var coordinate: CLLocationCoordinate2D { shop.location }
    
    init(shop: CoffeeShop) {
        self.shop = shop
        super.init()
    }
}

struct ModernMapPin: View {
    let shop: CoffeeShop
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isSelected ? 
                            [DesignSystem.Colors.primary, DesignSystem.Colors.secondary] :
                            [DesignSystem.Colors.secondary.opacity(0.8), DesignSystem.Colors.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                .shadow(
                    color: DesignSystem.Colors.secondary.opacity(0.3),
                    radius: isSelected ? 8 : 4,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
            
            Text(shop.emoji)
                .font(.system(size: isSelected ? 24 : 20))
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(DesignSystem.Animation.spring, value: isSelected)
    }
}

struct MapControlsView: View {
    @Binding var showListView: Bool
    @Binding var mapStyle: Int
    let coffeeShopCount: Int
    let onPopulate: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DesignSystem.Colors.textTertiary.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, DesignSystem.Spacing.sm)
            
            HStack {
                Button(action: {
                    withAnimation(DesignSystem.Animation.spring) {
                        showListView.toggle()
                    }
                }) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: showListView ? "map.fill" : "list.bullet")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text(showListView ? "Map View" : "List View")
                            .font(DesignSystem.Typography.callout)
                        
                        Text("(\(coffeeShopCount))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .foregroundColor(DesignSystem.Colors.primary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(
                        Capsule()
                            .fill(DesignSystem.Colors.primary.opacity(0.1))
                    )
                }
                
                Spacer()
                
                Button(action: onPopulate) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(DesignSystem.Colors.primary)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                
                Picker("Map Style", selection: $mapStyle) {
                    Image(systemName: "map").tag(0)
                    Image(systemName: "globe").tag(1)
                    Image(systemName: "antenna.radiowaves.left.and.right").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(
            Material.ultraThinMaterial
                .opacity(0.98)
        )
    }
}

struct ModernCoffeeShopCard: View {
    let shop: CoffeeShop
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                        .frame(width: 56, height: 56)
                    
                    Text(shop.emoji)
                        .font(.system(size: 28))
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(shop.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text(shop.address)
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        StarRatingView(rating: Int(shop.rating ?? 0))
                        
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        Text("\(shop.reviewCount ?? 0) reviews")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(isSelected ? DesignSystem.Colors.primary.opacity(0.1) : DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(
                color: DesignSystem.Colors.cardShadow,
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SelectedShopDetailView: View {
    let shop: CoffeeShop
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Text(shop.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(shop.name)
                        .font(DesignSystem.Typography.title3)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        StarRatingView(rating: Int(shop.rating ?? 0))
                        Text("(\(shop.reviewCount ?? 0))")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                }
            }
            
            Text(shop.address)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textSecondary)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: {}) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond")
                }
                .primaryButtonStyle()
                
                Button(action: {}) {
                    Label("Call", systemImage: "phone")
                }
                .secondaryButtonStyle()
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .glassStyle()
    }
}

#Preview {
    ExploreView()
}