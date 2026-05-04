// LoanCalculators.swift
// Finance Toolkit — Vehicle, Personal, Education, Business, Gold, LAP, Agricultural, Credit Line, Consumer Durable

import SwiftUI

// MARK: - Vehicle / Personal Loan
struct VehiclePersonalLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    let title: String
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var downPayment: Double = 0
    @State private var processingFeePercent: Double = 0
    @State private var insuranceAmount: Double = 0
    @State private var rtoCharges: Double = 0
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var isVehicle: Bool { title.lowercased().contains("vehicle") || title.lowercased().contains("car") }
    private var netLoanAmount: Double { max(vm.principal - downPayment, 0) }
    private var processingFeeAmount: Double { netLoanAmount * (processingFeePercent / 100.0) }
    private var emi: Double { vm.calculateEMI(principal: netLoanAmount, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths) }
    private var totalEMIPaid: Double { emi * Double(vm.tenureMonths) }
    private var totalInterest: Double { max(totalEMIPaid - netLoanAmount, 0) }
    private var totalOutflow: Double { totalEMIPaid + processingFeeAmount + (isVehicle ? insuranceAmount + rtoCharges : 0) }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: title, icon: isVehicle ? "car.fill" : "person.fill", date: Date(),
            note: "Net Loan ₹\(Int(netLoanAmount).formatted()) · \(vm.tenureMonths) months",
            results: [
                .init(label: "EMI",            value: CurrencySettings.formatCurrency(emi, code: currency),            isHighlight: true),
                .init(label: "Net Loan",        value: CurrencySettings.formatCurrency(netLoanAmount, code: currency),  isHighlight: false),
                .init(label: "Total Interest",  value: CurrencySettings.formatCurrency(totalInterest, code: currency),  isHighlight: false),
                .init(label: "Total Outflow",   value: CurrencySettings.formatCurrency(totalOutflow, code: currency),   isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: isVehicle ? "car.fill" : "person.fill", title: "Loan Details", color: accent)
                HStack { Text("On-road / Principal"); Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Down Payment");  Spacer(); TextField("Amount", value: $downPayment, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %"); Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                if isVehicle {
                    HStack { Text("Insurance Amount"); Spacer(); TextField("Amount", value: $insuranceAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("RTO / Registration"); Spacer(); TextField("Amount", value: $rtoCharges, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)"); Spacer(); TextField("Months", value: $vm.tenureMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: isVehicle ? "car.fill" : "person.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Net Loan Amount",  value: CurrencySettings.formatCurrency(netLoanAmount, code: currency))
                    ResultRow(label: "Processing Fee",   value: CurrencySettings.formatCurrency(processingFeeAmount, code: currency))
                    if isVehicle {
                        ResultRow(label: "Insurance",    value: CurrencySettings.formatCurrency(insuranceAmount, code: currency))
                        ResultRow(label: "RTO Charges",  value: CurrencySettings.formatCurrency(rtoCharges, code: currency))
                    }
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI",              value: CurrencySettings.formatCurrency(emi, code: currency),        isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest",   value: CurrencySettings.formatCurrency(totalInterest, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow",    value: CurrencySettings.formatCurrency(totalOutflow, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalOutflow)
                }
            }
            CustomAmortizationSection(
                principal: netLoanAmount,
                annualRatePercent: vm.annualRatePercent,
                standardEMI: emi,
                standardTenureMonths: vm.tenureMonths,
                standardTotalInterest: totalInterest,
                accent: accent, currency: currency,
                customEMIEnabled: $customEMIEnabled,
                customEMI: $customEMI
            )
            AmortizationToggleSection(
                rows: buildGenericAmortization(principal: netLoanAmount, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths, emi: emi),
                customRows: customEMIEnabled ? buildCustomAmortization(principal: netLoanAmount, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, netLoanAmount * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                customEMIEnabled: customEMIEnabled,
                accent: accent, currency: currency, showAmortization: $showAmortization)
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.principal)         { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.tenureMonths)      { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onAppear { customEMI = emi }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "\(title) Info",
                      body1: "EMI is computed on the net loan amount (On-road − Down Payment). Processing fee, insurance and RTO charges add to total outflow but do not affect EMI.",
                      body2: "Tip: A larger down payment reduces EMI and total interest paid over the tenure. Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save.", accent: accent)
        }
    }
}

