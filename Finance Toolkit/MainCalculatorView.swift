//
//  MainCalculatorView.swift
//  TestApp
//
//  Created by ashok arbad on 31/12/25.
//

import SwiftUI

struct MainCalculatorView: View {
    @StateObject private var vm = CalculatorViewModel()

    var body: some View {
        List {

            // MARK: — Loans (Navy)
            Section {
                NavigationLink { LoanCalculatorView(title: "Home Loan").environmentObject(vm) } label: {
                    CalcLabel("Home Loan", icon: "house.fill", color: Color(hex: "#185FA5"))
                }
                NavigationLink { LoanCalculatorView(title: "Car Loan").environmentObject(vm) } label: {
                    CalcLabel("Car Loan", icon: "car.fill", color: Color(hex: "#185FA5"))
                }
            } header: {
                SectionHeader("Loans", icon: "banknote", color: Color(hex: "#185FA5"))
            }

            // MARK: — Investments (Gold)
            Section {
                NavigationLink { SIPCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("SIP Calculator", icon: "calendar.badge.plus", color: Color(hex: "#BA7517"))
                }
                NavigationLink { LumpSumMFView().environmentObject(vm) } label: {
                    CalcLabel("Mutual Fund (Lump Sum)", icon: "chart.pie.fill", color: Color(hex: "#BA7517"))
                }
                NavigationLink { SWPCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("SWP Calculator", icon: "arrow.down.left.circle", color: Color(hex: "#BA7517"))
                }
                NavigationLink { FDCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("FD Calculator", icon: "building.columns.fill", color: Color(hex: "#BA7517"))
                }
                NavigationLink { RDCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("RD Calculator", icon: "clock.fill", color: Color(hex: "#BA7517"))
                }
            } header: {
                SectionHeader("Investments", icon: "chart.line.uptrend.xyaxis", color: Color(hex: "#BA7517"))
            }

            // MARK: — More Calculators (Teal/Green)
            Section {
                NavigationLink { TaxCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("Tax Calculator", icon: "percent", color: Color(hex: "#1D9E75"))
                }
                NavigationLink { NPSCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("NPS Calculator", icon: "shield.fill", color: Color(hex: "#1D9E75"))
                }
                NavigationLink { PFCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("PF Calculator", icon: "briefcase.fill", color: Color(hex: "#1D9E75"))
                }
                NavigationLink { GratuityCalculatorView().environmentObject(vm) } label: {
                    CalcLabel("Gratuity Calculator", icon: "gift.fill", color: Color(hex: "#1D9E75"))
                }
            } header: {
                SectionHeader("More Calculators", icon: "ellipsis.circle", color: Color(hex: "#1D9E75"))
            }
        }
        .navigationTitle("Calculators")
    }
}

// MARK: — Reusable icon-colored label
private struct CalcLabel: View {
    let title: String
    let icon: String
    let color: Color

    init(_ title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
        }
    }
}

// MARK: — Reusable section header
private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    init(_ title: String, icon: String, color: Color) {
        self.title = title
        self.icon = icon
        self.color = color
    }

    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: icon)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(color)
        }
        .foregroundStyle(.primary)
    }
}


#Preview {
    NavigationStack { MainCalculatorView() }
}
