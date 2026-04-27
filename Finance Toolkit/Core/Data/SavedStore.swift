// SavedStore.swift
// Finance Toolkit — persists saved calculator snapshots

import Foundation
import Combine
import SwiftUI

// MARK: - SavedCalculation model
struct SavedCalculation: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var calculatorTitle: String
    var icon: String
    var date: Date
    var note: String
    /// Key-value pairs of result labels → formatted strings
    var results: [ResultEntry]

    struct ResultEntry: Codable, Equatable {
        var label: String
        var value: String
        var isHighlight: Bool
    }
}

// MARK: - SavedStore
final class SavedStore: ObservableObject {
    static let shared = SavedStore()

    // Starred calculator names (for star-toggle in list)
    @Published private(set) var savedIDs: Set<String> = []

    // Full saved calculation snapshots
    @Published private(set) var calculations: [SavedCalculation] = []

    private let idsKey = "savedCalculatorIDs"
    private let calcsKey = "savedCalculations"

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: idsKey) ?? []
        savedIDs = Set(stored)
        if let data = UserDefaults.standard.data(forKey: calcsKey),
           let decoded = try? JSONDecoder().decode([SavedCalculation].self, from: data) {
            calculations = decoded
        }
    }

    // MARK: - Star toggle
    func toggle(_ id: String) {
        if savedIDs.contains(id) { savedIDs.remove(id) }
        else { savedIDs.insert(id) }
        UserDefaults.standard.set(Array(savedIDs), forKey: idsKey)
    }

    func isSaved(_ id: String) -> Bool { savedIDs.contains(id) }

    // MARK: - Calculation snapshots
    func save(calculation: SavedCalculation) {
        calculations.insert(calculation, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        calculations.remove(atOffsets: offsets)
        persist()
    }

    func delete(id: UUID) {
        calculations.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(calculations) {
            UserDefaults.standard.set(data, forKey: calcsKey)
        }
    }
}
