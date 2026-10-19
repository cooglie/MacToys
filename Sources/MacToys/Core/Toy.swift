//
//  Toy.swift
//  MacToys
//
//  Das zentrale Protokoll, das jedes Werkzeug (Toy) implementiert.
//  Modular: ein Toy registriert sich selbst, kann aktiviert/deaktiviert werden,
//  hat einen eigenen Hotkey und eine eigene Settings-View.
//

import Foundation
import SwiftUI

/// Metadaten eines Werkzeugs (für Dashboard-Karten & Registry).
struct ToyDescriptor: Identifiable, Hashable {
    let id: String
    let name: String
    let tagline: String
    let symbol: String          // SF Symbol Name
    let accent: String          // Hex-Farbe für Akzent
    let category: ToyCategory
}

enum ToyCategory: String, CaseIterable, Identifiable, Hashable {
    case system = "System"
    case files = "Dateien"
    case workflow = "Workflow"
    case developer = "Entwicklung"
    case media = "Medien"
    var id: String { rawValue }
}

/// Zustand eines Werkzeugs (aktiviert = läuft aktuell).
enum ToyStatus: Equatable {
    case off
    case on
    case needsPermission(String)   // z. B. "Accessibility"
}

/// Jedes Werkzeug implementiert dieses Protokoll.
/// Instanzen sind typischerweise ObservableObject und werden vom AppDelegate gehalten.
protocol Toy: AnyObject {
    var descriptor: ToyDescriptor { get }

    /// Aktuell laufend? Wird vom Dashboard beobachtet.
    var isRunning: Bool { get }

    /// Liefert den Status (für Badge/Prompt). Standardmäßig on/off.
    var status: ToyStatus { get }

    /// Startet das Werkzeug. Wird beim Aktivieren über das Dashboard aufgerufen.
    func start()

    /// Stoppt das Werkzeug. Wird beim Deaktivieren oder App-Ende aufgerufen.
    func stop()

    /// SwiftUI-View für die Eigenen Einstellungen dieses Werkzeugs.
    @MainActor func settingsView() -> AnyView
}

extension Toy {
    var status: ToyStatus { isRunning ? .on : .off }
    var isRunning: Bool { false }
    @MainActor func settingsView() -> AnyView {
        AnyView(EmptyView())
    }
}
