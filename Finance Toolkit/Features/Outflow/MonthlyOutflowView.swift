// MonthlyOutflowView.swift
// Finance Toolkit — combined monthly outflow calculator (EMIs + CC + others)

import SwiftUI
import Charts
import Combine

// MARK: - Outflow item model
struct OutflowItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var label: String
    var amount: Double
    var category: String   // "HomeLoan", "CarLoan", "PersonalLoan", "CreditCard", "Other"
}

// MARK: - Outflow Store
final class OutflowStore: ObservableObject {
    static let shared = OutflowStore()

    @Published private(set) var items: [OutflowItem] = []
    private let storeKey = "monthlyOutflowItems"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([OutflowItem].self, from: data) {
            items = decoded
        }
    }

    func add(_ item: OutflowItem) {
        items.append(item)
        persist()
    }

    func update(_ item: OutflowItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            persist()
        }
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}

// MARK: - Outflow categories
enum OutflowCategory: String, CaseIterable {
    case homeLoan = "Home Loan EMI"
    case carLoan = "Car Loan EMI"
    case personalLoan = "Personal Loan EMI"
    case educationLoan = "Education Loan EMI"
    case creditCard = "Credit Card Bill"
    case insurance = "Insurance Premium"
    case rent = "Rent"
    case other = "Other"

    var icon: String {
        switch self {
        case .homeLoan:      return "house.fill"
        case .carLoan:       return "car.fill"
        case .personalLoan:  return "person.fill"
        case .educationLoan: return "book.fill"
        case .creditCard:    return "creditcard.fill"
        case .insurance:     return "shield.fill"
        case .rent:          return "building.2.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .homeLoan:      return .navy
        case .carLoan:       return Color(hex: "#3B82F6")
        case .personalLoan:  return .teal
        case .educationLoan: return Color(hex: "#8B5CF6")
        case .creditCard:    return Color(hex: "#D44848")
        case .insurance:     return Color(hex: "#14B8A6")
        case .rent:          return .gold
        case .other:         return Color(hex: "#888888")
        }
    }
}

// MARK: - Monthly Outflow View
struct MonthlyOutflowView: View {
    @ObservedObject private var store = OutflowStore.shared
    @State private var showAddSheet = false

    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var totalOutflow: Double {
        store.items.reduce(0) { $0 + $1.amount }
    }

    private var groupedItems: [(category: String, items: [OutflowItem], total: Double, color: Color, icon: String)] {
        var groups: [String: [OutflowItem]] = [:]
        for item in store.items {
            groups[item.category, default: []].append(item)
        }
        return groups.sorted { $0.value.reduce(0) { $0 + $1.amount } > $1.value.reduce(0) { $0 + $1.amount } }
            .map { key, items in
                let cat = OutflowCategory(rawValue: key) ?? .other
                let total = items.reduce(0) { $0 + $1.amount }
                return (category: key, items: items, total: total, color: cat.color, icon: cat.icon)
            }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Total outflow card
                totalCard

                // Bar chart
                if !store.items.isEmpty {
                    barChartSection
                }

                // Item groups
                if !store.items.isEmpty {
                    itemsSection
                } else {
                    emptyState
                }
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.navy)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddOutflowSheet(store: store)
        }
    }

    // MARK: - Total Card
    private var totalCard: some View {
        VStack(spacing: 8) {
            Text("Total Monthly Outflow")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(totalOutflow.formatted(.currency(code: currency)))
                .font(.title.bold())
                .foregroundStyle(Color.navy)
                .contentTransition(.numericText())
            Text("\(store.items.count) items")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.2), lineWidth: 0.5))
    }

    // MARK: - Bar Chart
    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Outflow Breakdown")
                .font(.headline)
                .foregroundStyle(Color.navy)

            Chart(groupedItems, id: \.category) { group in
                BarMark(
                    x: .value("Amount", group.total),
                    y: .value("Category", group.category)
                )
                .foregroundStyle(group.color)
                .cornerRadius(4)
                .annotation(position: .trailing) {
                    Text(shortCurrency(group.total))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: CGFloat(max(groupedItems.count, 1) * 44))
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Items Section
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Outflows")
                .font(.headline)
                .foregroundStyle(Color.navy)

            ForEach(groupedItems, id: \.category) { group in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: group.icon)
                            .font(.system(size: 12))
                            .foregroundStyle(group.color)
                            .frame(width: 26, height: 26)
                            .background(RoundedRectangle(cornerRadius: 6).fill(group.color.opacity(0.12)))
                        Text(group.category)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(group.color)
                        Spacer()
                        Text(group.total.formatted(.currency(code: currency)))
                            .font(.subheadline.weight(.bold))
                    }

                    ForEach(group.items) { item in
                        HStack {
                            Text(item.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.amount.formatted(.currency(code: currency)))
                                .font(.caption.weight(.medium))

                            Button {
                                store.delete(id: item.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 34)
                    }
                }
                .padding(.vertical, 4)

                if group.category != groupedItems.last?.category {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.up.forward.circle")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No outflows added yet")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add your monthly EMIs, credit card bills, and other recurring outflows to see your total monthly commitments.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            Button("Add Outflow") { showAddSheet = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.navy)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private func shortCurrency(_ value: Double) -> String {
        if value >= 1_00_000 {
            return String(format: "₹%.1fL", value / 1_00_000)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000)
        }
        return String(format: "₹%.0f", value)
    }
}

// MARK: - Add Outflow Sheet
struct AddOutflowSheet: View {
    @ObservedObject var store: OutflowStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: OutflowCategory = .homeLoan
    @State private var label = ""
    @State private var amount = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SectionHeader(systemImage: "arrow.up.forward.circle.fill", title: "New Outflow", color: .navy)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(OutflowCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Details") {
                    HStack {
                        Text("Label")
                        Spacer()
                        TextField("e.g. SBI Home Loan", text: $label)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Amount (₹)")
                        Spacer()
                        TextField("0", text: $amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                }

                Section {
                    Button {
                        guard let amt = Double(amount), amt > 0 else { return }
                        let item = OutflowItem(
                            label: label.isEmpty ? selectedCategory.rawValue : label,
                            amount: amt,
                            category: selectedCategory.rawValue
                        )
                        store.add(item)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add Outflow", systemImage: "plus.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(Double(amount) == nil || (Double(amount) ?? 0) <= 0)
                    .tint(.navy)
                }
            }
            .keyboardDoneToolbar()
            .navigationTitle("Add Outflow")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
