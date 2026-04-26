//
//  MainCalculatorView.swift
//  TestApp
//
//  Created by ashok arbad on 31/12/25.
//

import SwiftUI
import Combine

// MARK: — Color extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red:     Double(r) / 255,
                  green:   Double(g) / 255,
                  blue:    Double(b) / 255,
                  opacity: Double(a) / 255)
    }

    // Brand palette — never comment these out; they are referenced throughout the file
    static let navy      = Color(hex: "#185FA5")
    static let navyLight = Color(hex: "#E6F1FB")
    static let gold      = Color(hex: "#BA7517")
    static let goldLight = Color(hex: "#FAEEDA")
    static let teal      = Color(hex: "#1D9E75")
    static let tealLight = Color(hex: "#E1F5EE")
}

// MARK: — CalcItem model
struct CalcItem: Identifiable {
    let id      = UUID()
    let title:       String
    let subtitle:    String
    let icon:        String
    let color:       Color
    let bgColor:     Color
    let destination: AnyView
}

// MARK: — Sidebar destinations
enum SidebarDestination: String, CaseIterable, Identifiable {
    case calculators = "Calculators"
    case dashboard   = "Dashboard"
    case saved       = "Saved"
    case profile     = "Profile"
    case settings    = "Settings"
    case about       = "About"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .calculators: return "square.grid.2x2.fill"
        case .dashboard:   return "chart.bar.fill"
        case .saved:       return "star.fill"
        case .profile:     return "person.crop.circle.fill"
        case .settings:    return "gearshape.fill"
        case .about:       return "info.circle.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .calculators: return .navy
        case .dashboard:   return .teal
        case .saved:       return .gold
        case .profile, .settings, .about: return Color(hex: "#888888")
        }
    }
}

// MARK: — Root entry point
// Use FinCalcRootView() as your top-level view in your @main App struct.
struct FinCalcRootView: View {
    @AppStorage("darkMode") private var darkMode = false

    var body: some View {
        FinCalcAppShell()
            .preferredColorScheme(darkMode ? .dark : .light)
    }
}

// MARK: — App shell
struct FinCalcAppShell: View {
    @AppStorage("darkMode") private var darkMode = false
    @State private var sidebarOpen = false
    @State private var selected: SidebarDestination = .calculators
    @StateObject private var vm = CalculatorViewModel()

    var body: some View {
        ZStack(alignment: .leading) {

            // Coloured gradient so .ultraThinMaterial has something to blur
            LinearGradient(
                colors: darkMode
                    ? [Color(hex: "#0d1b2e"), Color(hex: "#0a2218"), Color(hex: "#1a1200")]
                    : [Color(hex: "#dceeff"), Color(hex: "#d0f5ea"), Color(hex: "#fff5e0")],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: darkMode)

            // Blurred colour blobs (feed the glass material)
            AmbientBlobsView()

            // Main content
            NavigationStack {
                detailView
                    .navigationTitle(selected.rawValue)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                    sidebarOpen.toggle()
                                }
                            } label: {
                                Image(systemName: sidebarOpen ? "xmark" : "sidebar.left")
                                    .font(.system(size: 16, weight: .medium))
                                    .animation(.easeInOut(duration: 0.2), value: sidebarOpen)
                            }
                        }
                    }
            }
            .environmentObject(vm)
            .scaleEffect(sidebarOpen ? 0.92 : 1, anchor: .trailing)
            .offset(x: sidebarOpen ? 260 : 0)
            .opacity(sidebarOpen ? 0.55 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: sidebarOpen)
            .allowsHitTesting(!sidebarOpen)

            // Tap-outside overlay
            if sidebarOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            sidebarOpen = false
                        }
                    }
            }

            // Sidebar drawer
            SidebarDrawer(
                selected:    $selected,
                darkMode:    $darkMode,
                sidebarOpen: $sidebarOpen
            )
            .frame(width: 262)
            .offset(x: sidebarOpen ? 0 : -270)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: sidebarOpen)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selected {
        case .calculators: MainCalculatorView()
        case .dashboard:   DashboardPlaceholderView()
        case .saved:       SavedPlaceholderView()
        case .profile:     ProfilePlaceholderView()
        case .settings:    SettingsPlaceholderView(darkMode: $darkMode)
        case .about:       AboutPlaceholderView()
        }
    }
}

