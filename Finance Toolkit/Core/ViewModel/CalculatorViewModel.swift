// CalculatorViewModel.swift
// Finance Toolkit — shared financial calculation engine

import Foundation
import SwiftUI
import Combine

/// Shared view-model exposing inputs and computed outputs for all calculators.
@MainActor
final class CalculatorViewModel: ObservableObject {

    // MARK: - Loan Inputs
    @Published var principal: Double = 1_00_000
    @Published var annualRatePercent: Double = 8.5
    @Published var tenureMonths: Int = 120

    // MARK: - Home Loan specific
    @Published var homeLoanPrepayment: Double = 0
    @Published var homeLoanPrepaymentFrequency: Int = 0 // 0=none, 1=monthly, 2=annual

    // MARK: - SIP Inputs
    @Published var sipMonthly: Double = 5_000
    @Published var sipYears: Int = 10
    @Published var sipExpectedReturnPercent: Double = 12

    // MARK: - SWP Inputs
    @Published var swpCorpus: Double = 5_00_000
    @Published var swpMonthlyWithdrawal: Double = 5_000
    @Published var swpYears: Int = 5
    @Published var swpExpectedReturnPercent: Double = 8

    // MARK: - FD Inputs
    @Published var fdPrincipal: Double = 1_00_000
    @Published var fdYears: Int = 3
    @Published var fdAnnualRatePercent: Double = 7
    @Published var fdCompoundingPerYear: Int = 4

    // MARK: - RD Inputs
    @Published var rdMonthlyDeposit: Double = 3_000
    @Published var rdYears: Int = 3
    @Published var rdAnnualRatePercent: Double = 7.5
    @Published var rdCompoundingPerYear: Int = 4

    // MARK: - MF Lump Sum Inputs
    @Published var lumpSumAmount: Double = 1_00_000
    @Published var lumpSumYears: Int = 10
    @Published var lumpSumExpectedReturnPercent: Double = 12

    // MARK: - Tax Inputs
    @Published var taxRegime: Int = 0 // 0=Old, 1=New
    @Published var taxBasicSalary: Double = 6_00_000
    @Published var taxHRAExempt: Double = 0
    @Published var taxOtherIncome: Double = 2_00_000
    @Published var taxStandardDeduction: Double = 50_000
    @Published var taxDeduction80C: Double = 1_50_000
    @Published var taxDeduction80D: Double = 25_000
    @Published var taxOtherDeductions: Double = 0
    @Published var taxCessPercent: Double = 4

    // MARK: - NPS Inputs
    @Published var npsMonthlyContribution: Double = 5_000
    @Published var npsYears: Int = 20
    @Published var npsExpectedReturnPercent: Double = 10
    @Published var npsAnnuityPercentAtMaturity: Double = 40
    @Published var npsAnnuityReturnPercent: Double = 6

    // MARK: - PF Inputs
    @Published var pfBasicSalary: Double = 30_000
    @Published var pfEmployeeRatePercent: Double = 12
    @Published var pfEmployerRatePercent: Double = 12
    @Published var pfYears: Int = 20
    @Published var pfAnnualReturnPercent: Double = 8.1
    @Published var pfContributionMode: Int = 0
    @Published var pfEmployeeFixedAmount: Double = 0
    @Published var pfEmployerFixedAmount: Double = 0

    // MARK: - Gratuity Inputs
    @Published var gratuityLastDrawnBasic: Double = 50_000
    @Published var gratuityYearsOfService: Double = 5.0

    // MARK: - Outputs: Loan
    @Published private(set) var emi: Double = 0
    @Published private(set) var loanTotalPayment: Double = 0
    @Published private(set) var loanTotalInterest: Double = 0
    @Published private(set) var amortizationSchedule: [AmortizationRow] = []

    // MARK: - Outputs: SIP
    @Published private(set) var sipFutureValue: Double = 0
    @Published private(set) var sipTotalInvested: Double = 0
    @Published private(set) var sipTotalInterest: Double = 0

