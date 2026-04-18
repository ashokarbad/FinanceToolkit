//
//  ContentView.swift
//  TestApp
//
//  Created by ashok arbad on 31/12/25.
//

import SwiftUI

// MARK: - Brand Colors (Deep Navy & Gold Palette)
extension Color {
    // Navy ramp
    static let brand        = Color(hex: "#185FA5") // Mid navy
    static let brandDark    = Color(hex: "#0C447C") // Dark navy
    static let brandDeep    = Color(hex: "#042C53") // Deepest navy — gradient end
    static let brandMid     = Color(hex: "#85B7EB") // Light blue
    static let brandSoft    = Color(hex: "#E6F1FB") // Pale blue — light text on dark bg
    static let brandAccent  = Color(hex: "#B5D4F4") // Soft blue

    // Gold ramp
    static let gold         = Color(hex: "#BA7517") // Deep gold
    static let goldLight    = Color(hex: "#FAC775") // Light gold
    static let goldSoft     = Color(hex: "#FAEEDA") // Pale gold — icon circle bg

    // Semantic
    static let gainGreen    = Color(hex: "#1D9E75")
    static let gainSoft     = Color(hex: "#E1F5EE")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Content View
struct ContentView: View {
    @State private var showMain = false

    var body: some View {
        ZStack {
            // Deep navy top → richer navy mid → darkest navy bottom
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color(hex: "#FAC775"), location: 0.0),
                    .init(color: Color(hex: "#0A3A6B"), location: 0.35),
                    .init(color: Color(hex: "#063159"), location: 0.65),
                    .init(color: Color(hex: "#042C53"), location: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle radial glow behind icon for depth
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.brandMid.opacity(0.18),
                    Color.clear
                ]),
                center: .init(x: 0.5, y: 0.38),
                startRadius: 0,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.goldSoft)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.gold.opacity(0.35), radius: 20, x: 0, y: 8)

                    Image(systemName: "function")
                        .symbolRenderingMode(.hierarchical)
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(Color.gold)
                }

                Spacer().frame(height: 32)

                // Title
                Text("Finance Toolkit")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Spacer().frame(height: 10)

                // Tagline
                Text("Loans · Investments · Tax · Retirement")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.goldLight)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 8)

                // Description
                Text("Home Loan, Car Loan, SIP, Mutual Fund,\nSWP, FD, RD, Tax, NPS, PF & Gratuity")
                    .font(.footnote)
                    .foregroundStyle(Color.brandSoft.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                // Gold CTA button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showMain = true
                    }
                }) {
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
                            .fill(
                                LinearGradient(
                                    colors: [Color.goldLight, Color.gold],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .foregroundStyle(Color.brandDeep)
                    .shadow(color: Color.gold.opacity(0.4), radius: 16, x: 0, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .fullScreenCover(isPresented: $showMain) {
            NavigationStack { MainCalculatorView() }
        }
    }
}
