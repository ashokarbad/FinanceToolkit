// ShellViews.swift
// Finance Toolkit — sidebar destination views (Dashboard, Saved, Tips, Profile, Settings, About)

import SwiftUI
import StoreKit

// MARK: - Dashboard
struct DashboardView: View {
    @ObservedObject private var store = SavedStore.shared
    @ObservedObject private var expenseStore = ExpenseStore.shared
    @ObservedObject private var outflowStore = OutflowStore.shared
    @ObservedObject private var noteStore = NoteStore.shared
    var navigateTo: ((SidebarDestination) -> Void)?
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode
    @AppStorage("profileName") private var profileName = ""

    private var currentMonthExpenseTotal: Double {
        let cal = Calendar.current
        let now = Date()
        return expenseStore.expenses.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }

    private var currentMonthOutflowTotal: Double {
        let cal = Calendar.current
        let now = Date()
        return outflowStore.items.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }

    private var currentMonthExpenseCount: Int {
        let cal = Calendar.current
        let now = Date()
        return expenseStore.expenses.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }.count
    }

    private var currentMonthOutflowCount: Int {
        let cal = Calendar.current
        let now = Date()
        return outflowStore.items.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }.count
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Good Night"
        }
    }

    private var greetingIcon: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "sun.max.fill"
        case 12..<17: return "sun.min.fill"
        case 17..<21: return "sunset.fill"
        default: return "moon.stars.fill"
        }
    }

    private var monthLabel: String {
        Date().formatted(.dateTime.month(.wide).year())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Greeting header
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: greetingIcon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.gold)
                            Text(greeting)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Text(profileName.isEmpty ? "Welcome back!" : profileName)
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                    }
                    Spacer()
                    Text(monthLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.navy))
                }
                .padding(.horizontal, 4)

                // Expenses hero card (full width)
                Button { navigateTo?(.expenses) } label: {
                    DashboardHeroCard(
                        title: "Monthly Expenses",
                        value: currentMonthExpenseTotal.formatted(.currency(code: currency)),
                        subtitle: "\(currentMonthExpenseCount) transactions this month",
                        icon: "chart.pie.fill",
                        gradient: [Color(hex: "#E87D2B"), Color(hex: "#F5A623")]
                    )
                }
                .buttonStyle(.plain)

                // Outflow hero card (full width)
                Button { navigateTo?(.outflow) } label: {
                    DashboardHeroCard(
                        title: "Monthly Outflow",
                        value: currentMonthOutflowTotal.formatted(.currency(code: currency)),
                        subtitle: "\(currentMonthOutflowCount) items this month",
                        icon: "arrow.up.forward.circle.fill",
                        gradient: [Color(hex: "#1D9E75"), Color(hex: "#34D399")]
                    )
                }
                .buttonStyle(.plain)

                // Bottom row: Saved, Favourites, Notes
                HStack(spacing: 12) {
                    Button { navigateTo?(.saved) } label: {
                        DashboardCompactCard(
                            title: "Saved",
                            value: "\(store.calculations.count)",
                            icon: "bookmark.fill",
                            color: .navy
                        )
                    }
                    .buttonStyle(.plain)

                    Button { navigateTo?(.calculators) } label: {
                        DashboardCompactCard(
                            title: "Favourites",
                            value: "\(store.savedIDs.count)",
                            icon: "star.fill",
                            color: .gold
                        )
                    }
                    .buttonStyle(.plain)

                    Button { navigateTo?(.notes) } label: {
                        DashboardCompactCard(
                            title: "Notes",
                            value: "\(noteStore.notes.count)",
                            icon: "note.text",
                            color: Color(hex: "#8B5CF6")
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Quick actions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Actions")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .padding(.leading, 4)

                    HStack(spacing: 12) {
                        DashboardActionButton(icon: "plus.circle.fill", label: "Add Expense", color: Color(hex: "#E87D2B")) {
                            navigateTo?(.expenses)
                        }
                        DashboardActionButton(icon: "arrow.up.circle.fill", label: "Add Outflow", color: .teal) {
                            navigateTo?(.outflow)
                        }
                        DashboardActionButton(icon: "square.grid.2x2.fill", label: "Calculators", color: .navy) {
                            navigateTo?(.calculators)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Dashboard Hero Card (full-width, gradient)
struct DashboardHeroCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .contentTransition(.numericText())
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .top, endPoint: .center)
                )
        )
        .shadow(color: gradient.first!.opacity(0.3), radius: 8, y: 4)
    }
}

