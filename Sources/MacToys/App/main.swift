//
//  main.swift
//  MacToys — Mehr Power für deinen Mac.
//
//  Einstiegspunkt via @main (mit -parse-as-library keine Top-Level-Ausdrücke).
//  NSApplication wird manuell konfiguriert: Menüleisten-App (.accessory),
//  Dashboard als Fenster, globale Hotkeys.
//

import AppKit

@main
struct MacToysMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)   // kein Dock-Icon, nur Menüleiste
        app.run()
    }
}
