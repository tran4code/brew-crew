//
//  AvatarStyle.swift
//  BrewCrew
//
//  Created by Keith Tran on 7/11/25.
//

import Foundation
import SwiftUI

struct AvatarStyle: Codable {
    let skinTone: SkinTone
    let hairStyle: HairStyle
    let hairColor: HairColor
    let clothing: ClothingStyle
    let clothingColor: ClothingColor
    let accessory: Accessory
    
    enum SkinTone: String, CaseIterable, Codable {
        case light = "🏻"
        case mediumLight = "🏼"
        case medium = "🏽"
        case mediumDark = "🏾"
        case dark = "🏿"
    }
    
    enum HairStyle: String, CaseIterable, Codable {
        case short, bob, long, curly, buzz, ponytail
        
        var emoji: String {
            switch self {
            case .short: return "👨‍🦱"
            case .bob: return "👩‍🦱"
            case .long: return "👩‍🦳"
            case .curly: return "👨‍🦱"
            case .buzz: return "👨‍🦲"
            case .ponytail: return "👩‍🦰"
            }
        }
    }
    
    enum HairColor: String, CaseIterable, Codable {
        case black, brown, blonde, red, gray
        
        var color: Color {
            switch self {
            case .black: return Color.black
            case .brown: return Color.brown
            case .blonde: return Color.yellow.opacity(0.7)
            case .red: return Color.red.opacity(0.8)
            case .gray: return Color.gray
            }
        }
    }
    
    enum ClothingStyle: String, CaseIterable, Codable {
        case tshirt, hoodie, dress, casual, business, sweater
        
        var baseEmoji: String {
            switch self {
            case .tshirt: return "👕"
            case .hoodie: return "🧥"
            case .dress: return "👗"
            case .casual: return "👔"
            case .business: return "🤵"
            case .sweater: return "🧥"
            }
        }
    }
    
    enum ClothingColor: String, CaseIterable, Codable {
        case red, blue, green, purple, orange, pink, gray, black, white
        
        var color: Color {
            switch self {
            case .red: return Color.red
            case .blue: return Color.blue
            case .green: return Color.green
            case .purple: return Color.purple
            case .orange: return Color.orange
            case .pink: return Color.pink
            case .gray: return Color.gray
            case .black: return Color.black
            case .white: return Color.white
            }
        }
    }
    
    enum Accessory: String, CaseIterable, Codable {
        case none, glasses, hat, earrings, watch, necklace
        
        var emoji: String {
            switch self {
            case .none: return ""
            case .glasses: return "👓"
            case .hat: return "🧢"
            case .earrings: return "👂"
            case .watch: return "⌚"
            case .necklace: return "📿"
            }
        }
    }
}

// Avatar component builder
extension AvatarStyle {
    var avatarEmoji: String {
        // Base person with skin tone
        let basePerson = "🧑" + skinTone.rawValue
        return basePerson
    }
    
    var description: String {
        "\(hairColor.rawValue.capitalized) \(hairStyle.rawValue) hair, \(clothingColor.rawValue) \(clothing.rawValue)"
    }
}