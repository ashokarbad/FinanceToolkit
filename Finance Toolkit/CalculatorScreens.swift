//
//  CalculatorScreens.swift
//  TestApp
//
//  Created by ashok arbad on 31/12/25.
//

import SwiftUI

// MARK: - Shared Components

private struct SectionHeader: View {
    let systemImage: String
    let title: String
    let color: Color

    init(systemImage: String, title: String, color: Color = Color(hex: "#185FA5")) {
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
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(color.opacity(0.12))
                )
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(.vertical, 2)
    }
}

private struct ResultCard<Content: View>: View {
    let systemImage: String
    let accentColor: Color
    @ViewBuilder var content: () -> Content

    init(systemImage: String, accentColor: Color = Color(hex: "#185FA5"), @ViewBuilder content: @escaping () -> Content) {
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(accentColor)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.12))
                    )
                Text("Results")
                    .font(.headline)
                    .foregroundStyle(accentColor)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accentColor.opacity(0.28), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

private struct ResultRow: View {
    let label: String
    let value: String
    var isHighlight: Bool = false
    var accentColor: Color = Color(hex: "#185FA5")

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

private struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundStyle(Color(hex: "#185FA5"))
                    .fontWeight(.semibold)
                }
            }
    }
}

private extension View {
    func keyboardDoneToolbar() -> some View { self.modifier(KeyboardDoneToolbar()) }
}