// MARK: - Education Loan
struct EducationLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var moratoriumMonths: Int = 0
    @State private var repaymentMonths: Int = 60
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var principalAfterMoratorium: Double { vm.principal * pow(1 + vm.annualRatePercent / 12.0 / 100.0, Double(moratoriumMonths)) }
    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(max(repaymentMonths, 1))
        let p = principalAfterMoratorium
        guard r > 0 else { return p / n }
        return p * r * pow(1+r,n) / (pow(1+r,n)-1)
    }
    private var totalEMIPaid: Double { emi * Double(repaymentMonths) }
    private var totalInterest: Double { max(totalEMIPaid - vm.principal, 0) }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "Education Loan", icon: "book.fill", date: Date(),
            note: "Principal ₹\(Int(vm.principal).formatted()) · Moratorium \(moratoriumMonths)m",
            results: [
                .init(label: "Principal after Moratorium", value: CurrencySettings.formatCurrency(principalAfterMoratorium, code: currency), isHighlight: false),
                .init(label: "EMI", value: CurrencySettings.formatCurrency(emi, code: currency), isHighlight: true),
                .init(label: "Total Interest", value: CurrencySettings.formatCurrency(totalInterest, code: currency), isHighlight: false),
                .init(label: "Total Paid", value: CurrencySettings.formatCurrency(totalEMIPaid, code: currency), isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "book.fill", title: "Loan Details", color: accent)
                HStack { Text("Loan Amount");        Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %");       Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Moratorium (months)"); Spacer(); TextField("Months", value: $moratoriumMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Repayment (months)");  Spacer(); TextField("Months", value: $repaymentMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                Text("During the moratorium, interest accrues and no EMIs are paid. EMI is then computed on the grown principal.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                ResultCard(systemImage: "book.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Principal after Moratorium", value: CurrencySettings.formatCurrency(principalAfterMoratorium, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI",               value: CurrencySettings.formatCurrency(emi, code: currency),          isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest",    value: CurrencySettings.formatCurrency(totalInterest, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid",        value: CurrencySettings.formatCurrency(totalEMIPaid, code: currency),  isHighlight: true, accentColor: accent)
                }
            }
            CustomAmortizationSection(
                principal: principalAfterMoratorium,
                annualRatePercent: vm.annualRatePercent,
                standardEMI: emi,
                standardTenureMonths: repaymentMonths,
                standardTotalInterest: totalInterest,
                accent: accent, currency: currency,
                customEMIEnabled: $customEMIEnabled,
                customEMI: $customEMI
            )
            AmortizationToggleSection(
                rows: buildGenericAmortization(principal: principalAfterMoratorium, annualRatePercent: vm.annualRatePercent, months: repaymentMonths, emi: emi),
                customRows: customEMIEnabled ? buildCustomAmortization(principal: principalAfterMoratorium, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, principalAfterMoratorium * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                customEMIEnabled: customEMIEnabled,
                accent: accent, currency: currency, showAmortization: $showAmortization)
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.principal)         { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onAppear { customEMI = emi }
        .navigationTitle("Education Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Education Loan Info",
                      body1: "During moratorium (usually study + 6 months), interest compounds and EMIs have not yet started. Once moratorium ends, EMI is computed on the grown outstanding amount.",
                      body2: "Tip: Paying interest during the moratorium period keeps the outstanding balance from growing and results in lower future EMIs. Use Custom Amortization to see how a higher EMI saves months and interest.",
                      accent: accent)
        }
    }
}

// MARK: - Business Loan
struct BusinessLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var processingFeePercent: Double = 1.0
    @State private var collateralValue: Double = 0
    @State private var loanPurpose: String = "Working Capital"
    private let purposes = ["Working Capital", "Equipment Purchase", "Business Expansion", "Inventory", "Other"]
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var processingFee: Double { vm.principal * (processingFeePercent / 100.0) }
    private var emi: Double { vm.calculateEMI(principal: vm.principal, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths) }
    private var totalPaid: Double { emi * Double(vm.tenureMonths) + processingFee }
    private var totalInterest: Double { max(emi * Double(vm.tenureMonths) - vm.principal, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "briefcase.fill", title: "Loan Details", color: accent)
                Picker("Loan Purpose", selection: $loanPurpose) {
                    ForEach(purposes, id: \.self) { Text($0).tag($0) }
                }
                HStack { Text("Loan Amount");       Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Collateral Value");  Spacer(); TextField("Amount", value: $collateralValue, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %");  Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %");     Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");   Spacer(); TextField("Months", value: $vm.tenureMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            if collateralValue > 0 {
                Section("Collateral Coverage") {
                    let ratio = collateralValue / max(vm.principal, 1)
                    ResultRow(label: "Coverage Ratio", value: String(format: "%.1fx", ratio))
                    Text(ratio >= 1.2 ? "✅ Adequate collateral coverage" : "⚠️ Low coverage — lender may require additional security")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section {
                ResultCard(systemImage: "briefcase.fill", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: SavedCalculation(calculatorTitle: "Business Loan (\(loanPurpose))", icon: "briefcase.fill", date: Date(), note: "", results: [
                        .init(label: "EMI", value: CurrencySettings.formatCurrency(emi, code: currency), isHighlight: true),
                        .init(label: "Processing Fee", value: CurrencySettings.formatCurrency(processingFee, code: currency), isHighlight: false),
                        .init(label: "Total Interest", value: CurrencySettings.formatCurrency(totalInterest, code: currency), isHighlight: false),
                        .init(label: "Total Outflow", value: CurrencySettings.formatCurrency(totalPaid, code: currency), isHighlight: true),
                    ]))
                }) {
                    ResultRow(label: "EMI",             value: CurrencySettings.formatCurrency(emi, code: currency),           isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Processing Fee",  value: CurrencySettings.formatCurrency(processingFee, code: currency))
                    ResultRow(label: "Total Interest",  value: CurrencySettings.formatCurrency(totalInterest, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow",   value: CurrencySettings.formatCurrency(totalPaid, code: currency),      isHighlight: true, accentColor: accent)
                }
            }
            CustomAmortizationSection(
                principal: vm.principal,
                annualRatePercent: vm.annualRatePercent,
                standardEMI: emi,
                standardTenureMonths: vm.tenureMonths,
                standardTotalInterest: totalInterest,
                accent: accent, currency: currency,
                customEMIEnabled: $customEMIEnabled,
                customEMI: $customEMI
            )
            AmortizationToggleSection(
                rows: buildGenericAmortization(principal: vm.principal, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths, emi: emi),
                customRows: customEMIEnabled ? buildCustomAmortization(principal: vm.principal, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, vm.principal * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                customEMIEnabled: customEMIEnabled,
                accent: accent, currency: currency, showAmortization: $showAmortization)
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.principal) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.tenureMonths) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onAppear { customEMI = emi }
        .navigationTitle("Business Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Business Loan Info",
                      body1: "Business loans may be secured (with collateral) or unsecured. Rates vary by lender, loan purpose and creditworthiness. The processing fee is typically 0.5–2% of loan amount.",
                      body2: "Tip: MSME loans under ₹1Cr may qualify for priority-sector rates. Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save.", accent: accent)
        }
    }
}

// MARK: - Gold Loan
struct GoldLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var goldValue: Double = 5_00_000
    @State private var ltvPercent: Double = 75
    @State private var loanType: Int = 0  // 0 = EMI, 1 = Bullet (interest-only)
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var principalFromLTV: Double { goldValue * (ltvPercent / 100.0) }
    private var monthlyInterestOnly: Double { principalFromLTV * (vm.annualRatePercent / 100.0) / 12.0 }
    private var emiAmount: Double { vm.calculateEMI(principal: principalFromLTV, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths) }
    private var totalPaid: Double {
        loanType == 0 ? emiAmount * Double(vm.tenureMonths) : monthlyInterestOnly * Double(vm.tenureMonths) + principalFromLTV
    }
    private var totalInterest: Double { max(totalPaid - principalFromLTV, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "sparkles", title: "Gold Loan Details", color: accent)
                HStack { Text("Gold Jewellery Value"); Spacer(); TextField("Amount", value: $goldValue, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("LTV %");               Spacer(); TextField("%", value: $ltvPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %");        Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");      Spacer(); TextField("Months", value: $vm.tenureMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                Picker("Repayment Type", selection: $loanType) {
                    Text("EMI (reducing balance)").tag(0)
                    Text("Bullet (interest-only + lumpsum)").tag(1)
                }
            }
            Section("Eligible Loan Amount") {
                ResultRow(label: "Gold Value",       value: CurrencySettings.formatCurrency(goldValue, code: currency))
                ResultRow(label: "LTV Applied",      value: "\(Int(ltvPercent))%")
                ResultRow(label: "Loan Eligible",    value: CurrencySettings.formatCurrency(principalFromLTV, code: currency), isHighlight: true, accentColor: accent)
            }
            Section {
                ResultCard(systemImage: "sparkles", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: SavedCalculation(calculatorTitle: "Gold Loan", icon: "sparkles", date: Date(), note: "Gold ₹\(Int(goldValue).formatted()) · LTV \(Int(ltvPercent))%", results: [
                        .init(label: loanType == 0 ? "EMI" : "Monthly Interest", value: CurrencySettings.formatCurrency((loanType == 0 ? emiAmount : monthlyInterestOnly), code: currency), isHighlight: true),
                        .init(label: "Total Interest", value: CurrencySettings.formatCurrency(totalInterest, code: currency), isHighlight: false),
                        .init(label: "Total Outflow", value: CurrencySettings.formatCurrency(totalPaid, code: currency), isHighlight: true),
                    ]))
                }) {
                    if loanType == 0 {
                        ResultRow(label: "EMI", value: CurrencySettings.formatCurrency(emiAmount, code: currency), isHighlight: true, accentColor: accent)
                            .contentTransition(.numericText()).animation(.snappy, value: emiAmount)
                    } else {
                        ResultRow(label: "Monthly Interest", value: CurrencySettings.formatCurrency(monthlyInterestOnly, code: currency), isHighlight: true, accentColor: accent)
                        ResultRow(label: "Principal at End", value: CurrencySettings.formatCurrency(principalFromLTV, code: currency))
                    }
                    ResultRow(label: "Total Interest", value: CurrencySettings.formatCurrency(totalInterest, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow", value: CurrencySettings.formatCurrency(totalPaid, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPaid)
                }
            }
            if loanType == 0 {
                CustomAmortizationSection(
                    principal: principalFromLTV,
                    annualRatePercent: vm.annualRatePercent,
                    standardEMI: emiAmount,
                    standardTenureMonths: vm.tenureMonths,
                    standardTotalInterest: totalInterest,
                    accent: accent, currency: currency,
                    customEMIEnabled: $customEMIEnabled,
                    customEMI: $customEMI
                )
                AmortizationToggleSection(
                    rows: buildGenericAmortization(principal: principalFromLTV, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths, emi: emiAmount),
                    customRows: customEMIEnabled ? buildCustomAmortization(principal: principalFromLTV, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, principalFromLTV * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                    customEMIEnabled: customEMIEnabled,
                    accent: accent, currency: currency, showAmortization: $showAmortization)
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emiAmount } }
        .onChange(of: vm.tenureMonths) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emiAmount } }
        .onAppear { customEMI = emiAmount }
        .navigationTitle("Gold Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Gold Loan Info",
                      body1: "RBI caps LTV at 75% for gold loans. EMI type spreads both principal and interest monthly. Bullet type requires only monthly interest with full principal at end.",
                      body2: "Tip: Gold loans typically have lower rates than personal loans. Use Custom Amortization (EMI mode) to enter a higher EMI and see how many months and how much interest you save.", accent: accent)
        }
    }
}