    // MARK: - Outputs: SWP
    @Published private(set) var swpEndingCorpus: Double = 0
    @Published private(set) var swpTotalWithdrawn: Double = 0
    @Published private(set) var swpTotalEarnings: Double = 0

    // MARK: - Outputs: FD
    @Published private(set) var fdMaturityAmount: Double = 0
    @Published private(set) var fdPrincipalAmount: Double = 0
    @Published private(set) var fdInterestAmount: Double = 0

    // MARK: - Outputs: RD
    @Published private(set) var rdMaturityAmount: Double = 0
    @Published private(set) var rdTotalDeposited: Double = 0
    @Published private(set) var rdInterestAmount: Double = 0

    // MARK: - Outputs: Lump Sum MF
    @Published private(set) var lumpSumFutureValue: Double = 0
    @Published private(set) var lumpSumPrincipal: Double = 0
    @Published private(set) var lumpSumInterest: Double = 0

    // MARK: - Outputs: Tax
    @Published private(set) var taxPayable: Double = 0
    @Published private(set) var taxGrossIncome: Double = 0
    @Published private(set) var taxTotalDeductions: Double = 0
    @Published private(set) var taxTaxableIncomeComputed: Double = 0
    @Published private(set) var taxBeforeCess: Double = 0
    @Published private(set) var taxCessAmount: Double = 0

    // MARK: - Outputs: NPS
    @Published private(set) var npsCorpusAtMaturity: Double = 0
    @Published private(set) var npsAnnuityPurchase: Double = 0
    @Published private(set) var npsLumpsumWithdrawal: Double = 0
    @Published private(set) var npsEstimatedAnnualPension: Double = 0

    // MARK: - Outputs: PF
    @Published private(set) var pfEmployeeContribution: Double = 0
    @Published private(set) var pfEmployerContribution: Double = 0
    @Published private(set) var pfTotalContribution: Double = 0
    @Published private(set) var pfCorpusAtMaturity: Double = 0

    // MARK: - Outputs: Gratuity
    @Published private(set) var gratuityAmount: Double = 0

    init() { recalculateAll() }

