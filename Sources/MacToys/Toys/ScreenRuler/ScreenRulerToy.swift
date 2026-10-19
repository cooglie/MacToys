//
//  ScreenRulerToy.swift
//  MacToys — Screen Ruler
//
//  Misst Pixel-Abstände auf dem Bildschirm. Nutzer zieht ein Rechteck auf
//  (wie Text Extractor); das Overlay zeigt live Breite × Höhe in Pixeln.
//  Optional: Fadenkreuz-Linie zum Abmessen einzelner Strecken.
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

final class ScreenRulerToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "screen-ruler",
        name: "Screen Ruler",
        tagline: "Pixel-Abstände und -Größen auf dem Bildschirm messen.",
        symbol: "ruler",
        accent: "#FFD60A",
        category: .workflow
    )

    @Published private(set) var isRunning = false
    @Published private(set) var lastMeasurement: String = ""

    private var hotkeyID: UInt32?
    private let settings = ScreenRulerSettings.shared

    func start() {
        isRunning = true
        hotkeyID = HotkeyManager.shared.register(settings.hotkey) { [weak self] in
            self?.measure()
        }
        MacToysLog.info("Screen Ruler gestartet.", category: "ruler")
    }

    func stop() {
        if let hotkeyID { HotkeyManager.shared.unregister(hotkeyID) }
        hotkeyID = nil
        isRunning = false
    }

    /// Hauptaktion: aktiviert das Werkzeug bei Bedarf und startet die Messung.
    @MainActor func execute() {
        if !isRunning { ToyRegistry.shared.setEnabled(descriptor.id, true) }
        measure()
    }

    func measure() {
        guard isRunning else { return }
        let overlay = RulerOverlay()
        overlay.runModal(onComplete: { [weak self] rect in
            let w = Int(rect.width)
            let h = Int(rect.height)
            let m = "\(w) × \(h) px"
            self?.lastMeasurement = m
            if self?.settings.copyToClipboard ?? true {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString("\(w)x\(h)", forType: .string)
            }
        })
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(ScreenRulerSettingsView(toy: self)) }
}

final class ScreenRulerSettings: ObservableObject {
    static let shared = ScreenRulerSettings()
    @Published var hotkey: HotkeyConfig { didSet { save() } }
    @Published var copyToClipboard: Bool {
        didSet { UserDefaults.standard.set(copyToClipboard, forKey: "mactoys.ruler.copy") }
    }
    private let key = "mactoys.ruler.config"
    private init() {
        let ctrl = UInt32(controlKey), opt = UInt32(optionKey)
        let m = ctrl | opt
        copyToClipboard = UserDefaults.standard.object(forKey: "mactoys.ruler.copy") as? Bool ?? true
        hotkey = HotkeyConfig(keyCode: UInt32(kVK_ANSI_R), modifiers: m, label: "⌃⌥R")
        if let data = UserDefaults.standard.data(forKey: key),
           let d = try? JSONDecoder().decode(HotkeyConfig.self, from: data) { hotkey = d }
    }
    private func save() { if let d = try? JSONEncoder().encode(hotkey) { UserDefaults.standard.set(d, forKey: key) } }
}

struct ScreenRulerSettingsView: View {
    @ObservedObject var toy: ScreenRulerToy
    @ObservedObject private var settings = ScreenRulerSettings.shared
    var body: some View {
        Form {
            Section("Hotkey") {
                HStack { Text("Messung starten"); Spacer()
                    Text(settings.hotkey.label).font(.callout.monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 2).background(.quaternary, in: Capsule())
                }
                Button("Jetzt messen") { toy.measure() }
            }
            Section("Optionen") {
                Toggle("Maße automatisch kopieren", isOn: $settings.copyToClipboard)
            }
            Section("Letzte Messung") {
                if toy.lastMeasurement.isEmpty {
                    Text("Noch nichts gemessen.").foregroundStyle(.secondary)
                } else {
                    Text(toy.lastMeasurement).font(.headline.monospaced())
                }
            }
            Section("Tipp") {
                Text("Ziehe ein Rechteck über den Bereich, den du vermessen willst. Breite und Höhe erscheinen live und werden beim Loslassen kopiert.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
