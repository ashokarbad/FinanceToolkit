// SharedComponents.swift
// Finance Toolkit — reusable UI components for calculator screens

import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let systemImage: String
    let title: String
    let color: Color

    init(systemImage: String, title: String, color: Color = .navy) {
        self.systemImage = systemImage
        self.title = title
        self.color = color
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 28, height: 28)
                .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(color.opacity(0.12)))
            Text(title)
                .font(.headline)
                .foregroundStyle(color)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Result Card
struct ResultCard<Content: View>: View {
    let systemImage: String
    let accentColor: Color
    let title: String
    let onSave: (() -> Void)?
    @ViewBuilder var content: () -> Content

    init(systemImage: String,
         accentColor: Color = .navy,
         title: String = "Results",
         onSave: (() -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.systemImage = systemImage
        self.accentColor = accentColor
        self.title = title
        self.onSave = onSave
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(accentColor)
                    .font(.title3)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(accentColor.opacity(0.12)))
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Spacer()
                if let onSave {
                    SaveSkipButtons(onSave: onSave)
                }
            }
            content()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(accentColor.opacity(0.28), lineWidth: 1))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

// MARK: - Save / Skip buttons
struct SaveSkipButtons: View {
    let onSave: () -> Void
    @State private var saved = false

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                onSave()
                saved = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: saved ? "checkmark.circle.fill" : "bookmark")
                    .font(.system(size: 12, weight: .semibold))
                Text(saved ? "Saved" : "Save")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(saved ? .white : .navy)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Capsule().fill(saved ? Color.teal : Color.navy.opacity(0.12)))
        }
        .buttonStyle(.plain)
        .disabled(saved)
    }
}

// MARK: - Result Row
struct ResultRow: View {
    let label: String
    let value: String
    var isHighlight: Bool = false
    var accentColor: Color = .navy

    var body: some View {
        HStack {
            Text(label)
                .font(isHighlight ? .subheadline.weight(.semibold) : .subheadline)
                .foregroundStyle(isHighlight ? accentColor : .primary)
            Spacer()
            Text(value)
                .font(isHighlight ? .subheadline.bold() : .subheadline)
                .foregroundStyle(isHighlight ? accentColor : .secondary)
        }
    }
}

// MARK: - Keyboard Done toolbar
struct KeyboardDoneToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .foregroundStyle(Color.navy)
                .fontWeight(.semibold)
            }
        }
    }
}

extension View {
    func keyboardDoneToolbar() -> some View { modifier(KeyboardDoneToolbar()) }
}

// MARK: - Info sheet builder
struct InfoSheet: View {
    let title: String
    let body1: String
    let body2: String
    let accent: Color
    var link: String? = nil

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title2.bold())
                        .foregroundStyle(accent)
                    Text(body1)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Text(body2)
                        .font(.body)
                        .foregroundStyle(.secondary)
                    if let urlStr = link, let url = URL(string: urlStr) {
                        Link(destination: url) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                Text("Open Official Calculator")
                                Image(systemName: "arrow.up.right.square")
                            }
                            .font(.body.weight(.semibold))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Landscape-aware form wrapper
/// Wraps Form in a GeometryReader so calculators respond to orientation change naturally.
struct LandscapeAwareForm<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { _ in
            Form { content() }
        }
    }
}
