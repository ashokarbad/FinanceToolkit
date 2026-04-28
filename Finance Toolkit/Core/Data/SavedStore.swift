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
    /// User-added custom note with formatting
    var userNote: StyledNote?

    struct ResultEntry: Codable, Equatable {
        var label: String
        var value: String
        var isHighlight: Bool
    }
}

// MARK: - Styled note model
struct StyledNote: Codable, Equatable {
    var text: String = ""
    var fontSize: Int = 14 // 12, 14, 16, 18, 20
    var isBold: Bool = false
    var isItalic: Bool = false
    var colorHex: String = "#185FA5" // navy default

    var uiFont: UIFont {
        let size = CGFloat(fontSize)
        var font = UIFont.systemFont(ofSize: size, weight: isBold ? .bold : .regular)
        if isItalic {
            let descriptor = font.fontDescriptor.withSymbolicTraits(.traitItalic) ?? font.fontDescriptor
            font = UIFont(descriptor: descriptor, size: size)
        }
        return font
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

    func updateNote(id: UUID, note: StyledNote) {
        if let idx = calculations.firstIndex(where: { $0.id == id }) {
            calculations[idx].userNote = note
            persist()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(calculations) {
            UserDefaults.standard.set(data, forKey: calcsKey)
        }
    }
}
// MARK: - Quick Note model
struct QuickNote: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String = ""
    var style: StyledNote = StyledNote()
    var date: Date = Date()
}

// MARK: - Notes Store
final class NoteStore: ObservableObject {
    static let shared = NoteStore()

    @Published private(set) var notes: [QuickNote] = []
    private let storeKey = "quickNotes"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([QuickNote].self, from: data) {
            notes = decoded
        }
    }

    func add(_ note: QuickNote) {
        notes.insert(note, at: 0)
        persist()
    }

    func update(_ note: QuickNote) {
        if let idx = notes.firstIndex(where: { $0.id == note.id }) {
            notes[idx] = note
            persist()
        }
    }

    func delete(id: UUID) {
        notes.removeAll { $0.id == id }
        persist()
    }

    func delete(at offsets: IndexSet) {
        notes.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}

