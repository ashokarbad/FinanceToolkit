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

            // Custom Amortization section
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
                body1: "EMI = P × r × (1+r)^n / [(1+r)^n − 1], where P = principal, r = monthly rate, n = months. The amortisation schedule shows month-by-month breakdown of principal, interest and outstanding balance.",
                body2: "Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save. Prepaying even small extra amounts towards principal can cut total interest dramatically.",
                accent: accent
            )
        }
    }
}


