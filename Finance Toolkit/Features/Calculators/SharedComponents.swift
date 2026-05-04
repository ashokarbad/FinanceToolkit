// SharedComponents.swift
// Finance Toolkit — reusable UI components for calculator screens

import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let systemImage: String
    let title: String
    let color: Color

    init(systemImage: String, title: String, color: Color = .navy) {
        self.systemImage = systemImage
        self.title = title
        self.color = color
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.opacity(0.12)))
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Result Card
struct ResultCard<Content: View>: View {
    let systemImage: String
    let accentColor: Color
    let title: String
    let onSave: (() -> Void)?
    @ViewBuilder var content: () -> Content

    init(systemImage: String,
         accentColor: Color = .navy,
         title: String = "Results",
         onSave: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.title = title
        self.onSave = onSave
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(accentColor)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(accentColor.opacity(0.12)))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Spacer()
                if let onSave {
                    SaveSkipButtons(onSave: onSave)
                }
            }
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(accentColor.opacity(0.28), lineWidth: 1))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
    }
}

// MARK: - Save / Skip buttons
struct SaveSkipButtons: View {
    let onSave: () -> Void
    @State private var saved = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                onSave()
                saved = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: saved ? "checkmark.circle.fill" : "bookmark")
                    .font(.system(size: 12, weight: .semibold))
                Text(saved ? "Saved" : "Save")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(saved ? .white : .navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(saved ? Color.teal : Color.navy.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .disabled(saved)
    }
}

// MARK: - Result Row
struct ResultRow: View {
    let label: String
    let value: String
    var isHighlight: Bool = false
    var accentColor: Color = .navy

    var body: some View {
        HStack {
            Text(label)
                .font(isHighlight ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(isHighlight ? accentColor : .primary)
            Spacer()
            Text(value)
                .font(isHighlight ? .subheadline.bold() : .subheadline)
                .foregroundStyle(isHighlight ? accentColor : .secondary)
        }
    }
}

// MARK: - Keyboard Done toolbar
struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundStyle(Color.navy)
                .fontWeight(.semibold)
            }
        }
    }
}

extension View {
    func keyboardDoneToolbar() -> some View { modifier(KeyboardDoneToolbar()) }
}

// MARK: - Amortization schedule view (shared)
struct AmortizationRow: Identifiable {
    let id: Int
    let month: Int
    let emi: Double
    let principal: Double
    let interest: Double
    let balance: Double
}

/// Builds a generic amortization schedule for any reducing-balance loan.
func buildGenericAmortization(principal: Double, annualRatePercent: Double, months: Int, emi: Double) -> [AmortizationRow] {
    let r = annualRatePercent / 12.0 / 100.0
    var balance = principal
    var rows: [AmortizationRow] = []
    for month in 1...max(months, 1) {
        let interest = balance * r
        let prin = min(emi - interest, balance)
        balance = max(balance - prin, 0)
        rows.append(AmortizationRow(id: month, month: month, emi: emi, principal: prin, interest: interest, balance: balance))
        if balance <= 0 { break }
    }
    return rows
}

struct AmortizationScheduleView: View {
    let rows: [AmortizationRow]
    let accent: Color
    let currency: String

    @State private var showAll = false
    private let previewCount = 12

