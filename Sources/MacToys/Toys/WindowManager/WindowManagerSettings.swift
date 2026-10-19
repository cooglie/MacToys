//
//  WindowManagerSettings.swift
//  MacToys — Window Manager
//
//  Persistente Konfiguration des Window Managers: Hotkeys pro Layout, Gap,
//  Animiertes Layouten.
//

import AppKit
import Carbon.HIToolbox
import Combine
import Foundation

final class WindowManagerSettings: ObservableObject {

    static let shared = WindowManagerSettings()

    private let defaults = UserDefaults.standard
    private let key = "mactoys.windowmanager.config"

    @Published var hotkeys: [WindowLayout: HotkeyConfig] {
        didSet { save() }
    }
    @Published var gap: CGFloat {
        didSet { save() }
    }
    @Published var animate: Bool {
        didSet { save() }
    }

    /// Standard-Hotkeys (⌃⌥ + Richtung). Keine Konflikte mit macOS.
    private static func defaults_() -> [WindowLayout: HotkeyConfig] {
        let ctrl = UInt32(controlKey)
        let opt  = UInt32(optionKey)
        let m = ctrl | opt
        return [
            .leftHalf:    HotkeyConfig(keyCode: UInt32(kVK_LeftArrow),  modifiers: m, label: "⌃⌥←"),
            .rightHalf:   HotkeyConfig(keyCode: UInt32(kVK_RightArrow), modifiers: m, label: "⌃⌥→"),
            .topHalf:     HotkeyConfig(keyCode: UInt32(kVK_UpArrow),    modifiers: m, label: "⌃⌥↑"),
            .bottomHalf:  HotkeyConfig(keyCode: UInt32(kVK_DownArrow),  modifiers: m, label: "⌃⌥↓"),
            .topLeft:     HotkeyConfig(keyCode: UInt32(kVK_ANSI_U),     modifiers: m, label: "⌃⌥U"),
            .topRight:    HotkeyConfig(keyCode: UInt32(kVK_ANSI_I),     modifiers: m, label: "⌃⌥I"),
            .bottomLeft:  HotkeyConfig(keyCode: UInt32(kVK_ANSI_J),     modifiers: m, label: "⌃⌥J"),
            .bottomRight: HotkeyConfig(keyCode: UInt32(kVK_ANSI_K),     modifiers: m, label: "⌃⌥K"),
            .maximize:    HotkeyConfig(keyCode: UInt32(kVK_Return),     modifiers: m, label: "⌃⌥↩"),
            .center:      HotkeyConfig(keyCode: UInt32(kVK_ANSI_C),     modifiers: m, label: "⌃⌥C"),
            .restore:     HotkeyConfig(keyCode: UInt32(kVK_ANSI_Z),     modifiers: m, label: "⌃⌥Z"),
        ]
    }

    private init() {
        let d = WindowManagerSettings.defaults_()
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(Config.self, from: data) {
            // Gespeicherte Keys sind String → zurück nach WindowLayout mappen,
            // unbekannte Keys fallen raus; fehlende aus Defaults auffüllen.
            var restored: [WindowLayout: HotkeyConfig] = [:]
            for (k, v) in decoded.hotkeys {
                if let layout = WindowLayout(rawValue: k) { restored[layout] = v }
            }
            hotkeys = d.merging(restored) { _, b in b }
            gap = decoded.gap
            animate = decoded.animate
        } else {
            hotkeys = d
            gap = 8
            animate = true
        }
    }

    // MARK: - Persistenz

    private struct Config: Codable {
        let hotkeys: [String: HotkeyConfig]
        let gap: CGFloat
        let animate: Bool
    }

    private func save() {
        let mapped = Dictionary(uniqueKeysWithValues: hotkeys.map { ($0.key.rawValue, $0.value) })
        let cfg = Config(hotkeys: mapped, gap: gap, animate: animate)
        if let data = try? JSONEncoder().encode(cfg) {
            defaults.set(data, forKey: key)
        }
    }
}
