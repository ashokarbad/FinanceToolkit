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
    var isFixed: Bool = false
    var date: Date = Date()
}

// MARK: - Outflow Store
final class OutflowStore: ObservableObject {
    static let shared = OutflowStore()

    @Published private(set) var items: [OutflowItem] = []
    @Published var monthlySalary: Double {
        didSet { UserDefaults.standard.set(monthlySalary, forKey: salaryKey) }
    }
    private let storeKey = "monthlyOutflowItems"
    private let salaryKey = "monthlySalary"

    private init() {
        monthlySalary = UserDefaults.standard.double(forKey: salaryKey)
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

    func toggleFixed(id: UUID) {
        if let idx = items.firstIndex(where: { $0.id == id }) {
            items[idx].isFixed.toggle()
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

// MARK: - SwiftUI view → UIImage helper (outflow)
@MainActor
private func renderOutflowSwiftUIView<V: View>(_ view: V, size: CGSize) -> UIImage {
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

// MARK: - Outflow PDF Generator
@MainActor
private func generateOutflowPDF(
    monthLabel: String,
    totalOutflow: Double,
    groupedItems: [(category: String, items: [OutflowItem], total: Double, color: Color, icon: String)],
    currency: String,
    chartView: some View
) -> URL? {
    let pageW: CGFloat = 595
    let pageH: CGFloat = 842
    let margin: CGFloat = 50
    let topMarginNewPage: CGFloat = 60
    let contentW = pageW - margin * 2

    let pdfURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("Outflow_\(monthLabel.replacingOccurrences(of: " ", with: "_")).pdf")

    UIGraphicsBeginPDFContextToFile(pdfURL.path, CGRect(x: 0, y: 0, width: pageW, height: pageH), nil)
    UIGraphicsBeginPDFPage()

    guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
    var y: CGFloat = topMarginNewPage

    // --- Title ---
    let titleAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .bold),
        .foregroundColor: UIColor(Color.navy)
    ]
    NSAttributedString(string: "Monthly Outflow Report", attributes: titleAttr)
        .draw(at: CGPoint(x: margin, y: y))
    y += 30

    // --- Total ---
    let subAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel
    ]
    NSAttributedString(string: "\(monthLabel) · \(groupedItems.count) categories", attributes: subAttr)
        .draw(at: CGPoint(x: margin, y: y))

    let totalAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14, weight: .bold),
        .foregroundColor: UIColor(Color.navy)
    ]
    let totalStr = NSAttributedString(string: "Total: \(totalOutflow.formatted(.currency(code: currency)))", attributes: totalAttr)
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
    let chartH = CGFloat(max(groupedItems.count, 1) * 44 + 32)
    let chartW: CGFloat = contentW
    let chartImage = renderOutflowSwiftUIView(chartView, size: CGSize(width: chartW, height: chartH))
    let chartRect = CGRect(x: margin, y: y, width: chartW, height: chartH)
    chartImage.draw(in: chartRect)
    y += chartH + 16

