// HomeLoanView.swift
// Finance Toolkit — Home Loan with full amortization schedule

import SwiftUI

struct HomeLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    /// The minimum EMI is the interest-only payment for month 1 (otherwise balance never reduces)
    private var minimumEMI: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        return vm.principal * r + 1 // at least ₹1 above interest
    }

    /// Active EMI used for the what-if amortization
    private var activeEMI: Double {
        customEMIEnabled ? max(customEMI, minimumEMI) : vm.emi
    }

    /// Custom amortization schedule based on the active EMI
    private var customAmortization: [CalculatorViewModel.AmortizationRow] {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let emiVal = activeEMI
        var balance = vm.principal
        var rows: [CalculatorViewModel.AmortizationRow] = []
        var month = 1
        let maxMonths = 600 // safety cap at 50 years
        while balance > 0 && month <= maxMonths {
            let interest = balance * r
            let prin = min(emiVal - interest, balance)
            balance = max(balance - prin, 0)
            rows.append(.init(id: month, month: month, emi: emiVal, principal: prin, interest: interest, balance: balance))
            if balance <= 0 { break }
            month += 1
        }
        return rows
    }

    private var customTotalPaid: Double { activeEMI * Double(customAmortization.count) }
    private var customTotalInterest: Double { max(customTotalPaid - vm.principal, 0) }
    private var tenureSaved: Int { max(vm.tenureMonths - customAmortization.count, 0) }
    private var interestSaved: Double { max(vm.loanTotalInterest - customTotalInterest, 0) }

    // Helper to build SavedCalculation snapshot
    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(
            calculatorTitle: "Home Loan",
            icon: "house.fill",
            date: Date(),
            note: "Principal ₹\(Int(vm.principal).formatted()) · \(vm.tenureMonths) months",
            results: [
                .init(label: "EMI",            value: vm.emi.formatted(.currency(code: currency)),               isHighlight: true),
                .init(label: "Principal",      value: vm.principal.formatted(.currency(code: currency)),          isHighlight: false),
                .init(label: "Total Interest", value: vm.loanTotalInterest.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Total Paid",     value: vm.loanTotalPayment.formatted(.currency(code: currency)),   isHighlight: true),
            ]
        )
    }

    var body: some View {
        Form {
            // Inputs
            Section {
                SectionHeader(systemImage: "house.fill", title: "Loan Details", color: accent)
                HStack {
                    Text("Loan Amount")
                    Spacer()
                    TextField("Amount", value: $vm.principal, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                HStack {
                    Text("Annual Rate %")
                    Spacer()
                    TextField("Rate", value: $vm.annualRatePercent, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                HStack {
                    Text("Tenure (months)")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.numberPad)
                }
            }

            // Result
            Section {
                ResultCard(systemImage: "house.fill", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: makeSnapshot())
                }) {
                    ResultRow(label: "Monthly EMI",    value: vm.emi.formatted(.currency(code: currency)),              isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.emi)
                    ResultRow(label: "Principal",       value: vm.principal.formatted(.currency(code: currency)))
                    ResultRow(label: "Total Interest",  value: vm.loanTotalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid",      value: vm.loanTotalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.loanTotalPayment)
                }
            }

            // What-if EMI section
            Section {
                SectionHeader(systemImage: "slider.horizontal.3", title: "What-If EMI", color: accent)
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
                            ResultRow(label: "Custom EMI", value: activeEMI.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                            ResultRow(label: "New Tenure", value: "\(customAmortization.count) months")
                            ResultRow(label: "New Total Interest", value: customTotalInterest.formatted(.currency(code: currency)))
                            ResultRow(label: "New Total Paid", value: customTotalPaid.formatted(.currency(code: currency)))
                            if tenureSaved > 0 || interestSaved > 0 {
                                Divider().padding(.vertical, 2)
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.teal)
                                    Text("You save \(tenureSaved) months & \(interestSaved.formatted(.currency(code: currency))) interest")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else if customEMI > 0 {
                        Text("EMI must be at least \(minimumEMI.formatted(.currency(code: currency))) to cover monthly interest.")
                            .font(.caption).foregroundStyle(.red)
                    }
                }
            }

            // Amortization toggle
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
                        rows: customEMIEnabled ? customAmortization : vm.amortizationSchedule,
                        accent: accent,
                        currency: currency
                    )
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onAppear { customEMI = vm.emi }
        .onChange(of: vm.principal)         { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = vm.emi } }
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = vm.emi } }
        .onChange(of: vm.tenureMonths)      { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = vm.emi } }
        .navigationTitle("Home Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showInfoSheet = true } label: {
                    Image(systemName: "info.circle")
                }.tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(
                title: "Home Loan Calculator",
                body1: "EMI is calculated using standard amortisation. Total Paid = Principal + Total Interest. The amortisation schedule shows month-by-month breakdown of principal, interest and outstanding balance.",
                body2: "Tip: Making prepayments reduces the outstanding principal and can significantly cut total interest. Shorter tenure = lower total interest but higher EMI.",
                accent: accent
            )
        }
    }
}

// MARK: - Amortization schedule view
struct AmortizationScheduleView: View {
    let rows: [CalculatorViewModel.AmortizationRow]
    let accent: Color
    let currency: String

    @State private var showAll = false
    private let previewCount = 12

    var displayedRows: [CalculatorViewModel.AmortizationRow] {
        showAll ? rows : Array(rows.prefix(previewCount))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
        if value >= 1_00_000 {
            return String(format: "₹%.1fL", value / 1_00_000)
        } else if value >= 1_000 {
            return String(format: "₹%.0fK", value / 1_000)
        }
        return String(format: "₹%.0f", value)
    }
}