    // MARK: - Recalculate
    func recalculateAll() {
        // Loan
        emi = calculateEMI(principal: principal, annualRatePercent: annualRatePercent, months: tenureMonths)
        loanTotalPayment = emi * Double(tenureMonths)
        loanTotalInterest = max(loanTotalPayment - principal, 0)
        amortizationSchedule = buildAmortization(principal: principal, annualRatePercent: annualRatePercent, months: tenureMonths)

        // SIP
        sipFutureValue = calculateSIP(monthly: sipMonthly, years: sipYears, annualReturnPercent: sipExpectedReturnPercent)
        sipTotalInvested = Double(sipYears * 12) * sipMonthly
        sipTotalInterest = max(sipFutureValue - sipTotalInvested, 0)

        // SWP
        let swpResult = calculateSWPDetails(corpus: swpCorpus, monthlyWithdrawal: swpMonthlyWithdrawal, years: swpYears, annualReturnPercent: swpExpectedReturnPercent)
        swpEndingCorpus = swpResult.endingCorpus
        swpTotalWithdrawn = swpResult.totalWithdrawn
        swpTotalEarnings = max((swpResult.totalWithdrawn + swpResult.endingCorpus) - swpCorpus, 0)

        // FD
        fdMaturityAmount = calculateFD(principal: fdPrincipal, years: fdYears, annualRatePercent: fdAnnualRatePercent, n: fdCompoundingPerYear)
        fdPrincipalAmount = fdPrincipal
        fdInterestAmount = max(fdMaturityAmount - fdPrincipalAmount, 0)

        // RD
        rdMaturityAmount = calculateRD(monthlyDeposit: rdMonthlyDeposit, years: rdYears, annualRatePercent: rdAnnualRatePercent, n: rdCompoundingPerYear)
        rdTotalDeposited = Double(rdYears * 12) * rdMonthlyDeposit
        rdInterestAmount = max(rdMaturityAmount - rdTotalDeposited, 0)

        // Lump Sum MF
        lumpSumFutureValue = calculateLumpSumFV(amount: lumpSumAmount, years: lumpSumYears, annualReturnPercent: lumpSumExpectedReturnPercent)
        lumpSumPrincipal = lumpSumAmount
        lumpSumInterest = max(lumpSumFutureValue - lumpSumPrincipal, 0)

        // Tax
        taxGrossIncome = max(taxBasicSalary + taxOtherIncome, 0)
        let allowedStandard = max(taxStandardDeduction, 0)
        let allowed80C  = taxRegime == 0 ? max(taxDeduction80C, 0) : 0
        let allowed80D  = taxRegime == 0 ? max(taxDeduction80D, 0) : 0
        let allowedOther = taxRegime == 0 ? max(taxOtherDeductions, 0) : 0
        let hraExempt   = taxRegime == 0 ? max(taxHRAExempt, 0) : 0
        taxTotalDeductions = min(taxGrossIncome, allowedStandard + allowed80C + allowed80D + allowedOther + hraExempt)
        taxTaxableIncomeComputed = max(taxGrossIncome - taxTotalDeductions, 0)
        taxBeforeCess = taxRegime == 0 ? calculateOldRegimeTax(for: taxTaxableIncomeComputed) : calculateNewRegimeTax(for: taxTaxableIncomeComputed)
        taxCessAmount = taxBeforeCess * (taxCessPercent / 100.0)
        taxPayable = max(taxBeforeCess + taxCessAmount, 0)

        // NPS
        npsCorpusAtMaturity = calculateSIP(monthly: npsMonthlyContribution, years: npsYears, annualReturnPercent: npsExpectedReturnPercent)
        npsAnnuityPurchase = npsCorpusAtMaturity * (npsAnnuityPercentAtMaturity / 100.0)
        npsLumpsumWithdrawal = npsCorpusAtMaturity - npsAnnuityPurchase
        npsEstimatedAnnualPension = npsAnnuityPurchase * (npsAnnuityReturnPercent / 100.0)

        // PF
        if pfContributionMode == 0 {
            pfEmployeeContribution = pfBasicSalary * (pfEmployeeRatePercent / 100.0) * Double(pfYears * 12)
            pfEmployerContribution = pfBasicSalary * (pfEmployerRatePercent / 100.0) * Double(pfYears * 12)
        } else {
            pfEmployeeContribution = pfEmployeeFixedAmount * Double(pfYears * 12)
            pfEmployerContribution = pfEmployerFixedAmount * Double(pfYears * 12)
        }
        pfTotalContribution = pfEmployeeContribution + pfEmployerContribution
        pfCorpusAtMaturity = calculateLumpSumFV(amount: pfTotalContribution, years: pfYears, annualReturnPercent: pfAnnualReturnPercent)

        // Gratuity
        gratuityAmount = (15.0 / 26.0) * gratuityLastDrawnBasic * floor(gratuityYearsOfService)
    }

    // MARK: - Amortization schedule
    struct AmortizationRow: Identifiable {
        let id: Int        // month number
        let month: Int
        let emi: Double
        let principal: Double
        let interest: Double
        let balance: Double
    }

    private func buildAmortization(principal: Double, annualRatePercent: Double, months: Int) -> [AmortizationRow] {
        let r = annualRatePercent / 12.0 / 100.0
        let n = months
        let emiVal = calculateEMI(principal: principal, annualRatePercent: annualRatePercent, months: months)
        var balance = principal
        var rows: [AmortizationRow] = []
        for month in 1...max(n, 1) {
            let interest  = balance * r
            let prin      = min(emiVal - interest, balance)
            balance       = max(balance - prin, 0)
            rows.append(AmortizationRow(id: month, month: month, emi: emiVal, principal: prin, interest: interest, balance: balance))
            if balance <= 0 { break }
        }
        return rows
    }