    // --- Category detail table ---
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
    let subItemAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel
    ]
    let pctAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 10, weight: .regular),
        .foregroundColor: UIColor.secondaryLabel
    ]

    let col1X = margin
    let col2X = margin + contentW * 0.55
    let col3X = margin + contentW * 0.80

    NSAttributedString(string: "Category / Item", attributes: headerAttr).draw(at: CGPoint(x: col1X, y: y))
    NSAttributedString(string: "Amount", attributes: headerAttr).draw(at: CGPoint(x: col2X, y: y))
    NSAttributedString(string: "%", attributes: headerAttr).draw(at: CGPoint(x: col3X, y: y))
    y += 18

    ctx.setStrokeColor(UIColor.separator.cgColor)
    ctx.move(to: CGPoint(x: margin, y: y))
    ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
    ctx.strokePath()
    y += 6

    for group in groupedItems {
        if y > pageH - 80 {
            UIGraphicsBeginPDFPage()
            y = topMarginNewPage
        }
        let pct = totalOutflow > 0 ? group.total / totalOutflow * 100 : 0

        // Color dot + category
        ctx.setFillColor(UIColor(group.color).cgColor)
        ctx.fillEllipse(in: CGRect(x: col1X, y: y + 3, width: 8, height: 8))

        NSAttributedString(string: group.category, attributes: cellBoldAttr)
            .draw(at: CGPoint(x: col1X + 14, y: y))
        NSAttributedString(string: group.total.formatted(.currency(code: currency)), attributes: cellBoldAttr)
            .draw(at: CGPoint(x: col2X, y: y))
        NSAttributedString(string: String(format: "%.1f%%", pct), attributes: pctAttr)
            .draw(at: CGPoint(x: col3X, y: y))
        y += 20

        // Sub-items
        for item in group.items {
            if y > pageH - 60 {
                UIGraphicsBeginPDFPage()
                y = topMarginNewPage
            }
            NSAttributedString(string: "    \(item.label)", attributes: subItemAttr)
                .draw(at: CGPoint(x: col1X + 14, y: y))
            NSAttributedString(string: item.amount.formatted(.currency(code: currency)), attributes: cellAttr)
                .draw(at: CGPoint(x: col2X, y: y))
            y += 17
        }
        y += 4
    }

    // --- Footer ---
    let footerAttr: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 9, weight: .regular),
        .foregroundColor: UIColor.tertiaryLabel
    ]
    NSAttributedString(string: "Generated by Finance Toolkit", attributes: footerAttr)
        .draw(at: CGPoint(x: margin, y: pageH - 30))

    UIGraphicsEndPDFContext()
    return pdfURL
}

// MARK: - Monthly Outflow View
struct MonthlyOutflowView: View {
    @ObservedObject private var store = OutflowStore.shared
    @State private var showAddSheet = false
    @State private var sharePDFURL: URL?
    @State private var shareCSVURL: URL?
    @State private var deleteItemID: UUID?
    @State private var showDeleteAlert = false
    @State private var salaryText = ""
    @State private var editingSalary = false
    @State private var selectedMonth = Date()

    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var currencySymbol: String { CurrencySettings.symbol(for: currency) }

