// ShellViews.swift
// Finance Toolkit — sidebar destination views (Dashboard, Saved, Tips, Profile, Settings, About)

import SwiftUI

// MARK: - Dashboard
struct DashboardView: View {
    @EnvironmentObject private var vm: CalculatorViewModel
    @ObservedObject private var store = SavedStore.shared
    var navigateTo: ((SidebarDestination) -> Void)?
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Quick summary cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    DashboardCard(title: "Last EMI", value: vm.emi.formatted(.currency(code: currency)), icon: "house.fill", color: .navy)
                    DashboardCard(title: "Last SIP FV", value: vm.sipFutureValue.formatted(.currency(code: currency)), icon: "chart.line.uptrend.xyaxis", color: .gold)
                    DashboardCard(title: "Tax Payable", value: vm.taxPayable.formatted(.currency(code: currency)), icon: "percent", color: .teal)
                    Button { navigateTo?(.saved) } label: {
                        DashboardCard(title: "Saved Items", value: "\(store.calculations.count)", icon: "bookmark.fill", color: .gold)
                    }
                    .buttonStyle(.plain)
                }

                // Quick navigation
                HStack(spacing: 12) {
                    Button { navigateTo?(.saved) } label: {
                        Label("View Saved", systemImage: "bookmark.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.navy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.navy.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    Button { navigateTo?(.calculators) } label: {
                        Label("Favourites", systemImage: "star.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.gold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.gold.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                if !store.calculations.isEmpty {
                    Text("Recent Saves")
                        .font(.headline)
                        .padding(.top, 8)
                    ForEach(store.calculations.prefix(5)) { calc in
                        HStack(spacing: 12) {
                            Image(systemName: calc.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                                .frame(width: 28, height: 28)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.06)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(calc.calculatorTitle)
                                    .font(.subheadline.weight(.medium))
                                Text(calc.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(calc.date, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }

                if store.calculations.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(.tertiary)
                        Text("Your dashboard will populate as you use calculators and save results.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                }
            }
            .padding()
        }
    }
}

struct DashboardCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(color.opacity(0.2), lineWidth: 0.5))
    }
}

// MARK: - Saved
struct SavedView: View {
    @ObservedObject private var store = SavedStore.shared
    private var currency: String { Locale.current.currency?.identifier ?? "INR" }

    var body: some View {
        Group {
            if store.calculations.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "star")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No saved calculations")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap \"Save\" on any calculator result to bookmark it here.")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.calculations) { calc in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: calc.icon)
                                    .foregroundStyle(.secondary)
                                Text(calc.calculatorTitle)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(calc.date, style: .date)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            if !calc.note.isEmpty {
                                Text(calc.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(calc.results, id: \.label) { entry in
                                HStack {
                                    Text(entry.label)
                                        .font(entry.isHighlight ? .caption.weight(.semibold) : .caption)
                                    Spacer()
                                    Text(entry.value)
                                        .font(entry.isHighlight ? .caption.bold() : .caption)
                                        .foregroundStyle(entry.isHighlight ? .primary : .secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete { offsets in store.delete(at: offsets) }
                }
            }
        }
    }
}

// MARK: - Tips & FAQ
struct TipsFAQView: View {
    private let tips: [(icon: String, title: String, detail: String)] = [
        ("lightbulb.fill", "Start SIPs early", "Even small monthly investments grow significantly over 15–20 years thanks to compounding."),
        ("percent", "Compare tax regimes", "Use the Tax Calculator to check which regime — Old or New — saves you more tax."),
        ("house.fill", "Prepay your home loan", "Extra payments towards the principal reduce total interest dramatically."),
        ("shield.fill", "Max out NPS for tax benefits", "NPS gives an extra ₹50K deduction under 80CCD(1B) beyond ₹1.5L under 80C."),
        ("banknote.fill", "Track your PF balance", "EPF earns ~8.1% p.a. tax-free — one of the best guaranteed-return instruments."),
        ("gift.fill", "Know your gratuity entitlement", "After 5 years of service, gratuity up to ₹20L is tax-exempt."),
        ("chart.line.uptrend.xyaxis", "SWP for retirement income", "Use SWP from a mutual fund corpus to create a monthly pension-like income."),
        ("creditcard.fill", "Avoid high-interest debt", "Credit card/overdraft interest (24–42% p.a.) compounds fast — pay off quickly."),
    ]

    var body: some View {
        List {
            ForEach(tips, id: \.title) { tip in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: tip.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "#E87D2B"))
                        .frame(width: 30, height: 30)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#E87D2B").opacity(0.12)))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.subheadline.weight(.semibold))
                        Text(tip.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Profile
struct ProfileView: View {
    @AppStorage("profileName") private var name = ""
    @AppStorage("profileAge") private var age = ""
    @AppStorage("profileCity") private var city = ""
    @ObservedObject private var store = SavedStore.shared
    var navigateTo: ((SidebarDestination) -> Void)?

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.navy, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                        Text(initials)
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name.isEmpty ? "Your Name" : name)
                            .font(.headline)
                            .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                        Text(city.isEmpty ? "City" : city)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Personal Details") {
                HStack { Text("Full Name"); Spacer(); TextField("Enter name", text: $name).multilineTextAlignment(.trailing) }
                HStack { Text("Age"); Spacer(); TextField("Age", text: $age).multilineTextAlignment(.trailing).keyboardType(.numberPad) }
                HStack { Text("City"); Spacer(); TextField("City", text: $city).multilineTextAlignment(.trailing) }
            }

            Section("Activity") {
                Button {
                    navigateTo?(.saved)
                } label: {
                    HStack {
                        Label("Saved Calculations", systemImage: "bookmark.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.calculations.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)

                Button {
                    navigateTo?(.calculators)
                } label: {
                    HStack {
                        Label("Favourites", systemImage: "star.fill")
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(store.savedIDs.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .keyboardDoneToolbar()
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        if parts.isEmpty { return "FT" }
        let first = parts.first?.prefix(1) ?? "F"
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }
}

// MARK: - Settings
struct SettingsView: View {
    @Binding var darkMode: Bool

    var body: some View {
        Form {
            Section("Appearance") {
                Toggle("Dark Mode", isOn: $darkMode)
            }
            Section("Data") {
                HStack {
                    Label("App Version", systemImage: "info.circle")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Feedback / Queries
struct FeedbackView: View {
    @State private var feedbackType: Int = 0
    @State private var subject = ""
    @State private var message = ""
    @State private var email = ""
    @State private var submitted = false
    @State private var showMailError = false
    private let types = ["Bug Report", "Feature Request", "General Query", "Other"]
    private let supportEmail = "ashokarbad@gmail.com"

    var body: some View {
        if submitted {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(.teal)
                Text("Thank you!")
                    .font(.title2.bold())
                Text("Your feedback has been sent.\nWe will get back to you if needed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Submit Another") {
                    withAnimation { resetForm() }
                }
                .buttonStyle(.bordered)
                .tint(.navy)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                Section {
                    SectionHeader(systemImage: "envelope.fill", title: "Feedback / Queries", color: .navy)
                    Picker("Type", selection: $feedbackType) {
                        ForEach(0..<types.count, id: \.self) { Text(types[$0]).tag($0) }
                    }
                    HStack { Text("Subject"); Spacer(); TextField("Brief subject", text: $subject).multilineTextAlignment(.trailing) }
                    HStack {
                        Text("Email (optional)")
                        Spacer()
                        TextField("", text: $email, prompt: Text("you@example.com").foregroundStyle(.quaternary))
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                }

                Section("Your Message") {
                    TextEditor(text: $message)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if message.isEmpty {
                                Text("Describe your feedback, bug, or question...")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section {
                    Button {
                        sendFeedbackEmail()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Submit Feedback", systemImage: "paperplane.fill")
                                .font(.headline)
                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                    .disabled(subject.isEmpty || message.isEmpty)
                    .tint(.navy)
                }
            }
            .keyboardDoneToolbar()
            .alert("Unable to Send Email", isPresented: $showMailError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Could not open the mail app. Please send your feedback manually to \(supportEmail).")
            }
        }
    }

    private func sendFeedbackEmail() {
        let typeLabel = types[feedbackType]
        let subjectLine = "[Finance Toolkit] \(typeLabel): \(subject)"
        let body = """
        Type: \(typeLabel)
        From: \(email.isEmpty ? "Not provided" : email)

        \(message)
        """

        let subjectEncoded = subjectLine.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:\(supportEmail)?subject=\(subjectEncoded)&body=\(bodyEncoded)"

        if let url = URL(string: mailtoString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                if success {
                    DispatchQueue.main.async {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            submitted = true
                        }
                    }
                }
            }
        } else {
            showMailError = true
        }
    }

    private func resetForm() {
        feedbackType = 0
        subject = ""
        message = ""
        email = ""
        submitted = false
    }
}

// MARK: - About
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(LinearGradient(colors: [.navy, .teal], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(.white)
                }
                .padding(.top, 30)

                Text("Finance Toolkit")
                    .font(.title.bold())
                Text("Loans · Investments · Tax · Retirement")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("A comprehensive Indian financial calculator suite covering home loans, vehicle loans, SIPs, mutual funds, FDs, RDs, tax planning, NPS, PF, and gratuity.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()
            }
        }
    }
}