// MARK: - Loan (Home/Car) EMI
// Accent: Navy #185FA5
struct LoanCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    var title: String
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "banknote.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Principal", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("Rate", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
            }
            Section {
                ResultCard(systemImage: "house.fill", accentColor: accent) {
                    ResultRow(label: "EMI", value: vm.emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.emi)
                    ResultRow(label: "Principal", value: vm.principal.formatted(.currency(code: currency)))
                    ResultRow(label: "Total Interest", value: vm.loanTotalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid", value: vm.loanTotalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.loanTotalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.principal) { _ in vm.recalculateAll() }
        .onChange(of: vm.annualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.tenureMonths) { _ in vm.recalculateAll() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Loan Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("EMI is computed using the standard amortization formula. Enter principal, annual interest rate, and tenure in months. Total Paid = Principal + Total Interest.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Higher prepayments or shorter tenure reduce total interest.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - SIP
// Accent: Gold #BA7517
struct SIPCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    @State private var showInfoSheet = false
    @State private var sipMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "calendar.badge.plus", title: "Inputs", color: accent)
                HStack { Text("Monthly Investment"); Spacer(); TextField("Amount", value: $vm.sipMonthly, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $sipMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.sipExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "arrow.up.right.circle.fill", accentColor: accent) {
                    ResultRow(label: "Total Invested", value: vm.sipTotalInvested.formatted(.currency(code: currency)))
                    ResultRow(label: "Est. Returns", value: vm.sipTotalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Future Value", value: vm.sipFutureValue.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.sipFutureValue)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onAppear {
            sipMonths = max(0, vm.sipYears) * 12
        }
        .onChange(of: sipMonths) { _ in
            vm.sipYears = max(0, sipMonths) / 12
        }
        .onChange(of: vm.sipMonthly) { _ in vm.recalculateAll() }
        .onChange(of: vm.sipExpectedReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("SIP Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SIP Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("SIP future value assumes monthly investments compounded at the expected annual return. Results are estimates and not guarantees.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Increasing SIP amount annually can significantly improve long-term corpus.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - SWP
// Accent: Gold #BA7517
struct SWPCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    @State private var showInfoSheet = false
    @State private var swpMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "arrow.down.left.circle.fill", title: "Inputs", color: accent)
                HStack { Text("Corpus"); Spacer(); TextField("Corpus", value: $vm.swpCorpus, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $swpMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Monthly Withdrawal"); Spacer(); TextField("Withdrawal", value: $vm.swpMonthlyWithdrawal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.swpExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "arrow.down.left.circle.fill", accentColor: accent) {
                    ResultRow(label: "Total Withdrawn", value: vm.swpTotalWithdrawn.formatted(.currency(code: currency)))
                    ResultRow(label: "Total Earnings", value: vm.swpTotalEarnings.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Ending Corpus", value: vm.swpEndingCorpus.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.swpEndingCorpus)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onAppear {
            swpMonths = max(0, vm.swpYears) * 12
        }
        .onChange(of: swpMonths) { _ in
            vm.swpYears = max(0, swpMonths) / 12
        }
        .onChange(of: vm.swpCorpus) { _ in vm.recalculateAll() }
        .onChange(of: vm.swpMonthlyWithdrawal) { _ in vm.recalculateAll() }
        .onChange(of: vm.swpExpectedReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("SWP Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SWP Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Systematic Withdrawal Plan simulates monthly withdrawals while the remaining corpus continues to earn returns. Ending corpus depends on withdrawal size and returns.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Choosing a sustainable withdrawal rate helps preserve capital.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - FD
// Accent: Gold #BA7517
struct FDCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    @State private var showInfoSheet = false
    @State private var fdMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "building.columns.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Principal", value: $vm.fdPrincipal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $fdMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.fdAnnualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Compounding / Year"); Spacer(); TextField("Times", value: $vm.fdCompoundingPerYear, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "building.columns.fill", accentColor: accent) {
                    ResultRow(label: "Principal", value: vm.fdPrincipalAmount.formatted(.currency(code: currency)))
                    ResultRow(label: "Interest Earned", value: vm.fdInterestAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Maturity Amount", value: vm.fdMaturityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.fdMaturityAmount)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onAppear {
            fdMonths = max(0, vm.fdYears) * 12
        }
        .onChange(of: fdMonths) { _ in
            vm.fdYears = max(0, fdMonths) / 12
        }
        .onChange(of: vm.fdPrincipal) { _ in vm.recalculateAll() }
        .onChange(of: vm.fdAnnualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.fdCompoundingPerYear) { _ in vm.recalculateAll() }
        .navigationTitle("FD Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("FD Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Fixed Deposit maturity is computed using compound interest with your chosen compounding frequency. Bank rates and compounding may vary.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Senior citizen rates and special tenures may offer higher returns.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - RD
// Accent: Gold #BA7517
struct RDCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    @State private var showInfoSheet = false
    @State private var rdMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "clock.fill", title: "Inputs", color: accent)
                HStack { Text("Monthly Deposit"); Spacer(); TextField("Deposit", value: $vm.rdMonthlyDeposit, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $rdMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.rdAnnualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Compounding / Year"); Spacer(); TextField("Times", value: $vm.rdCompoundingPerYear, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "chart.bar.fill", accentColor: accent) {
                    ResultRow(label: "Total Deposited", value: vm.rdTotalDeposited.formatted(.currency(code: currency)))
                    ResultRow(label: "Interest Earned", value: vm.rdInterestAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Maturity Amount", value: vm.rdMaturityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.rdMaturityAmount)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onAppear {
            rdMonths = max(0, vm.rdYears) * 12
        }
        .onChange(of: rdMonths) { _ in
            vm.rdYears = max(0, rdMonths) / 12
        }
        .onChange(of: vm.rdMonthlyDeposit) { _ in vm.recalculateAll() }
        .onChange(of: vm.rdAnnualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.rdCompoundingPerYear) { _ in vm.recalculateAll() }
        .navigationTitle("RD Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("RD Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Recurring Deposit maturity uses the future value of monthly deposits compounded at the expected rate. Actual bank computation may differ slightly.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Missing deposits can impact the final maturity amount.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Mutual Fund Lump Sum
// Accent: Gold #BA7517
struct LumpSumMFView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    @State private var showInfoSheet = false
    @State private var lumpSumMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "chart.pie.fill", title: "Inputs", color: accent)
                HStack { Text("Lump Sum Amount"); Spacer(); TextField("Amount", value: $vm.lumpSumAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $lumpSumMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.lumpSumExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "chart.line.uptrend.xyaxis", accentColor: accent) {
                    ResultRow(label: "Principal", value: vm.lumpSumPrincipal.formatted(.currency(code: currency)))
                    ResultRow(label: "Est. Returns", value: vm.lumpSumInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Future Value", value: vm.lumpSumFutureValue.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.lumpSumFutureValue)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onAppear {
            lumpSumMonths = max(0, vm.lumpSumYears) * 12
        }
        .onChange(of: lumpSumMonths) { _ in
            vm.lumpSumYears = max(0, lumpSumMonths) / 12
        }
        .onChange(of: vm.lumpSumAmount) { _ in vm.recalculateAll() }
        .onChange(of: vm.lumpSumExpectedReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("MF Lump Sum")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Mutual Fund Lump Sum Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Future value is estimated using annual compounding at your expected return. Market-linked products carry risk; past performance is not indicative of future returns.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Consider diversification and suitable investment horizon.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Tax Calculator
// Accent: Teal #1D9E75
struct TaxCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    @State private var showInfoSheet = false
    private let accent = Color(hex: "#1D9E75")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section("Regime") {
                Picker("Tax Regime", selection: $vm.taxRegime) {
                    Text("Old Regime").tag(0)
                    Text("New Regime").tag(1)
                }
                .pickerStyle(.segmented)
                .tint(accent)
                Text("Old Regime allows popular deductions; New Regime offers lower slabs with fewer deductions.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                SectionHeader(systemImage: "indianrupeesign.circle.fill", title: "Income", color: accent)
                HStack { Text("Basic Salary"); Spacer(); TextField("Amount", value: $vm.taxBasicSalary, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Other Income"); Spacer(); TextField("Amount", value: $vm.taxOtherIncome, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                if vm.taxRegime == 0 {
                    HStack { Text("HRA Exempt"); Spacer(); TextField("Amount", value: $vm.taxHRAExempt, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                }
                HStack { Text("Standard Deduction"); Spacer(); TextField("Amount", value: $vm.taxStandardDeduction, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            if vm.taxRegime == 0 {
                Section {
                    SectionHeader(systemImage: "minus.circle.fill", title: "Deductions (Old Regime)", color: accent)
                    HStack { Text("80C (PF/ELSS/etc.)"); Spacer(); TextField("Amount", value: $vm.taxDeduction80C, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("80D (Health Insurance)"); Spacer(); TextField("Amount", value: $vm.taxDeduction80D, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Other Deductions"); Spacer(); TextField("Amount", value: $vm.taxOtherDeductions, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                }
            }
            Section("Settings") {
                HStack { Text("Cess %"); Spacer(); TextField("%", value: $vm.taxCessPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "percent", accentColor: accent) {
                    ResultRow(label: "Gross Income", value: vm.taxGrossIncome.formatted(.currency(code: currency)))
                    ResultRow(label: "Total Deductions", value: vm.taxTotalDeductions.formatted(.currency(code: currency)))
                    ResultRow(label: "Taxable Income", value: vm.taxTaxableIncomeComputed.formatted(.currency(code: currency)))
                    ResultRow(label: "Tax (before cess)", value: vm.taxBeforeCess.formatted(.currency(code: currency)))
                    ResultRow(label: "Cess", value: vm.taxCessAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Tax Payable", value: vm.taxPayable.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.taxPayable)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.taxRegime) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxBasicSalary) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxOtherIncome) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxHRAExempt) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxStandardDeduction) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxDeduction80C) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxDeduction80D) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxOtherDeductions) { _ in vm.recalculateAll() }
        .onChange(of: vm.taxCessPercent) { _ in vm.recalculateAll() }
        .navigationTitle("Tax Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Tax Info & Reference")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("As per the latest update, there is no tax up to ₹12,00,000 under both regimes in this app. Slabs above 12L are illustrative. Always verify with official sources for your assessment year.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Link(destination: URL(string: "https://www.incometaxindia.gov.in/income-tax-calculator")!) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                Text("Open Official Income Tax Calculator")
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.body.weight(.semibold))
                        }
                    }
                    .padding()
                }
                .navigationTitle("Tax Info")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showInfoSheet = false }
                    }
                }
            }
        }
    }
}

// MARK: - NPS Calculator
// Accent: Teal #1D9E75
struct NPSCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#1D9E75")
    @State private var showInfoSheet = false
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "shield.fill", title: "Inputs", color: accent)
                HStack { Text("Monthly Contribution"); Spacer(); TextField("Amount", value: $vm.npsMonthlyContribution, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Years"); Spacer(); TextField("Years", value: $vm.npsYears, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.npsExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annuity % at Maturity"); Spacer(); TextField("%", value: $vm.npsAnnuityPercentAtMaturity, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annuity Return %"); Spacer(); TextField("%", value: $vm.npsAnnuityReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "shield.fill", accentColor: accent) {
                    ResultRow(label: "Corpus at Maturity", value: vm.npsCorpusAtMaturity.formatted(.currency(code: currency)))
                    ResultRow(label: "Lumpsum Withdrawal", value: vm.npsLumpsumWithdrawal.formatted(.currency(code: currency)))
                    ResultRow(label: "Annuity Purchase", value: vm.npsAnnuityPurchase.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Est. Annual Pension", value: vm.npsEstimatedAnnualPension.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.npsEstimatedAnnualPension)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.npsMonthlyContribution) { _ in vm.recalculateAll() }
        .onChange(of: vm.npsYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.npsExpectedReturnPercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.npsAnnuityPercentAtMaturity) { _ in vm.recalculateAll() }
        .onChange(of: vm.npsAnnuityReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("NPS Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("NPS Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("NPS corpus is estimated by compounding contributions at the expected return. At maturity, a portion is allocated to annuity and the rest can be withdrawn as lumpsum.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Equity allocation during early years may improve long-term corpus, subject to risk profile.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - PF Calculator
// Accent: Teal #1D9E75
struct PFCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#1D9E75")
    @State private var showInfoSheet = false
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            inputsSection
            resultSection
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.pfBasicSalary) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployeeRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployerRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfAnnualReturnPercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfContributionMode) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployeeFixedAmount) { _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployerFixedAmount) { _ in vm.recalculateAll() }
        .navigationTitle("PF Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("PF Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("EPF contributions from employee and employer are accumulated and compounded at the declared annual rate. Actual rules (wage caps, EPS split) may apply.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Changes in basic salary or contribution rates affect the corpus.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }

    private var inputsSection: some View {
        Section {
            SectionHeader(systemImage: "briefcase.fill", title: "Inputs", color: accent)
            Picker("Contribution Mode", selection: $vm.pfContributionMode) {
                Text("Based on Basic Salary").tag(0 as Int)
                Text("Fixed Amount").tag(1 as Int)
            }
            .pickerStyle(.segmented)
            contributionInputs
            HStack { Text("Years"); Spacer(); TextField("Years", value: $vm.pfYears, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            HStack {
                Text("Expected Return %")
                Spacer()
                TextField("%", value: $vm.pfAnnualReturnPercent, format: .number)
                    .multilineTextAlignment(.trailing).keyboardType(.decimalPad)
            }
        }
    }

    @ViewBuilder
    private var contributionInputs: some View {
        if vm.pfContributionMode == 0 {
            HStack { Text("Basic Salary (Monthly)"); Spacer(); TextField("Basic", value: $vm.pfBasicSalary, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            HStack { Text("Employee %"); Spacer(); TextField("%", value: $vm.pfEmployeeRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            HStack { Text("Employer %"); Spacer(); TextField("%", value: $vm.pfEmployerRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
        } else {
            HStack { Text("Employee (Fixed)"); Spacer(); TextField("Amount", value: $vm.pfEmployeeFixedAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            HStack { Text("Employer (Fixed)"); Spacer(); TextField("Amount", value: $vm.pfEmployerFixedAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
        }
    }

    private var resultSection: some View {
        Section {
            ResultCard(systemImage: "briefcase.fill", accentColor: accent) {
                ResultRow(label: "Employee Contribution", value: vm.pfEmployeeContribution.formatted(.currency(code: currency)))
                ResultRow(label: "Employer Contribution", value: vm.pfEmployerContribution.formatted(.currency(code: currency)))
                ResultRow(label: "Total Contribution", value: vm.pfTotalContribution.formatted(.currency(code: currency)))
                Divider().padding(.vertical, 4)
                ResultRow(label: "Corpus at Maturity", value: vm.pfCorpusAtMaturity.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                    .contentTransition(.numericText()).animation(.snappy, value: vm.pfCorpusAtMaturity)
            }
        }
    }
}

// MARK: - Gratuity Calculator
// Accent: Teal #1D9E75
struct GratuityCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#1D9E75")
    @State private var showInfoSheet = false
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "gift.fill", title: "Inputs", color: accent)
                HStack { Text("Last Drawn Basic"); Spacer(); TextField("Basic", value: $vm.gratuityLastDrawnBasic, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Years of Service"); Spacer(); TextField("Years", value: $vm.gratuityYearsOfService, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "gift.fill", accentColor: accent) {
                    ResultRow(label: "Last Drawn Basic", value: vm.gratuityLastDrawnBasic.formatted(.currency(code: currency)))
                    ResultRow(label: "Years of Service", value: "\(Int(floor(vm.gratuityYearsOfService))) yrs")
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Gratuity Amount", value: vm.gratuityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.gratuityAmount)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.gratuityLastDrawnBasic) { _ in vm.recalculateAll() }
        .onChange(of: vm.gratuityYearsOfService) { _ in vm.recalculateAll() }
        .navigationTitle("Gratuity Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Gratuity Calculator Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Gratuity is computed using (15/26) × Last Drawn Basic × Years of Service (rounded down). Statutory limits and eligibility conditions apply.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Service of 5 or more years is generally required for eligibility (with exceptions).")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Vehicle/Personal Loan (Down Payment, Processing Fee)
struct VehiclePersonalLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    let title: String
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var downPayment: Double = 0
    @State private var processingFeePercent: Double = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var netLoanAmount: Double { max(vm.principal - downPayment, 0) }
    private var processingFeeAmount: Double { netLoanAmount * (processingFeePercent / 100.0) }
    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(vm.tenureMonths)
        guard r > 0, n > 0 else { return netLoanAmount / max(n, 1) }
        let numerator = netLoanAmount * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(vm.tenureMonths) + processingFeeAmount }
    private var totalInterest: Double { max(totalPayment - netLoanAmount - processingFeeAmount, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "banknote.fill", title: "Inputs", color: accent)
                HStack { Text("On-road / Principal"); Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Down Payment"); Spacer(); TextField("Amount", value: $downPayment, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %"); Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
            }
            Section {
                ResultCard(systemImage: "car.fill", accentColor: accent) {
                    ResultRow(label: "Net Loan Amount", value: netLoanAmount.formatted(.currency(code: currency)))
                    ResultRow(label: "Processing Fee", value: processingFeeAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest", value: totalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow", value: totalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("\(title) Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("This calculator considers down payment and processing fee. EMI is computed on the net loan amount (On-road/Principal − Down Payment). Processing fee is added to total outflow.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: A larger down payment reduces EMI and total interest.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Education Loan (Moratorium)
struct EducationLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var moratoriumMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var principalAfterMoratorium: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        return vm.principal * pow(1 + r, Double(moratoriumMonths))
    }
    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(max(vm.tenureMonths - moratoriumMonths, 1))
        let p = principalAfterMoratorium
        guard r > 0, n > 0 else { return p / max(n, 1) }
        let numerator = p * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(max(vm.tenureMonths - moratoriumMonths, 0)) }
    private var totalInterest: Double { max(totalPayment - vm.principal, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "book.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Moratorium"); Spacer(); TextField("Months", value: $moratoriumMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad); Text("months").foregroundStyle(.secondary) }
            }
            Section {
                ResultCard(systemImage: "book.fill", accentColor: accent) {
                    ResultRow(label: "Principal after Moratorium", value: principalAfterMoratorium.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest (approx)", value: totalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid (EMIs)", value: totalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.principal) { _ in vm.recalculateAll() }
        .onChange(of: vm.annualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.tenureMonths) { _ in vm.recalculateAll() }
        .onChange(of: moratoriumMonths) { _ in vm.recalculateAll() }
        .navigationTitle("Education Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Education Loan Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("This calculator supports a moratorium period where interest accrues and EMIs start later. Principal grows during moratorium and EMIs are computed on the increased amount.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Paying interest during moratorium can reduce future EMIs.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Credit Line / Overdraft
struct CreditLineOverdraftView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var creditLimit: Double = 500_000
    @State private var utilizationPercent: Double = 40
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var utilizedAmount: Double { creditLimit * (utilizationPercent / 100.0) }
    private var monthlyInterest: Double { utilizedAmount * (vm.annualRatePercent / 100.0) / 12.0 }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "creditcard.fill", title: "Inputs", color: accent)
                HStack { Text("Credit Limit"); Spacer(); TextField("Amount", value: $creditLimit, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Utilization %"); Spacer(); TextField("%", value: $utilizationPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "creditcard.fill", accentColor: accent) {
                    ResultRow(label: "Utilized Amount", value: utilizedAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Monthly Interest (approx)", value: monthlyInterest.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: monthlyInterest)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .navigationTitle("Credit Line / Overdraft")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Credit Line / Overdraft")
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfoSheet = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .tint(accent)
            }
        }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Credit Line / Overdraft Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Interest is charged on the utilized balance only. This view estimates monthly interest based on average utilization and annual rate.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Reducing average utilization lowers monthly interest cost.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Business Loan (Processing Fee)
struct BusinessLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var processingFeePercent: Double = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var processingFeeAmount: Double { vm.principal * (processingFeePercent / 100.0) }
    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(vm.tenureMonths)
        let p = vm.principal
        guard r > 0, n > 0 else { return p / max(n, 1) }
        let numerator = p * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(vm.tenureMonths) + processingFeeAmount }
    private var totalInterest: Double { max((emi * Double(vm.tenureMonths)) - vm.principal, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "briefcase.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %"); Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
            }
            Section {
                ResultCard(systemImage: "briefcase.fill", accentColor: accent) {
                    ResultRow(label: "Processing Fee", value: processingFeeAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest", value: totalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow", value: totalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .navigationTitle("Business Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Business Loan Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Includes processing fee in total outflow. EMI is based on principal at the selected rate and tenure.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Compare processing fee and pre-closure charges across lenders.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Gold Loan (LTV)
struct GoldLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var goldValue: Double = 300_000
    @State private var ltvPercent: Double = 75
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var principalFromLTV: Double { max(goldValue * (ltvPercent / 100.0), 0) }
    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(vm.tenureMonths)
        let p = principalFromLTV
        guard r > 0, n > 0 else { return p / max(n, 1) }
        let numerator = p * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(vm.tenureMonths) }
    private var totalInterest: Double { max(totalPayment - principalFromLTV, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "indianrupeesign.circle.fill", title: "Inputs", color: accent)
                HStack { Text("Gold Value"); Spacer(); TextField("Amount", value: $goldValue, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("LTV %"); Spacer(); TextField("%", value: $ltvPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
            }
            Section {
                ResultCard(systemImage: "indianrupeesign.circle.fill", accentColor: accent) {
                    ResultRow(label: "Eligible Principal (LTV)", value: principalFromLTV.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest", value: totalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid", value: totalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .navigationTitle("Gold Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Gold Loan Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Principal is derived using LTV% of the gold value. EMI is computed on the eligible principal.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Higher LTV increases eligibility but raises EMI and interest.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Loan Against Property (LAP)
struct LAPLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var propertyValue: Double = 5_000_000
    @State private var ltvPercent: Double = 70
    @State private var processingFeePercent: Double = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var principalFromLTV: Double { max(propertyValue * (ltvPercent / 100.0), 0) }
    private var processingFeeAmount: Double { principalFromLTV * (processingFeePercent / 100.0) }
    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(vm.tenureMonths)
        let p = principalFromLTV
        guard r > 0, n > 0 else { return p / max(n, 1) }
        let numerator = p * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(vm.tenureMonths) + processingFeeAmount }
    private var totalInterest: Double { max((emi * Double(vm.tenureMonths)) - principalFromLTV, 0) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "building.2.fill", title: "Inputs", color: accent)
                HStack { Text("Property Value"); Spacer(); TextField("Amount", value: $propertyValue, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("LTV %"); Spacer(); TextField("%", value: $ltvPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %"); Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
            }
            Section {
                ResultCard(systemImage: "building.2.fill", accentColor: accent) {
                    ResultRow(label: "Eligible Principal (LTV)", value: principalFromLTV.formatted(.currency(code: currency)))
                    ResultRow(label: "Processing Fee", value: processingFeeAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    ResultRow(label: "Total Interest", value: totalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow", value: totalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .navigationTitle("Loan Against Property (LAP)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("LAP Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Principal eligibility is derived from property value and LTV%. Processing fee is added to total outflow.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: LTV caps vary by lender and property type.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Agricultural Loan (Monthly EMI, optional moratorium)
struct AgriculturalLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var moratoriumMonths: Int = 0
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var emi: Double {
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(max(vm.tenureMonths - moratoriumMonths, 1))
        let p = vm.principal * pow(1 + r, Double(moratoriumMonths))
        guard r > 0, n > 0 else { return p / max(n, 1) }
        let numerator = p * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(max(vm.tenureMonths - moratoriumMonths, 0)) }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "leaf.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Amount", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
                HStack { Text("Moratorium"); Spacer(); TextField("Months", value: $moratoriumMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad); Text("months").foregroundStyle(.secondary) }
            }
            Section {
                ResultCard(systemImage: "leaf.fill", accentColor: accent) {
                    ResultRow(label: "EMI (monthly)", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Paid (EMIs)", value: totalPayment.formatted(.currency(code: currency)))
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.principal) { _ in vm.recalculateAll() }
        .onChange(of: vm.annualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.tenureMonths) { _ in vm.recalculateAll() }
        .onChange(of: moratoriumMonths) { _ in vm.recalculateAll() }
        .navigationTitle("Agricultural Loan")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Agricultural Loan Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("This version uses monthly EMIs and optionally supports a short moratorium. We can extend it to seasonal or annual repayments if needed.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Align repayments with harvest cycles to manage cash flows.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

// MARK: - Consumer Durable / EMI Loan (No-cost toggle)
struct ConsumerDurableLoanView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#185FA5")
    @State private var showInfoSheet = false
    @State private var price: Double = 50_000
    @State private var downPayment: Double = 0
    @State private var processingFeePercent: Double = 0
    @State private var noCostEMI: Bool = false
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private var netLoanAmount: Double { max(price - downPayment, 0) }
    private var processingFeeAmount: Double { netLoanAmount * (processingFeePercent / 100.0) }
    private var emi: Double {
        if noCostEMI {
            // Evenly spread principal with zero interest
            return netLoanAmount / max(Double(vm.tenureMonths), 1)
        }
        let r = vm.annualRatePercent / 12.0 / 100.0
        let n = Double(vm.tenureMonths)
        let p = netLoanAmount
        guard r > 0, n > 0 else { return p / max(n, 1) }
        let numerator = p * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }
    private var totalPayment: Double { emi * Double(vm.tenureMonths) + processingFeeAmount }
    private var impliedInterest: Double {
        if noCostEMI { return 0 }
        return max((emi * Double(vm.tenureMonths)) - netLoanAmount, 0)
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "cart.fill", title: "Inputs", color: accent)
                HStack { Text("Product Price"); Spacer(); TextField("Amount", value: $price, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Down Payment"); Spacer(); TextField("Amount", value: $downPayment, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Processing Fee %"); Spacer(); TextField("%", value: $processingFeePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Toggle("No-cost EMI", isOn: $noCostEMI)
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack {
                    Text("Tenure in months")
                    Spacer()
                    TextField("Months", value: $vm.tenureMonths, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numberPad)
                    
                }
            }
            Section {
                ResultCard(systemImage: "cart.fill", accentColor: accent) {
                    ResultRow(label: "Net Loan Amount", value: netLoanAmount.formatted(.currency(code: currency)))
                    ResultRow(label: "Processing Fee", value: processingFeeAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "EMI", value: emi.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: emi)
                    if !noCostEMI {
                        ResultRow(label: "Implied Interest", value: impliedInterest.formatted(.currency(code: currency)))
                    }
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Total Outflow", value: totalPayment.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: totalPayment)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .navigationTitle("Consumer Durable / EMI Loan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Consumer Durable / EMI Loan Info")
                            .font(.title2.bold())
                            .foregroundStyle(accent)
                        Text("Supports down payment and processing fee. No-cost EMI spreads principal evenly without interest. Otherwise, standard EMI is used.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Tip: Check effective cost when no-cost EMI includes processing fees.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .navigationTitle("Info")
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Done") { showInfoSheet = false } } }
            }
        }
    }
}

#Preview {
    NavigationStack { MainCalculatorView() }
}

