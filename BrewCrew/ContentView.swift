//
//  ContentView.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showTabBar = true
    @Namespace private var animation
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                TimelineView()
                    .tag(0)
                
                ExploreView()
                    .tag(1)
                
                NewCoffeeShopsView()
                    .tag(2)
                
                CrewView()
                    .tag(3)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            if showTabBar {
                CustomTabBar(selectedTab: $selectedTab, animation: animation)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background(DesignSystem.Colors.background)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            withAnimation(DesignSystem.Animation.standard) {
                showTabBar = true
            }
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(
                icon: "cup.and.saucer.fill",
                title: "Timeline",
                isSelected: selectedTab == 0,
                animation: animation,
                action: { selectedTab = 0 }
            )
            
            TabBarItem(
                icon: "map.fill",
                title: "Explore",
                isSelected: selectedTab == 1,
                animation: animation,
                action: { selectedTab = 1 }
            )
            
            TabBarItem(
                icon: "sparkle.magnifyingglass",
                title: "Discover",
                isSelected: selectedTab == 2,
                animation: animation,
                action: { selectedTab = 2 }
            )
            
            TabBarItem(
                icon: "person.3.fill",
                title: "Crew",
                isSelected: selectedTab == 3,
                animation: animation,
                action: { selectedTab = 3 }
            )
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            Material.ultraThinMaterial
                .opacity(0.95)
        )
        .cornerRadius(DesignSystem.CornerRadius.xlarge)
        .shadow(
            color: DesignSystem.Colors.cardShadow,
            radius: 20,
            x: 0,
            y: -5
        )
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.bottom, DesignSystem.Spacing.sm)
    }
}

struct TabBarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let animation: Namespace.ID
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(DesignSystem.Animation.spring) {
                action()
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                
                Text(title)
                    .font(DesignSystem.Typography.caption2)
                    .foregroundColor(isSelected ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .opacity(isSelected ? 1.0 : 0.7)
                
                if isSelected {
                    Circle()
                        .fill(DesignSystem.Colors.primary)
                        .frame(width: 5, height: 5)
                        .matchedGeometryEffect(id: "indicator", in: animation)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
            withAnimation(DesignSystem.Animation.quick) {
                isPressed = pressing
            }
        } perform: {}
    }
}

#Preview {
    ContentView()
}
