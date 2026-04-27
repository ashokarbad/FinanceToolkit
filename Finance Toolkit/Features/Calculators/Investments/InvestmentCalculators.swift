// InvestmentCalculators.swift
// Finance Toolkit — SIP, SWP, FD, RD, Mutual Fund Lump Sum

import SwiftUI

// MARK: - SIP
struct SIPCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.gold
    @State private var showInfoSheet = false
    @State private var sipMonths: Int = 120
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "SIP Calculator", icon: "calendar.badge.plus", date: Date(),
            note: "₹\(Int(vm.sipMonthly).formatted())/mo · \(sipMonths) months",
            results: [
                .init(label: "Total Invested",  value: vm.sipTotalInvested.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Est. Returns",    value: vm.sipTotalInterest.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Future Value",    value: vm.sipFutureValue.formatted(.currency(code: currency)),    isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "calendar.badge.plus", title: "SIP Inputs", color: accent)
                HStack { Text("Monthly Investment"); Spacer(); TextField("Amount", value: $vm.sipMonthly, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)"); Spacer(); TextField("Months", value: $sipMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.sipExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "chart.line.uptrend.xyaxis", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Total Invested", value: vm.sipTotalInvested.formatted(.currency(code: currency)))
                    ResultRow(label: "Est. Returns",   value: vm.sipTotalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Future Value",   value: vm.sipFutureValue.formatted(.currency(code: currency)),  isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.sipFutureValue)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { sipMonths = vm.sipYears * 12 }
        .onChange(of: sipMonths) { _, _ in vm.sipYears = max(1, sipMonths / 12); vm.recalculateAll() }
        .onChange(of: vm.sipMonthly) { _, _ in vm.recalculateAll() }
        .onChange(of: vm.sipExpectedReturnPercent) { _, _ in vm.recalculateAll() }
        .navigationTitle("SIP Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "SIP Calculator Info",
                      body1: "SIP (Systematic Investment Plan) future value uses monthly compounding of your expected annual return. Results are projections — actual mutual fund returns vary.",
                      body2: "Tip: Increasing your SIP amount by 10% annually (step-up SIP) can significantly improve your long-term corpus.",
                      accent: accent)
        }
    }
}

