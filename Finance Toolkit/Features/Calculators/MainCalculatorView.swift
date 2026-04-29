// MainCalculatorView.swift
// Finance Toolkit — calculator grid / list view

import SwiftUI

// MARK: - Main Calculator View
struct MainCalculatorView: View {
    @EnvironmentObject private var vm: CalculatorViewModel
    @ObservedObject private var store = SavedStore.shared
    @State private var searchText = ""
    @AppStorage("calcViewMode") private var isGridMode = false

    // MARK: Calculator sections
    private var loanItems: [CalcItem] {[
        CalcItem(title: "Home Loan",               subtitle: "EMI · amortisation schedule",   icon: "house.fill",                  color: Color(hex: "#3B82F6"), bgColor: Color(hex: "#3B82F6").opacity(0.1), destination: AnyView(HomeLoanView().environmentObject(vm))),
        CalcItem(title: "Vehicle Loan",            subtitle: "Car · bike · down payment",      icon: "car.fill",                    color: Color(hex: "#EF4444"), bgColor: Color(hex: "#EF4444").opacity(0.1), destination: AnyView(VehiclePersonalLoanView(title: "Vehicle Loan").environmentObject(vm))),
        CalcItem(title: "Personal Loan",           subtitle: "Unsecured · quick disbursal",    icon: "person.fill",                 color: Color(hex: "#8B5CF6"), bgColor: Color(hex: "#8B5CF6").opacity(0.1), destination: AnyView(VehiclePersonalLoanView(title: "Personal Loan").environmentObject(vm))),
        CalcItem(title: "Education Loan",          subtitle: "Moratorium · study period",      icon: "book.fill",                   color: Color(hex: "#0EA5E9"), bgColor: Color(hex: "#0EA5E9").opacity(0.1), destination: AnyView(EducationLoanView().environmentObject(vm))),
        CalcItem(title: "Business Loan",           subtitle: "MSME · working capital",         icon: "briefcase.fill",              color: Color(hex: "#6366F1"), bgColor: Color(hex: "#6366F1").opacity(0.1), destination: AnyView(BusinessLoanView().environmentObject(vm))),
        CalcItem(title: "Gold Loan",               subtitle: "Pledged ornaments · LTV",        icon: "sparkles",                    color: Color(hex: "#F59E0B"), bgColor: Color(hex: "#F59E0B").opacity(0.1), destination: AnyView(GoldLoanView().environmentObject(vm))),
        CalcItem(title: "Loan Against Property",   subtitle: "LAP · collateral-backed",        icon: "building.2.fill",             color: Color(hex: "#14B8A6"), bgColor: Color(hex: "#14B8A6").opacity(0.1), destination: AnyView(LAPLoanView().environmentObject(vm))),
        CalcItem(title: "Agricultural Loan",       subtitle: "Kisan · crop · farm credit",     icon: "leaf.fill",                   color: Color(hex: "#22C55E"), bgColor: Color(hex: "#22C55E").opacity(0.1), destination: AnyView(AgriculturalLoanView().environmentObject(vm))),
        CalcItem(title: "Credit Line / Overdraft", subtitle: "Revolving · interest-only",      icon: "creditcard.fill",             color: Color(hex: "#EC4899"), bgColor: Color(hex: "#EC4899").opacity(0.1), destination: AnyView(CreditLineOverdraftView().environmentObject(vm))),
        CalcItem(title: "Consumer Durable / EMI",  subtitle: "Electronics · no-cost EMI",      icon: "cart.fill",                   color: Color(hex: "#E87D2B"), bgColor: Color(hex: "#E87D2B").opacity(0.1), destination: AnyView(ConsumerDurableLoanView().environmentObject(vm))),
    ]}

    private var investmentItems: [CalcItem] {[
        CalcItem(title: "SIP Calculator",          subtitle: "Monthly · goal-based planning",  icon: "calendar.badge.plus",         color: Color(hex: "#22C55E"), bgColor: Color(hex: "#22C55E").opacity(0.1), destination: AnyView(SIPCalculatorView().environmentObject(vm))),
        CalcItem(title: "Mutual Fund (Lump Sum)",  subtitle: "One-time · CAGR returns",        icon: "chart.pie.fill",              color: Color(hex: "#F59E0B"), bgColor: Color(hex: "#F59E0B").opacity(0.1), destination: AnyView(LumpSumMFView().environmentObject(vm))),
        CalcItem(title: "SWP Calculator",          subtitle: "Systematic withdrawal plan",     icon: "arrow.down.left.circle.fill", color: Color(hex: "#EF4444"), bgColor: Color(hex: "#EF4444").opacity(0.1), destination: AnyView(SWPCalculatorView().environmentObject(vm))),
        CalcItem(title: "FD Calculator",           subtitle: "Fixed deposit · maturity",       icon: "building.columns.fill",       color: Color(hex: "#3B82F6"), bgColor: Color(hex: "#3B82F6").opacity(0.1), destination: AnyView(FDCalculatorView().environmentObject(vm))),
        CalcItem(title: "RD Calculator",           subtitle: "Recurring deposit · monthly",    icon: "calendar.circle.fill",        color: Color(hex: "#8B5CF6"), bgColor: Color(hex: "#8B5CF6").opacity(0.1), destination: AnyView(RDCalculatorView().environmentObject(vm))),
    ]}

