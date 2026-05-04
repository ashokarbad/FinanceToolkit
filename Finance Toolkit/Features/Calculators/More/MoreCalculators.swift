// MoreCalculators.swift
// Finance Toolkit — Tax, NPS, PF, Gratuity calculators

import SwiftUI

// MARK: - Tax Calculator
struct TaxCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.teal
    @State private var showInfoSheet = false
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: L("Tax Calculator"), icon: "percent", date: Date(),
            note: "\(vm.taxRegime == 0 ? L("Old") : L("New")) \(L("Regime")) · \(L("Gross")) ₹\(Int(vm.taxGrossIncome).formatted())",
            results: [
                .init(label: L("Gross Income"),       value: CurrencySettings.formatCurrency(vm.taxGrossIncome, code: currency),              isHighlight: false),
                .init(label: L("Total Deductions"),   value: CurrencySettings.formatCurrency(vm.taxTotalDeductions, code: currency),          isHighlight: false),
                .init(label: L("Taxable Income"),     value: CurrencySettings.formatCurrency(vm.taxTaxableIncomeComputed, code: currency),    isHighlight: false),
                .init(label: L("Tax Payable"),        value: CurrencySettings.formatCurrency(vm.taxPayable, code: currency),                  isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "percent", title: L("Income Details"), color: accent)
                Picker(L("Tax Regime"), selection: $vm.taxRegime) {
                    Text(L("Old Regime")).tag(0)
                    Text(L("New Regime")).tag(1)
                }
                .pickerStyle(.segmented)
                HStack { Text(L("Basic Salary"));           Spacer(); TextField(L("Amount"), value: $vm.taxBasicSalary, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text(L("Other Income"));           Spacer(); TextField(L("Amount"), value: $vm.taxOtherIncome, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text(L("Standard Deduction"));     Spacer(); TextField(L("Amount"), value: $vm.taxStandardDeduction, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                if vm.taxRegime == 0 {
                    HStack { Text(L("HRA Exemption"));      Spacer(); TextField(L("Amount"), value: $vm.taxHRAExempt, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text(L("Section 80C"));        Spacer(); TextField(L("Amount"), value: $vm.taxDeduction80C, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text(L("Section 80D"));        Spacer(); TextField(L("Amount"), value: $vm.taxDeduction80D, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text(L("Other Deductions"));   Spacer(); TextField(L("Amount"), value: $vm.taxOtherDeductions, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                }
                HStack { Text(L("Cess %"));                 Spacer(); TextField(L("%"), value: $vm.taxCessPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "percent", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: L("Gross Income"),       value: CurrencySettings.formatCurrency(vm.taxGrossIncome, code: currency))
                    ResultRow(label: L("Total Deductions"),   value: CurrencySettings.formatCurrency(vm.taxTotalDeductions, code: currency))
                    ResultRow(label: L("Taxable Income"),     value: CurrencySettings.formatCurrency(vm.taxTaxableIncomeComputed, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: L("Tax (before cess)"),  value: CurrencySettings.formatCurrency(vm.taxBeforeCess, code: currency))
                    ResultRow(label: "\(L("Cess")) (\(Int(vm.taxCessPercent))%)", value: CurrencySettings.formatCurrency(vm.taxCessAmount, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: L("Tax Payable"),        value: CurrencySettings.formatCurrency(vm.taxPayable, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.taxPayable)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.taxRegime)              { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxBasicSalary)         { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxOtherIncome)         { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxStandardDeduction)   { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxHRAExempt)           { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxDeduction80C)        { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxDeduction80D)        { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxOtherDeductions)     { _, _ in vm.recalculateAll() }
        .onChange(of: vm.taxCessPercent)         { _, _ in vm.recalculateAll() }
        .navigationTitle("Tax Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Tax Calculator Info",
                      body1: "Compares Old vs New regime. Old regime allows HRA, 80C, 80D and other deductions. New regime offers lower slab rates but fewer deductions.",
                      body2: "Tip: Use Old regime if your total deductions exceed ₹3.75L. Otherwise the New regime's lower slabs may save more tax.",
                      accent: accent)
        }
    }
}

// MARK: - NPS Calculator
struct NPSCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.teal
    @State private var showInfoSheet = false
    @State private var npsMonths: Int = 240
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "NPS Calculator", icon: "shield.fill", date: Date(),
            note: "₹\(Int(vm.npsMonthlyContribution).formatted())/mo · \(npsMonths) months",
            results: [
                .init(label: "Corpus at Maturity",     value: CurrencySettings.formatCurrency(vm.npsCorpusAtMaturity, code: currency),       isHighlight: true),
                .init(label: "Annuity Purchase",       value: CurrencySettings.formatCurrency(vm.npsAnnuityPurchase, code: currency),        isHighlight: false),
                .init(label: "Lumpsum Withdrawal",     value: CurrencySettings.formatCurrency(vm.npsLumpsumWithdrawal, code: currency),      isHighlight: false),
                .init(label: "Est. Annual Pension",    value: CurrencySettings.formatCurrency(vm.npsEstimatedAnnualPension, code: currency), isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "shield.fill", title: "NPS Inputs", color: accent)
                HStack { Text("Monthly Contribution");  Spacer(); TextField("Amount", value: $vm.npsMonthlyContribution, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Tenure (months)");       Spacer(); TextField("Months", value: $npsMonths, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Expected Return %");     Spacer(); TextField("%", value: $vm.npsExpectedReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annuity % at Maturity"); Spacer(); TextField("%", value: $vm.npsAnnuityPercentAtMaturity, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Annuity Return %");      Spacer(); TextField("%", value: $vm.npsAnnuityReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "shield.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Corpus at Maturity",  value: CurrencySettings.formatCurrency(vm.npsCorpusAtMaturity, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.npsCorpusAtMaturity)
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Annuity Purchase",    value: CurrencySettings.formatCurrency(vm.npsAnnuityPurchase, code: currency))
                    ResultRow(label: "Lumpsum Withdrawal",  value: CurrencySettings.formatCurrency(vm.npsLumpsumWithdrawal, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Est. Annual Pension", value: CurrencySettings.formatCurrency(vm.npsEstimatedAnnualPension, code: currency), isHighlight: true, accentColor: accent)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onAppear { npsMonths = vm.npsYears * 12 }
        .onChange(of: npsMonths) { _, _ in vm.npsYears = max(1, npsMonths / 12); vm.recalculateAll() }
        .onChange(of: vm.npsMonthlyContribution)     { _, _ in vm.recalculateAll() }
        .onChange(of: vm.npsExpectedReturnPercent)    { _, _ in vm.recalculateAll() }
        .onChange(of: vm.npsAnnuityPercentAtMaturity) { _, _ in vm.recalculateAll() }
        .onChange(of: vm.npsAnnuityReturnPercent)     { _, _ in vm.recalculateAll() }
        .navigationTitle("NPS Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "NPS Calculator Info",
                      body1: "NPS (National Pension System) builds a retirement corpus through monthly contributions. At maturity, a minimum 40% must be used to buy an annuity; the rest can be withdrawn as lumpsum (tax-free up to 60%).",
                      body2: "Tip: NPS offers additional ₹50,000 tax deduction under Section 80CCD(1B) over and above ₹1.5L under 80C.",
                      accent: accent)
        }
    }
}

// MARK: - PF Calculator
struct PFCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.teal
    @State private var showInfoSheet = false
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "PF Calculator", icon: "banknote.fill", date: Date(),
            note: "Basic ₹\(Int(vm.pfBasicSalary).formatted()) · \(vm.pfYears) years",
            results: [
                .init(label: "Employee Contribution", value: CurrencySettings.formatCurrency(vm.pfEmployeeContribution, code: currency), isHighlight: false),
                .init(label: "Employer Contribution", value: CurrencySettings.formatCurrency(vm.pfEmployerContribution, code: currency), isHighlight: false),
                .init(label: "Total Contribution",    value: CurrencySettings.formatCurrency(vm.pfTotalContribution, code: currency),    isHighlight: false),
                .init(label: "Corpus at Maturity",    value: CurrencySettings.formatCurrency(vm.pfCorpusAtMaturity, code: currency),     isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "banknote.fill", title: "PF Inputs", color: accent)
                Picker("Contribution Mode", selection: $vm.pfContributionMode) {
                    Text("% of Basic").tag(0)
                    Text("Fixed Amount").tag(1)
                }
                .pickerStyle(.segmented)
                HStack { Text("Basic Salary");   Spacer(); TextField("Amount", value: $vm.pfBasicSalary, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                if vm.pfContributionMode == 0 {
                    HStack { Text("Employee Rate %"); Spacer(); TextField("%", value: $vm.pfEmployeeRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Employer Rate %"); Spacer(); TextField("%", value: $vm.pfEmployerRatePercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                } else {
                    HStack { Text("Employee Fixed/mo"); Spacer(); TextField("Amount", value: $vm.pfEmployeeFixedAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                    HStack { Text("Employer Fixed/mo"); Spacer(); TextField("Amount", value: $vm.pfEmployerFixedAmount, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                }
                HStack { Text("Service Years");      Spacer(); TextField("Years", value: $vm.pfYears, format: .number).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("Annual Return %");    Spacer(); TextField("%", value: $vm.pfAnnualReturnPercent, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                ResultCard(systemImage: "banknote.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Employee Contribution", value: CurrencySettings.formatCurrency(vm.pfEmployeeContribution, code: currency))
                    ResultRow(label: "Employer Contribution", value: CurrencySettings.formatCurrency(vm.pfEmployerContribution, code: currency))
                    ResultRow(label: "Total Contribution",    value: CurrencySettings.formatCurrency(vm.pfTotalContribution, code: currency))
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Corpus at Maturity",    value: CurrencySettings.formatCurrency(vm.pfCorpusAtMaturity, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.pfCorpusAtMaturity)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.pfContributionMode)      { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfBasicSalary)           { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployeeRatePercent)   { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployerRatePercent)   { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployeeFixedAmount)   { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfEmployerFixedAmount)   { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfYears)                 { _, _ in vm.recalculateAll() }
        .onChange(of: vm.pfAnnualReturnPercent)   { _, _ in vm.recalculateAll() }
        .navigationTitle("PF Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "PF Calculator Info",
                      body1: "EPF (Employees' Provident Fund) accumulates through equal employee and employer contributions. The current EPF interest rate is ~8.1% p.a., declared annually by EPFO.",
                      body2: "Tip: Voluntary PF (VPF) lets you contribute more than 12% from your side, earning the same rate. Withdrawals after 5 years of continuous service are tax-free.",
                      accent: accent)
        }
    }
}

// MARK: - Gratuity Calculator
struct GratuityCalculatorView: View {
    @EnvironmentObject var vm: CalculatorViewModel
    private let accent = Color.teal
    @State private var showInfoSheet = false
    @AppStorage("selectedCurrency") private var currency = CurrencySettings.selectedCode

    private func makeSnapshot() -> SavedCalculation {
        SavedCalculation(calculatorTitle: "Gratuity Calculator", icon: "gift.fill", date: Date(),
            note: "Basic ₹\(Int(vm.gratuityLastDrawnBasic).formatted()) · \(String(format: "%.1f", vm.gratuityYearsOfService)) years",
            results: [
                .init(label: "Last Drawn Basic + DA", value: CurrencySettings.formatCurrency(vm.gratuityLastDrawnBasic, code: currency), isHighlight: false),
                .init(label: "Years of Service",      value: String(format: "%.1f", vm.gratuityYearsOfService),               isHighlight: false),
                .init(label: "Gratuity Amount",       value: CurrencySettings.formatCurrency(vm.gratuityAmount, code: currency),          isHighlight: true),
            ])
    }

    var body: some View {
        Form {
            Section {
                SectionHeader(systemImage: "gift.fill", title: "Gratuity Inputs", color: accent)
                HStack { Text("Last Drawn Basic + DA"); Spacer(); TextField("Amount", value: $vm.gratuityLastDrawnBasic, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
                HStack { Text("Years of Service");      Spacer(); TextField("Years", value: $vm.gratuityYearsOfService, format: .number).multilineTextAlignment(.trailing).keyboardType(.decimalPad) }
            }
            Section {
                Text("Gratuity = (15 / 26) × Last Drawn Basic × Completed Years of Service")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                ResultCard(systemImage: "gift.fill", accentColor: accent, onSave: { SavedStore.shared.save(calculation: makeSnapshot()) }) {
                    ResultRow(label: "Last Drawn Basic + DA", value: CurrencySettings.formatCurrency(vm.gratuityLastDrawnBasic, code: currency))
                    ResultRow(label: "Completed Years",       value: "\(Int(floor(vm.gratuityYearsOfService)))")
                    Divider().padding(.vertical, 4)
                    ResultRow(label: "Gratuity Amount",       value: CurrencySettings.formatCurrency(vm.gratuityAmount, code: currency), isHighlight: true, accentColor: accent)
                        .contentTransition(.numericText()).animation(.snappy, value: vm.gratuityAmount)
                }
            }
        }
        .keyboardDoneToolbar().tint(accent)
        .onChange(of: vm.gratuityLastDrawnBasic)  { _, _ in vm.recalculateAll() }
        .onChange(of: vm.gratuityYearsOfService)  { _, _ in vm.recalculateAll() }
        .navigationTitle("Gratuity Calculator")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button { showInfoSheet = true } label: { Image(systemName: "info.circle") }.tint(accent) } }
        .sheet(isPresented: $showInfoSheet) {
            InfoSheet(title: "Gratuity Calculator Info",
                      body1: "Under the Payment of Gratuity Act, gratuity is payable to employees who have completed 5+ years of continuous service. Formula: (15/26) × last drawn salary × completed years.",
                      body2: "Tip: Gratuity up to ₹20L is tax-exempt under Section 10(10). Months > 6 in the last year are rounded up to the next full year.",
                      accent: accent)
        }
    }
}
