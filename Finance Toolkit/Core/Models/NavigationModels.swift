// NavigationModels.swift
// Finance Toolkit — navigation-level models

import SwiftUI

// MARK: - CalcItem
struct CalcItem: Identifiable {
    let id       = UUID()
    let title:       String
    let subtitle:    String
    let icon:        String
    let color:       Color
    let bgColor:     Color
    let destination: AnyView
}

// MARK: - Sidebar destinations
enum SidebarDestination: String, CaseIterable, Identifiable {
    case calculators = "Calculators"
    case dashboard   = "Dashboard"
    case saved       = "Saved"
    case expenses    = "Expenses"
    case outflow     = "Monthly Outflow"
    case tips        = "Tips & FAQ"
    case profile     = "Profile"
    case settings    = "Settings"
    case feedback    = "Feedback"
    case about       = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .calculators: return "square.grid.2x2.fill"
        case .dashboard:   return "chart.bar.fill"
        case .saved:       return "bookmark.fill"
        case .expenses:    return "chart.pie.fill"
        case .outflow:     return "arrow.up.forward.circle.fill"
        case .tips:        return "lightbulb.fill"
        case .profile:     return "person.crop.circle.fill"
        case .settings:    return "gearshape.fill"
        case .feedback:    return "envelope.fill"
        case .about:       return "info.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .calculators: return .navy
        case .dashboard:   return .teal
        case .saved:       return .gold
        case .expenses:    return Color(hex: "#E87D2B")
        case .outflow:     return .navy
        case .tips:        return Color(hex: "#E87D2B")
        case .profile, .settings, .feedback, .about: return Color(hex: "#888888")
        }
    }
}
