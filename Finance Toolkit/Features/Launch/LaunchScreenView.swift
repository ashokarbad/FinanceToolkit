// LaunchScreenView.swift
// Finance Toolkit — animated launch / splash screen

import SwiftUI

struct LaunchScreenView: View {
    @State private var showMain = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @Environment(\.verticalSizeClass) private var vSizeClass

    private var isCompact: Bool { vSizeClass == .compact }

    var body: some View {
        ZStack {
            // Deep navy gradient
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#FAC775"), location: 0.0),
                    .init(color: Color(hex: "#0A3A6B"), location: 0.30),
                    .init(color: Color(hex: "#063159"), location: 0.65),
                    .init(color: Color(hex: "#042C53"), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Radial glow
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.navyMid.opacity(0.20),
                    Color.clear
                ]),
                center: .init(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 300
            )
            .ignoresSafeArea()

            if isCompact {
                // Landscape layout — horizontal arrangement
                HStack(spacing: 40) {
                    Spacer()

                    // Logo + text group
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.goldSoft)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.gold.opacity(0.40), radius: 18, x: 0, y: 6)
                            Image(systemName: "indianrupeesign.circle.fill")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(Color.gold)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        Text("Finance Toolkit")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)
                            .opacity(textOpacity)

                        Text("Loans · Investments · Tax · Retirement")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.goldLight)
                            .opacity(textOpacity)
                    }

                    // CTA button
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            showMain = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.headline)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.goldLight, Color.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .foregroundStyle(Color.navyDeep)
                        .shadow(color: Color.gold.opacity(0.45), radius: 18, x: 0, y: 8)
                    }
                    .opacity(buttonOpacity)

                    Spacer()
                }
            } else {
                // Portrait layout — vertical arrangement
                VStack(spacing: 0) {
                    Spacer()

                    // Logo icon
                    ZStack {
                        Circle()
                            .fill(Color.goldSoft)
                            .frame(width: 110, height: 110)
                            .shadow(color: Color.gold.opacity(0.40), radius: 24, x: 0, y: 10)

                        Image(systemName: "indianrupeesign.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 58, weight: .bold))
                            .foregroundStyle(Color.gold)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    Spacer().frame(height: 30)

                    // App name
                    VStack(spacing: 6) {
                        Text("Finance Toolkit")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Loans · Investments · Tax · Retirement")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.goldLight)
                            .multilineTextAlignment(.center)

                        Spacer().frame(height: 6)

                        Text("Home Loan, Car Loan, SIP, Mutual Fund,\nSWP, FD, RD, Tax, NPS, PF & Gratuity")
                            .font(.footnote)
                            .foregroundStyle(Color.navySoft.opacity(0.80))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .opacity(textOpacity)

                    Spacer()

                    // CTA button
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                            showMain = true
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text("Get Started")
                                .font(.headline)
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title3)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color.goldLight, Color.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                        .foregroundStyle(Color.navyDeep)
                        .shadow(color: Color.gold.opacity(0.45), radius: 18, x: 0, y: 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 52)
                    .opacity(buttonOpacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.65).delay(0.1)) {
                logoScale   = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.45)) {
                textOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.75)) {
                buttonOpacity = 1.0
            }
        }
        .fullScreenCover(isPresented: $showMain) {
            FinCalcRootView()
        }
    }
}

#Preview { LaunchScreenView() }
