//
//  Theme.swift
//  NagrikMitra2
//
//  Design system and theme
//

import SwiftUI

struct Theme {
    // Colors matching the frontend design
    struct Colors {
        static let emerald500 = Color(hex: "059669")
        static let emerald600 = Color(hex: "047857")
        static let emerald700 = Color(hex: "065F46")
        static let emerald800 = Color(hex: "065F46")
        static let emerald50 = Color(hex: "ECFDF5")
        static let emerald100 = Color(hex: "D1FAE5")
        
        static let indigo700 = Color(hex: "047857")
        static let purple700 = Color(hex: "059669")
        
        static let gray50 = Color(hex: "F9FAFB")
        static let gray100 = Color(hex: "F3F4F6")
        static let gray200 = Color(hex: "E5E7EB")
        static let gray300 = Color(hex: "D1D5DB")
        static let gray400 = Color(hex: "9CA3AF")
        static let gray500 = Color(hex: "6B7280")
        static let gray600 = Color(hex: "4B5563")
        static let gray700 = Color(hex: "374151")
        static let gray800 = Color(hex: "1F2937")
        static let gray900 = Color(hex: "111827")
        
        static let primary = emerald500
        static let primaryDark = emerald600
        static let background = gray50
        static let surface = Color.white
        static let error = Color.red
    }
    
    struct Gradients {
        static let emeraldGradient = LinearGradient(
            colors: [Colors.emerald500, Colors.emerald700],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let heroGradient = LinearGradient(
            colors: [Colors.emerald600, Colors.emerald500],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// Helper for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
