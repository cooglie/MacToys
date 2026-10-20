//
//  QuickLauncherToy.swift
//  MacToys — Quick Launcher
//
//  Ein globaler Hotkey öffnet ein schwebendes Suchfenster (Palette):
//  Apps starten, Taschenrechner, Dateien öffnen, Web-Suche.
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

final class QuickLauncherToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "quick-launcher",
        name: "Quick Launcher",
        tagline: "Apps starten, rechnen, Dateien finden — alles per Tastatur.",
        symbol: "command",
        accent: "#FF375F",
        category: .workflow
    )

    @Published private(set) var isRunning = false
    private var hotkeyID: UInt32?
    private var panelController: LauncherPanelController?
    private let settings = QuickLauncherSettings.shared

    @MainActor
    func start() {
        isRunning = true
        hotkeyID = HotkeyManager.shared.register(settings.hotkey) { [weak self] in
            DispatchQueue.main.async {
                self?.togglePalette()
            }
        }
        MacToysLog.info("Quick Launcher gestartet.", category: "launcher")
    }

    @MainActor
    func stop() {
        if let hotkeyID { HotkeyManager.shared.unregister(hotkeyID) }
        hotkeyID = nil
        panelController?.close()
        panelController = nil
        isRunning = false
    }

    /// Hauptaktion: aktiviert bei Bedarf und zeigt die Launcher-Palette.
    @MainActor func execute() {
        if !isRunning { ToyRegistry.shared.setEnabled(descriptor.id, true) }
        togglePalette()
    }

    @MainActor
    private func togglePalette() {
        if panelController?.isVisible == true {
            panelController?.close()
        } else {
            panelController = LauncherPanelController()
            panelController?.show()
        }
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(QuickLauncherSettingsView(toy: self)) }
}

final class QuickLauncherSettings: ObservableObject {
    static let shared = QuickLauncherSettings()
    @Published var hotkey: HotkeyConfig { didSet { save() } }
    private let key = "mactoys.launcher.config"
    private init() {
        // ⌘Space ist von Spotlight reserviert — RegisterEventHotKey schlägt
        // dort fehl. Daher ⌘⇧Space als Konflikt-freien Default wählen.
        let mods = UInt32(cmdKey | shiftKey), sp = UInt32(kVK_Space)
        hotkey = HotkeyConfig(keyCode: sp, modifiers: mods, label: "⌘⇧Space")
        if let data = UserDefaults.standard.data(forKey: key),
           let d = try? JSONDecoder().decode(HotkeyConfig.self, from: data) { hotkey = d }
    }
    private func save() { if let d = try? JSONEncoder().encode(hotkey) { UserDefaults.standard.set(d, forKey: key) } }
}

struct QuickLauncherSettingsView: View {
    @ObservedObject var toy: QuickLauncherToy
    @ObservedObject private var settings = QuickLauncherSettings.shared
    var body: some View {
        Form {
            Section("Hotkey") {
                HStack { Text("Palette ein-/ausblenden"); Spacer()
                    Text(settings.hotkey.label).font(.callout.monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 2).background(.quaternary, in: Capsule())
                }
            }
            Section("Funktionen") {
                Label("Apps starten", systemImage: "app")
                Label("Taschenrechner (z. B. 12*9+3)", systemImage: "equals")
                Label("Dateien öffnen", systemImage: "doc")
                Label("Web-Suche (prefix: g <suche>)", systemImage: "magnifyingglass")
            }
            Section("Tipp") {
                Text("Tippe einen Ausdruck wie 2+2 für Berechnung, einen App-Namen zum Starten, oder 'g katzen' für eine Google-Suche.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