// MARK: — Sidebar drawer
struct SidebarDrawer: View {
    @Binding var selected:    SidebarDestination
    @Binding var darkMode:    Bool
    @Binding var sidebarOpen: Bool

    private let mainItems:    [SidebarDestination] = [.calculators, .dashboard, .saved]
    private let accountItems: [SidebarDestination] = [.profile, .settings, .about]

    var body: some View {
        ZStack {
            // Glass layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            // Subtle navy tint so glass reads as coloured, not just blurred white
            Rectangle()
                .fill(Color.navy.opacity(0.07))
                .ignoresSafeArea()

            // Thin separator on the right edge
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.primary.opacity(0.09))
                    .frame(width: 0.5)
            }

            VStack(alignment: .leading, spacing: 0) {
                BrandHeaderView()
                    .padding(.horizontal, 16)
                    .padding(.top, 58)
                    .padding(.bottom, 26)

                SidebarSectionLabel("Main")
                ForEach(mainItems) { item in
                    SidebarRow(item: item, isSelected: selected == item) {
                        selected = item
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            sidebarOpen = false
                        }
                    }
                }

                sectionDivider

                SidebarSectionLabel("Account")
                ForEach(accountItems) { item in
                    SidebarRow(item: item, isSelected: selected == item) {
                        selected = item
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            sidebarOpen = false
                        }
                    }
                }

                Spacer()

                sectionDivider

                DarkModeToggleRow(darkMode: $darkMode)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
            }
        }
        .clipShape(RoundedCornerShape(radius: 22, corners: [.topRight, .bottomRight]))
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
    }
}

// MARK: — Brand header
private struct BrandHeaderView: View {
    var body: some View {
        HStack(spacing: 11) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.navy, .teal],
                        startPoint: .topLeading,
                        endPoint:   .bottomTrailing
                    ))
                    .frame(width: 40, height: 40)
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("FinCalc")
                    .font(.system(size: 16, weight: .semibold))
                Text("Pro Suite")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)
            }
        }
    }
}

// MARK: — Section label
private struct SidebarSectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.tertiary)
            .tracking(1.0)
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
    }
}

// MARK: — Sidebar row
private struct SidebarRow: View {
    let item:       SidebarDestination
    let isSelected: Bool
    let action:     () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(isSelected
                              ? item.accentColor.opacity(0.18)
                              : Color.primary.opacity(0.05))
                        .frame(width: 33, height: 33)
                    Image(systemName: item.icon)
                        .font(.system(size: 13.5, weight: .medium))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(isSelected ? item.accentColor : .secondary)
                }
                Text(item.rawValue)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? item.accentColor : .primary)
                Spacer()
                if isSelected {
                    Circle()
                        .fill(item.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? item.accentColor.opacity(0.10) : Color.clear)
            )
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: — Dark mode toggle
private struct DarkModeToggleRow: View {
    @Binding var darkMode: Bool
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(darkMode
                          ? Color.gold.opacity(0.15)
                          : Color.orange.opacity(0.10))
                    .frame(width: 33, height: 33)
                Image(systemName: darkMode ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(darkMode ? Color.gold : Color.orange)
            }
            Text("Dark mode")
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: $darkMode)
                .toggleStyle(SwitchToggleStyle(tint: .navy))
                .labelsHidden()
                .scaleEffect(0.85)
        }
    }
}

// MARK: — Rounded corner shape (selective corners)
struct RoundedCornerShape: Shape {
    var radius:  CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: — Ambient blobs (glass needs colour behind it to blur)
struct AmbientBlobsView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .fill(Color.navy.opacity(0.32))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: -90, y: -110)

                Circle()
                    .fill(Color.teal.opacity(0.27))
                    .frame(width: 260, height: 260)
                    .blur(radius: 75)
                    .offset(x: geo.size.width * 0.55,
                            y: geo.size.height * 0.58)

                Circle()
                    .fill(Color.gold.opacity(0.24))
                    .frame(width: 220, height: 220)
                    .blur(radius: 70)
                    .offset(x: geo.size.width * 0.60,
                            y: geo.size.height * 0.18)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: — Main Calculator View