// MARK: - LAP
struct LAPLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var propertyValue: Double = 50_00_000
    @State private var ltvPercent: Double = 70
    @State private var processingFeePercent: Double = 0.5
    @State private var propertyType: String = "Residential"
    private let propertyTypes = ["Residential", "Commercial", "Industrial", "Land"]
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var principalFromLTV: Double { propertyValue * (ltvPercent / 100.0) }
    private var processingFee: Double { principalFromLTV * (processingFeePercent / 100.0) }
    private var emi: Double { vm.calculateEMI(principal: principalFromLTV, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths) }
    private var totalInterest: Double { max(emi * Double(vm.tenureMonths) - principalFromLTV, 0) }
    private var totalOutflow: Double { emi * Double(vm.tenureMonths) + processingFee }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "building.2.fill", title: "Property Details", color: accent)
                Picker("Property Type", selection: $propertyType) {
                    ForEach(propertyTypes, id: \.self) { Text($0).tag($0) }
                }
                HStack { Text("Property Value");    Spacer(); TextField("Amount", value: $propertyValue, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("LTV %");             Spacer(); TextField("%", value: $ltvPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %");  Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %");     Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");   Spacer(); TextField("Months", value: $vm.tenureMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "building.2.fill", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: SavedCalculation(calculatorTitle: "Loan Against Property (LAP)", icon: "building.2.fill", date: Date(), note: "\(propertyType) · LTV \(Int(ltvPercent))%", results: [
                        .init(label: "Eligible Principal", value: CurrencySettings.formatCurrency(principalFromLTV, code: currency), isHighlight: false),
                        .init(label: "EMI", value: CurrencySettings.formatCurrency(emi, code: currency), isHighlight: true),
                        .init(label: "Total Interest", value: CurrencySettings.formatCurrency(totalInterest, code: currency), isHighlight: false),
                        .init(label: "Total Outflow", value: CurrencySettings.formatCurrency(totalOutflow, code: currency), isHighlight: true),
                    ]))
                }) {
                    ResultRow(label: "Eligible Principal (LTV)", value: CurrencySettings.formatCurrency(principalFromLTV, code: currency), isHighlight: false, accentColor: accent)
                    ResultRow(label: "Processing Fee",           value: CurrencySettings.formatCurrency(processingFee, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI",                      value: CurrencySettings.formatCurrency(emi, code: currency),           isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest",           value: CurrencySettings.formatCurrency(totalInterest, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow",            value: CurrencySettings.formatCurrency(totalOutflow, code: currency),   isHighlight: true, accentColor: accent)
                }
            }
            CustomAmortizationSection(
                principal: principalFromLTV,
                annualRatePercent: vm.annualRatePercent,
                standardEMI: emi,
                standardTenureMonths: vm.tenureMonths,
                standardTotalInterest: totalInterest,
                accent: accent, currency: currency,
                customEMIEnabled: $customEMIEnabled,
                customEMI: $customEMI
            )
            AmortizationToggleSection(
                rows: buildGenericAmortization(principal: principalFromLTV, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths, emi: emi),
                customRows: customEMIEnabled ? buildCustomAmortization(principal: principalFromLTV, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, principalFromLTV * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                customEMIEnabled: customEMIEnabled,
                accent: accent, currency: currency, showAmortization: $showAmortization)
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.tenureMonths) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onAppear { customEMI = emi }
        .navigationTitle("Loan Against Property")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "LAP Info",
                      body1: "LTV (Loan-to-Value) determines what % of property value you can borrow. Residential: up to 75%, Commercial: up to 65%, Land: up to 50% typically.",
                      body2: "Tip: A lower LTV request may get a better interest rate. Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save.", accent: accent)
        }
    }
}

