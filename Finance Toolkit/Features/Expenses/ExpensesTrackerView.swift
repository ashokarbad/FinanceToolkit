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

    func update(_ entry: ExpenseEntry) {
        if let idx = expenses.firstIndex(where: { $0.id == entry.id }) {
            expenses[idx] = entry
            persist()
        }
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
        .foregroundColor: UIColor.gray
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
    ctx.setStrokeColor(UIColor.lightGray.cgColor)
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
        .foregroundColor: UIColor.darkGray
    ]
    let cellBoldAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: UIColor.black
    ]
    let pctAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: UIColor.gray
    ]

    // Table header
    let col1X = margin
    let col2X = margin + contentW * 0.55
    let col3X = margin + contentW * 0.80

    NSAttributedString(string: "Category", attributes: headerAttr).draw(at: CGPoint(x: col1X, y: y))
    NSAttributedString(string: "Amount", attributes: headerAttr).draw(at: CGPoint(x: col2X, y: y))
    NSAttributedString(string: "%", attributes: headerAttr).draw(at: CGPoint(x: col3X, y: y))
    y += 18

    ctx.setStrokeColor(UIColor.lightGray.cgColor)
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
    ctx.setStrokeColor(UIColor.lightGray.cgColor)
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
        .foregroundColor: UIColor.lightGray
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
    @State private var editingExpense: ExpenseEntry?

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

    @State private var showYearlySheet = false

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
                    Button { showYearlySheet = true } label: {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.teal)
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
        .sheet(item: $editingExpense) { expense in
            AddExpenseSheet(store: store, editingExpense: expense)
        }
        .sheet(isPresented: $showYearlySheet) {
            YearlyExpensesOverview(store: store, selectedMonth: selectedMonth, currency: currency)
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
                            editingExpense = entry
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue.opacity(0.5))
                        }
                        .buttonStyle(.plain)

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

// MARK: - Yearly Expenses Overview
struct YearlyExpensesOverview: View {
    @ObservedObject var store: ExpenseStore
    let selectedMonth: Date
    let currency: String
    @Environment(\.dismiss) private var dismiss

    private var year: Int {
        Calendar.current.component(.year, from: selectedMonth)
    }

    private var monthlyData: [(month: String, total: Double, monthIndex: Int)] {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return (1...12).compactMap { monthNum in
            var comps = DateComponents()
            comps.year = year
            comps.month = monthNum
            let monthDate = cal.date(from: comps) ?? Date()
            let total = store.expenses.filter {
                cal.component(.year, from: $0.date) == year &&
                cal.component(.month, from: $0.date) == monthNum
            }.reduce(0) { $0 + $1.amount }
            guard total > 0 else { return nil }
            return (month: formatter.string(from: monthDate), total: total, monthIndex: monthNum)
        }
    }

    private var yearTotal: Double {
        monthlyData.reduce(0) { $0 + $1.total }
    }

    private var avgMonthly: Double {
        monthlyData.isEmpty ? 0 : yearTotal / Double(monthlyData.count)
    }

    private var highestMonth: (month: String, total: Double)? {
        monthlyData.max(by: { $0.total < $1.total }).map { ($0.month, $0.total) }
    }

    private var lowestMonth: (month: String, total: Double)? {
        monthlyData.min(by: { $0.total < $1.total }).map { ($0.month, $0.total) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if monthlyData.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "chart.bar")
                                .font(.system(size: 44, weight: .light))
                                .foregroundStyle(.tertiary)
                            Text("No expense data for \(year.description)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            Text("Add expenses to see your yearly overview here.")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        // Summary cards
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            summaryCard(title: "Year Total", value: yearTotal.formatted(.currency(code: currency)), color: .navy)
                            summaryCard(title: "Monthly Average", value: avgMonthly.formatted(.currency(code: currency)), color: .teal)
                            if let high = highestMonth {
                                summaryCard(title: "Highest (\(high.month))", value: high.total.formatted(.currency(code: currency)), color: Color(hex: "#D44848"))
                            }
                            if let low = lowestMonth {
                                summaryCard(title: "Lowest (\(low.month))", value: low.total.formatted(.currency(code: currency)), color: Color(hex: "#1D9E75"))
                            }
                        }

                        // Bar chart
                        let currentMonthIdx = Calendar.current.component(.month, from: selectedMonth)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Monthly Expenses")
                                .font(.headline)
                                .foregroundStyle(Color.navy)

                            Chart(monthlyData, id: \.monthIndex) { item in
                                BarMark(
                                    x: .value("Month", item.month),
                                    y: .value("Amount", item.total)
                                )
                                .foregroundStyle(item.monthIndex == currentMonthIdx ? Color.navy : Color.teal.opacity(0.7))
                                .cornerRadius(4)
                                .annotation(position: .top, spacing: 2) {
                                    Text(shortCurrency(item.total))
                                        .font(.system(size: 8, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel {
                                        if let v = value.as(Double.self) {
                                            Text(shortCurrency(v))
                                                .font(.caption2)
                                        }
                                    }
                                }
                            }
                            .frame(height: 240)

                            HStack {
                                Spacer()
                                Circle().fill(Color.navy).frame(width: 8, height: 8)
                                Text("Selected Month")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Circle().fill(Color.teal.opacity(0.7)).frame(width: 8, height: 8)
                                Text("Other")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))

                        // Month-wise list
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Month-wise Breakdown")
                                .font(.headline)
                                .foregroundStyle(Color.navy)

                            ForEach(monthlyData, id: \.monthIndex) { item in
                                HStack {
                                    Text(item.month)
                                        .font(.subheadline.weight(.medium))
                                        .frame(width: 40, alignment: .leading)
                                    GeometryReader { geo in
                                        let maxVal = monthlyData.map(\.total).max() ?? 1
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(item.monthIndex == currentMonthIdx ? Color.navy : Color.teal.opacity(0.5))
                                            .frame(width: geo.size.width * (item.total / maxVal))
                                    }
                                    .frame(height: 16)
                                    Text(item.total.formatted(.currency(code: currency)))
                                        .font(.caption.weight(.semibold))
                                        .frame(width: 90, alignment: .trailing)
                                }
                            }
                        }
                        .padding(14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
                    }
                }
                .padding()
            }
            .navigationTitle("Yearly Expenses \(year.description)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func summaryCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(color.opacity(0.2), lineWidth: 0.5))
    }

    private func shortCurrency(_ value: Double) -> String {
        let sym = CurrencySettings.symbol(for: currency)
        if value >= 1_00_000 {
            return String(format: "%@%.1fL", sym, value / 1_00_000)
        } else if value >= 1_000 {
            return String(format: "%@%.0fK", sym, value / 1_000)
        }
        return String(format: "%@%.0f", sym, value)
    }
}