// MARK: - SWP
struct SWPCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.gold
    @State private var showInfoSheet = false
    @State private var swpMonths: Int = 60
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "SWP Calculator", icon: "arrow.down.left.circle.fill", date: Date(),
            note: "Corpus ₹\(Int(vm.swpCorpus).formatted()) · Withdraw ₹\(Int(vm.swpMonthlyWithdrawal).formatted())/mo",
            results: [
                .init(label: "Total Withdrawn", value: vm.swpTotalWithdrawn.formatted(.currency(code: currency)), isHighlight: false),
                .init(label: "Total Earnings",  value: vm.swpTotalEarnings.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Ending Corpus",   value: vm.swpEndingCorpus.formatted(.currency(code: currency)),   isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "arrow.down.left.circle.fill", title: "SWP Inputs", color: accent)
                HStack { Text("Initial Corpus");       Spacer(); TextField("Amount", value: $vm.swpCorpus, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Monthly Withdrawal");   Spacer(); TextField("Amount", value: $vm.swpMonthlyWithdrawal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");      Spacer(); TextField("Months", value: $swpMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Expected Return %");    Spacer(); TextField("%", value: $vm.swpExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            if vm.swpMonthlyWithdrawal > 0 {
                Section("Sustainable Withdrawal") {
                    let sustainableRate = vm.swpCorpus * (vm.swpExpectedReturnPercent / 100.0) / 12.0
                    ResultRow(label: "Max Sustainable/mo", value: sustainableRate.formatted(.currency(code: currency)))
                    Text(vm.swpMonthlyWithdrawal <= sustainableRate
                         ? "✅ Withdrawal is within sustainable limit — corpus may grow."
                         : "⚠️ Withdrawal exceeds returns — corpus will deplete over time.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section {
                ResultCard(systemImage: "arrow.down.left.circle.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Total Withdrawn", value: vm.swpTotalWithdrawn.formatted(.currency(code: currency)))
                    ResultRow(label: "Total Earnings",  value: vm.swpTotalEarnings.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Ending Corpus",   value: vm.swpEndingCorpus.formatted(.currency(code: currency)),  isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.swpEndingCorpus)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { swpMonths = vm.swpYears * 12 }
        .onChange(of: swpMonths) { _, _ in vm.swpYears = max(1, swpMonths / 12); vm.recalculateAll() }
        .onChange(of: vm.swpCorpus) { _, _ in vm.recalculateAll() }
        .onChange(of: vm.swpMonthlyWithdrawal) { _, _ in vm.recalculateAll() }
        .onChange(of: vm.swpExpectedReturnPercent) { _, _ in vm.recalculateAll() }
        .navigationTitle("SWP Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "SWP Calculator Info",
                      body1: "SWP (Systematic Withdrawal Plan) simulates monthly withdrawals from a corpus that continues to earn returns. The ending corpus depends on withdrawal rate and returns.",
                      body2: "Tip: A withdrawal rate ≤ annual return preserves or grows the corpus. Many retirees use the 4% rule as a starting benchmark.",
                      accent: accent)
        }
    }
}

// MARK: - FD
struct FDCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.gold
    @State private var showInfoSheet = false
    @State private var fdMonths: Int = 36
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "FD Calculator", icon: "building.columns.fill", date: Date(),
            note: "₹\(Int(vm.fdPrincipal).formatted()) · \(fdMonths) months",
            results: [
                .init(label: "Principal",        value: vm.fdPrincipalAmount.formatted(.currency(code: currency)), isHighlight: false),
                .init(label: "Interest Earned",  value: vm.fdInterestAmount.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Maturity Amount",  value: vm.fdMaturityAmount.formatted(.currency(code: currency)),  isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "building.columns.fill", title: "FD Inputs", color: accent)
                HStack { Text("Principal");            Spacer(); TextField("Amount", value: $vm.fdPrincipal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");      Spacer(); TextField("Months", value: $fdMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Annual Rate %");        Spacer(); TextField("%", value: $vm.fdAnnualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Compounding / Year");   Spacer(); TextField("Times", value: $vm.fdCompoundingPerYear, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "building.columns.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Principal",       value: vm.fdPrincipalAmount.formatted(.currency(code: currency)))
                    ResultRow(label: "Interest Earned", value: vm.fdInterestAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Maturity Amount", value: vm.fdMaturityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.fdMaturityAmount)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { fdMonths = vm.fdYears * 12 }
        .onChange(of: fdMonths) { _, _ in vm.fdYears = max(1, fdMonths / 12); vm.recalculateAll() }
        .onChange(of: vm.fdPrincipal)          { _, _ in vm.recalculateAll() }
        .onChange(of: vm.fdAnnualRatePercent)  { _, _ in vm.recalculateAll() }
        .onChange(of: vm.fdCompoundingPerYear) { _, _ in vm.recalculateAll() }
        .navigationTitle("FD Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "FD Calculator Info",
                      body1: "Fixed Deposit maturity uses compound interest: A = P(1 + r/n)^(n×t). Quarterly compounding (n=4) is most common in Indian banks.",
                      body2: "Tip: Senior citizens get an additional 0.25–0.50% p.a. rate benefit. Tax-saving FDs have a 5-year lock-in.",
                      accent: accent)
        }
    }
}

// MARK: - RD
struct RDCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.gold
    @State private var showInfoSheet = false
    @State private var rdMonths: Int = 36
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "RD Calculator", icon: "calendar.circle.fill", date: Date(),
            note: "₹\(Int(vm.rdMonthlyDeposit).formatted())/mo · \(rdMonths) months",
            results: [
                .init(label: "Total Deposited",  value: vm.rdTotalDeposited.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Interest Earned",  value: vm.rdInterestAmount.formatted(.currency(code: currency)),   isHighlight: false),
                .init(label: "Maturity Amount",  value: vm.rdMaturityAmount.formatted(.currency(code: currency)),   isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "calendar.circle.fill", title: "RD Inputs", color: accent)
                HStack { Text("Monthly Deposit");   Spacer(); TextField("Amount", value: $vm.rdMonthlyDeposit, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");   Spacer(); TextField("Months", value: $rdMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Annual Rate %");     Spacer(); TextField("%", value: $vm.rdAnnualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Compounding / Year"); Spacer(); TextField("Times", value: $vm.rdCompoundingPerYear, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
            }
            Section {
                ResultCard(systemImage: "calendar.circle.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Total Deposited",  value: vm.rdTotalDeposited.formatted(.currency(code: currency)))
                    ResultRow(label: "Interest Earned",  value: vm.rdInterestAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Maturity Amount",  value: vm.rdMaturityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.rdMaturityAmount)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { rdMonths = vm.rdYears * 12 }
        .onChange(of: rdMonths) { _, _ in vm.rdYears = max(1, rdMonths / 12); vm.recalculateAll() }
        .onChange(of: vm.rdMonthlyDeposit)   { _, _ in vm.recalculateAll() }
        .onChange(of: vm.rdAnnualRatePercent){ _, _ in vm.recalculateAll() }
        .onChange(of: vm.rdCompoundingPerYear){ _, _ in vm.recalculateAll() }
        .navigationTitle("RD Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "RD Calculator Info",
                      body1: "Recurring Deposit grows monthly deposits using future-value of annuity formula. Post Office RDs and bank RDs are popular safe-return options.",
                      body2: "Tip: Missing even one RD instalment can affect the maturity amount and may attract penalties at some banks.",
                      accent: accent)
        }
    }
}

// MARK: - MF Lump Sum
struct LumpSumMFView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.gold
    @State private var showInfoSheet = false
    @State private var lumpSumMonths: Int = 120
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "MF Lump Sum", icon: "chart.pie.fill", date: Date(),
            note: "₹\(Int(vm.lumpSumAmount).formatted()) · \(lumpSumMonths) months",
            results: [
                .init(label: "Principal",       value: vm.lumpSumPrincipal.formatted(.currency(code: currency)),  isHighlight: false),
                .init(label: "Est. Returns",    value: vm.lumpSumInterest.formatted(.currency(code: currency)),   isHighlight: false),
                .init(label: "Future Value",    value: vm.lumpSumFutureValue.formatted(.currency(code: currency)), isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "chart.pie.fill", title: "Investment Inputs", color: accent)
                HStack { Text("Lump Sum Amount");    Spacer(); TextField("Amount", value: $vm.lumpSumAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");    Spacer(); TextField("Months", value: $lumpSumMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Expected Return %");  Spacer(); TextField("%", value: $vm.lumpSumExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "chart.line.uptrend.xyaxis", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Principal",       value: vm.lumpSumPrincipal.formatted(.currency(code: currency)))
                    ResultRow(label: "Est. Returns",    value: vm.lumpSumInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Future Value",    value: vm.lumpSumFutureValue.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.lumpSumFutureValue)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { lumpSumMonths = vm.lumpSumYears * 12 }
        .onChange(of: lumpSumMonths) { _, _ in vm.lumpSumYears = max(1, lumpSumMonths / 12); vm.recalculateAll() }
        .onChange(of: vm.lumpSumAmount) { _, _ in vm.recalculateAll() }
        .onChange(of: vm.lumpSumExpectedReturnPercent) { _, _ in vm.recalculateAll() }
        .navigationTitle("MF Lump Sum")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Mutual Fund Lump Sum Info",
                      body1: "FV = P × (1 + r)^n using your expected annual return compounded annually. Equity MFs historically deliver 12–15% CAGR over 10+ years but returns are not guaranteed.",
                      body2: "Tip: For lump-sum investments, consider STP (Systematic Transfer Plan) into equity funds during volatile markets to reduce timing risk.",
                      accent: accent)
        }
    }
}
