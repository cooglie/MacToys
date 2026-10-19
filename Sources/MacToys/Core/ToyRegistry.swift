//
//  ToyRegistry.swift
//  MacToys
//
//  Zentrale Registry aller Werkzeuge. Jedes Toy registriert sich hier beim Start.
//  Das Dashboard und das Menüleisten-Menü beziehen aus der Registry.
//

import Foundation
import Combine
import SwiftUI

final class ToyRegistry: ObservableObject {

    static let shared = ToyRegistry()

    /// Alle registrierten Werkzeuge (unabhängig vom Aktivierungsstatus).
    @Published private(set) var toys: [any Toy] = []

    /// Aktivierungsstatus pro Toy-ID (persistent).
    @Published var enabled: [String: Bool] = [:] {
        didSet { persist() }
    }

    private let defaults = UserDefaults.standard
    private let enabledKey = "mactoys.enabledToys"

    private init() {
        load()
        bootstrap()
    }

    // MARK: - Bootstrap

    /// Hier werden alle Werkzeuge instanziiert und registriert.
    /// Neues Toy hinzufügen = eine Zeile hier.
    private func bootstrap() {
        // System
        register(WindowManagerToy())
        register(AlwaysOnTopToy())
        register(AwakeToy())
        // Workflow
        register(QuickLauncherToy())
        register(TextExtractorToy())
        register(ScreenRulerToy())
        register(WorkspacesToy())
        // Dateien
        register(PowerRenameToy())
        register(ImageResizerToy())
        register(QuickPreviewToy())
        register(DesktopSearchToy())
        // Medien
        register(ColorPickerToy())
        // Entwicklung
        register(KeyboardToolsToy())
    }

    func register(_ toy: some Toy) {
        toys.append(toy)
    }

    // MARK: - Aktivierung

    /// Schaltet ein Toy an/aus. Startet/stopt es live und persistiert den Status.
    func toggle(_ id: String) {
        let newState = !(enabled[id] ?? false)
        enabled[id] = newState
        apply(id: id, running: newState)
    }

    func setEnabled(_ id: String, _ on: Bool) {
        enabled[id] = on
        apply(id: id, running: on)
    }

    private func apply(id: String, running: Bool) {
        guard let toy = toy(id: id) else { return }
        if running {
            toy.start()
            MacToysLog.info("Toy aktiviert: \(id)", category: "registry")
        } else {
            toy.stop()
            MacToysLog.info("Toy deaktiviert: \(id)", category: "registry")
        }
    }

    func toy(id: String) -> (any Toy)? {
        toys.first { $0.descriptor.id == id }
    }

    /// Startet alle als aktiv markierten Toys (beim App-Start).
    func startEnabled() {
        for toy in toys where enabled[toy.descriptor.id] ?? false {
            toy.start()
        }
    }

    /// Stoppt alle laufenden Toys (beim App-Ende).
    func stopAll() {
        for toy in toys where (enabled[toy.descriptor.id] ?? false) {
            toy.stop()
        }
    }

    // MARK: - Persistenz

    private func persist() {
        defaults.set(enabled, forKey: enabledKey)
    }

    private func load() {
        if let dict = defaults.dictionary(forKey: enabledKey) as? [String: Bool] {
            enabled = dict
        }
    }
}