struct MainCalculatorView: View {
    @EnvironmentObject private var vm: CalculatorViewModel
    @State private var searchText = ""

    private var loanItems: [CalcItem] {[
        CalcItem(title: "Home Loan",               subtitle: "EMI · amortization schedule",  icon: "house.fill",                   color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Home Loan").environmentObject(vm))),
        CalcItem(title: "Vehicle Loan",            subtitle: "Car · bike · commercial",       icon: "car.fill",                     color: .navy, bgColor: .navyLight, destination: AnyView(VehiclePersonalLoanView(title: "Vehicle Loan").environmentObject(vm))),
        CalcItem(title: "Personal Loan",           subtitle: "Unsecured · quick disbursal",   icon: "person.fill",                  color: .navy, bgColor: .navyLight, destination: AnyView(VehiclePersonalLoanView(title: "Personal Loan").environmentObject(vm))),
        CalcItem(title: "Education Loan",          subtitle: "Moratorium · study period",     icon: "book.fill",                    color: .navy, bgColor: .navyLight, destination: AnyView(EducationLoanView().environmentObject(vm))),
        CalcItem(title: "Business Loan",           subtitle: "MSME · working capital",        icon: "briefcase.fill",               color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Business Loan").environmentObject(vm))),
        CalcItem(title: "Gold Loan",               subtitle: "Pledged ornaments · LTV",       icon: "indianrupeesign.circle.fill",  color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Gold Loan").environmentObject(vm))),
        CalcItem(title: "Loan Against Property",   subtitle: "LAP · collateral-backed",       icon: "building.2.fill",              color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Loan Against Property (LAP)").environmentObject(vm))),
        CalcItem(title: "Agricultural Loan",       subtitle: "Kisan · crop · farm credit",    icon: "leaf.fill",                    color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Agricultural Loan").environmentObject(vm))),
        CalcItem(title: "Credit Line / Overdraft", subtitle: "Revolving · interest-only",     icon: "creditcard.fill",              color: .navy, bgColor: .navyLight, destination: AnyView(CreditLineOverdraftView().environmentObject(vm))),
        CalcItem(title: "Consumer Durable / EMI",  subtitle: "Electronics · appliances",      icon: "cart.fill",                    color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Consumer Durable / EMI Loan").environmentObject(vm))),
    ]}

    private var investmentItems: [CalcItem] {[
        CalcItem(title: "SIP Calculator",          subtitle: "Monthly · goal-based planning", icon: "calendar.badge.plus",          color: .gold, bgColor: .goldLight, destination: AnyView(SIPCalculatorView().environmentObject(vm))),
        CalcItem(title: "Mutual Fund (Lump Sum)",  subtitle: "One-time · CAGR returns",       icon: "chart.pie.fill",               color: .gold, bgColor: .goldLight, destination: AnyView(LumpSumMFView().environmentObject(vm))),
        CalcItem(title: "SWP Calculator",          subtitle: "Systematic withdrawal plan",    icon: "arrow.down.left.circle",       color: .gold, bgColor: .goldLight, destination: AnyView(SWPCalculatorView().environmentObject(vm))),
        CalcItem(title: "FD Calculator",           subtitle: "Fixed deposit · maturity",      icon: "building.columns.fill",        color: .gold, bgColor: .goldLight, destination: AnyView(FDCalculatorView().environmentObject(vm))),
        CalcItem(title: "RD Calculator",           subtitle: "Recurring deposit · monthly",   icon: "clock.fill",                   color: .gold, bgColor: .goldLight, destination: AnyView(RDCalculatorView().environmentObject(vm))),
    ]}

    private var moreItems: [CalcItem] {[
        CalcItem(title: "Tax Calculator",          subtitle: "Old vs new regime · slabs",     icon: "percent",                      color: .teal, bgColor: .tealLight, destination: AnyView(TaxCalculatorView().environmentObject(vm))),
        CalcItem(title: "NPS Calculator",          subtitle: "National pension · annuity",    icon: "shield.fill",                  color: .teal, bgColor: .tealLight, destination: AnyView(NPSCalculatorView().environmentObject(vm))),
        CalcItem(title: "PF Calculator",           subtitle: "EPF · employer · employee",     icon: "briefcase.fill",               color: .teal, bgColor: .tealLight, destination: AnyView(PFCalculatorView().environmentObject(vm))),
        CalcItem(title: "Gratuity Calculator",     subtitle: "Retirement benefit · years",    icon: "gift.fill",                    color: .teal, bgColor: .tealLight, destination: AnyView(GratuityCalculatorView().environmentObject(vm))),
    ]}

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
        !searchText.isEmpty &&
        filteredLoans.isEmpty &&
        filteredInvestments.isEmpty &&
        filteredMore.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if hasNoResults {
                    NoResultsView(query: searchText)
                        .padding(.top, 80)
                } else {
                    if !filteredLoans.isEmpty {
                        CalcSectionView(title: "Loans",
                                        icon: "banknote",
                                        color: .navy,
                                        items: filteredLoans)
                    }
                    if !filteredInvestments.isEmpty {
                        CalcSectionView(title: "Investments",
                                        icon: "chart.line.uptrend.xyaxis",
                                        color: .gold,
                                        items: filteredInvestments)
                    }
                    if !filteredMore.isEmpty {
                        CalcSectionView(title: "More Calculators",
                                        icon: "ellipsis.circle",
                                        color: .teal,
                                        items: filteredMore)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search calculators…"
        )
    }
}

// MARK: — Section view
private struct CalcSectionView: View {
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
                // Glass card
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                        NavigationLink(destination: item.destination) {
                            CalcRowView(item: item)
                        }
                        .buttonStyle(.plain)

                        if idx < items.count - 1 {
                            Divider().padding(.leading, 62)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

                // Top highlight shimmer
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.30), Color.clear],
                        startPoint: .top,
                        endPoint:   .center
                    ))
                    .frame(height: 44)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: — Row view
private struct CalcRowView: View {
    let item: CalcItem
    @ObservedObject private var store = SavedStore.shared

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(item.color.opacity(0.13))
                    .frame(width: 38, height: 38)
                Image(systemName: item.icon)
                    .font(.system(size: 16, weight: .medium))
                    .symbolRenderingMode(.hierarchical)
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

// MARK: — No results
private struct NoResultsView: View {
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

// MARK: — Saved calculators store
final class SavedStore: ObservableObject {
    static let shared = SavedStore()
    private let key = "savedCalculatorIDs"

    @Published private(set) var savedIDs: Set<String> = []

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: key) ?? []
        savedIDs = Set(stored)
    }

    func toggle(_ id: String) {
        if savedIDs.contains(id) { savedIDs.remove(id) }
        else { savedIDs.insert(id) }
        UserDefaults.standard.set(Array(savedIDs), forKey: key)
    }

    func isSaved(_ id: String) -> Bool { savedIDs.contains(id) }
}

// MARK: — Dashboard
struct DashboardPlaceholderView: View {
    @EnvironmentObject private var vm: CalculatorViewModel
    private let currency: String = Locale.current.currency?.identifier ?? "INR"
    private let accent = Color.teal

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // ── Loan Summary
                DashCard(title: "Loan", icon: "banknote.fill", color: .navy) {
                    DashRow(label: "EMI",            value: vm.emi.formatted(.currency(code: currency)), highlight: true, color: .navy)
                    DashRow(label: "Principal",      value: fmt(vm.principal))
                    DashRow(label: "Total Interest", value: fmt(vm.loanTotalInterest))
                    DashDivider()
                    DashRow(label: "Total Paid",     value: fmt(vm.loanTotalPayment), highlight: true, color: .navy)
                }

                // ── SIP Summary
                DashCard(title: "SIP", icon: "calendar.badge.plus", color: .gold) {
                    DashRow(label: "Invested",    value: fmt(vm.sipTotalInvested))
                    DashRow(label: "Est. Returns",value: fmt(vm.sipTotalInterest))
                    DashDivider()
                    DashRow(label: "Future Value",value: fmt(vm.sipFutureValue), highlight: true, color: .gold)
                }

                // ── FD / RD
                DashCard(title: "FD & RD", icon: "building.columns.fill", color: .teal) {
                    DashRow(label: "FD Maturity", value: fmt(vm.fdMaturityAmount), highlight: true, color: .teal)
                    DashRow(label: "FD Interest", value: fmt(vm.fdInterestAmount))
                    DashDivider()
                    DashRow(label: "RD Maturity", value: fmt(vm.rdMaturityAmount), highlight: true, color: .teal)
                    DashRow(label: "RD Interest", value: fmt(vm.rdInterestAmount))
                }

                // ── Tax & Retirement
                DashCard(title: "Tax & Retirement", icon: "shield.fill", color: Color(hex: "#7F77DD")) {
                    DashRow(label: "Tax Payable",      value: fmt(vm.taxPayable), highlight: true, color: Color(hex: "#7F77DD"))
                    DashRow(label: "NPS Corpus",       value: fmt(vm.npsCorpusAtMaturity))
                    DashRow(label: "Est. Pension/yr",  value: fmt(vm.npsEstimatedAnnualPension))
                    DashDivider()
                    DashRow(label: "PF Corpus",        value: fmt(vm.pfCorpusAtMaturity))
                    DashRow(label: "Gratuity",         value: fmt(vm.gratuityAmount))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .padding(.bottom, 32)
        }
    }

    private func fmt(_ v: Double) -> String { v.formatted(.currency(code: currency)) }
}

private struct DashCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)

            VStack(spacing: 8) { content() }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 0.5))
    }
}

