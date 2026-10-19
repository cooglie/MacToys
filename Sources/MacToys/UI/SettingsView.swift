//
//  SettingsView.swift
//  MacToys
//
//  Globale Einstellungen: Appearance, Launch-at-Login, Dashboard-Verhalten.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        Form {
            Section("Erscheinungsbild") {
                Picker("Darstellung", selection: $settings.appearance) {
                    ForEach(Appearance.allCases) { a in Text(a.label).tag(a) }
                }
                .pickerStyle(.segmented)
            }

            Section("Start") {
                Toggle("Beim Login starten", isOn: $settings.launchAtLogin)
                Toggle("Dashboard beim Start anzeigen", isOn: $settings.showDashboardAtLaunch)
            }

            Section("Über") {
                row("Version", "0.1")
                row("Lizenz", "MIT")
                row("Architektur", "Universal (arm64 + x86_64)")
            }
        }
        .frame(minWidth: 720, minHeight: 520)
    }

    /// macOS 12-taugliche Alternative zu LabeledContent.
    @ViewBuilder
    private func row(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