// MARK: - Agricultural Loan
struct AgriculturalLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var moratoriumMonths: Int = 0
    @State private var cropCycle: String = "Kharif (June-Nov)"
    private let cropCycles = ["Kharif (June-Nov)", "Rabi (Nov-Apr)", "Zaid (Apr-June)", "Annual"]
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var principalGrown: Double { vm.principal * pow(1 + vm.annualRatePercent / 12.0 / 100.0, Double(moratoriumMonths)) }
    private var repayMonths: Int { max(vm.tenureMonths - moratoriumMonths, 1) }
    private var emi: Double { vm.calculateEMI(principal: principalGrown, annualRatePercent: vm.annualRatePercent, months: repayMonths) }
    private var totalPaid: Double { emi * Double(repayMonths) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "leaf.fill", title: "Agricultural Loan Details", color: accent)
                HStack { Text("Loan Amount");        Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %");       Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Total Tenure (mo)");   Spacer(); TextField("Months", value: $vm.tenureMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Moratorium (mo)");     Spacer(); TextField("Months", value: $moratoriumMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                Picker("Crop Cycle", selection: $cropCycle) {
                    ForEach(cropCycles, id: \.self) { Text($0).tag($0) }
                }
            }
            Section("Repayment Info") {
                ResultRow(label: "Repayment Months",      value: "\(repayMonths) months")
                ResultRow(label: "Principal (post-morat.)", value: CurrencySettings.formatCurrency(principalGrown, code: currency))
                Text("Align EMIs with your crop cycle harvest for better cash-flow management.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                ResultCard(systemImage: "leaf.fill", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: SavedCalculation(calculatorTitle: "Agricultural Loan (\(cropCycle))", icon: "leaf.fill", date: Date(), note: "", results: [
                        .init(label: "EMI", value: CurrencySettings.formatCurrency(emi, code: currency), isHighlight: true),
                        .init(label: "Total Paid", value: CurrencySettings.formatCurrency(totalPaid, code: currency), isHighlight: true),
                    ]))
                }) {
                    ResultRow(label: "EMI (monthly)", value: CurrencySettings.formatCurrency(emi, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid (EMIs)", value: CurrencySettings.formatCurrency(totalPaid, code: currency))
                }
            }
            CustomAmortizationSection(
                principal: principalGrown,
                annualRatePercent: vm.annualRatePercent,
                standardEMI: emi,
                standardTenureMonths: repayMonths,
                standardTotalInterest: max(totalPaid - vm.principal, 0),
                accent: accent, currency: currency,
                customEMIEnabled: $customEMIEnabled,
                customEMI: $customEMI
            )
            AmortizationToggleSection(
                rows: buildGenericAmortization(principal: principalGrown, annualRatePercent: vm.annualRatePercent, months: repayMonths, emi: emi),
                customRows: customEMIEnabled ? buildCustomAmortization(principal: principalGrown, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, principalGrown * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                customEMIEnabled: customEMIEnabled,
                accent: accent, currency: currency, showAmortization: $showAmortization)
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.principal) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.annualRatePercent) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.tenureMonths) { _, _ in vm.recalculateAll(); if !customEMIEnabled { customEMI = emi } }
        .onAppear { customEMI = emi }
        .navigationTitle("Agricultural Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Agricultural Loan Info",
                      body1: "Kisan Credit Card (KCC) loans under ₹3L attract subsidised interest rates (often ~7% p.a.). NABARD and cooperative banks offer crop-specific financing.",
                      body2: "Tip: Under PM-KISAN and PMFBY, insurance subsidies are available. Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save.", accent: accent)
        }
    }
}