// MARK: - Dashboard Compact Card (small, for bottom row)
struct DashboardCompactCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(color)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(color.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Dashboard Action Button
struct DashboardActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(color.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved
struct SavedView: View {
    @ObservedObject private var store = SavedStore.shared
    @State private var sharePDFURL: URL?
    @State private var shareAllPDFURL: URL?
    @State private var shareCSVURL: URL?
    @State private var editingNoteCalc: SavedCalculation?
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var totalSaved: Int { store.calculations.count }

    private var calculatorBreakdown: [(name: String, icon: String, count: Int)] {
        var dict: [String: (icon: String, count: Int)] = [:]
        for calc in store.calculations {
            let existing = dict[calc.calculatorTitle]
            dict[calc.calculatorTitle] = (calc.icon, (existing?.count ?? 0) + 1)
        }
        return dict.map { (name: $0.key, icon: $0.value.icon, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        Group {
            if store.calculations.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.navy.opacity(0.08))
                            .frame(width: 90, height: 90)
                        Circle()
                            .fill(Color.navy.opacity(0.05))
                            .frame(width: 70, height: 70)
                        Image(systemName: "bookmark")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(Color.navy.opacity(0.4))
                    }
                    Text("No saved calculations")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap \"Save\" on any calculator result to bookmark it here.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 16) {

                        // Summary header card
                        VStack(spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Saved")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.white.opacity(0.8))
                                    Text("\(totalSaved)")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                        .contentTransition(.numericText())
                                }
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(.white.opacity(0.15))
                                        .frame(width: 50, height: 50)
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white)
                                }
                            }

                            // Mini breakdown chips
                            if !calculatorBreakdown.isEmpty {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(calculatorBreakdown.prefix(5), id: \.name) { item in
                                            HStack(spacing: 4) {
                                                Image(systemName: item.icon)
                                                    .font(.system(size: 9))
                                                Text("\(item.count)")
                                                    .font(.caption2.weight(.bold))
                                                Text(item.name)
                                                    .font(.caption2)
                                                    .lineLimit(1)
                                            }
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Capsule().fill(.white.opacity(0.15)))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LinearGradient(colors: [Color.navy, Color.navyDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: .center))
                        )
                        .shadow(color: Color.navy.opacity(0.25), radius: 8, y: 4)

                        // Saved calculation cards
                        ForEach(store.calculations) { calc in
                            savedCalcCard(calc)
                        }
                    }
                    .padding()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                shareAllPDFURL = generateSavedPDF(calculations: store.calculations)
                            } label: {
                                Label("Export as PDF", systemImage: "doc.richtext")
                            }
                            Button {
                                shareCSVURL = generateSavedCSV(calculations: store.calculations)
                            } label: {
                                Label("Export as Excel (CSV)", systemImage: "tablecells")
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14))
                        }
                    }
                }
            }
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
            get: { shareAllPDFURL != nil },
            set: { if !$0 { shareAllPDFURL = nil } }
        )) {
            if let url = shareAllPDFURL {
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
        .sheet(isPresented: Binding(
            get: { editingNoteCalc != nil },
            set: { if !$0 { editingNoteCalc = nil } }
        )) {
            if let calc = editingNoteCalc {
                NoteEditorSheet(store: store, calculationID: calc.id, existingNote: calc.userNote ?? StyledNote())
            }
        }
    }

    @ViewBuilder
    private func savedCalcCard(_ calc: SavedCalculation) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Card header
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.navy.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: calc.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.navy)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(calc.calculatorTitle)
                        .font(.subheadline.weight(.semibold))
                    if !calc.note.isEmpty {
                        Text(calc.note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text(calc.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider().padding(.horizontal, 16)

            // Results
            VStack(spacing: 6) {
                ForEach(calc.results, id: \.label) { entry in
                    HStack {
                        Text(entry.label)
                            .font(entry.isHighlight ? .caption.weight(.semibold) : .caption)
                            .foregroundStyle(entry.isHighlight ? .primary : .secondary)
                        Spacer()
                        Text(entry.value)
                            .font(entry.isHighlight ? .subheadline.bold() : .caption)
                            .foregroundStyle(entry.isHighlight ? Color.navy : .secondary)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // User note (if exists)
            if let userNote = calc.userNote, !userNote.text.isEmpty {
                Divider().padding(.horizontal, 16)
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: userNote.colorHex))
                    Text(userNote.text)
                        .font(.system(size: CGFloat(userNote.fontSize),
                                      weight: userNote.isBold ? .bold : .regular))
                        .italic(userNote.isItalic)
                        .foregroundStyle(Color(hex: userNote.colorHex))
                        .lineLimit(3)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }

            Divider().padding(.horizontal, 16)

            // Action buttons row
            HStack(spacing: 0) {
                Button {
                    sharePDFURL = generateSavedPDF(calculations: [calc])
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 11))
                        Text("Share")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Color.navy)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 0.5, height: 20)

                Button {
                    editingNoteCalc = calc
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.system(size: 11))
                        Text("Note")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(Color(hex: "#8B5CF6"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 0.5, height: 20)

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        store.delete(id: calc.id)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.system(size: 11))
                        Text("Delete")
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 4, y: 2)
    }

    private func generateSavedPDF(calculations: [SavedCalculation]) -> URL? {
        let pageW: CGFloat = 595
        let pageH: CGFloat = 842
        let margin: CGFloat = 50
        let topMarginNewPage: CGFloat = 60
        let contentW = pageW - margin * 2

        let pdfURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("Saved_Calculations.pdf")

        UIGraphicsBeginPDFContextToFile(pdfURL.path, CGRect(x: 0, y: 0, width: pageW, height: pageH), nil)
        UIGraphicsBeginPDFPage()

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        var y: CGFloat = topMarginNewPage

        let titleAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 22, weight: .bold),
            .foregroundColor: UIColor(Color.navy)
        ]
        let headAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let bodyAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .regular),
            .foregroundColor: UIColor.darkGray
        ]
        let valAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: UIColor.black
        ]
        let subAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .regular),
            .foregroundColor: UIColor.gray
        ]
        let footerAttr: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9, weight: .regular),
            .foregroundColor: UIColor.lightGray
        ]

        // Title
        let title = calculations.count == 1 ? "Saved Calculation" : "Saved Calculations (\(calculations.count))"
        NSAttributedString(string: title, attributes: titleAttr)
            .draw(at: CGPoint(x: margin, y: y))
        y += 34

        for calc in calculations {
            if y > pageH - 100 {
                // Footer on current page
                NSAttributedString(string: "Generated by Finance Toolkit", attributes: footerAttr)
                    .draw(at: CGPoint(x: margin, y: pageH - 30))
                UIGraphicsBeginPDFPage()
                y = topMarginNewPage
            }

            // Calculator title
            NSAttributedString(string: calc.calculatorTitle, attributes: headAttr)
                .draw(at: CGPoint(x: margin, y: y))

            let dateStr = NSAttributedString(string: calc.date.formatted(date: .abbreviated, time: .omitted), attributes: subAttr)
            let dateSize = dateStr.size()
            dateStr.draw(at: CGPoint(x: pageW - margin - dateSize.width, y: y + 2))
            y += 20

            if !calc.note.isEmpty {
                NSAttributedString(string: calc.note, attributes: subAttr)
                    .draw(at: CGPoint(x: margin, y: y))
                y += 16
            }

            // Results
            let labelX = margin
            let valueX = margin + contentW * 0.65
            for entry in calc.results {
                if y > pageH - 60 {
                    NSAttributedString(string: "Generated by Finance Toolkit", attributes: footerAttr)
                        .draw(at: CGPoint(x: margin, y: pageH - 30))
                    UIGraphicsBeginPDFPage()
                    y = topMarginNewPage
                }
                let attr = entry.isHighlight ? valAttr : bodyAttr
                NSAttributedString(string: entry.label, attributes: bodyAttr)
                    .draw(at: CGPoint(x: labelX, y: y))
                NSAttributedString(string: entry.value, attributes: attr)
                    .draw(at: CGPoint(x: valueX, y: y))
                y += 17
            }

            // User note
            if let userNote = calc.userNote, !userNote.text.isEmpty {
                if y > pageH - 80 {
                    NSAttributedString(string: "Generated by Finance Toolkit", attributes: footerAttr)
                        .draw(at: CGPoint(x: margin, y: pageH - 30))
                    UIGraphicsBeginPDFPage()
                    y = topMarginNewPage
                }
                y += 4
                let noteAttr: [NSAttributedString.Key: Any] = [
                    .font: userNote.uiFont,
                    .foregroundColor: UIColor(Color(hex: userNote.colorHex))
                ]
                let noteStr = NSAttributedString(string: userNote.text, attributes: noteAttr)
                let noteRect = noteStr.boundingRect(with: CGSize(width: contentW, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
                noteStr.draw(in: CGRect(x: margin, y: y, width: contentW, height: noteRect.height))
                y += noteRect.height + 4
            }

            y += 8
            ctx.setStrokeColor(UIColor.lightGray.cgColor)
            ctx.setLineWidth(0.5)
            ctx.move(to: CGPoint(x: margin, y: y))
            ctx.addLine(to: CGPoint(x: pageW - margin, y: y))
            ctx.strokePath()
            y += 14
        }

        // Footer
        NSAttributedString(string: "Generated by Finance Toolkit", attributes: footerAttr)
            .draw(at: CGPoint(x: margin, y: pageH - 30))

        UIGraphicsEndPDFContext()
        return pdfURL
    }

    private func generateSavedCSV(calculations: [SavedCalculation]) -> URL? {
        var csv = "Calculator,Date,Note"
        // Find max result columns and collect proper column headers
        let maxResults = calculations.map(\.results.count).max() ?? 0
        // Use labels from the calculation with the most results as column headers
        let headerCalc = calculations.max(by: { $0.results.count < $1.results.count })
        for i in 0..<maxResults {
            if let headerCalc, i < headerCalc.results.count {
                let label = headerCalc.results[i].label.replacingOccurrences(of: ",", with: " ")
                csv += ",\(label)"
            } else {
                csv += ",Result \(i+1)"
            }
        }
        csv += ",User Note\n"

        for calc in calculations {
            let dateStr = calc.date.formatted(date: .abbreviated, time: .omitted)
            let escapedNote = calc.note.replacingOccurrences(of: ",", with: " ")
            csv += "\(calc.calculatorTitle),\(dateStr),\(escapedNote)"
            for entry in calc.results {
                let escapedValue = entry.value.replacingOccurrences(of: ",", with: " ")
                csv += ",\(escapedValue)"
            }
            // Pad if fewer results
            for _ in calc.results.count..<maxResults {
                csv += ","
            }
            let userNoteText = calc.userNote?.text.replacingOccurrences(of: ",", with: " ").replacingOccurrences(of: "\n", with: " ") ?? ""
            csv += ",\(userNoteText)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Saved_Calculations.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
}

// MARK: - Note Editor Sheet
struct NoteEditorSheet: View {
    @ObservedObject var store: SavedStore
    let calculationID: UUID
    @State var existingNote: StyledNote
    @Environment(\.dismiss) private var dismiss

    private let fontSizes = [12, 14, 16, 18, 20]
    private let colorOptions: [(name: String, hex: String)] = [
        ("Navy", "#185FA5"),
        ("Teal", "#1D9E75"),
        ("Gold", "#BA7517"),
        ("Red", "#D44848"),
        ("Purple", "#8B5CF6"),
        ("Dark", "#333333"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Note") {
                    TextEditor(text: $existingNote.text)
                        .frame(minHeight: 100)
                        .overlay(alignment: .topLeading) {
                            if existingNote.text.isEmpty {
                                Text("Add your note here...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Font Size") {
                    Picker("Size", selection: $existingNote.fontSize) {
                        ForEach(fontSizes, id: \.self) { size in
                            Text("\(size)pt").tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Style") {
                    HStack(spacing: 16) {
                        Toggle(isOn: $existingNote.isBold) {
                            Label("Bold", systemImage: "bold")
                                .font(.subheadline)
                        }
                        .toggleStyle(.button)
                        .tint(.navy)

                        Toggle(isOn: $existingNote.isItalic) {
                            Label("Italic", systemImage: "italic")
                                .font(.subheadline)
                        }
                        .toggleStyle(.button)
                        .tint(.navy)

                        Spacer()
                    }
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.hex) { option in
                            Button {
                                existingNote.colorHex = option.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: option.hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if existingNote.colorHex == option.hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Preview
                if !existingNote.text.isEmpty {
                    Section("Preview") {
                        Text(existingNote.text)
                            .font(.system(size: CGFloat(existingNote.fontSize),
                                          weight: existingNote.isBold ? .bold : .regular))
                            .italic(existingNote.isItalic)
                            .foregroundStyle(Color(hex: existingNote.colorHex))
                    }
                }

                Section {
                    Button {
                        store.updateNote(id: calculationID, note: existingNote)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Save Note", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .tint(.navy)
                }
            }
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        store.updateNote(id: calculationID, note: existingNote)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Share sheet wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Notes List
struct NotesListView: View {
    @ObservedObject private var store = NoteStore.shared
    @State private var editingNote: QuickNote?
    @State private var showNewNote = false
    @State private var deleteNoteID: UUID?
    @State private var showDeleteAlert = false

    var body: some View {
        Group {
            if store.notes.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "note.text")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No notes yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap + to create your first note with custom styling.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Button("Create Note") { showNewNote = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.notes) { note in
                        noteRow(note)
                    }
                    .onDelete { offsets in store.delete(at: offsets) }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showNewNote = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "#8B5CF6"))
                }
            }
        }
        .sheet(isPresented: $showNewNote) {
            QuickNoteEditorSheet(store: store, note: nil)
        }
        .sheet(isPresented: Binding(
            get: { editingNote != nil },
            set: { if !$0 { editingNote = nil } }
        )) {
            if let note = editingNote {
                QuickNoteEditorSheet(store: store, note: note)
            }
        }
        .alert("Delete Note", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let id = deleteNoteID {
                    withAnimation { store.delete(id: id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this note?")
        }
    }

    @ViewBuilder
    private func noteRow(_ note: QuickNote) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if !note.title.isEmpty {
                    Text(note.title)
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("Untitled Note")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text(note.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            if !note.style.text.isEmpty {
                Text(note.style.text)
                    .font(.system(size: CGFloat(note.style.fontSize),
                                  weight: note.style.isBold ? .bold : .regular))
                    .italic(note.style.isItalic)
                    .foregroundStyle(Color(hex: note.style.colorHex))
                    .lineLimit(4)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { editingNote = note }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteNoteID = note.id
                showDeleteAlert = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Quick Note Editor Sheet
struct QuickNoteEditorSheet: View {
    @ObservedObject var store: NoteStore
    let note: QuickNote?
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var styledNote = StyledNote()

    private let fontSizes = [12, 14, 16, 18, 20]
    private let colorOptions: [(name: String, hex: String)] = [
        ("Navy", "#185FA5"),
        ("Teal", "#1D9E75"),
        ("Gold", "#BA7517"),
        ("Red", "#D44848"),
        ("Purple", "#8B5CF6"),
        ("Dark", "#333333"),
    ]

    init(store: NoteStore, note: QuickNote?) {
        self.store = store
        self.note = note
        if let note {
            _title = State(initialValue: note.title)
            _styledNote = State(initialValue: note.style)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Note title", text: $title)
                }

                Section("Content") {
                    TextEditor(text: $styledNote.text)
                        .font(.system(size: CGFloat(styledNote.fontSize),
                                      weight: styledNote.isBold ? .bold : .regular))
                        .italic(styledNote.isItalic)
                        .foregroundStyle(Color(hex: styledNote.colorHex))
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if styledNote.text.isEmpty {
                                Text("Write your note here...")
                                    .foregroundStyle(.tertiary)
                                    .font(.system(size: CGFloat(styledNote.fontSize)))
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Font Size") {
                    Picker("Size", selection: $styledNote.fontSize) {
                        ForEach(fontSizes, id: \.self) { size in
                            Text("\(size)pt").tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Style") {
                    HStack(spacing: 16) {
                        Toggle(isOn: $styledNote.isBold) {
                            Label("Bold", systemImage: "bold")
                                .font(.subheadline)
                        }
                        .toggleStyle(.button)
                        .tint(Color(hex: "#8B5CF6"))

                        Toggle(isOn: $styledNote.isItalic) {
                            Label("Italic", systemImage: "italic")
                                .font(.subheadline)
                        }
                        .toggleStyle(.button)
                        .tint(Color(hex: "#8B5CF6"))

                        Spacer()
                    }
                }

                Section("Color") {
                    HStack(spacing: 12) {
                        ForEach(colorOptions, id: \.hex) { option in
                            Button {
                                styledNote.colorHex = option.hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: option.hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if styledNote.colorHex == option.hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Button {
                        saveNote()
                    } label: {
                        HStack {
                            Spacer()
                            Label(note == nil ? "Create Note" : "Update Note", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(styledNote.text.isEmpty)
                    .tint(Color(hex: "#8B5CF6"))
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { saveNote() }
                        .fontWeight(.semibold)
                        .disabled(styledNote.text.isEmpty)
                }
            }
        }
    }

    private func saveNote() {
        if let existing = note {
            var updated = existing
            updated.title = title
            updated.style = styledNote
            updated.date = Date()
            store.update(updated)
        } else {
            let newNote = QuickNote(title: title, style: styledNote, date: Date())
            store.add(newNote)
        }
        dismiss()
    }
}

// MARK: - Tips & FAQ
struct TipsFAQView: View {
    private let sections: [(heading: String, color: String, tips: [(icon: String, title: String, detail: String)])] = [
        ("App Features", "#8B5CF6", [
            ("person.badge.plus", "Personalised onboarding", "On first launch, a welcome screen lets you set your name, age, and preferred currency — so everything is ready from the start."),
            ("eye.slash.fill", "Privacy screen", "When you leave the app or switch to another, your financial data is automatically hidden behind a privacy screen. No extra setup needed."),
            ("bookmark.fill", "Save & compare results", "Save any calculation result for future reference. Access all saved items from the Dashboard or Saved section."),
            ("square.and.arrow.up.fill", "Export as PDF or CSV", "Share or export individual calculations or all saved items as a formatted PDF or CSV file from the Saved section."),
            ("star.fill", "Favourite calculators", "Star your most-used calculators for quick access. Favourites appear at the top of the Calculators screen."),
            ("note.text", "Use Notes for quick reminders", "Create styled notes with custom font sizes, colors, bold and italic formatting. Perfect for financial planning reminders."),
            ("list.number", "View amortization schedules", "Every loan calculator includes a month-by-month amortization schedule showing EMI, principal, interest, and outstanding balance."),
            ("moon.fill", "Dark mode support", "Toggle dark mode from the sidebar for comfortable viewing in any lighting condition."),
            ("exclamationmark.triangle.fill", "Smart validation", "The app alerts you with a clear message if you try to save without entering required fields — no silent failures."),
        ]),
        ("Expenses & Outflow", "#E87D2B", [
            ("chart.pie.fill", "Track monthly expenses", "Log every expense by category to understand your spending patterns. View the pie chart breakdown and export monthly reports as PDF or CSV."),
            ("pencil.circle.fill", "Edit & delete entries", "Tap the pencil icon on any expense or outflow entry to update it, or the × icon to remove it. Full control over your records."),
            ("ellipsis.circle.fill", "Custom expense categories", "When you select 'Other' as a category, a text field appears so you can type your own category name — Donation, Gift, or anything you need."),
            ("arrow.up.forward.circle.fill", "Monitor monthly outflow", "Track EMIs, subscriptions, and bills in Monthly Outflow with salary tracking to see how much you have left after all outflows."),
            ("chart.bar.fill", "Yearly graphical overview", "Tap the chart icon in Expenses or Outflow to see a full-year bar chart overview — identify high-spend months and track your trends."),
            ("dollarsign.circle.fill", "Multi-currency support", "Switch currencies in Settings — supports 12 currencies including INR, USD, EUR, GBP, AED, SAR, CAD, AUD, SGD, JPY & RD$. All calculators and trackers update automatically."),
        ]),
        ("Loan Tips", "#185FA5", [
            ("house.fill", "Prepay your home loan", "Even a small extra payment towards the principal each month reduces total interest dramatically. Use Custom Amortization to see exactly how much you save."),
            ("slider.horizontal.3", "Try Custom Amortization", "Available on all loan calculators — enter a higher EMI to instantly see how many months and how much interest you save compared to the standard schedule."),
            ("car.fill", "Maximise your down payment", "A larger down payment on vehicle or consumer durable loans reduces EMI and total interest. The Vehicle Loan calculator shows the net loan after down payment."),
            ("book.fill", "Pay interest during moratorium", "For education and agricultural loans, paying interest during the moratorium period prevents the outstanding balance from growing, resulting in lower future EMIs."),
            ("sparkles", "Understand gold loan LTV", "RBI caps gold loan LTV at 75%. Compare EMI repayment vs bullet (interest-only) mode in the Gold Loan calculator to pick the best option."),
            ("building.2.fill", "LAP for lower rates", "Loan Against Property offers lower interest rates than personal loans since it's secured. Use the LAP calculator to compare outflow at different LTV percentages."),
            ("creditcard.fill", "Avoid high-interest debt", "Credit card and overdraft interest (24–42% p.a.) compounds fast. Use the Credit Line calculator to see the true cost, and pay off quickly."),
            ("cart.fill", "No-cost EMI isn't free", "Consumer durable no-cost EMI may have hidden processing fees. Compare total outflow of standard EMI vs no-cost EMI using the calculator."),
        ]),
        ("Investment Tips", "#BA7517", [
            ("calendar.badge.plus", "Start SIPs early", "Even small monthly investments grow significantly over 15–20 years thanks to compounding. The SIP calculator shows the power of time on your returns."),
            ("chart.pie.fill", "Lump sum vs SIP", "Use the Mutual Fund Lump Sum calculator for one-time investments and compare with SIP returns. Lump sum works better in bullish markets, SIP averages out volatility."),
            ("arrow.down.left.circle.fill", "SWP for retirement income", "Use SWP from a mutual fund corpus to create a monthly pension-like income stream without selling your entire investment at once."),
            ("building.columns.fill", "FD for safety", "Fixed deposits offer guaranteed returns with zero market risk. Use the FD calculator to compare maturity amounts across different tenures and rates."),
            ("calendar.circle.fill", "RD builds discipline", "Recurring Deposits enforce a monthly savings habit with guaranteed returns. Great for short-term goals — use the RD calculator to plan ahead."),
        ]),
        ("Tax & Benefits", "#1D9E75", [
            ("percent", "Compare tax regimes", "Use the Tax Calculator to check which regime — Old or New — saves you more tax based on your salary, HRA, and deductions under 80C, 80D, etc."),
            ("shield.fill", "Max out NPS for tax benefits", "NPS gives an extra ₹50K deduction under 80CCD(1B) beyond ₹1.5L under 80C. The NPS calculator shows your corpus and annuity at retirement."),
            ("banknote.fill", "Track your PF balance", "EPF earns ~8.1% p.a. tax-free — one of the best guaranteed-return instruments. Use the PF calculator with both employee and employer contributions."),
            ("gift.fill", "Know your gratuity entitlement", "After 5 years of service, gratuity up to ₹20L is tax-exempt. The Gratuity calculator shows your exact entitlement based on last drawn basic salary."),
        ]),
    ]

    var body: some View {
        List {
            ForEach(sections, id: \.heading) { section in
                Section {
                    ForEach(section.tips, id: \.title) { tip in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: tip.icon)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(hex: section.color))
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: section.color).opacity(0.12)))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(tip.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text(section.heading)
                }
            }
        }
    }
}

// MARK: - Profile
struct ProfileView: View {
    @AppStorage("profileName") private var name = ""
    @AppStorage("profileAge") private var age = ""
    @AppStorage("profileCity") private var city = ""
    @ObservedObject private var store = SavedStore.shared
    var navigateTo: ((SidebarDestination) -> Void)?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.navy, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                        Text(initials)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name.isEmpty ? "Your Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                        Text(city.isEmpty ? "City" : city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Personal Details") {
                HStack { Text("Full Name"); Spacer(); TextField("Enter name", text: $name).multilineTextAlignment(.trailing) }
                HStack { Text("Age"); Spacer(); TextField("Age", text: $age).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("City"); Spacer(); TextField("City", text: $city).multilineTextAlignment(.trailing) }
            }

            Section("Activity") {
                Button {
                    navigateTo?(.saved)
                } label: {
                    HStack {
                        Label("Saved Calculations", systemImage: "bookmark.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.calculations.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    navigateTo?(.calculators)
                } label: {
                    HStack {
                        Label("Favourites", systemImage: "star.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.savedIDs.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .keyboardDoneToolbar()
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "FT" }
        let first = parts.first?.prefix(1) ?? "F"
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Settings
struct SettingsView: View {
    @Binding var darkMode: Bool
    @AppStorage("selectedCurrency") private var selectedCurrency = CurrencySettings.selectedCode
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkMode)
            }
            Section("Currency") {
                Picker(selection: $selectedCurrency) {
                    ForEach(CurrencySettings.supportedCurrencies, id: \.code) { curr in
                        HStack {
                            Text(curr.symbol)
                                .frame(width: 30, alignment: .leading)
                            Text(curr.name)
                            Text("(\(curr.code))")
                                .foregroundStyle(.secondary)
                        }
                        .tag(curr.code)
                    }
                } label: {
                    Label("Currency", systemImage: "coloncurrencysign.circle")
                }
            }
            Section("Support") {
                Button {
                    requestReview()
                } label: {
                    HStack {
                        Label("Rate this App", systemImage: "star.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
            Section("Data") {
                HStack {
                    Label("App Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Feedback / Queries
struct FeedbackView: View {
    @State private var feedbackType: Int = 0
    @State private var subject = ""
    @State private var message = ""
    @State private var email = ""
    @State private var submitted = false
    @State private var showMailError = false
    private let types = ["Bug Report", "Feature Request", "General Query", "Other"]
    private let supportEmail = "ashokarbad@gmail.com"

    var body: some View {
        if submitted {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.teal)
                Text("Thank you!")
                    .font(.title2.bold())
                Text("Your feedback has been sent.\nWe will get back to you if needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Submit Another") {
                    withAnimation { resetForm() }
                }
                .buttonStyle(.bordered)
                .tint(.navy)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                Section {
                    SectionHeader(systemImage: "envelope.fill", title: "Feedback / Queries", color: .navy)
                    Picker("Type", selection: $feedbackType) {
                        ForEach(0..<types.count, id: \.self) { Text(types[$0]).tag($0) }
                    }
                    HStack { Text("Subject"); Spacer(); TextField("Brief subject", text: $subject).multilineTextAlignment(.trailing) }
                    HStack {
                        Text("Email (optional)")
                        Spacer()
                        TextField("", text: $email, prompt: Text("you@example.com").foregroundStyle(.quaternary))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Your Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Describe your feedback, bug, or question...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    Button {
                        sendFeedbackEmail()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Submit Feedback", systemImage: "paperplane.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(subject.isEmpty || message.isEmpty)
                    .tint(.navy)
                }
            }
            .keyboardDoneToolbar()
            .alert("Unable to Send Email", isPresented: $showMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not open the mail app. Please send your feedback manually to \(supportEmail).")
            }
        }
    }

    private func sendFeedbackEmail() {
        let typeLabel = types[feedbackType]
        let subjectLine = "[Finance Toolkit] \(typeLabel): \(subject)"
        let body = """
        Type: \(typeLabel)
        From: \(email.isEmpty ? "Not provided" : email)

        \(message)
        """

        let subjectEncoded = subjectLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:\(supportEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)"

        if let url = URL(string: mailtoString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            submitted = true
                        }
                    }
                }
            }
        } else {
            showMailError = true
        }
    }

    private func resetForm() {
        feedbackType = 0
        subject = ""
        message = ""
        email = ""
        submitted = false
    }
}

// MARK: - About
struct AboutView: View {
    @Environment(\.requestReview) private var requestReview

    private let features: [(icon: String, title: String, desc: String)] = [
        ("house.fill", "10+ Loan Calculators", "Home, vehicle, personal, education, business, gold, LAP, agricultural, consumer durable & credit line — each with custom amortization and what-if EMI analysis"),
        ("chart.line.uptrend.xyaxis", "Investment Tools", "SIP, lump sum mutual fund, SWP, FD & RD calculators with detailed growth projections"),
        ("percent", "Tax & Benefits", "Income tax (old vs new regime), NPS, PF & gratuity calculators for Indian tax planning"),
        ("chart.pie.fill", "Expense Tracker", "Track monthly expenses by category with pie chart breakdown, custom categories, yearly overview & PDF/CSV export. Edit or delete any entry."),
        ("arrow.up.forward.circle.fill", "Monthly Outflow", "Track EMIs, subscriptions & bills month-wise with salary tracking, edit support & detailed reports"),
        ("slider.horizontal.3", "Custom Amortization", "Enter a higher EMI on any loan to instantly see months saved, interest saved & the revised schedule"),
        ("note.text", "Smart Notes", "Create styled notes with custom font sizes, colors, bold & italic formatting"),
        ("star.fill", "Save & Export", "Bookmark any calculation, favourite calculators, and export all saved data as PDF or CSV"),
        ("person.crop.circle.fill", "Onboarding & Profile", "Personalised welcome screen on first launch — set your name, age & preferred currency right away"),
        ("lock.shield.fill", "Privacy Screen", "App content is automatically hidden when you switch away — your financial data stays private"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon & Title
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .navy.opacity(0.3), radius: 8, y: 4)
                    .padding(.top, 30)

                VStack(spacing: 6) {
                    Text("Finance Toolkit")
                        .font(.title.bold())
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Your Complete Financial Companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Description
                Text("Finance Toolkit is an all-in-one financial calculator suite built for users worldwide. Whether you're planning a home purchase, comparing investment options, tracking monthly expenses, or analysing loan repayments - this app has you covered with accurate, easy-to-use tools that work in 12 currencies across the globe. A personalised onboarding experience gets you started in seconds, and a built-in privacy screen keeps your data safe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                // Features Grid
                VStack(alignment: .leading, spacing: 6) {
                    Text("Features")
                        .font(.headline)
                        .foregroundStyle(Color.navy)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)

                    ForEach(features, id: \.title) { feature in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: feature.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(Color.teal)
                                .frame(width: 30, height: 30)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.teal.opacity(0.1)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(feature.desc)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.navy.opacity(0.1), lineWidth: 0.5))
                .padding(.horizontal, 16)

                // Highlights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Highlights")
                        .font(.headline)
                        .foregroundStyle(Color.navy)

                    aboutHighlightRow(icon: "globe", text: "Works worldwide — supports 12 currencies including INR, USD, EUR, GBP, AED, SAR, CAD, AUD, SGD, JPY, DOP & more")
                    aboutHighlightRow(icon: "function", text: "Universal financial math — EMI, SIP, FD, RD, SWP & amortization calculations work for any currency or country")
                    aboutHighlightRow(icon: "chart.bar.fill", text: "Yearly graphical overviews for expenses and outflow with month-wise bar charts")
                    aboutHighlightRow(icon: "pencil.circle.fill", text: "Edit & delete expenses and outflow entries — full control over your financial records")
                    aboutHighlightRow(icon: "eye.slash.fill", text: "Privacy screen hides content automatically when you leave the app")
                    aboutHighlightRow(icon: "person.badge.plus", text: "Guided onboarding — set your name, age & currency on first launch")
                    aboutHighlightRow(icon: "moon.fill", text: "Dark mode support with adaptive UI")
                    aboutHighlightRow(icon: "doc.richtext", text: "Export reports as PDF or CSV — share with advisors or keep for records")
                    aboutHighlightRow(icon: "lock.shield.fill", text: "100% offline — your data stays on your device, no sign-up required")
                    aboutHighlightRow(icon: "ipad.and.iphone", text: "Optimized for iPhone & iPad with landscape support")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.teal.opacity(0.15), lineWidth: 0.5))
                .padding(.horizontal, 16)

                // Global note
                VStack(alignment: .leading, spacing: 6) {
                    Text("Global & Indian Features")
                        .font(.headline)
                        .foregroundStyle(Color.navy)

                    Text("Loan calculators, investment tools (SIP, FD, RD, SWP), expense tracking with custom categories, outflow management, notes, privacy screen, onboarding, and custom amortization work universally in any currency.\n\nTax Calculator (Old vs New Regime), NPS, PF, and Gratuity calculators are tailored for Indian tax laws and labour regulations.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.gold.opacity(0.15), lineWidth: 0.5))
                .padding(.horizontal, 16)

                // Rate Button
                Button {
                    requestReview()
                } label: {
                    Label("Rate this App", systemImage: "star.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(LinearGradient(colors: [.navy, .teal], startPoint: .leading, endPoint: .trailing)))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)

                // Footer
                VStack(spacing: 4) {
                    Text("Made with care for users everywhere")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("© 2025 Finance Toolkit. All rights reserved.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.top, 8)
                .padding(.bottom, 30)
            }
        }
    }

    private func aboutHighlightRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.teal)
                .frame(width: 22)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
