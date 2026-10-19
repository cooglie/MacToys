//
//  Permissions.swift
//  MacToys
//
//  Zentrale Hilfsfunktionen für Systemberechtigungen.
//  Aktuell: Bedienhilfen (Accessibility) für Fenster-Steuerung.
//

import AppKit
import ApplicationServices

enum Permissions {

    /// Hat die App Accessibility-Vertrauen (für Fenster-Steuerung nötig)?
    static func hasAccessibility() -> Bool {
        AXIsProcessTrusted()
    }

    /// Löst den System-Prompt aus (oder öffnet die Einstellungen, falls schon verweigert).
    static func requestAccessibility() {
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    /// Öffnet direkt den Bedienhilfen-Pane in den Systemeinstellungen (macOS 13+).
    static func openAccessibilitySettings() {
        if #available(macOS 13.0, *) {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
    }

    /// Warnt den Nutzer per Alert, wenn eine Berechtigung fehlt.
    static func showAccessibilityAlert() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Bedienhilfen-Berechtigung benötigt"
        alert.informativeText = "MacToys benötigt Zugriff auf Bedienhilfen, um Fenster zu steuern.\n" +
                                "Bitte aktiviere MacToys unter Systemeinstellungen → Datenschutz & Sicherheit → Bedienhilfen."
        alert.addButton(withTitle: "Systemeinstellungen öffnen")
        alert.addButton(withTitle: "Später")
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}
