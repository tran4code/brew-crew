//
//  CrewView.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import SwiftUI

struct CrewView: View {
    @State private var friends = User.sampleUsers
    @State private var searchText = ""
    @State private var showOnlineOnly = false
    @State private var selectedUser: User?
    
    var filteredFriends: [User] {
        friends.filter { friend in
            let matchesSearch = searchText.isEmpty || friend.name.localizedCaseInsensitiveContains(searchText)
            let matchesOnline = !showOnlineOnly || friend.isOnline
            return matchesSearch && matchesOnline
        }
    }
    
    var onlineFriendsCount: Int {
        friends.filter { $0.isOnline }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignSystem.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    CrewHeaderView(
                        onlineFriendsCount: onlineFriendsCount,
                        totalFriendsCount: friends.count,
                        searchText: $searchText,
                        showOnlineOnly: $showOnlineOnly
                    )
                    
                    if filteredFriends.isEmpty {
                        CrewEmptyStateView(searchText: searchText, showOnlineOnly: showOnlineOnly)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: DesignSystem.Spacing.md) {
                                ForEach(filteredFriends) { friend in
                                    ModernCrewMemberCard(user: friend, isSelected: selectedUser?.id == friend.id) {
                                        withAnimation(DesignSystem.Animation.spring) {
                                            selectedUser = selectedUser?.id == friend.id ? nil : friend
                                        }
                                    }
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                            .padding(.bottom, 80)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .bottomTrailing) {
                FloatingActionButton(systemImage: "person.badge.plus") {
                    // Handle add friend
                }
                .padding(.bottom, 90)
                .padding(.trailing, DesignSystem.Spacing.md)
            }
        }
        .sheet(item: $selectedUser) { user in
            UserDetailSheet(user: user)
        }
    }
}

struct CrewHeaderView: View {
    let onlineFriendsCount: Int
    let totalFriendsCount: Int
    @Binding var searchText: String
    @Binding var showOnlineOnly: Bool
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Your Crew")
                        .font(DesignSystem.Typography.largeTitle)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Circle()
                                .fill(DesignSystem.Colors.success)
                                .frame(width: 8, height: 8)
                            Text("\(onlineFriendsCount) online")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.success)
                        }
                        
                        Text("•")
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        Text("\(totalFriendsCount) total")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Toggle(isOn: $showOnlineOnly) {
                    Text("Online")
                        .font(DesignSystem.Typography.caption)
                }
                .toggleStyle(ModernToggleStyle())
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.md)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                
                TextField("Search crew members...", text: $searchText)
                    .font(DesignSystem.Typography.body)
                    .focused($isSearchFocused)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(DesignSystem.Colors.textTertiary.opacity(0.1))
            )
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.sm)
        }
        .background(
            DesignSystem.Colors.cardBackground
                .shadow(
                    color: DesignSystem.Colors.cardShadow,
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
}

struct CrewEmptyStateView: View {
    let searchText: String
    let showOnlineOnly: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: showOnlineOnly ? "wifi.slash" : "person.slash")
                .font(.system(size: 60))
                .foregroundColor(DesignSystem.Colors.textTertiary)
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                Text(showOnlineOnly ? "No friends online" : "No friends found")
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(showOnlineOnly ? "Your crew members are currently offline" : "Try adjusting your search")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xl)
    }
}

struct ModernCrewMemberCard: View {
    let user: User
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var showMessageSent = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack(alignment: .topTrailing) {
                    ModernAvatarView(user: user)
                        .frame(width: 72, height: 72)
                    
                    if user.isOnline {
                        Circle()
                            .fill(DesignSystem.Colors.success)
                            .frame(width: 16, height: 16)
                            .overlay(
                                Circle()
                                    .stroke(DesignSystem.Colors.cardBackground, lineWidth: 3)
                            )
                            .offset(x: -5, y: 5)
                    }
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(user.name)
                        .font(DesignSystem.Typography.headline)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 12))
                            .foregroundColor(DesignSystem.Colors.secondary)
                        
                        Text("Last visit: Sola Coffee")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    if let lastVisit = CoffeeVisit.sampleVisits.first(where: { $0.user.id == user.id }) {
                        Text(lastVisit.timeAgo)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: DesignSystem.Spacing.sm) {
                    QuickActionButton(
                        icon: "message.fill",
                        color: .blue,
                        showSuccess: showMessageSent
                    ) {
                        withAnimation(DesignSystem.Animation.spring) {
                            showMessageSent = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showMessageSent = false
                        }
                    }
                    
                    QuickActionButton(
                        icon: "cup.and.saucer.fill",
                        color: DesignSystem.Colors.secondary,
                        showSuccess: false
                    ) {
                        // Handle coffee invite
                    }
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                            .stroke(isSelected ? DesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(
                color: DesignSystem.Colors.cardShadow,
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
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

struct QuickActionButton: View {
    let icon: String
    let color: Color
    let showSuccess: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(showSuccess ? DesignSystem.Colors.success : color)
                    .frame(width: 44, height: 44)
                
                Image(systemName: showSuccess ? "checkmark" : icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(showSuccess ? 1.2 : 1.0)
            }
        }
        .animation(DesignSystem.Animation.spring, value: showSuccess)
    }
}

struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.round)
                .fill(configuration.isOn ? DesignSystem.Colors.success : DesignSystem.Colors.textTertiary.opacity(0.3))
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 9 : -9)
                )
                .onTapGesture {
                    withAnimation(DesignSystem.Animation.quick) {
                        configuration.isOn.toggle()
                    }
                }
        }
    }
}

struct UserDetailSheet: View {
    let user: User
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    ModernAvatarView(user: user)
                        .frame(width: 120, height: 120)
                        .padding(.top, DesignSystem.Spacing.xl)
                    
                    Text(user.name)
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    HStack {
                        Circle()
                            .fill(user.isOnline ? DesignSystem.Colors.success : DesignSystem.Colors.textTertiary)
                            .frame(width: 10, height: 10)
                        Text(user.isOnline ? "Online now" : "Offline")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(user.isOnline ? DesignSystem.Colors.success : DesignSystem.Colors.textSecondary)
                    }
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Button(action: {}) {
                            Label("Send Message", systemImage: "message.fill")
                        }
                        .primaryButtonStyle()
                        
                        Button(action: {}) {
                            Label("Invite for Coffee", systemImage: "cup.and.saucer.fill")
                        }
                        .secondaryButtonStyle()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Recent Coffee Visits")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        ForEach(CoffeeVisit.sampleVisits.filter { $0.user.id == user.id }.prefix(3)) { visit in
                            HStack {
                                Text(visit.coffeeShop.emoji)
                                    .font(.system(size: 24))
                                
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                    Text(visit.coffeeShop.name)
                                        .font(DesignSystem.Typography.callout)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                    
                                    Text(visit.order)
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                }
                                
                                Spacer()
                                
                                Text(visit.timeAgo)
                                    .font(DesignSystem.Typography.caption2)
                                    .foregroundColor(DesignSystem.Colors.textTertiary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.lg)
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
    CrewView()
}