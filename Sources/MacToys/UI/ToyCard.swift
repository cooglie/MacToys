//
//  ToyCard.swift
//  MacToys
//
//  Eine Karte pro Werkzeug im Dashboard: Icon, Name, Tagline, Status-Badge,
//  Aktivierungs-Schalter und ein Button zu den Eigenen Einstellungen.
//

import SwiftUI

struct ToyCard: View {
    let toy: any Toy
    @EnvironmentObject private var registry: ToyRegistry

    private var id: String { toy.descriptor.id }
    private var isOn: Bool { registry.enabled[id] ?? false }

    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                iconBlock
                VStack(alignment: .leading, spacing: 4) {
                    Text(toy.descriptor.name).font(.headline)
                    Text(toy.descriptor.tagline)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { registry.setEnabled(id, $0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }

            HStack {
                StatusBadge(status: toy.status)
                Spacer()
                Button {
                    showingSettings = true
                } label: {
                    Label("Einstellungen", systemImage: "slider.horizontal.3")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(Theme.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                .strokeBorder(.tertiary, lineWidth: 0.5)
        )
        .sheet(isPresented: $showingSettings) {
            ToySettingsSheet(toy: toy)
        }
    }

    private var iconBlock: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Theme.color(toy.descriptor.accent).opacity(0.18))
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: toy.descriptor.symbol)
                    .font(.title3)
                    .foregroundStyle(Theme.color(toy.descriptor.accent))
            )
    }
}

/// Sheet-Wrapper für die Eigenen Einstellungen eines Toys.
struct ToySettingsSheet: View {
    let toy: any Toy
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(toy.descriptor.name) — Einstellungen")
                    .font(.headline)
                Spacer()
                Button("Fertig") {
                    dismiss()
                    // Standalone-Fenster (via NSWindow): ebenfalls schließen.
                    NSApp.keyWindow?.close()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            Divider()
            toy.settingsView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding()
        }
        .frame(minWidth: 560, minHeight: 460)
    }
}
