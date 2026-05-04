// LaunchScreenView.swift
// Finance Toolkit — animated launch / splash screen

import SwiftUI

// MARK: - Feature Pill Data
private struct FeaturePill: Identifiable {
    let id = UUID()
    let icon: String
    let label: String
    let color: Color
}

private let featurePills: [FeaturePill] = [
    FeaturePill(icon: "house.fill", label: "Loans", color: Color.navy),
    FeaturePill(icon: "chart.line.uptrend.xyaxis", label: "Investments", color: Color.teal),
    FeaturePill(icon: "percent", label: "Tax", color: Color.gold),
    FeaturePill(icon: "chart.pie.fill", label: "Expenses", color: Color(hex: "#E87D2B")),
    FeaturePill(icon: "arrow.up.forward.circle.fill", label: "Outflow", color: Color(hex: "#3B82F6")),
    FeaturePill(icon: "note.text", label: "Notes", color: Color(hex: "#8B5CF6")),
]

// MARK: - Floating Circle
private struct FloatingCircle: Identifiable {
    let id = UUID()
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let opacity: Double
    let delay: Double
}

struct LaunchScreenView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showMain = false
    @State private var showOnboarding = false
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var logoRotation: Double = -30
    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var pillsOpacity: Double = 0
    @State private var pillsOffset: CGFloat = 30
    @State private var buttonOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.8
    @State private var pulseScale: CGFloat = 1.0
    @State private var circlesAnimated = false
    @Environment(\.verticalSizeClass) private var vSizeClass

    private var isCompact: Bool { vSizeClass == .compact }

    private let floatingCircles: [FloatingCircle] = [
        FloatingCircle(size: 140, x: 0.1, y: 0.15, opacity: 0.08, delay: 0),
        FloatingCircle(size: 90, x: 0.85, y: 0.2, opacity: 0.06, delay: 0.2),
        FloatingCircle(size: 60, x: 0.7, y: 0.75, opacity: 0.07, delay: 0.4),
        FloatingCircle(size: 110, x: 0.2, y: 0.8, opacity: 0.05, delay: 0.1),
        FloatingCircle(size: 50, x: 0.5, y: 0.6, opacity: 0.06, delay: 0.3),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#FAC775"), location: 0.0),
                        .init(color: Color(hex: "#0D4A7F"), location: 0.25),
                        .init(color: Color(hex: "#063159"), location: 0.60),
                        .init(color: Color(hex: "#031E3A"), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Floating circles background
                ForEach(floatingCircles) { circle in
                    Circle()
                        .fill(Color.goldLight.opacity(circle.opacity))
                        .frame(width: circle.size, height: circle.size)
                        .blur(radius: 20)
                        .position(
                            x: geo.size.width * circle.x,
                            y: geo.size.height * circle.y
                        )
                        .offset(y: circlesAnimated ? -12 : 12)
                        .animation(
                            .easeInOut(duration: 3.0)
                            .repeatForever(autoreverses: true)
                            .delay(circle.delay),
                            value: circlesAnimated
                        )
                }

                // Subtle grid pattern overlay
                Canvas { context, size in
                    let spacing: CGFloat = 40
                    context.opacity = 0.03
                    for x in stride(from: 0, to: size.width, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        context.stroke(path, with: .color(.white), lineWidth: 0.5)
                    }
                    for y in stride(from: 0, to: size.height, by: spacing) {
                        var path = Path()
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        context.stroke(path, with: .color(.white), lineWidth: 0.5)
                    }
                }
                .ignoresSafeArea()

                // Radial glow behind logo
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.goldLight.opacity(0.15),
                        Color.clear
                    ]),
                    center: isCompact ? .init(x: 0.3, y: 0.5) : .init(x: 0.5, y: 0.32),
                    startRadius: 0,
                    endRadius: 250
                )
                .ignoresSafeArea()

                if isCompact {
                    landscapeLayout
                } else {
                    portraitLayout
                }
            }
        }
        .onAppear { runAnimations() }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                hasCompletedOnboarding = true
                showOnboarding = false
                showMain = true
            }
        }
        .fullScreenCover(isPresented: $showMain) {
            FinCalcRootView()
        }
    }

    // MARK: - Portrait Layout
    private var portraitLayout: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            logoView(size: 110, iconSize: 56)

            Spacer().frame(height: 28)

            // App name + tagline
            VStack(spacing: 8) {
                Text("Finance Toolkit")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Calculators · Expenses · Outflow · Notes")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goldLight)
                    .multilineTextAlignment(.center)

                Text("Loans, SIP, Mutual Fund, FD, RD, Tax,\nNPS, PF, Gratuity & Multi-Currency Support")
                    .font(.caption)
                    .foregroundStyle(Color.navySoft.opacity(0.70))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 2)
            }
            .opacity(textOpacity)
            .offset(y: textOffset)

            Spacer().frame(height: 28)

            // Feature pills
            featurePillsGrid
                .padding(.horizontal, 28)
                .opacity(pillsOpacity)
                .offset(y: pillsOffset)

            Spacer()

            // CTA button
            ctaButton
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
                .opacity(buttonOpacity)
                .scaleEffect(buttonScale)
        }
    }

    // MARK: - Landscape Layout
    private var landscapeLayout: some View {
        HStack(spacing: 36) {
            Spacer()

            VStack(spacing: 12) {
                logoView(size: 76, iconSize: 40)

                Text("Finance Toolkit")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(textOpacity)

                Text("Calculators · Expenses · Outflow · Notes")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.goldLight)
                    .opacity(textOpacity)
            }

            VStack(spacing: 16) {
                featurePillsCompact
                    .opacity(pillsOpacity)
                    .offset(y: pillsOffset)

                ctaButton
                    .opacity(buttonOpacity)
                    .scaleEffect(buttonScale)
            }

            Spacer()
        }
    }

    // MARK: - Logo
    private func logoView(size: CGFloat, iconSize: CGFloat) -> some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(Color.goldLight.opacity(0.25), lineWidth: 2)
                .frame(width: size + 24, height: size + 24)
                .scaleEffect(pulseScale)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.goldSoft, Color.goldLight.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: Color.gold.opacity(0.50), radius: 28, x: 0, y: 12)

            Image(systemName: "indianrupeesign.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .font(.system(size: iconSize, weight: .bold))
                .foregroundStyle(Color.gold)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
        .rotationEffect(.degrees(logoRotation))
    }

    // MARK: - Feature Pills Grid (Portrait)
    private var featurePillsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 10) {
            ForEach(Array(featurePills.enumerated()), id: \.element.id) { index, pill in
                HStack(spacing: 5) {
                    Image(systemName: pill.icon)
                        .font(.system(size: 10))
                        .foregroundStyle(pill.color)
                    Text(pill.label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().strokeBorder(pill.color.opacity(0.3), lineWidth: 0.5))
                )
            }
        }
    }

    // MARK: - Feature Pills Compact (Landscape)
    private var featurePillsCompact: some View {
        HStack(spacing: 8) {
            ForEach(featurePills.prefix(4)) { pill in
                HStack(spacing: 4) {
                    Image(systemName: pill.icon)
                        .font(.system(size: 9))
                        .foregroundStyle(pill.color)
                    Text(pill.label)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.1))
                        .overlay(Capsule().strokeBorder(pill.color.opacity(0.3), lineWidth: 0.5))
                )
            }
        }
    }

    // MARK: - CTA Button
    private var ctaButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                if hasCompletedOnboarding {
                    showMain = true
                } else {
                    showOnboarding = true
                }
            }
        } label: {
            HStack(spacing: 12) {
                Text("Get Started")
                    .font(.headline)
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title3)
            }
            .frame(maxWidth: isCompact ? nil : .infinity)
            .padding(.horizontal, isCompact ? 36 : 0)
            .padding(.vertical, isCompact ? 14 : 18)
            .background(
                Capsule()
                    .fill(LinearGradient(
                        colors: [Color.goldLight, Color.gold],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
            )
            .foregroundStyle(Color.navyDeep)
            .shadow(color: Color.gold.opacity(0.50), radius: 20, x: 0, y: 10)
        }
    }

    // MARK: - Animations
    private func runAnimations() {
        // Floating circles start
        circlesAnimated = true

        // Logo: spring in with rotation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            logoScale = 1.0
            logoOpacity = 1.0
            logoRotation = 0
        }

        // Text: fade up
        withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
            textOpacity = 1.0
            textOffset = 0
        }

        // Feature pills: fade up
        withAnimation(.easeOut(duration: 0.5).delay(0.65)) {
            pillsOpacity = 1.0
            pillsOffset = 0
        }

        // Button: scale + fade
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9)) {
            buttonOpacity = 1.0
            buttonScale = 1.0
        }

        // Pulse ring: continuous
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true).delay(1.0)) {
            pulseScale = 1.12
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    var onComplete: () -> Void

    @AppStorage("profileName") private var profileName = ""
    @AppStorage("profileAge") private var profileAge = ""
    @AppStorage("selectedCurrency") private var selectedCurrency = CurrencySettings.selectedCode

    @State private var name = ""
    @State private var age = ""
    @State private var currency = CurrencySettings.selectedCode
    @State private var showValidation = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#0D4A7F"), location: 0.0),
                        .init(color: Color(hex: "#063159"), location: 0.5),
                        .init(color: Color(hex: "#031E3A"), location: 1.0)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer().frame(height: 20)

                        // App logo
                        Image("AppLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .shadow(color: .black.opacity(0.3), radius: 10, y: 4)

                        VStack(spacing: 8) {
                            Text("Welcome to")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                            Text("Finance Toolkit")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("Let's set up your profile")
                                .font(.subheadline)
                                .foregroundStyle(Color.goldLight)
                        }

                        // Profile fields
                        VStack(spacing: 16) {
                            // Name field
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Your Name", systemImage: "person.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                TextField("Enter your name", text: $name)
                                    .font(.body)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.12)))
                                    .foregroundStyle(.white)
                                    .tint(Color.goldLight)
                            }

                            // Age field
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Your Age", systemImage: "calendar")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                TextField("Enter your age", text: $age)
                                    .font(.body)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.12)))
                                    .foregroundStyle(.white)
                                    .keyboardType(.numberPad)
                                    .tint(Color.goldLight)
                            }

                            // Currency picker
                            VStack(alignment: .leading, spacing: 6) {
                                Label("Preferred Currency", systemImage: "banknote.fill")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                Picker("Currency", selection: $currency) {
                                    ForEach(CurrencySettings.supportedCurrencies, id: \.code) { c in
                                        Text("\(c.symbol) \(c.name) (\(c.code))").tag(c.code)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(RoundedRectangle(cornerRadius: 10).fill(.white.opacity(0.12)))
                                .tint(Color.goldLight)
                            }
                        }
                        .padding(.horizontal, 28)

                        // Continue button
                        Button {
                            let trimmed = name.trimmingCharacters(in: .whitespaces)
                            guard !trimmed.isEmpty else {
                                showValidation = true
                                return
                            }
                            profileName = trimmed
                            profileAge = age
                            selectedCurrency = currency
                            onComplete()
                        } label: {
                            HStack(spacing: 10) {
                                Text("Continue")
                                    .font(.headline)
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.title3)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color.goldLight, Color.gold],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                            )
                            .foregroundStyle(Color(hex: "#031E3A"))
                            .shadow(color: Color.gold.opacity(0.4), radius: 16, y: 8)
                        }
                        .padding(.horizontal, 32)

                        Text("You can update these anytime in Profile settings.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)

                        Spacer()
                    }
                }
            }
        }
        .alert("Please Enter Your Name", isPresented: $showValidation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your name is required to continue.")
        }
    }
}

#Preview { LaunchScreenView() }