private struct DashRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    var color: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: highlight ? .semibold : .regular))
                .foregroundStyle(highlight ? color : .primary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: highlight ? .bold : .regular))
                .foregroundStyle(highlight ? color : .secondary)
        }
    }
}

private struct DashDivider: View {
    var body: some View { Divider().padding(.vertical, 2) }
}

// MARK: — Saved
struct SavedPlaceholderView: View {
    @EnvironmentObject private var vm: CalculatorViewModel
    @ObservedObject private var store = SavedStore.shared

    // All calculators flat list — same source of truth as MainCalculatorView
    private var allItems: [CalcItem] {
        let loanItems: [CalcItem] = [
            CalcItem(title: "Home Loan",               subtitle: "EMI · amortization schedule",  icon: "house.fill",                  color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Home Loan").environmentObject(vm))),
            CalcItem(title: "Vehicle Loan",            subtitle: "Car · bike · commercial",       icon: "car.fill",                    color: .navy, bgColor: .navyLight, destination: AnyView(VehiclePersonalLoanView(title: "Vehicle Loan").environmentObject(vm))),
            CalcItem(title: "Personal Loan",           subtitle: "Unsecured · quick disbursal",   icon: "person.fill",                 color: .navy, bgColor: .navyLight, destination: AnyView(VehiclePersonalLoanView(title: "Personal Loan").environmentObject(vm))),
            CalcItem(title: "Education Loan",          subtitle: "Moratorium · study period",     icon: "book.fill",                   color: .navy, bgColor: .navyLight, destination: AnyView(EducationLoanView().environmentObject(vm))),
            CalcItem(title: "Business Loan",           subtitle: "MSME · working capital",        icon: "briefcase.fill",              color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Business Loan").environmentObject(vm))),
            CalcItem(title: "Gold Loan",               subtitle: "Pledged ornaments · LTV",       icon: "indianrupeesign.circle.fill", color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Gold Loan").environmentObject(vm))),
            CalcItem(title: "Loan Against Property",   subtitle: "LAP · collateral-backed",       icon: "building.2.fill",             color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Loan Against Property (LAP)").environmentObject(vm))),
            CalcItem(title: "Agricultural Loan",       subtitle: "Kisan · crop · farm credit",    icon: "leaf.fill",                   color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Agricultural Loan").environmentObject(vm))),
            CalcItem(title: "Credit Line / Overdraft", subtitle: "Revolving · interest-only",     icon: "creditcard.fill",             color: .navy, bgColor: .navyLight, destination: AnyView(CreditLineOverdraftView().environmentObject(vm))),
            CalcItem(title: "Consumer Durable / EMI",  subtitle: "Electronics · appliances",      icon: "cart.fill",                   color: .navy, bgColor: .navyLight, destination: AnyView(LoanCalculatorView(title: "Consumer Durable / EMI Loan").environmentObject(vm))),
        ]
        let investmentItems: [CalcItem] = [
            CalcItem(title: "SIP Calculator",         subtitle: "Monthly · goal-based planning",  icon: "calendar.badge.plus",         color: .gold, bgColor: .goldLight, destination: AnyView(SIPCalculatorView().environmentObject(vm))),
            CalcItem(title: "Mutual Fund (Lump Sum)", subtitle: "One-time · CAGR returns",        icon: "chart.pie.fill",              color: .gold, bgColor: .goldLight, destination: AnyView(LumpSumMFView().environmentObject(vm))),
            CalcItem(title: "SWP Calculator",         subtitle: "Systematic withdrawal plan",     icon: "arrow.down.left.circle",      color: .gold, bgColor: .goldLight, destination: AnyView(SWPCalculatorView().environmentObject(vm))),
            CalcItem(title: "FD Calculator",          subtitle: "Fixed deposit · maturity",       icon: "building.columns.fill",       color: .gold, bgColor: .goldLight, destination: AnyView(FDCalculatorView().environmentObject(vm))),
            CalcItem(title: "RD Calculator",          subtitle: "Recurring deposit · monthly",    icon: "clock.fill",                  color: .gold, bgColor: .goldLight, destination: AnyView(RDCalculatorView().environmentObject(vm))),
        ]
        let moreItems: [CalcItem] = [
            CalcItem(title: "Tax Calculator",     subtitle: "Old vs new regime · slabs",  icon: "percent",       color: .teal, bgColor: .tealLight, destination: AnyView(TaxCalculatorView().environmentObject(vm))),
            CalcItem(title: "NPS Calculator",     subtitle: "National pension · annuity", icon: "shield.fill",   color: .teal, bgColor: .tealLight, destination: AnyView(NPSCalculatorView().environmentObject(vm))),
            CalcItem(title: "PF Calculator",      subtitle: "EPF · employer · employee",  icon: "briefcase.fill",color: .teal, bgColor: .tealLight, destination: AnyView(PFCalculatorView().environmentObject(vm))),
            CalcItem(title: "Gratuity Calculator",subtitle: "Retirement benefit · years", icon: "gift.fill",     color: .teal, bgColor: .tealLight, destination: AnyView(GratuityCalculatorView().environmentObject(vm))),
        ]
        return loanItems + investmentItems + moreItems
    }

    private var savedItems: [CalcItem] {
        allItems.filter { store.isSaved($0.title) }
    }

    var body: some View {
        Group {
            if savedItems.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "star")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Color.gold.opacity(0.5))
                    Text("No saved calculators")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap the star on any calculator to bookmark it here.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ZStack(alignment: .top) {
                            VStack(spacing: 0) {
                                ForEach(Array(savedItems.enumerated()), id: \.element.id) { idx, item in
                                    HStack {
                                        NavigationLink(destination: item.destination) {
                                            CalcRowView(item: item)
                                        }
                                        .buttonStyle(.plain)
//                                        Button {
//                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                                store.toggle(item.title)
//                                            }
//                                        } label: {
//                                            Image(systemName: "star.fill")
//                                                .font(.system(size: 15))
//                                                .foregroundStyle(Color.gold)
//                                                .padding(.trailing, 14)
//                                        }
                                    }
                                    if idx < savedItems.count - 1 {
                                        Divider().padding(.leading, 62)
                                    }
                                }
                            }
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))

                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color.white.opacity(0.28), Color.clear], startPoint: .top, endPoint: .center))
                                .frame(height: 44)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

// MARK: — Profile
struct ProfilePlaceholderView: View {
    @AppStorage("profileName")       private var name       = ""
    @AppStorage("profileEmail")      private var email      = ""
    @AppStorage("profilePhone")      private var phone      = ""
    @AppStorage("profileCity")       private var city       = ""
    @AppStorage("profileOccupation") private var occupation = ""
    @AppStorage("profileMonthlyIncome") private var monthlyIncome = ""

    @State private var editMode = false

    private let accent = Color.navy

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.navy, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 90, height: 90)
                    Text(initials)
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.top, 12)