// MARK: - Credit Line / Overdraft
struct CreditLineOverdraftView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var creditLimit: Double = 5_00_000
    @State private var utilizationPercent: Double = 40
    @State private var averageMonths: Int = 6
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var utilizedAmount: Double { creditLimit * (utilizationPercent / 100.0) }
    private var monthlyInterest: Double { utilizedAmount * (vm.annualRatePercent / 100.0) / 12.0 }
    private var totalInterest6Months: Double { monthlyInterest * Double(averageMonths) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "creditcard.fill", title: "Credit Line Details", color: accent)
                HStack { Text("Credit Limit");       Spacer(); TextField("Amount", value: $creditLimit, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Utilization %");      Spacer(); TextField("%", value: $utilizationPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %");      Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Projection (months)"); Spacer(); TextField("Months", value: $averageMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "creditcard.fill", accentColor: accent) {
                    ResultRow(label: "Utilized Amount",          value: CurrencySettings.formatCurrency(utilizedAmount, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Monthly Interest (approx)", value: CurrencySettings.formatCurrency(monthlyInterest, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: monthlyInterest)
                    ResultRow(label: "Interest over \(averageMonths) months", value: CurrencySettings.formatCurrency(totalInterest6Months, code: currency))
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .navigationTitle("Credit Line / Overdraft")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Credit Line Info",
                      body1: "Interest is charged only on the amount withdrawn (utilised), not the full credit limit. This is unlike a term loan where you pay interest on the full disbursed amount.",
                      body2: "Tip: Reducing average utilization and repaying drawn amounts quickly can significantly lower interest cost.", accent: accent)
        }
    }
}

