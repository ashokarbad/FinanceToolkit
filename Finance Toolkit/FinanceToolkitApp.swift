// FinanceToolkitApp.swift
// Finance Toolkit
// Entry point for the application

import SwiftUI

@main
struct FinanceToolkitApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacy = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                LaunchScreenView()

                if showPrivacy {
                    PrivacyScreen()
                        .transition(.opacity)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showPrivacy = phase != .active
                }
            }
        }
    }
}

// MARK: - Privacy Screen
struct PrivacyScreen: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "#0D4A7F"), Color(hex: "#063159"), Color(hex: "#031E3A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 10, y: 4)

                Text("Finance Toolkit")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
    }
}
