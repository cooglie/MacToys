//
//  DashboardView.swift
//  MacToys
//
//  Zentrale Übersicht aller Werkzeuge: Karten mit Aktivierungs-Schalter,
//  Status-Badge und Schnellzugriff auf die Eigenen Einstellungen.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var registry: ToyRegistry
    @EnvironmentObject private var settings: AppSettings

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: Theme.spacing)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                header
                LazyVGrid(columns: columns, spacing: Theme.spacing) {
                    ForEach(registry.toys, id: \.descriptor.id) { toy in
                        ToyCard(toy: toy)
                    }
                }
                footer
            }
            .padding(24)
        }
        .frame(minWidth: 640, minHeight: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "hammer.fill")
                .font(.title)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("MacToys").font(.largeTitle.bold())
                Text("More power to your Mac.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Einstellungen") {
                NSApp.sendAction(#selector(AppDelegate.showSettings), to: nil, from: nil)
            }
            .buttonStyle(.bordered)
        }
    }

    private var footer: some View {
        HStack {
            Text("\(registry.toys.count) Werkzeuge · \(registry.enabled.filter { $0.value }.count) aktiv")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
            Text("Free forever · Open source")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 4)
    }
}