    // MARK: - Core math helpers

    func calculateEMI(principal: Double, annualRatePercent: Double, months: Int) -> Double {
        let r = annualRatePercent / 12.0 / 100.0
        let n = Double(months)
        guard r > 0, n > 0 else { return principal / max(n, 1) }
        let numerator = principal * r * pow(1 + r, n)
        let denominator = pow(1 + r, n) - 1
        return numerator / denominator
    }

    private func calculateSIP(monthly: Double, years: Int, annualReturnPercent: Double) -> Double {
        let r = annualReturnPercent / 12.0 / 100.0
        let n = Double(years * 12)
        guard r > 0, n > 0 else { return monthly * n }
        return monthly * ((pow(1 + r, n) - 1) / r) * (1 + r)
    }

    private func calculateSWPDetails(corpus: Double, monthlyWithdrawal: Double, years: Int, annualReturnPercent: Double) -> (endingCorpus: Double, totalWithdrawn: Double) {
        let r = annualReturnPercent / 12.0 / 100.0
        var balance = corpus
        var withdrawn: Double = 0
        for _ in 0..<(years * 12) {
            balance *= (1 + r)
            let w = min(monthlyWithdrawal, balance)
            balance -= w
            withdrawn += w
            if balance <= 0 { return (0, withdrawn) }
        }
        return (max(balance, 0), withdrawn)
    }

    private func calculateFD(principal: Double, years: Int, annualRatePercent: Double, n: Int) -> Double {
        let r = annualRatePercent / 100.0
        let periods = Double(n * years)
        guard n > 0 else { return principal * pow(1 + r, Double(years)) }
        return principal * pow(1 + r / Double(n), periods)
    }

    private func calculateRD(monthlyDeposit: Double, years: Int, annualRatePercent: Double, n: Int) -> Double {
        let r = annualRatePercent / 12.0 / 100.0
        let months = years * 12
        guard months > 0 else { return 0 }
        return monthlyDeposit * ((pow(1 + r, Double(months)) - 1) / r) * (1 + r)
    }

    func calculateLumpSumFV(amount: Double, years: Int, annualReturnPercent: Double) -> Double {
        let r = annualReturnPercent / 100.0
        return amount * pow(1 + r, Double(max(years, 0)))
    }

    // MARK: - Tax slabs (FY 2024-25 illustrative)
    private func calculateOldRegimeTax(for income: Double) -> Double {
        // No tax up to ₹5L under old regime with rebate 87A; slabs illustrated
        let slabs: [(limit: Double, rate: Double)] = [
            (250_000, 0.0),
            (250_000, 0.05),
            (500_000, 0.20),
            (Double.greatestFiniteMagnitude, 0.30)
        ]
        return applySlabs(income: income, slabs: slabs)
    }

    private func calculateNewRegimeTax(for income: Double) -> Double {
        // No tax up to ₹7L under new regime with rebate 87A; slabs per Finance Act 2023
        let slabs: [(limit: Double, rate: Double)] = [
            (300_000, 0.0),
            (300_000, 0.05),
            (300_000, 0.10),
            (300_000, 0.15),
            (300_000, 0.20),
            (Double.greatestFiniteMagnitude, 0.30)
        ]
        return applySlabs(income: income, slabs: slabs)
    }

    private func applySlabs(income: Double, slabs: [(limit: Double, rate: Double)]) -> Double {
        var remaining = max(income, 0)
        var tax: Double = 0
        for (limit, rate) in slabs {
            let portion = min(remaining, limit)
            tax += portion * rate
            remaining -= portion
            if remaining <= 0 { break }
        }
        return max(tax, 0)
    }
}