// MARK: - Consumer Durable / EMI Loan
struct ConsumerDurableLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.navy
    @State private var showInfoSheet = false
    @State private var showAmortization = false
    @State private var price: Double = 50_000
    @State private var downPayment: Double = 0
    @State private var processingFeePercent: Double = 0
    @State private var noCostEMI: Bool = false
    @State private var customEMIEnabled = false
    @State private var customEMI: Double = 0
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private var netLoanAmount: Double { max(price - downPayment, 0) }
    private var processingFeeAmount: Double { netLoanAmount * (processingFeePercent / 100.0) }
    private var emi: Double {
        if noCostEMI { return netLoanAmount / max(Double(vm.tenureMonths), 1) }
        return vm.calculateEMI(principal: netLoanAmount, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths)
    }
    private var totalPayment: Double { emi * Double(vm.tenureMonths) + processingFeeAmount }
    private var impliedInterest: Double { noCostEMI ? 0 : max(emi * Double(vm.tenureMonths) - netLoanAmount, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "cart.fill", title: "Product & Loan Details", color: accent)
                HStack { Text("Product Price");      Spacer(); TextField("Amount", value: $price, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Down Payment");       Spacer(); TextField("Amount", value: $downPayment, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %");   Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Toggle("No-cost EMI", isOn: $noCostEMI)
                if !noCostEMI {
                    HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                }
                HStack { Text("Tenure (months)"); Spacer(); TextField("Months", value: $vm.tenureMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            if noCostEMI {
                Section {
                    Label("No-cost EMI: principal spread evenly — but check if processing fees make it costlier than it appears.", systemImage: "exclamationmark.triangle")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section {
                ResultCard(systemImage: "cart.fill", accentColor: accent, onSave: {
                    SavedStore.shared.save(calculation: SavedCalculation(calculatorTitle: "Consumer Durable / EMI", icon: "cart.fill", date: Date(), note: noCostEMI ? "No-cost EMI" : "Standard EMI", results: [
                        .init(label: "EMI", value: CurrencySettings.formatCurrency(emi, code: currency), isHighlight: true),
                        .init(label: "Implied Interest", value: CurrencySettings.formatCurrency(impliedInterest, code: currency), isHighlight: false),
                        .init(label: "Total Outflow", value: CurrencySettings.formatCurrency(totalPayment, code: currency), isHighlight: true),
                    ]))
                }) {
                    ResultRow(label: "Net Loan Amount",  value: CurrencySettings.formatCurrency(netLoanAmount, code: currency))
                    ResultRow(label: "Processing Fee",   value: CurrencySettings.formatCurrency(processingFeeAmount, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI",              value: CurrencySettings.formatCurrency(emi, code: currency),         isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    if !noCostEMI {
                        ResultRow(label: "Implied Interest", value: CurrencySettings.formatCurrency(impliedInterest, code: currency))
                    }
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow",    value: CurrencySettings.formatCurrency(totalPayment, code: currency), isHighlight: true, accentColor: accent)
                }
            }
            if !noCostEMI {
                CustomAmortizationSection(
                    principal: netLoanAmount,
                    annualRatePercent: vm.annualRatePercent,
                    standardEMI: emi,
                    standardTenureMonths: vm.tenureMonths,
                    standardTotalInterest: impliedInterest,
                    accent: accent, currency: currency,
                    customEMIEnabled: $customEMIEnabled,
                    customEMI: $customEMI
                )
                AmortizationToggleSection(
                    rows: buildGenericAmortization(principal: netLoanAmount, annualRatePercent: vm.annualRatePercent, months: vm.tenureMonths, emi: emi),
                    customRows: customEMIEnabled ? buildCustomAmortization(principal: netLoanAmount, annualRatePercent: vm.annualRatePercent, customEMI: max(customEMI, netLoanAmount * (vm.annualRatePercent / 12.0 / 100.0) + 1)) : nil,
                    customEMIEnabled: customEMIEnabled,
                    accent: accent, currency: currency, showAmortization: $showAmortization)
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { customEMI = emi }
        .onChange(of: vm.annualRatePercent) { _, _ in if !customEMIEnabled { customEMI = emi } }
        .onChange(of: vm.tenureMonths) { _, _ in if !customEMIEnabled { customEMI = emi } }
        .navigationTitle("Consumer Durable / EMI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Consumer Durable EMI Info",
                      body1: "No-cost EMI simply spreads the product price with zero interest. However, the discount (if any) is foregone and processing fees still apply, making the effective rate non-zero.",
                      body2: "Tip: Compare standard EMI vs no-cost EMI total outflow. Use Custom Amortization to enter a higher EMI and see how many months and how much interest you save.", accent: accent)
        }
    }
}