// MARK: - Add Expense Sheet
struct AddExpenseSheet: View {
    @ObservedObject var store: ExpenseStore
    var initialDate: Date = Date()
    var editingExpense: ExpenseEntry?
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: ExpenseCategory = .groceries
    @State private var customCategoryName = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var showDatePicker = false
    @State private var showValidationAlert = false
    @State private var validationMessage = ""

    private var isEditMode: Bool { editingExpense != nil }

    private var resolvedCategory: String {
        if selectedCategory == .other {
            let trimmed = customCategoryName.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? ExpenseCategory.other.rawValue : trimmed
        }
        return selectedCategory.rawValue
    }

    init(store: ExpenseStore, initialDate: Date = Date()) {
        self.store = store
        self.initialDate = initialDate
        self.editingExpense = nil
        let cal = Calendar.current
        let components = cal.dateComponents([.year, .month], from: initialDate)
        let now = Date()
        let nowComponents = cal.dateComponents([.year, .month], from: now)
        if components.year == nowComponents.year && components.month == nowComponents.month {
            _date = State(initialValue: now)
        } else {
            _date = State(initialValue: cal.date(from: components) ?? initialDate)
        }
    }

    init(store: ExpenseStore, editingExpense: ExpenseEntry) {
        self.store = store
        self.editingExpense = editingExpense
        self.initialDate = editingExpense.date
        let cat = ExpenseCategory(rawValue: editingExpense.category)
        _selectedCategory = State(initialValue: cat ?? .other)
        // If the category doesn't match any enum case, it's a custom "Other" name
        if cat == nil {
            _customCategoryName = State(initialValue: editingExpense.category)
        }
        _amount = State(initialValue: String(format: "%.2f", editingExpense.amount))
        _date = State(initialValue: editingExpense.date)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SectionHeader(systemImage: isEditMode ? "pencil.circle.fill" : "plus.circle.fill", title: isEditMode ? "Edit Expense" : "New Expense", color: .navy)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    if selectedCategory == .other {
                        HStack {
                            Text("Name")
                            Spacer()
                            TextField("e.g. Donation, Gift", text: $customCategoryName)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }

                Section("Details") {
                    HStack {
                        Text("Amount (\(CurrencySettings.symbol(for: CurrencySettings.selectedCode)))")
                        Spacer()
                        TextField("0", text: $amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    Button { showDatePicker = true } label: {
                        HStack {
                            Text("Date")
                                .foregroundStyle(.primary)
                            Spacer()
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .foregroundStyle(.secondary)
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.navy)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section {
                    Button {
                        guard let amt = Double(amount), amt > 0 else {
                            validationMessage = "Please enter a valid amount greater than 0."
                            showValidationAlert = true
                            return
                        }
                        if isEditMode, var existing = editingExpense {
                            existing.category = resolvedCategory
                            existing.amount = amt
                            existing.date = date
                            store.update(existing)
                        } else {
                            let entry = ExpenseEntry(category: resolvedCategory, amount: amt, date: date)
                            store.add(entry)
                        }
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label(isEditMode ? "Update Expense" : "Add Expense", systemImage: isEditMode ? "checkmark.circle.fill" : "plus.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .tint(.navy)
                }
            }
            .keyboardDoneToolbar()
            .navigationTitle(isEditMode ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(selectedDate: $date)
                    .presentationDetents([.medium])
            }
            .alert("Invalid Input", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(validationMessage)
            }
        }
    }
}

// MARK: - Date Picker Sheet (auto-dismiss)
struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(Color.navy)
                .padding()
                .onChange(of: selectedDate) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
                .navigationTitle("Select Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}
