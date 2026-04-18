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
                .strokeBorder(accentColor.opacity(0.18))
        )
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
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "banknote.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Principal", value: $vm.principal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annual Rate %"); Spacer(); TextField("Rate", value: $vm.annualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Tenure: \(vm.tenureMonths) months", value: $vm.tenureMonths, in: 1...600)
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
                    Divider().padding(.vertical, 4)
                    Text("EMI is the fixed monthly payment. Total Paid = Principal + Interest.")
                        .font(.footnote).foregroundStyle(.secondary)
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
    }
}

// MARK: - SIP
// Accent: Gold #BA7517
struct SIPCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "calendar.badge.plus", title: "Inputs", color: accent)
                HStack { Text("Monthly Investment"); Spacer(); TextField("Amount", value: $vm.sipMonthly, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Years: \(vm.sipYears)", value: $vm.sipYears, in: 1...50)
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.sipExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "arrow.up.right.circle.fill", accentColor: accent) {
                    ResultRow(label: "Total Invested", value: vm.sipTotalInvested.formatted(.currency(code: currency)))
                    ResultRow(label: "Est. Returns", value: vm.sipTotalInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Future Value", value: vm.sipFutureValue.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.sipFutureValue)
                    Divider().padding(.vertical, 4)
                    Text("Future Value = Invested amount plus compounded returns over the period.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.sipMonthly) { _ in vm.recalculateAll() }
        .onChange(of: vm.sipYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.sipExpectedReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("SIP Calculator")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - SWP
// Accent: Gold #BA7517
struct SWPCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "arrow.down.left.circle.fill", title: "Inputs", color: accent)
                HStack { Text("Corpus"); Spacer(); TextField("Corpus", value: $vm.swpCorpus, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Monthly Withdrawal"); Spacer(); TextField("Withdrawal", value: $vm.swpMonthlyWithdrawal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Years: \(vm.swpYears)", value: $vm.swpYears, in: 1...50)
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.swpExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "arrow.down.left.circle.fill", accentColor: accent) {
                    ResultRow(label: "Total Withdrawn", value: vm.swpTotalWithdrawn.formatted(.currency(code: currency)))
                    ResultRow(label: "Total Earnings", value: vm.swpTotalEarnings.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Ending Corpus", value: vm.swpEndingCorpus.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.swpEndingCorpus)
                    Divider().padding(.vertical, 4)
                    Text("Ending Corpus is the remaining balance after monthly withdrawals and returns.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.swpCorpus) { _ in vm.recalculateAll() }
        .onChange(of: vm.swpMonthlyWithdrawal) { _ in vm.recalculateAll() }
        .onChange(of: vm.swpYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.swpExpectedReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("SWP Calculator")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - FD
// Accent: Gold #BA7517
struct FDCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "building.columns.fill", title: "Inputs", color: accent)
                HStack { Text("Principal"); Spacer(); TextField("Principal", value: $vm.fdPrincipal, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Years: \(vm.fdYears)", value: $vm.fdYears, in: 1...30)
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.fdAnnualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Compounding / Year: \(vm.fdCompoundingPerYear)", value: $vm.fdCompoundingPerYear, in: 1...12)
            }
            Section {
                ResultCard(systemImage: "building.columns.fill", accentColor: accent) {
                    ResultRow(label: "Principal", value: vm.fdPrincipalAmount.formatted(.currency(code: currency)))
                    ResultRow(label: "Interest Earned", value: vm.fdInterestAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Maturity Amount", value: vm.fdMaturityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.fdMaturityAmount)
                    Divider().padding(.vertical, 4)
                    Text("Maturity Amount = Principal compounded at the chosen frequency and rate.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.fdPrincipal) { _ in vm.recalculateAll() }
        .onChange(of: vm.fdYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.fdAnnualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.fdCompoundingPerYear) { _ in vm.recalculateAll() }
        .navigationTitle("FD Calculator")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - RD
// Accent: Gold #BA7517
struct RDCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "clock.fill", title: "Inputs", color: accent)
                HStack { Text("Monthly Deposit"); Spacer(); TextField("Deposit", value: $vm.rdMonthlyDeposit, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Years: \(vm.rdYears)", value: $vm.rdYears, in: 1...30)
                HStack { Text("Annual Rate %"); Spacer(); TextField("%", value: $vm.rdAnnualRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Compounding / Year: \(vm.rdCompoundingPerYear)", value: $vm.rdCompoundingPerYear, in: 1...12)
            }
            Section {
                ResultCard(systemImage: "chart.bar.fill", accentColor: accent) {
                    ResultRow(label: "Total Deposited", value: vm.rdTotalDeposited.formatted(.currency(code: currency)))
                    ResultRow(label: "Interest Earned", value: vm.rdInterestAmount.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Maturity Amount", value: vm.rdMaturityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.rdMaturityAmount)
                    Divider().padding(.vertical, 4)
                    Text("Maturity Amount is the compounded value of monthly deposits over the term.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.rdMonthlyDeposit) { _ in vm.recalculateAll() }
        .onChange(of: vm.rdYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.rdAnnualRatePercent) { _ in vm.recalculateAll() }
        .onChange(of: vm.rdCompoundingPerYear) { _ in vm.recalculateAll() }
        .navigationTitle("RD Calculator")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Mutual Fund Lump Sum
// Accent: Gold #BA7517
struct LumpSumMFView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#BA7517")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "chart.pie.fill", title: "Inputs", color: accent)
                HStack { Text("Lump Sum Amount"); Spacer(); TextField("Amount", value: $vm.lumpSumAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Years: \(vm.lumpSumYears)", value: $vm.lumpSumYears, in: 0...50)
                HStack { Text("Expected Return %"); Spacer(); TextField("%", value: $vm.lumpSumExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "chart.line.uptrend.xyaxis", accentColor: accent) {
                    ResultRow(label: "Principal", value: vm.lumpSumPrincipal.formatted(.currency(code: currency)))
                    ResultRow(label: "Est. Returns", value: vm.lumpSumInterest.formatted(.currency(code: currency)))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Future Value", value: vm.lumpSumFutureValue.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.lumpSumFutureValue)
                    Divider().padding(.vertical, 4)
                    Text("Future Value is the compounded value of the one-time investment.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.lumpSumAmount) { _ in vm.recalculateAll() }
        .onChange(of: vm.lumpSumYears) { _ in vm.recalculateAll() }
        .onChange(of: vm.lumpSumExpectedReturnPercent) { _ in vm.recalculateAll() }
        .navigationTitle("MF Lump Sum")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Tax Calculator
// Accent: Teal #1D9E75
struct TaxCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
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
                    Divider().padding(.vertical, 4)
                    Text("Illustrative estimate only. Verify slabs, exemptions, and limits for your assessment year.")
                        .font(.footnote).foregroundStyle(.secondary)
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
    }
}

// MARK: - NPS Calculator
// Accent: Teal #1D9E75
struct NPSCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#1D9E75")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "shield.fill", title: "Inputs", color: accent)
                HStack { Text("Monthly Contribution"); Spacer(); TextField("Amount", value: $vm.npsMonthlyContribution, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                Stepper("Years: \(vm.npsYears)", value: $vm.npsYears, in: 1...50)
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
                    Divider().padding(.vertical, 4)
                    Text("Corpus is split into lumpsum and annuity as per the selected percentage.")
                        .font(.footnote).foregroundStyle(.secondary)
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
    }
}

// MARK: - PF Calculator
// Accent: Teal #1D9E75
struct PFCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#1D9E75")
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
            Stepper("Years: \(vm.pfYears)", value: $vm.pfYears, in: 1...40)
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
                Divider().padding(.vertical, 4)
                Text("Corpus at Maturity is an approximation by compounding total contributions at the expected rate.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Gratuity Calculator
// Accent: Teal #1D9E75
struct GratuityCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color(hex: "#1D9E75")
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "gift.fill", title: "Inputs", color: accent)
                HStack { Text("Last Drawn Basic"); Spacer(); TextField("Basic", value: $vm.gratuityLastDrawnBasic, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Years of Service"); Spacer(); TextField("Years", value: $vm.gratuityYearsOfService, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "gift.fill", accentColor: accent) {
                    ResultRow(label: "Last Drawn Basic", value: vm.gratuityLastDrawnBasic.formatted(.currency(code: currency)))
                    ResultRow(label: "Years of Service", value: "\(Int(floor(vm.gratuityYearsOfService))) yrs")
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Gratuity Amount", value: vm.gratuityAmount.formatted(.currency(code: currency)), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.gratuityAmount)
                    Divider().padding(.vertical, 4)
                    Text("Formula: (15 ÷ 26) × Last Drawn Basic × Years of Service")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .keyboardDoneToolbar()
        .tint(accent)
        .onChange(of: vm.gratuityLastDrawnBasic) { _ in vm.recalculateAll() }
        .onChange(of: vm.gratuityYearsOfService) { _ in vm.recalculateAll() }
        .navigationTitle("Gratuity Calculator")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack { MainCalculatorView() }
}

