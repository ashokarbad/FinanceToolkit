// ExpensesTrackerView.swift
// Finance Toolkit — monthly expense tracker with chart visualization

import SwiftUI
import Charts
import Combine

// MARK: - Expense model
struct ExpenseEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var category: String
    var amount: Double
    var date: Date
}

// MARK: - Expense categories
enum ExpenseCategory: String, CaseIterable {
    case rent = "Rent"
    case groceries = "Groceries"
    case utilities = "Utilities"
    case transport = "Transport"
    case dining = "Dining Out"
    case shopping = "Shopping"
    case health = "Health"
    case education = "Education"
    case entertainment = "Entertainment"
    case insurance = "Insurance"
    case other = "Other"

    var icon: String {
        switch self {
        case .rent:          return "house.fill"
        case .groceries:     return "cart.fill"
        case .utilities:     return "bolt.fill"
        case .transport:     return "car.fill"
        case .dining:        return "fork.knife"
        case .shopping:      return "bag.fill"
        case .health:        return "heart.fill"
        case .education:     return "book.fill"
        case .entertainment: return "tv.fill"
        case .insurance:     return "shield.fill"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .rent:          return .navy
        case .groceries:     return .teal
        case .utilities:     return Color(hex: "#E87D2B")
        case .transport:     return .gold
        case .dining:        return Color(hex: "#D44848")
        case .shopping:      return Color(hex: "#8B5CF6")
        case .health:        return Color(hex: "#EC4899")
        case .education:     return Color(hex: "#3B82F6")
        case .entertainment: return Color(hex: "#6366F1")
        case .insurance:     return Color(hex: "#14B8A6")
        case .other:         return Color(hex: "#888888")
        }
    }
}

// MARK: - Expense Store
final class ExpenseStore: ObservableObject {
    static let shared = ExpenseStore()

    @Published private(set) var expenses: [ExpenseEntry] = []
    private let storeKey = "monthlyExpenses"

    private init() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([ExpenseEntry].self, from: data) {
            expenses = decoded
        }
    }

    func add(_ entry: ExpenseEntry) {
        expenses.insert(entry, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        expenses.remove(atOffsets: offsets)
        persist()
    }

    func delete(id: UUID) {
        expenses.removeAll { $0.id == id }
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(expenses) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
}

// MARK: - Expenses Tracker View
struct ExpensesTrackerView: View {
    @ObservedObject private var store = ExpenseStore.shared
    @State private var showAddSheet = false
    @State private var selectedMonth = Date()

    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var currentMonthExpenses: [ExpenseEntry] {
        let cal = Calendar.current
        return store.expenses.filter {
            cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var categoryTotals: [(category: String, total: Double, color: Color)] {
        var dict: [String: Double] = [:]
        for exp in currentMonthExpenses {
            dict[exp.category, default: 0] += exp.amount
        }
        return dict.sorted { $0.value > $1.value }.map { key, val in
            let cat = ExpenseCategory(rawValue: key) ?? .other
            return (category: key, total: val, color: cat.color)
        }
    }

    private var grandTotal: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Month selector
                monthPicker

                // Total card
                totalCard

                // Pie chart
                if !categoryTotals.isEmpty {
                    chartSection
                }

                // Category breakdown
                if !categoryTotals.isEmpty {
                    breakdownSection
                }

                // Recent entries
                recentEntriesSection
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
            AddExpenseSheet(store: store)
        }
    }

    // MARK: - Month Picker
    private var monthPicker: some View {
        HStack {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.bold())
                    .foregroundStyle(Color.navy)
            }

            Spacer()
            Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                .font(.subheadline.weight(.semibold))
            Spacer()

            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(Color.navy)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Total Card
    private var totalCard: some View {
        VStack(spacing: 8) {
            Text("Total Expenses")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(grandTotal.formatted(.currency(code: currency)))
                .font(.title.bold())
                .foregroundStyle(Color.navy)
                .contentTransition(.numericText())
            Text("\(currentMonthExpenses.count) entries this month")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.2), lineWidth: 0.5))
    }

    // MARK: - Chart
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Breakdown")
                .font(.headline)
                .foregroundStyle(Color.navy)

            Chart(categoryTotals, id: \.category) { item in
                SectorMark(
                    angle: .value("Amount", item.total),
                    innerRadius: .ratio(0.55),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .frame(height: 220)
            .chartBackground { proxy in
                VStack(spacing: 2) {
                    Text(grandTotal.formatted(.currency(code: currency)))
                        .font(.system(size: 14, weight: .bold))
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Breakdown
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("By Category")
                .font(.headline)
                .foregroundStyle(Color.navy)

            ForEach(categoryTotals, id: \.category) { item in
                let cat = ExpenseCategory(rawValue: item.category) ?? .other
                let pct = grandTotal > 0 ? item.total / grandTotal : 0
                HStack(spacing: 12) {
                    Image(systemName: cat.icon)
                        .font(.system(size: 12))
                        .foregroundStyle(item.color)
                        .frame(width: 28, height: 28)
                        .background(RoundedRectangle(cornerRadius: 7).fill(item.color.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.category)
                            .font(.subheadline.weight(.medium))
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(item.color.opacity(0.25))
                                .frame(width: geo.size.width * pct, height: 4)
                        }
                        .frame(height: 4)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.total.formatted(.currency(code: currency)))
                            .font(.caption.weight(.semibold))
                        Text(pct.formatted(.percent.precision(.fractionLength(1))))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
    }

    // MARK: - Recent Entries
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Entries")
                .font(.headline)
                .foregroundStyle(Color.navy)

            if currentMonthExpenses.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray")
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No expenses recorded this month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button("Add Expense") { showAddSheet = true }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.navy)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(currentMonthExpenses.prefix(10)) { entry in
                    let cat = ExpenseCategory(rawValue: entry.category) ?? .other
                    HStack(spacing: 12) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 11))
                            .foregroundStyle(cat.color)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(cat.color.opacity(0.12)))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.category)
                                .font(.subheadline.weight(.medium))
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(entry.amount.formatted(.currency(code: currency)))
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseSheet: View {
    @ObservedObject var store: ExpenseStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ExpenseCategory = .groceries
    @State private var amount = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SectionHeader(systemImage: "plus.circle.fill", title: "New Expense", color: .navy)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Details") {
                    HStack {
                        Text("Amount (₹)")
                        Spacer()
                        TextField("0", text: $amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    Button {
                        guard let amt = Double(amount), amt > 0 else { return }
                        let entry = ExpenseEntry(category: selectedCategory.rawValue, amount: amt, date: date)
                        store.add(entry)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add Expense", systemImage: "plus.circle.fill")
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
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