    private var currentMonthItems: [OutflowItem] {
        let cal = Calendar.current
        return store.items.filter {
            $0.isFixed || cal.isDate($0.date, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    private var totalOutflow: Double {
        currentMonthItems.reduce(0) { $0 + $1.amount }
    }

    private var fixedTotal: Double {
        currentMonthItems.filter(\.isFixed).reduce(0) { $0 + $1.amount }
    }

    private var remainingAfterOutflow: Double {
        store.monthlySalary - totalOutflow
    }

    private var groupedItems: [(category: String, items: [OutflowItem], total: Double, color: Color, icon: String)] {
        var groups: [String: [OutflowItem]] = [:]
        for item in currentMonthItems {
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
                // Month selector
                monthPicker

                // Salary & balance card
                salaryCard

                // Total outflow card
                totalCard

                // Fixed outflows section
                if currentMonthItems.contains(where: \.isFixed) {
                    fixedOutflowsSection
                }

                // Bar chart
                if !currentMonthItems.isEmpty {
                    barChartSection
                }

                // Item groups
                if !currentMonthItems.isEmpty {
                    itemsSection
                } else {
                    emptyState
                }
            }
            .padding()
        }
        .onAppear {
            if store.monthlySalary > 0 {
                salaryText = String(format: "%.0f", store.monthlySalary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    if !currentMonthItems.isEmpty {
                        Menu {
                            Button { shareOutflowPDF() } label: {
                                Label("Export as PDF", systemImage: "doc.richtext")
                            }
                            Button { shareOutflowCSV() } label: {
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
            AddOutflowSheet(store: store, initialDate: selectedMonth)
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
        .alert("Delete Item", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let id = deleteItemID {
                    withAnimation { store.delete(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove this outflow item?")
        }
    }

    // MARK: - Share as PDF
    private func shareOutflowPDF() {
        let month = selectedMonth.formatted(.dateTime.month(.wide).year())
        let chartView = OutflowShareChart(
            groupedItems: groupedItems,
            totalOutflow: totalOutflow,
            currency: currency
        )
        sharePDFURL = generateOutflowPDF(
            monthLabel: month,
            totalOutflow: totalOutflow,
            groupedItems: groupedItems,
            currency: currency,
            chartView: chartView
        )
    }

    // MARK: - Share as CSV
    private func shareOutflowCSV() {
        let month = selectedMonth.formatted(.dateTime.month(.wide).year())
        var csv = "Monthly Outflow Report - \(month)\n\n"

        if store.monthlySalary > 0 {
            csv += "Monthly Salary,\(String(format: "%.2f", store.monthlySalary))\n"
            csv += "Total Outflow,\(String(format: "%.2f", totalOutflow))\n"
            csv += "Remaining,\(String(format: "%.2f", remainingAfterOutflow))\n\n"
        }

        csv += "Category,Item,Amount (\(currency)),Fixed\n"
        for group in groupedItems {
            for item in group.items {
                let escaped = item.label.replacingOccurrences(of: ",", with: " ")
                csv += "\(group.category),\(escaped),\(String(format: "%.2f", item.amount)),\(item.isFixed ? "Yes" : "No")\n"
            }
        }
        csv += "\nCategory Summary\nCategory,Total,Percentage\n"
        for group in groupedItems {
            let pct = totalOutflow > 0 ? group.total / totalOutflow * 100 : 0
            csv += "\(group.category),\(String(format: "%.2f", group.total)),\(String(format: "%.1f%%", pct))\n"
        }
        csv += "\nTotal,,\(String(format: "%.2f", totalOutflow))\n"

        let fileName = "Outflow_\(month.replacingOccurrences(of: " ", with: "_")).csv"
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

    // MARK: - Salary Card
    private var salaryCard: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "banknote.fill")
                    .foregroundStyle(.teal)
                Text("Monthly Salary")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !editingSalary {
                    Button {
                        salaryText = store.monthlySalary > 0 ? String(format: "%.0f", store.monthlySalary) : ""
                        editingSalary = true
                    } label: {
                        HStack(spacing: 4) {
                            Text(store.monthlySalary > 0 ? store.monthlySalary.formatted(.currency(code: currency)) : "Tap to set")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(store.monthlySalary > 0 ? .primary : .tertiary)
                            Image(systemName: "pencil")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }

            if editingSalary {
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text(currencySymbol)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        TextField("Enter salary", text: $salaryText)
                            .keyboardType(.decimalPad)
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))

                    Button {
                        store.monthlySalary = Double(salaryText) ?? 0
                        editingSalary = false
                    } label: {
                        Text("Save")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(Color.teal))
                    }
                    .buttonStyle(.plain)

                    Button {
                        editingSalary = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if store.monthlySalary > 0 && !store.items.isEmpty {
                Divider()
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Remaining after outflows")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(remainingAfterOutflow.formatted(.currency(code: currency)))
                            .font(.headline.bold())
                            .foregroundStyle(remainingAfterOutflow >= 0 ? .teal : Color(hex: "#D44848"))
                    }
                    Spacer()
                    let pct = store.monthlySalary > 0 ? totalOutflow / store.monthlySalary : 0
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Outflow %")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(pct.formatted(.percent.precision(.fractionLength(1))))
                            .font(.headline.bold())
                            .foregroundStyle(pct > 0.7 ? Color(hex: "#D44848") : .navy)
                    }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.teal.opacity(0.25), lineWidth: 0.5))
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
            Text("\(currentMonthItems.count) items this month")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.2), lineWidth: 0.5))
    }

    private var fixedItems: [OutflowItem] {
        currentMonthItems.filter(\.isFixed)
    }

    // MARK: - Fixed Outflows
    private var fixedOutflowsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pin.fill")
                    .foregroundStyle(Color.gold)
                Text("Fixed Monthly Outflows")
                    .font(.headline)
                    .foregroundStyle(Color.navy)
                Spacer()
                Text(fixedTotal.formatted(.currency(code: currency)))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.navy)
            }

            ForEach(fixedItems) { item in
                fixedItemRow(item)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.gold.opacity(0.25), lineWidth: 0.5))
    }

    @ViewBuilder
    private func fixedItemRow(_ item: OutflowItem) -> some View {
        let cat = OutflowCategory(rawValue: item.category) ?? .other
        HStack(spacing: 10) {
            Image(systemName: "pin.fill")
                .font(.system(size: 8))
                .foregroundStyle(Color.gold)
            Image(systemName: cat.icon)
                .font(.system(size: 11))
                .foregroundStyle(cat.color)
                .frame(width: 22, height: 22)
                .background(RoundedRectangle(cornerRadius: 5).fill(cat.color.opacity(0.1)))
            Text(item.label)
                .font(.caption)
            Spacer()
            Text(item.amount.formatted(.currency(code: currency)))
                .font(.caption.weight(.semibold))
        }
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
                outflowGroupRow(group)
                if group.category != groupedItems.last?.category {
                    Divider()
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.15), lineWidth: 0.5))
    }

    @ViewBuilder
    private func outflowGroupRow(_ group: (category: String, items: [OutflowItem], total: Double, color: Color, icon: String)) -> some View {
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
                outflowItemRow(item)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func outflowItemRow(_ item: OutflowItem) -> some View {
        HStack {
            if item.isFixed {
                Image(systemName: "pin.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.gold)
            }
            Text(item.label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(item.amount.formatted(.currency(code: currency)))
                .font(.caption.weight(.medium))

            Button {
                withAnimation { store.toggleFixed(id: item.id) }
            } label: {
                Image(systemName: item.isFixed ? "pin.slash.fill" : "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(item.isFixed ? .secondary : Color.gold)
            }
            .buttonStyle(.plain)

            Button {
                deleteItemID = item.id
                showDeleteAlert = true
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 34)
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
        let sym = currencySymbol
        if value >= 1_00_000 {
            return String(format: "%@%.1fL", sym, value / 1_00_000)
        } else if value >= 1_000 {
            return String(format: "%@%.0fK", sym, value / 1_000)
        }
        return String(format: "%@%.0f", sym, value)
    }
}

// MARK: - Chart-only view for PDF rendering
struct OutflowShareChart: View {
    let groupedItems: [(category: String, items: [OutflowItem], total: Double, color: Color, icon: String)]
    let totalOutflow: Double
    let currency: String

    var body: some View {
        Chart(groupedItems, id: \.category) { group in
            BarMark(
                x: .value("Amount", group.total),
                y: .value("Category", group.category)
            )
            .foregroundStyle(group.color)
            .cornerRadius(4)
        }
        .chartXAxis(.hidden)
        .padding(16)
        .background(Color.white)
    }
}

// MARK: - Add Outflow Sheet
struct AddOutflowSheet: View {
    @ObservedObject var store: OutflowStore
    var initialDate: Date = Date()
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: OutflowCategory = .homeLoan
    @State private var label = ""
    @State private var amount = ""
    @State private var isFixed = false
    @State private var date = Date()

    init(store: OutflowStore, initialDate: Date = Date()) {
        self.store = store
        self.initialDate = initialDate
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
                        Text("Amount (\(CurrencySettings.symbol(for: CurrencySettings.selectedCode)))")
                        Spacer()
                        TextField("0", text: $amount)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.decimalPad)
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle(isOn: $isFixed) {
                        Label("Fixed Monthly Outflow", systemImage: "pin.fill")
                            .font(.subheadline)
                    }
                    .tint(.gold)
                }

                Section {
                    Button {
                        guard let amt = Double(amount), amt > 0 else { return }
                        let item = OutflowItem(
                            label: label.isEmpty ? selectedCategory.rawValue : label,
                            amount: amt,
                            category: selectedCategory.rawValue,
                            isFixed: isFixed,
                            date: date
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