    var displayedRows: [AmortizationRow] {
        showAll ? rows : Array(rows.prefix(previewCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Month").font(.caption.weight(.bold)).frame(width: 44, alignment: .leading)
                Text("EMI").font(.caption.weight(.bold)).frame(maxWidth: .infinity, alignment: .trailing)
                Text("Principal").font(.caption.weight(.bold)).frame(maxWidth: .infinity, alignment: .trailing)
                Text("Interest").font(.caption.weight(.bold)).frame(maxWidth: .infinity, alignment: .trailing)
                Text("Balance").font(.caption.weight(.bold)).frame(maxWidth: .infinity, alignment: .trailing)
            }
            .foregroundStyle(accent)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)

            Divider()

            ForEach(displayedRows) { row in
                HStack {
                    Text("\(row.month)").font(.caption).frame(width: 44, alignment: .leading)
                    Text(shortCurrency(row.emi)).font(.caption).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(shortCurrency(row.principal)).font(.caption).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(shortCurrency(row.interest)).font(.caption).frame(maxWidth: .infinity, alignment: .trailing)
                    Text(shortCurrency(row.balance)).font(.caption.bold()).frame(maxWidth: .infinity, alignment: .trailing).foregroundStyle(accent)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
                .background(row.month % 2 == 0 ? Color.primary.opacity(0.03) : Color.clear)
            }

            if rows.count > previewCount {
                Button {
                    withAnimation { showAll.toggle() }
                } label: {
                    Text(showAll ? "Show less" : "Show all \(rows.count) months")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
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

/// Reusable amortization toggle section for any loan calculator.
struct AmortizationToggleSection: View {
    let rows: [AmortizationRow]
    var customRows: [AmortizationRow]? = nil
    var customEMIEnabled: Bool = false
    let accent: Color
    let currency: String
    @Binding var showAmortization: Bool

    var body: some View {
        Section {
            Button {
                withAnimation { showAmortization.toggle() }
            } label: {
                HStack {
                    Image(systemName: "list.number")
                        .foregroundStyle(accent)
                    Text("View Amortization Schedule")
                        .foregroundStyle(accent)
                    Spacer()
                    Image(systemName: showAmortization ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)

            if showAmortization {
                AmortizationScheduleView(
                    rows: (customEMIEnabled && customRows != nil) ? customRows! : rows,
                    accent: accent,
                    currency: currency
                )
            }
        }
    }
}

// MARK: - Custom Amortization Section (what-if EMI analysis)

/// Builds a custom amortization schedule given a principal, annual rate, and a custom EMI amount.
func buildCustomAmortization(principal: Double, annualRatePercent: Double, customEMI: Double) -> [AmortizationRow] {
    let r = annualRatePercent / 12.0 / 100.0
    var balance = principal
    var rows: [AmortizationRow] = []
    var month = 1
    let maxMonths = 600 // safety cap at 50 years
    while balance > 0 && month <= maxMonths {
        let interest = balance * r
        let prin = min(customEMI - interest, balance)
        balance = max(balance - prin, 0)
        rows.append(.init(id: month, month: month, emi: customEMI, principal: prin, interest: interest, balance: balance))
        if balance <= 0 { break }
        month += 1
    }
    return rows
}

/// Reusable custom amortization section with what-if EMI analysis.
struct CustomAmortizationSection: View {
    let principal: Double
    let annualRatePercent: Double
    let standardEMI: Double
    let standardTenureMonths: Int
    let standardTotalInterest: Double
    let accent: Color
    let currency: String
    @Binding var customEMIEnabled: Bool
    @Binding var customEMI: Double

    private var minimumEMI: Double {
        let r = annualRatePercent / 12.0 / 100.0
        return principal * r + 1
    }

    private var activeEMI: Double {
        max(customEMI, minimumEMI)
    }

    private var customSchedule: [AmortizationRow] {
        buildCustomAmortization(principal: principal, annualRatePercent: annualRatePercent, customEMI: activeEMI)
    }

    private var customTotalPaid: Double { activeEMI * Double(customSchedule.count) }
    private var customTotalInterest: Double { max(customTotalPaid - principal, 0) }
    private var tenureSaved: Int { max(standardTenureMonths - customSchedule.count, 0) }
    private var interestSaved: Double { max(standardTotalInterest - customTotalInterest, 0) }

    var body: some View {
        Section {
            SectionHeader(systemImage: "slider.horizontal.3", title: "Custom Amortization", color: accent)
            Toggle("Use Custom EMI", isOn: $customEMIEnabled)
            if customEMIEnabled {
                HStack {
                    Text("Your EMI")
                    Spacer()
                    TextField("EMI", value: $customEMI, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                if customEMI > 0 && customEMI >= minimumEMI {
                    VStack(alignment: .leading, spacing: 6) {
                        ResultRow(label: "Custom EMI", value: CurrencySettings.formatCurrency(activeEMI, code: currency), isHighlight: true, accentColor: accent)
                        ResultRow(label: "New Tenure", value: "\(customSchedule.count) months")
                        ResultRow(label: "New Total Interest", value: CurrencySettings.formatCurrency(customTotalInterest, code: currency))
                        ResultRow(label: "New Total Paid", value: CurrencySettings.formatCurrency(customTotalPaid, code: currency))
                        if tenureSaved > 0 || interestSaved > 0 {
                            Divider().padding(.vertical, 2)
                            HStack {
                                Image(systemName: "arrow.down.circle.fill")
                                    .foregroundStyle(.teal)
                                Text("You save \(tenureSaved) months & \(CurrencySettings.formatCurrency(interestSaved, code: currency)) interest")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.teal)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } else if customEMI > 0 {
                    Text("EMI must be at least \(CurrencySettings.formatCurrency(minimumEMI, code: currency)) to cover monthly interest.")
                        .font(.caption).foregroundStyle(.red)
                }
            }
        }
    }
}

// MARK: - Info sheet builder
struct InfoSheet: View {
    let title: String
    let body1: String
    let body2: String
    let accent: Color
    var link: String? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(accent)
                    Text(body1)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(body2)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    if let urlStr = link, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                Text("Open Official Calculator")
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.body.weight(.semibold))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}


