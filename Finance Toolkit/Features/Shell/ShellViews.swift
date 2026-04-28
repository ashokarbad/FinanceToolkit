// ShellViews.swift
// Finance Toolkit — sidebar destination views (Dashboard, Saved, Tips, Profile, Settings, About)

import SwiftUI
import StoreKit

// MARK: - Dashboard
struct DashboardView: View {
    @ObservedObject private var store = SavedStore.shared
    @ObservedObject private var expenseStore = ExpenseStore.shared
    @ObservedObject private var outflowStore = OutflowStore.shared
    var navigateTo: ((SidebarDestination) -> Void)?
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var currentMonthExpenseTotal: Double {
        let cal = Calendar.current
        let now = Date()
        return expenseStore.expenses.filter {
            cal.isDate($0.date, equalTo: now, toGranularity: .month)
        }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    Button { navigateTo?(.saved) } label: {
                        DashboardCard(title: "Saved Items", value: "\(store.calculations.count)", icon: "bookmark.fill", color: .navy)
                    }
                    .buttonStyle(.plain)

                    Button { navigateTo?(.calculators) } label: {
                        DashboardCard(title: "Favourites", value: "Calculators", icon: "star.fill", color: .gold)
                    }
                    .buttonStyle(.plain)

                    Button { navigateTo?(.expenses) } label: {
                        DashboardCard(
                            title: "Monthly Expenses",
                            value: currentMonthExpenseTotal.formatted(.currency(code: currency)),
                            icon: "chart.pie.fill",
                            color: Color(hex: "#E87D2B")
                        )
                    }
                    .buttonStyle(.plain)

                    Button { navigateTo?(.outflow) } label: {
                        DashboardCard(
                            title: "Monthly Outflow",
                            value: outflowStore.items.reduce(0) { $0 + $1.amount }.formatted(.currency(code: currency)),
                            icon: "arrow.up.forward.circle.fill",
                            color: .teal
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(color.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Saved
struct SavedView: View {
    @ObservedObject private var store = SavedStore.shared
    @State private var sharePDFURL: URL?
    @State private var shareAllPDFURL: URL?
    @State private var shareCSVURL: URL?
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    var body: some View {
        Group {
            if store.calculations.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "star")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.tertiary)
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
                List {
                    ForEach(store.calculations) { calc in
                        savedCalcRow(calc)
                    }
                    .onDelete { offsets in store.delete(at: offsets) }
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

    }

    @ViewBuilder
    private func savedCalcRow(_ calc: SavedCalculation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: calc.icon)
                    .foregroundStyle(.secondary)
                Text(calc.calculatorTitle)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(calc.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !calc.note.isEmpty {
                Text(calc.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(calc.results, id: \.label) { entry in
                HStack {
                    Text(entry.label)
                        .font(entry.isHighlight ? .caption.weight(.semibold) : .caption)
                    Spacer()
                    Text(entry.value)
                        .font(entry.isHighlight ? .caption.bold() : .caption)
                        .foregroundStyle(entry.isHighlight ? .primary : .secondary)
                }
            }
            // User note
            if let userNote = calc.userNote, !userNote.text.isEmpty {
                Divider()
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "note.text")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: userNote.colorHex))
                    Text(userNote.text)
                        .font(.system(size: CGFloat(userNote.fontSize),
                                      weight: userNote.isBold ? .bold : .regular))
                        .italic(userNote.isItalic)
                        .foregroundStyle(Color(hex: userNote.colorHex))
                }
            }
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .leading) {
            Button {
                sharePDFURL = generateSavedPDF(calculations: [calc])
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            .tint(.navy)
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                store.delete(id: calc.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
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
        // Find max result columns
        let maxResults = calculations.map(\.results.count).max() ?? 0
        for i in 0..<maxResults {
            csv += ",Label \(i+1),Value \(i+1)"
        }
        csv += ",User Note\n"

        for calc in calculations {
            let dateStr = calc.date.formatted(date: .abbreviated, time: .omitted)
            let escapedNote = calc.note.replacingOccurrences(of: ",", with: " ")
            csv += "\(calc.calculatorTitle),\(dateStr),\(escapedNote)"
            for entry in calc.results {
                let escapedLabel = entry.label.replacingOccurrences(of: ",", with: " ")
                let escapedValue = entry.value.replacingOccurrences(of: ",", with: " ")
                csv += ",\(escapedLabel),\(escapedValue)"
            }
            // Pad if fewer results
            for _ in calc.results.count..<maxResults {
                csv += ",,"
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
    private let tips: [(icon: String, title: String, detail: String)] = [
        ("lightbulb.fill", "Start SIPs early", "Even small monthly investments grow significantly over 15–20 years thanks to compounding."),
        ("percent", "Compare tax regimes", "Use the Tax Calculator to check which regime — Old or New — saves you more tax."),
        ("house.fill", "Prepay your home loan", "Extra payments towards the principal reduce total interest dramatically."),
        ("shield.fill", "Max out NPS for tax benefits", "NPS gives an extra ₹50K deduction under 80CCD(1B) beyond ₹1.5L under 80C."),
        ("banknote.fill", "Track your PF balance", "EPF earns ~8.1% p.a. tax-free — one of the best guaranteed-return instruments."),
        ("gift.fill", "Know your gratuity entitlement", "After 5 years of service, gratuity up to ₹20L is tax-exempt."),
        ("chart.line.uptrend.xyaxis", "SWP for retirement income", "Use SWP from a mutual fund corpus to create a monthly pension-like income."),
        ("creditcard.fill", "Avoid high-interest debt", "Credit card/overdraft interest (24–42% p.a.) compounds fast — pay off quickly."),
    ]

    var body: some View {
        List {
            ForEach(tips, id: \.title) { tip in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#E87D2B"))
                        .frame(width: 30, height: 30)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#E87D2B").opacity(0.12)))
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
        ("house.fill", "Loan Calculators", "Home loan, vehicle loan, personal loan & education loan with full amortization schedules"),
        ("chart.line.uptrend.xyaxis", "Investment Tools", "SIP, lump sum, mutual fund, FD, RD & PPF calculators with growth projections"),
        ("indianrupeesign.circle", "Tax Planning", "Income tax calculator supporting old & new regime with HRA, 80C & 80D deductions"),
        ("person.badge.clock", "Retirement", "NPS, PF, gratuity & retirement corpus calculators to plan your financial future"),
        ("chart.pie.fill", "Expense Tracker", "Track monthly expenses with category-wise breakdown, charts & PDF/CSV export"),
        ("arrow.up.arrow.down", "Monthly Outflow", "Manage recurring & one-time outflows with salary tracking and month-wise views"),
        ("note.text", "Smart Notes", "Create styled notes with custom font sizes, colors, bold & italic formatting"),
        ("star.fill", "Save & Compare", "Bookmark any calculation result and export all saved data as PDF or Excel"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App Icon & Title
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.navy, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.top, 30)

                VStack(spacing: 6) {
                    Text("Finance Toolkit")
                        .font(.title.bold())
                    Text("Version 1.0")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Your Complete Indian Financial Companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Description
                Text("Finance Toolkit is an all-in-one financial calculator suite designed for Indian users. Whether you're planning a home purchase, comparing investment options, filing taxes, or tracking monthly expenses — this app has you covered with accurate, easy-to-use tools.")
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

                    aboutHighlightRow(icon: "globe", text: "Supports 10 currencies — INR, USD, EUR, GBP & more")
                    aboutHighlightRow(icon: "moon.fill", text: "Dark mode support with adaptive UI")
                    aboutHighlightRow(icon: "doc.richtext", text: "Export reports as PDF or Excel (CSV)")
                    aboutHighlightRow(icon: "lock.shield.fill", text: "100% offline — your data stays on your device")
                    aboutHighlightRow(icon: "ipad.and.iphone", text: "Optimized for iPhone & iPad with landscape support")
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.teal.opacity(0.15), lineWidth: 0.5))
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
                    Text("Made with care in India")
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
