//
//  KeyboardToolsToy.swift
//  MacToys — Keyboard Tools
//
//  Referenz der aktuell von MacToys belegten Hotkeys aller aktiven Toys
//  plus ein Tasten-Inspektor, der den letzten Tastendruck anzeigt
//  (KeyCode + Modifier + lesbares Symbol).
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

final class KeyboardToolsToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "keyboard-tools",
        name: "Keyboard Tools",
        tagline: "Hotkey-Übersicht aller Werkzeuge und Tasten-Inspektor.",
        symbol: "keyboard",
        accent: "#64D2FF",
        category: .developer
    )

    @Published private(set) var isRunning = false
    @Published var lastKey: KeyInfo?

    private var monitor: Any?

    func start() {
        isRunning = true
        installMonitor()
    }

    func stop() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
        isRunning = false
    }

    // MARK: - Tasten-Monitor (global, nur wenn App frontmost — sonst nicht erlaubt ohne Input Monitoring)

    private func installMonitor() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.lastKey = KeyInfo(event: event)
            return event
        }
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(KeyboardToolsView(toy: self)) }
}

struct KeyInfo: Hashable {
    let keyCode: UInt16
    let modifiers: UInt32
    let characters: String
    let label: String
    init(event: NSEvent) {
        keyCode = event.keyCode
        modifiers = UInt32(event.modifierFlags.rawValue)
        characters = event.characters ?? ""
        label = KeyInfo.label(keyCode: keyCode, modifiers: modifiers, chars: characters)
    }
    static func label(keyCode: UInt16, modifiers: UInt32, chars: String) -> String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("⌘") }
        parts.append(chars.isEmpty ? "KeyCode \(keyCode)" : chars)
        return parts.joined()
    }
}

struct KeyboardToolsView: View {
    @ObservedObject var toy: KeyboardToolsToy
    @EnvironmentObject private var registry: ToyRegistry

    var body: some View {
        Form {
            Section("Tasten-Inspektor") {
                if let k = toy.lastKey {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Zeichen: \(k.characters)").font(.callout.monospaced())
                            Text("KeyCode: \(k.keyCode)").font(.caption).foregroundStyle(.secondary)
                            Text("Modifier: 0x\(String(k.modifiers, radix: 16))").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(k.label).font(.title2.monospaced())
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.quaternary, in: Capsule())
                    }
                } else {
                    Text("Taste drücken (Fokus auf MacToys)…").foregroundStyle(.secondary)
                }
            }
            Section("Hotkey-Übersicht (aktive Toys)") {
                let allHotkeys = collectHotkeys()
                if allHotkeys.isEmpty {
                    Text("Keine aktiven Toys mit Hotkeys.").foregroundStyle(.secondary)
                } else {
                    ForEach(allHotkeys, id: \.id) { entry in
                        HStack {
                            Image(systemName: entry.symbol).foregroundStyle(.tertiary).frame(width: 20)
                            Text(entry.toyName).foregroundStyle(.primary)
                            Spacer()
                            Text(entry.action).foregroundStyle(.secondary).font(.caption)
                            Text(entry.hotkey).font(.callout.monospaced())
                                .padding(.horizontal, 8).padding(.vertical, 2)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                }
            }
            Section("Hinweis") {
                Text("Der Tasten-Inspektor funktioniert nur, während ein MacToys-Fenster den Fokus hat. Die Hotkey-Übersicht listet alle von MacToys belegten Tastenkombinationen.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private struct HotkeyEntry: Identifiable {
        let id = UUID()
        let toyName: String
        let symbol: String
        let action: String
        let hotkey: String
    }

    private func collectHotkeys() -> [HotkeyEntry] {
        // Statisch aus den bekannten Settings extrahieren — zentrale Wahrheit ist
        // pro Toy. Wir greifen auf die bekannten Settings-Singletons zurück.
        var entries: [HotkeyEntry] = []
        entries.append(HotkeyEntry(toyName: "Window Manager", symbol: "rectangle.3.group",
                                   action: "Halblinks", hotkey: WindowManagerSettings.shared.hotkeys[.leftHalf]?.label ?? "—"))
        entries.append(HotkeyEntry(toyName: "Window Manager", symbol: "rectangle.3.group",
                                   action: "Maximieren", hotkey: WindowManagerSettings.shared.hotkeys[.maximize]?.label ?? "—"))
        entries.append(HotkeyEntry(toyName: "Always on Top", symbol: "pin.fill",
                                   action: "Pinnen", hotkey: AlwaysOnTopSettings.shared.hotkey.label))
        entries.append(HotkeyEntry(toyName: "Color Picker", symbol: "eyedropper",
                                   action: "Abtasten", hotkey: ColorPickerSettings.shared.hotkey.label))
        entries.append(HotkeyEntry(toyName: "Text Extractor", symbol: "doc.text.viewfinder",
                                   action: "OCR", hotkey: TextExtractorSettings.shared.hotkey.label))
        entries.append(HotkeyEntry(toyName: "Quick Launcher", symbol: "command",
                                   action: "Palette", hotkey: QuickLauncherSettings.shared.hotkey.label))
        entries.append(HotkeyEntry(toyName: "Screen Ruler", symbol: "ruler",
                                   action: "Messen", hotkey: ScreenRulerSettings.shared.hotkey.label))
        return entries
    }
}
