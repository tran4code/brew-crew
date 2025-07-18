//
//  TimelineView.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI

struct TimelineView: View {
    @State private var visits = CoffeeVisit.sampleVisits
    @State private var showAddSheet = false
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        HeaderView()
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        if visits.isEmpty {
                            EmptyStateView()
                        } else {
                            LazyVStack(spacing: DesignSystem.Spacing.xl) {
                                ForEach(visits) { visit in
                                    ModernTimelineCard(visit: visit)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale.combined(with: .opacity)
                                        ))
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await refreshTimeline()
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(systemImage: "plus") {
                    showAddSheet = true
                }
                .padding(.bottom, 90)
                .padding(.trailing, DesignSystem.Spacing.md)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            Text("Add New Coffee Visit")
                .font(DesignSystem.Typography.title)
        }
        .id(refreshID)
    }
    
    private func refreshTimeline() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        withAnimation(DesignSystem.Animation.spring) {
            refreshID = UUID()
        }
    }
}

struct HeaderView: View {
    @State private var coffeeRotation: Double = 0
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Text("☕")
                    .font(.system(size: 34))
                    .rotationEffect(.degrees(coffeeRotation))
                    .onAppear {
                        withAnimation(
                            .linear(duration: 20)
                            .repeatForever(autoreverses: false)
                        ) {
                            coffeeRotation = 360
                        }
                    }
                
                Text("Brew Crew")
                    .font(DesignSystem.Typography.largeTitle)
                    .foregroundColor(DesignSystem.Colors.primary)
            }
            
            Text("Coffee Adventures with Friends")
                .font(DesignSystem.Typography.subheadline)
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "cup.and.saucer")
                .font(.system(size: 80))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text("No coffee visits yet")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Start your coffee journey by checking in at your favorite spot!")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ModernTimelineCard: View {
    let visit: CoffeeVisit
    @State private var isExpanded = false
    @State private var showActions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                ModernAvatarView(user: visit.user)
                    .frame(width: 56, height: 56)
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack {
                        Text(visit.user.name)
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        if visit.user.isOnline {
                            Circle()
                                .fill(DesignSystem.Colors.success)
                                .frame(width: 8, height: 8)
                        }
                        
                        Spacer()
                        
                        Text(visit.timeAgo)
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(visit.coffeeShop.emoji)
                            .font(.system(size: 20))
                        
                        Text(visit.coffeeShop.name)
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(DesignSystem.Colors.secondary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(visit.order)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                
                HStack {
                    StarRatingView(rating: visit.rating)
                    
                    Spacer()
                    
                    Text(visit.emoji)
                        .font(.system(size: 24))
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        if let photo = visit.photoURL {
                            AsyncImage(url: URL(string: photo)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .clipped()
                                    .cornerRadius(DesignSystem.CornerRadius.medium)
                            } placeholder: {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                                    .fill(DesignSystem.Colors.textTertiary.opacity(0.2))
                                    .frame(height: 200)
                                    .overlay(
                                        ProgressView()
                                            .tint(DesignSystem.Colors.textSecondary)
                                    )
                            }
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.lg) {
                            ActionButton(icon: "heart", count: 12, isActive: false) {}
                            ActionButton(icon: "bubble.left", count: 3, isActive: false) {}
                            ActionButton(icon: "arrow.turn.up.right", count: 0, isActive: false) {}
                            Spacer()
                            ActionButton(icon: "bookmark", count: 0, isActive: false) {}
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.8).combined(with: .opacity)
                    ))
                }
            }
            .padding(.bottom, DesignSystem.Spacing.md)
        }
        .cardStyle()
        .onTapGesture {
            withAnimation(DesignSystem.Animation.spring) {
                isExpanded.toggle()
            }
        }
    }
}

struct ModernAvatarView: View {
    let user: User
    
    var body: some View {
        ZStack {
            Circle()
                .fill(user.gradient)
            
            Text(user.avatar.avatarEmoji)
                .font(.system(size: 28))
            
            if user.avatar.accessory != .none {
                Text(user.avatar.accessory.emoji)
                    .font(.system(size: 12))
                    .offset(x: 12, y: -12)
            }
        }
    }
}

struct StarRatingView: View {
    let rating: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundColor(star <= rating ? .yellow : DesignSystem.Colors.textTertiary)
                    .font(.system(size: 14))
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: isActive ? "\(icon).fill" : icon)
                    .font(.system(size: 18))
                    .foregroundColor(isActive ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                
                if count > 0 {
                    Text("\(count)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TimelineView()
}