                Text(name.isEmpty ? "Your Name" : name)
                    .font(.title3.weight(.semibold))
                Text(email.isEmpty ? "email@example.com" : email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Edit / Save button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { editMode.toggle() }
                } label: {
                    Label(editMode ? "Save Profile" : "Edit Profile",
                          systemImage: editMode ? "checkmark.circle.fill" : "pencil.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(accent.opacity(0.12)))
                        .foregroundStyle(accent)
                }

                // Fields
                ProfileSection(title: "Personal Info", icon: "person.fill", color: accent) {
                    ProfileField(label: "Full Name",   value: $name,   placeholder: "Full Name",        editMode: editMode)
                    ProfileField(label: "Email",       value: $email,  placeholder: "info@example.com",    editMode: editMode, keyboardType: .emailAddress)
                    ProfileField(label: "Phone",       value: $phone,  placeholder: "+91 0000000000",    editMode: editMode, keyboardType: .phonePad)
                    ProfileField(label: "City",        value: $city,   placeholder: "Mumbai",             editMode: editMode)
                }
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 16)
        }
    }

    private var initials: String {
        let words = name.split(separator: " ").prefix(2)
        return words.compactMap { $0.first.map(String.init) }.joined().uppercased()
            .isEmpty ? "FP" : words.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 4)

            VStack(spacing: 0) { content() }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.18), lineWidth: 0.5))
        }
    }
}

