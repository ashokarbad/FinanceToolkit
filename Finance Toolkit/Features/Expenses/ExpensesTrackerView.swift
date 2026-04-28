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

// MARK: - SwiftUI view → UIImage helper
@MainActor
private func renderSwiftUIView<V: View>(_ view: V, size: CGSize) -> UIImage {
    let controller = UIHostingController(rootView: view.frame(width: size.width, height: size.height))
    controller.view.bounds = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .white
    controller.overrideUserInterfaceStyle = .light
    controller.view.layoutIfNeeded()
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
}

// MARK: - Expense PDF Generator
@MainActor
private func generateExpensesPDF(
    monthLabel: String,
    grandTotal: Double,
    categoryTotals: [(category: String, total: Double, color: Color)],
    entries: [ExpenseEntry],
    currency: String,
    chartView: some View
) -> URL? {
    let pageW: CGFloat = 595  // A4
    let pageH: CGFloat = 842
    let margin: CGFloat = 50
    let topMarginNewPage: CGFloat = 60
    let contentW = pageW - margin * 2

    let pdfURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("Expenses_\(monthLabel.replacingOccurrences(of: " ", with: "_")).pdf")

    UIGraphicsBeginPDFContextToFile(pdfURL.path, CGRect(x: 0, y: 0, width: pageW, height: pageH), nil)
    UIGraphicsBeginPDFPage()

    guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
    var y: CGFloat = topMarginNewPage

    // --- Title ---
    let titleAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .bold),
        .foregroundColor: UIColor(Color.navy)
    ]
    let title = NSAttributedString(string: "Monthly Expenses Report", attributes: titleAttr)
    title.draw(at: CGPoint(x: margin, y: y))
    y += 30

    // --- Subtitle: month + total ---
    let subAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel
    ]
    let sub = NSAttributedString(string: monthLabel, attributes: subAttr)
    sub.draw(at: CGPoint(x: margin, y: y))

    let totalAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14, weight: .bold),
        .foregroundColor: UIColor(Color.navy)
    ]
    let totalStr = NSAttributedString(string: "Total: \(grandTotal.formatted(.currency(code: currency)))", attributes: totalAttr)
    let totalSize = totalStr.size()
    totalStr.draw(at: CGPoint(x: pageW - margin - totalSize.width, y: y))
    y += 28

    // --- Separator ---
    ctx.setStrokeColor(UIColor.separator.cgColor)
    ctx.setLineWidth(0.5)
    ctx.move(to: CGPoint(x: margin, y: y))
    ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
    ctx.strokePath()
    y += 16

    // --- Chart image ---
    let chartW: CGFloat = 280
    let chartH: CGFloat = 280
    let chartImage = renderSwiftUIView(chartView, size: CGSize(width: chartW, height: chartH))
    let chartRect = CGRect(x: margin + (contentW - chartW) / 2, y: y, width: chartW, height: chartH)
    chartImage.draw(in: chartRect)
    y += chartH + 16

    // --- Category breakdown table ---
    let headerAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .bold),
        .foregroundColor: UIColor(Color.navy)
    ]
    let cellAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .regular),
        .foregroundColor: UIColor.label
    ]
    let cellBoldAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: UIColor.label
    ]
    let pctAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel
    ]

    // Table header
    let col1X = margin
    let col2X = margin + contentW * 0.55
    let col3X = margin + contentW * 0.80

    NSAttributedString(string: "Category", attributes: headerAttr).draw(at: CGPoint(x: col1X, y: y))
    NSAttributedString(string: "Amount", attributes: headerAttr).draw(at: CGPoint(x: col2X, y: y))
    NSAttributedString(string: "%", attributes: headerAttr).draw(at: CGPoint(x: col3X, y: y))
    y += 18

    ctx.setStrokeColor(UIColor.separator.cgColor)
    ctx.move(to: CGPoint(x: margin, y: y))
    ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
    ctx.strokePath()
    y += 6

    for item in categoryTotals {
        if y > pageH - 80 {
            UIGraphicsBeginPDFPage()
            y = topMarginNewPage
        }
        let pct = grandTotal > 0 ? item.total / grandTotal * 100 : 0

        // Color dot
        ctx.setFillColor(UIColor(item.color).cgColor)
        ctx.fillEllipse(in: CGRect(x: col1X, y: y + 3, width: 8, height: 8))

        NSAttributedString(string: item.category, attributes: cellAttr)
            .draw(at: CGPoint(x: col1X + 14, y: y))
        NSAttributedString(string: item.total.formatted(.currency(code: currency)), attributes: cellBoldAttr)
            .draw(at: CGPoint(x: col2X, y: y))
        NSAttributedString(string: String(format: "%.1f%%", pct), attributes: pctAttr)
            .draw(at: CGPoint(x: col3X, y: y))
        y += 20
    }

    y += 12
    ctx.setStrokeColor(UIColor.separator.cgColor)
    ctx.move(to: CGPoint(x: margin, y: y))
    ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
    ctx.strokePath()
    y += 16

    // --- Recent entries ---
    if !entries.isEmpty {
        NSAttributedString(string: "Recent Entries", attributes: [
            .font: UIFont.systemFont(ofSize: 13, weight: .bold),
            .foregroundColor: UIColor(Color.navy)
        ]).draw(at: CGPoint(x: margin, y: y))
        y += 22

        let dateCol = margin
        let catCol = margin + 80
        let amtCol = margin + contentW * 0.75

        NSAttributedString(string: "Date", attributes: headerAttr).draw(at: CGPoint(x: dateCol, y: y))
        NSAttributedString(string: "Category", attributes: headerAttr).draw(at: CGPoint(x: catCol, y: y))
        NSAttributedString(string: "Amount", attributes: headerAttr).draw(at: CGPoint(x: amtCol, y: y))
        y += 16

        for entry in entries.prefix(20) {
            if y > pageH - 60 {
                UIGraphicsBeginPDFPage()
                y = topMarginNewPage
            }
            NSAttributedString(string: entry.date.formatted(date: .abbreviated, time: .omitted), attributes: pctAttr)
                .draw(at: CGPoint(x: dateCol, y: y))
            NSAttributedString(string: entry.category, attributes: cellAttr)
                .draw(at: CGPoint(x: catCol, y: y))
            NSAttributedString(string: entry.amount.formatted(.currency(code: currency)), attributes: cellBoldAttr)
                .draw(at: CGPoint(x: amtCol, y: y))
            y += 18
        }
    }

    // --- Footer ---
    let footerAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: UIColor.tertiaryLabel
    ]
    let footer = NSAttributedString(string: "Generated by Finance Toolkit", attributes: footerAttr)
    footer.draw(at: CGPoint(x: margin, y: pageH - 30))

    UIGraphicsEndPDFContext()
    return pdfURL
}