    private var moreItems: [CalcItem] {[
        CalcItem(title: "Tax Calculator",          subtitle: "Old vs new regime · slabs",      icon: "percent",                     color: Color(hex: "#EF4444"), bgColor: Color(hex: "#EF4444").opacity(0.1), destination: AnyView(TaxCalculatorView().environmentObject(vm))),
        CalcItem(title: "NPS Calculator",          subtitle: "National pension · annuity",     icon: "shield.fill",                 color: Color(hex: "#6366F1"), bgColor: Color(hex: "#6366F1").opacity(0.1), destination: AnyView(NPSCalculatorView().environmentObject(vm))),
        CalcItem(title: "PF Calculator",           subtitle: "EPF · employer · employee",      icon: "banknote.fill",               color: Color(hex: "#14B8A6"), bgColor: Color(hex: "#14B8A6").opacity(0.1), destination: AnyView(PFCalculatorView().environmentObject(vm))),
        CalcItem(title: "Gratuity Calculator",     subtitle: "Retirement benefit · years",     icon: "gift.fill",                   color: Color(hex: "#EC4899"), bgColor: Color(hex: "#EC4899").opacity(0.1), destination: AnyView(GratuityCalculatorView().environmentObject(vm))),
    ]}

    // Filtered
    private func filtered(_ items: [CalcItem]) -> [CalcItem] {
        guard !searchText.isEmpty else { return items }
        return items.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }
    private var filteredLoans:       [CalcItem] { filtered(loanItems) }
    private var filteredInvestments: [CalcItem] { filtered(investmentItems) }
    private var filteredMore:        [CalcItem] { filtered(moreItems) }
    private var hasNoResults: Bool {
        !searchText.isEmpty && filteredLoans.isEmpty && filteredInvestments.isEmpty && filteredMore.isEmpty
    }

    // All items for favourites lookup
    private var allItems: [CalcItem] { loanItems + investmentItems + moreItems }
    private var favouriteItems: [CalcItem] {
        guard searchText.isEmpty else { return [] }
        return allItems.filter { store.isSaved($0.title) }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if hasNoResults {
                    NoResultsView(query: searchText).padding(.top, 80)
                } else {
                    if !favouriteItems.isEmpty {
                        calcSection(title: "Favourites", icon: "star.fill", color: .gold, items: favouriteItems)
                    }
                    if !filteredLoans.isEmpty {
                        calcSection(title: "Loans", icon: "banknote", color: .navy, items: filteredLoans)
                    }
                    if !filteredInvestments.isEmpty {
                        calcSection(title: "Investments", icon: "chart.line.uptrend.xyaxis", color: .gold, items: filteredInvestments)
                    }
                    if !filteredMore.isEmpty {
                        calcSection(title: "More Calculators", icon: "ellipsis.circle", color: .teal, items: filteredMore)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search calculators…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { isGridMode.toggle() }
                } label: {
                    Image(systemName: isGridMode ? "list.bullet" : "square.grid.2x2")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.navy)
                }
            }
        }
    }

    // MARK: - Section builder (switches between list and grid)
    @ViewBuilder
    private func calcSection(title: String, icon: String, color: Color, items: [CalcItem]) -> some View {
        if isGridMode {
            CalcGridSectionView(title: title, icon: icon, color: color, items: items)
        } else {
            CalcSectionView(title: title, icon: icon, color: color, items: items)
        }
    }
}

// MARK: - Section view
struct CalcSectionView: View {
    let title: String
    let icon:  String
    let color: Color
    let items: [CalcItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.7)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.top, 22)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        NavigationLink(destination: item.destination) {
                            CalcRowView(item: item)
                        }
                        .buttonStyle(.plain)
                        if idx < items.count - 1 { Divider().padding(.horizontal, 14) }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))

                // Top shimmer
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color.white.opacity(0.28), Color.clear], startPoint: .top, endPoint: .center))
                    .frame(height: 44)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Row view
struct CalcRowView: View {
    let item: CalcItem
    @ObservedObject private var store = SavedStore.shared

    var body: some View {
        HStack(spacing: 13) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 40, height: 40)
                Image(systemName: item.icon)
                    .font(.system(size: 18))
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(item.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.primary)
                Text(item.subtitle)
                    .font(.system(size: 11.5))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Star bookmark
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    store.toggle(item.title)
                }
            } label: {
                Image(systemName: store.isSaved(item.title) ? "star.fill" : "star")
                    .font(.system(size: 14))
                    .foregroundStyle(store.isSaved(item.title) ? Color.gold : Color.secondary.opacity(0.4))
                    .scaleEffect(store.isSaved(item.title) ? 1.15 : 1)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 2)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

// MARK: - No results
struct NoResultsView: View {
    let query: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No results for \"\(query)\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text("Try a different search term.")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Grid section view
struct CalcGridSectionView: View {
    let title: String
    let icon:  String
    let color: Color
    let items: [CalcItem]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.7)
            } icon: {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 4)
            .padding(.top, 22)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    NavigationLink(destination: item.destination) {
                        CalcGridCell(item: item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Grid cell
struct CalcGridCell: View {
    let item: CalcItem
    @ObservedObject private var store = SavedStore.shared

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        store.toggle(item.title)
                    }
                } label: {
                    Image(systemName: store.isSaved(item.title) ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundStyle(store.isSaved(item.title) ? Color.gold : Color.secondary.opacity(0.3))
                }
                .buttonStyle(.plain)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 46, height: 46)
                Image(systemName: item.icon)
                    .font(.system(size: 22))
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(item.color)
            }

            Text(item.title)
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(item.subtitle)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
    }
}

#Preview {
    NavigationStack { MainCalculatorView() }
        .environmentObject(CalculatorViewModel())
}