private struct ProfileField: View {
    let label: String
    @Binding var value: String
    let placeholder: String
    let editMode: Bool
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 120, alignment: .leading)
            if editMode {
                TextField(placeholder, text: $value)
                    .font(.system(size: 14))
                    .keyboardType(keyboardType)
                    .multilineTextAlignment(.trailing)
            } else {
                Spacer()
                Text(value.isEmpty ? placeholder : value)
                    .font(.system(size: 14))
                    .foregroundStyle(value.isEmpty ? Color.secondary.opacity(0.5) : .primary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(alignment: .bottom) {
            Divider().padding(.leading, 14).opacity(0.6)
        }
    }
}

struct SettingsPlaceholderView: View {
    @Binding var darkMode: Bool
    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkMode)
            }
            Section("App") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build",   value: "1")
            }
        }
        .navigationTitle("Settings")
    }
}

struct AboutPlaceholderView: View {
    
    @State private var selectedLegalDoc: LegalDoc?
    
    var body: some View {
        List {
            
            Section {
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(
                                LinearGradient(
                                    colors: [.navy, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    
                    Text("FinCalc Pro")
                        .font(.title2.weight(.semibold))
                    
                    Text("Your complete financial toolkit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            
            Section("Legal") {
                
                Button("Privacy Policy") {
                    selectedLegalDoc = .privacy
                }
                .foregroundStyle(.primary)
                
                Button("Terms of Service") {
                    selectedLegalDoc = .terms
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("About")
        .sheet(item: $selectedLegalDoc) { doc in
            LegalSheetView(
                title: doc.title,
                content: doc.content
            )
        }
    }
}

// MARK: - Legal Types

enum LegalDoc: Identifiable {
    case privacy
    case terms
    
    var id: String { title }
    
    var title: String {
        switch self {
        case .privacy:
            return "Privacy Policy"
        case .terms:
            return "Terms of Service"
        }
    }
    
    var content: String {
        switch self {
            
        case .privacy:
            return """
            FinCalc Pro respects your privacy.

            We do not store personal financial data entered into calculators such as EMI, SIP, SWP, NPS, Home Loan, or Tax calculators.

            Calculations are processed locally on your device.

            Anonymous analytics may be used to improve app performance and user experience.

            We do not sell or share personal information with third parties.
            """
            
        case .terms:
            return """
            FinCalc Pro provides financial calculators for educational and informational purposes only.

            Results from EMI, SIP, SWP, NPS, Tax, and Loan calculators are estimates and should not be considered financial advice.

            Users should verify results independently before making financial decisions.

            FinCalc Pro is not responsible for decisions or losses arising from use of this app.
            """
        }
    }
}

// MARK: - Sheet View

struct LegalSheetView: View {
    
    let title: String
    let content: String
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                Text(content)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: — Preview
#Preview {
    FinCalcRootView()
}


