// AppShell.swift
// Finance Toolkit — root shell with sidebar navigation

import SwiftUI

// MARK: - Root entry
struct FinCalcRootView: View {
    @AppStorage("darkMode") private var darkMode = false
    @StateObject private var vm = CalculatorViewModel()
    @StateObject private var savedStore = SavedStore.shared

    var body: some View {
        FinCalcAppShell()
            .environmentObject(vm)
            .environmentObject(savedStore)
            .preferredColorScheme(darkMode ? .dark : .light)
    }
}

// MARK: - App shell
struct FinCalcAppShell: View {
    @AppStorage("darkMode") private var darkMode = false
    @EnvironmentObject private var vm: CalculatorViewModel
    @State private var sidebarOpen = false
    @State private var selected: SidebarDestination = .dashboard

    var body: some View {
        ZStack(alignment: .leading) {

            // Background gradient
            LinearGradient(
                colors: darkMode
                    ? [Color(hex: "#0d1b2e"), Color(hex: "#0a2218"), Color(hex: "#1a1200")]
                    : [Color(hex: "#dceeff"), Color(hex: "#d0f5ea"), Color(hex: "#fff5e0")],
                startPoint: .topLeading,
                endPoint:   .bottomTrailing
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.4), value: darkMode)

            AmbientBlobsView()

            // Main content — pushed right when sidebar is open
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
            .scaleEffect(sidebarOpen ? 0.92 : 1, anchor: .trailing)
            .offset(x: sidebarOpen ? 260 : 0)
            .opacity(sidebarOpen ? 0.55 : 1)
            .animation(.spring(response: 0.35, dampingFraction: 0.82), value: sidebarOpen)
            .allowsHitTesting(!sidebarOpen)

            // Dim overlay — tap-outside closes sidebar
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
            SidebarDrawer(selected: $selected,
                          darkMode: $darkMode,
                          sidebarOpen: $sidebarOpen)
                .frame(width: 264)
                .offset(x: sidebarOpen ? 0 : -272)
                .animation(.spring(response: 0.35, dampingFraction: 0.82), value: sidebarOpen)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch selected {
        case .calculators: MainCalculatorView()
        case .dashboard:   DashboardView(navigateTo: navigate)
        case .saved:       SavedView()
        case .expenses:    ExpensesTrackerView()
        case .outflow:     MonthlyOutflowView()
        case .notes:       NotesListView()
        case .tips:        TipsFAQView()
        case .profile:     ProfileView(navigateTo: navigate)
        case .settings:    SettingsView(darkMode: $darkMode)
        case .feedback:    FeedbackView()
        case .about:       AboutView()
        }
    }

    private func navigate(_ destination: SidebarDestination) {
        selected = destination
    }
}

// MARK: - Sidebar drawer
struct SidebarDrawer: View {
    @Binding var selected: SidebarDestination
    @Binding var darkMode: Bool
    @Binding var sidebarOpen: Bool

    private let mainItems:    [SidebarDestination] = [.dashboard, .expenses, .outflow, .saved, .calculators, .notes, .tips]
    private let accountItems: [SidebarDestination] = [.profile, .settings, .feedback]
    private let infoItems:    [SidebarDestination] = [.about]

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Rectangle().fill(Color.navy.opacity(0.07)).ignoresSafeArea()

            // Right edge separator
            HStack {
                Spacer()
                Rectangle()
                    .fill(Color.primary.opacity(0.09))
                    .frame(width: 0.5)
            }

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        BrandHeaderView()
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 26)

                        SidebarSectionLabel("Main")
                        ForEach(mainItems) { item in
                            SidebarRow(item: item, isSelected: selected == item) {
                                select(item)
                            }
                        }

                        sectionDivider

                        SidebarSectionLabel("Account")
                        ForEach(accountItems) { item in
                            SidebarRow(item: item, isSelected: selected == item) {
                                select(item)
                            }
                        }

                        sectionDivider

                        SidebarSectionLabel("Info")
                        ForEach(infoItems) { item in
                            SidebarRow(item: item, isSelected: selected == item) {
                                select(item)
                            }
                        }
                    }
                }

                DarkModeToggleRow(darkMode: $darkMode)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .safeAreaPadding(.top, 8)
            .safeAreaPadding(.bottom, 8)
        }
        .clipShape(RoundedCornerShape(radius: 22, corners: [.topRight, .bottomRight]))
    }

    private func select(_ item: SidebarDestination) {
        selected = item
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            sidebarOpen = false
        }
    }

    private var sectionDivider: some View {
        Divider()
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
    }
}

// MARK: - Brand header
struct BrandHeaderView: View {
    var body: some View {
        HStack(spacing: 11) {
            Image("AppLogo")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Finance Toolkit")
                    .font(.system(size: 15, weight: .semibold))
                Text("Your financial companion")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .tracking(0.4)
            }
        }
    }
}

// MARK: - Section label
struct SidebarSectionLabel: View {
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

// MARK: - Sidebar row (full-width tap area)
struct SidebarRow: View {
    let item: SidebarDestination
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(isSelected
                              ? item.accentColor.opacity(0.15)
                              : Color(.systemGray6).opacity(0.8))
                        .frame(width: 33, height: 33)
                    Image(systemName: item.icon)
                        .font(.system(size: 14))
                        .symbolRenderingMode(.multicolor)
                        .foregroundStyle(isSelected ? item.accentColor : item.accentColor.opacity(0.7))
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
            // Full-width tap area — no horizontal padding inside button, added via frame
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? item.accentColor.opacity(0.10) : Color.clear)
                    .padding(.horizontal, 8)
            )
            .contentShape(Rectangle()) // ensures the entire row is tappable
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Dark mode toggle
struct DarkModeToggleRow: View {
    @Binding var darkMode: Bool
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(darkMode ? Color.gold.opacity(0.15) : Color.orange.opacity(0.10))
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

// MARK: - Ambient colour blobs
struct AmbientBlobsView: View {
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle().fill(Color.navy.opacity(0.32))
                    .frame(width: 340, height: 340).blur(radius: 90)
                    .offset(x: -90, y: -110)
                Circle().fill(Color.teal.opacity(0.27))
                    .frame(width: 260, height: 260).blur(radius: 75)
                    .offset(x: geo.size.width * 0.55, y: geo.size.height * 0.58)
                Circle().fill(Color.gold.opacity(0.24))
                    .frame(width: 220, height: 220).blur(radius: 70)
                    .offset(x: geo.size.width * 0.60, y: geo.size.height * 0.18)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Rounded corner shape (selective corners)
struct RoundedCornerShape: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
