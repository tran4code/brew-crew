//
//  User.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import Foundation
import SwiftUI

struct User: Identifiable, Codable {
    let id = UUID()
    let name: String
    let avatar: AvatarStyle
    let isOnline: Bool
    let gradientColors: [String] // Color names for gradient
    
    static let sampleUsers = [
        User(
            name: "Sarah M.",
            avatar: AvatarStyle(
                skinTone: .medium,
                hairStyle: .bob,
                hairColor: .brown,
                clothing: .casual,
                clothingColor: .green,
                accessory: .none
            ),
            isOnline: true,
            gradientColors: ["purple", "blue"]
        ),
        User(
            name: "Alex K.",
            avatar: AvatarStyle(
                skinTone: .light,
                hairStyle: .short,
                hairColor: .blonde,
                clothing: .hoodie,
                clothingColor: .gray,
                accessory: .glasses
            ),
            isOnline: true,
            gradientColors: ["orange", "pink"]
        ),
        User(
            name: "Mike R.",
            avatar: AvatarStyle(
                skinTone: .light,
                hairStyle: .curly,
                hairColor: .brown,
                clothing: .tshirt,
                clothingColor: .blue,
                accessory: .hat
            ),
            isOnline: false,
            gradientColors: ["teal", "pink"]
        ),
        User(
            name: "Emma L.",
            avatar: AvatarStyle(
                skinTone: .medium,
                hairStyle: .long,
                hairColor: .black,
                clothing: .dress,
                clothingColor: .pink,
                accessory: .earrings
            ),
            isOnline: true,
            gradientColors: ["pink", "purple"]
        )
    ]
    
    var gradient: LinearGradient {
        let colors = gradientColors.map { colorName in
            switch colorName {
            case "purple": return Color.purple
            case "blue": return Color.blue
            case "orange": return Color.orange
            case "pink": return Color.pink
            case "teal": return Color.teal
            default: return Color.gray
            }
        }
        return LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}