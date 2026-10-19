//
//  AppEvents.swift
//  MacToys
//
//  Zentraler Event-Bus für App-interne Signale (z. B. "Einstellungen für Toy X
//  öffnen"). Brückt zwischen ToyRegistry (Modell) und AppDelegate (Fenster).
//

import Combine
import Foundation

final class AppEvents {
    static let shared = AppEvents()

    /// ID des Toys, dessen Einstellungs-Fenster geöffnet werden soll.
    let openSettingsRequests = PassthroughSubject<String, Never>()

    private init() {}
}
