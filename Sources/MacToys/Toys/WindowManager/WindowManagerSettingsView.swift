//
//  WindowManagerSettingsView.swift
//  MacToys — Window Manager
//
//  Eigen-Einstellungen des Window Managers: Layout-Liste mit Hotkey-Anzeige,
//  Gap-Slider, Animations-Toggle, Berechtigungs-Status.
//

import SwiftUI

struct WindowManagerSettingsView: View {
    @ObservedObject var toy: WindowManagerToy
    @ObservedObject private var settings = WindowManagerSettings.shared

    var body: some View {
        Form {
            Section("Berechtigung") {
                if toy.status == .needsPermission("Bedienhilfen") {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Bedienhilfen benötigt — Fenster lassen sich nicht steuern.")
                        Spacer()
                        Button("Öffnen") { Permissions.openAccessibilitySettings() }
                    }
                } else {
                    Label("Bedienhilfen aktiv", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }

            Section {
                ForEach(WindowLayout.allCases) { layout in
                    HStack {
                        Image(systemName: layout.symbol)
                            .frame(width: 22)
                        Text(layout.label)
                        Spacer()
                        Text(settings.hotkeys[layout]?.label ?? "—")
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.quaternary, in: Capsule())
                    }
                }
            } header: {
                Text("Layouts & Hotkeys")
            } footer: {
                Text("Hotkeys sind ⌃⌥-basiert (Standard). Anpassbare Zuweisung folgt in einer späteren Version.")
                    .font(.caption)
            }

            Section("Verhalten") {
                Slider(value: $settings.gap, in: 0...24) {
                    Text("Randabstand")
                } minimumValueLabel: {
                    Text("0").font(.caption)
                } maximumValueLabel: {
                    Text("24").font(.caption)
                }
                Toggle("Animiertes Einschnappen", isOn: $settings.animate)
            }

            Section("Tipp") {
                Text("Aktiviere das Werkzeug im Dashboard und nutze die Hotkeys, um das fokussierte Fenster einzuschnappen.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