// MARK: - Expenses Tracker View
struct ExpensesTrackerView: View {
    @ObservedObject private var store = ExpenseStore.shared
    @State private var showAddSheet = false
    @State private var sharePDFURL: URL?
    @State private var shareCSVURL: URL?
    @State private var selectedMonth = Date()
    @State private var deleteEntryID: UUID?
    @State private var showDeleteAlert = false

    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

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
                HStack(spacing: 14) {
                    if !currentMonthExpenses.isEmpty {
                        Menu {
                            Button { shareExpensesPDF() } label: {
                                Label("Export as PDF", systemImage: "doc.richtext")
                            }
                            Button { shareExpensesCSV() } label: {
                                Label("Export as Excel (CSV)", systemImage: "tablecells")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.navy)
                        }
                    }
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.navy)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddExpenseSheet(store: store, initialDate: selectedMonth)
        }
        .sheet(isPresented: Binding(
            get: { sharePDFURL != nil },
            set: { if !$0 { sharePDFURL = nil } }
        )) {
            if let url = sharePDFURL {
                ShareSheet(items: [url])
            }
        }
        .sheet(isPresented: Binding(
            get: { shareCSVURL != nil },
            set: { if !$0 { shareCSVURL = nil } }
        )) {
            if let url = shareCSVURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let id = deleteEntryID {
                    withAnimation { store.delete(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this expense entry?")
        }
    }

    // MARK: - Share as PDF
    private func shareExpensesPDF() {
        let chartView = ExpenseShareChart(
            categoryTotals: categoryTotals,
            grandTotal: grandTotal,
            monthLabel: selectedMonth.formatted(.dateTime.month(.wide).year()),
            currency: currency
        )
        sharePDFURL = generateExpensesPDF(
            monthLabel: selectedMonth.formatted(.dateTime.month(.wide).year()),
            grandTotal: grandTotal,
            categoryTotals: categoryTotals,
            entries: currentMonthExpenses,
            currency: currency,
            chartView: chartView
        )
    }

    // MARK: - Share as CSV
    private func shareExpensesCSV() {
        let month = selectedMonth.formatted(.dateTime.month(.wide).year())
        var csv = "Date,Category,Amount (\(currency))\n"
        for entry in currentMonthExpenses {
            let dateStr = entry.date.formatted(date: .abbreviated, time: .omitted)
            let escaped = entry.category.replacingOccurrences(of: ",", with: " ")
            csv += "\(dateStr),\(escaped),\(String(format: "%.2f", entry.amount))\n"
        }
        csv += "\nTotal,,\(String(format: "%.2f", grandTotal))\n"
        csv += "\nCategory Breakdown\nCategory,Amount,Percentage\n"
        for item in categoryTotals {
            let pct = grandTotal > 0 ? item.total / grandTotal * 100 : 0
            csv += "\(item.category),\(String(format: "%.2f", item.total)),\(String(format: "%.1f%%", pct))\n"
        }

        let fileName = "Expenses_\(month.replacingOccurrences(of: " ", with: "_")).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        shareCSVURL = url
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

                        Button {
                            deleteEntryID = entry.id
                            showDeleteAlert = true
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
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

// MARK: - Chart-only view for PDF rendering
struct ExpenseShareChart: View {
    let categoryTotals: [(category: String, total: Double, color: Color)]
    let grandTotal: Double
    let monthLabel: String
    let currency: String

    var body: some View {
        Chart(categoryTotals, id: \.category) { item in
            SectorMark(
                angle: .value("Amount", item.total),
                innerRadius: .ratio(0.55),
                angularInset: 1.5
            )
            .foregroundStyle(item.color)
            .cornerRadius(4)
        }
        .chartLegend(.hidden)
        .padding(32)
        .background(Color.white)
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseSheet: View {
    @ObservedObject var store: ExpenseStore
    var initialDate: Date = Date()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ExpenseCategory = .groceries
    @State private var amount = ""
    @State private var date = Date()

    init(store: ExpenseStore, initialDate: Date = Date()) {
        self.store = store
        self.initialDate = initialDate
        // Set default date to a day in the selected month
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: initialDate)
        let now = Date()
        let nowComponents = cal.dateComponents([.year, .month], from: now)
        // If selected month is current month, use today; otherwise use 1st of that month
        if components.year == nowComponents.year && components.month == nowComponents.month {
            _date = State(initialValue: now)
        } else {
            _date = State(initialValue: cal.date(from: components) ?? initialDate)
        }
    }

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
                        Text("Amount (\(CurrencySettings.symbol(for: CurrencySettings.selectedCode)))")
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
