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
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

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
    private var customAmortization: [AmortizationRow] {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let emiVal = activeEMI
        var balance = vm.principal
        var rows: [AmortizationRow] = []
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

    /// Standard amortization from VM converted to shared type
    private var standardAmortization: [AmortizationRow] {
        vm.amortizationSchedule.map { AmortizationRow(id: $0.id, month: $0.month, emi: $0.emi, principal: $0.principal, interest: $0.interest, balance: $0.balance) }
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
                .init(label: "EMI",            value: CurrencySettings.formatCurrency(vm.emi, code: currency),               isHighlight: true),
                .init(label: "Principal",      value: CurrencySettings.formatCurrency(vm.principal, code: currency),          isHighlight: false),
                .init(label: "Total Interest", value: CurrencySettings.formatCurrency(vm.loanTotalInterest, code: currency),  isHighlight: false),
                .init(label: "Total Paid",     value: CurrencySettings.formatCurrency(vm.loanTotalPayment, code: currency),   isHighlight: true),
            ]
        )
    }

    var body: some View {
        Form {
            // Inputs
            Section {
                SectionHeader(systemImage: "house.fill", title: L("Loan Details"), color: accent)
                HStack {
                    Text(L("Loan Amount"))
                    Spacer()
                    TextField(L("Amount"), value: $vm.principal, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                HStack {
                    Text(L("Annual Rate %"))
                    Spacer()
                    TextField(L("Rate"), value: $vm.annualRatePercent, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                }
                HStack {
                    Text(L("Tenure (months)"))
                    Spacer()
                    TextField(L("Months"), value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing).keyboardType(.numberPad)
                }
            }

            // Result
            Section {
                ResultCard(systemImage: "house.fill", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: makeSnapshot())
                }) {
                    ResultRow(label: L("Monthly EMI"),    value: CurrencySettings.formatCurrency(vm.emi, code: currency),              isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.emi)
                    ResultRow(label: L("Principal"),       value: CurrencySettings.formatCurrency(vm.principal, code: currency))
                    ResultRow(label: L("Total Interest"),  value: CurrencySettings.formatCurrency(vm.loanTotalInterest, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: L("Total Paid"),      value: CurrencySettings.formatCurrency(vm.loanTotalPayment, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.loanTotalPayment)
                }
            }

            // Custom Amortization section
            Section {
                SectionHeader(systemImage: "slider.horizontal.3", title: L("Custom Amortization"), color: accent)
                Toggle(L("Use Custom EMI"), isOn: $customEMIEnabled)
                if customEMIEnabled {
                    HStack {
                        Text(L("Your EMI"))
                        Spacer()
                        TextField(L("EMI"), value: $customEMI, format: .number)
                            .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
                    }
                    if customEMI > 0 && customEMI >= minimumEMI {
                        VStack(alignment: .leading, spacing: 6) {
                            ResultRow(label: L("Custom EMI"), value: CurrencySettings.formatCurrency(activeEMI, code: currency), isHighlight: true, accentColor: accent)
                            ResultRow(label: L("New Tenure"), value: "\(customAmortization.count) \(L("months"))")
                            ResultRow(label: L("New Total Interest"), value: CurrencySettings.formatCurrency(customTotalInterest, code: currency))
                            ResultRow(label: L("New Total Paid"), value: CurrencySettings.formatCurrency(customTotalPaid, code: currency))
                            if tenureSaved > 0 || interestSaved > 0 {
                                Divider().padding(.vertical, 2)
                                HStack {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .foregroundStyle(.teal)
                                    Text(L("You save \(tenureSaved) months & \(CurrencySettings.formatCurrency(interestSaved, code: currency)) interest"))
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.teal)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } else if customEMI > 0 {
                        Text(L("EMI must be at least \(CurrencySettings.formatCurrency(minimumEMI, code: currency)) to cover monthly interest."))
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
                        Text(L("View Amortization Schedule"))
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
                        rows: customEMIEnabled ? customAmortization : standardAmortization,
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
        .navigationTitle(L("Home Loan"))
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
                title: L("Home Loan Calculator"),
                body1: L("EMI = P × r × (1+r)^n / [(1+r)^n − 1], where P = principal, r = monthly rate, n = months. The amortisation schedule shows month-by-month breakdown of principal, interest and outstanding balance."),
                body2: L("Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save. Prepaying even small extra amounts towards principal can cut total interest dramatically."),
                accent: accent
            )
        }
    }
}


