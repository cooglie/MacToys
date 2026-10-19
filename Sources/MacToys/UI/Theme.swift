//
//  Theme.swift
//  MacToys
//
//  Gemeinsame Styling-Hilfen: Akzentfarben, Kartengestalt, Abstände.
//

import SwiftUI

enum Theme {
    static let cornerRadius: CGFloat = 12
    static let cardPadding: CGFloat = 16
    static let spacing: CGFloat = 16

    /// Hex-String → Color (z. B. "#FF8800").
    static func color(_ hex: String) -> Color {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard let v = UInt32(s, radix: 16) else { return .accentColor }
        let r = Double((v >> 16) & 0xFF) / 255
        let g = Double((v >> 8) & 0xFF) / 255
        let b = Double(v & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }
}

/// Status-Badge für eine Toy-Karte.
struct StatusBadge: View {
    let status: ToyStatus

    var body: some View {
        switch status {
        case .off:
            badge("Aus", color: .secondary)
        case .on:
            badge("Aktiv", color: .green)
        case .needsPermission(let label):
            badge(label, color: .orange)
        }
    }

    private func badge(_ text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12), in: Capsule())
    }
}
