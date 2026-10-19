//
//  AlwaysOnTopToy.swift
//  MacToys — Always on Top
//
//  Hält ausgewählte Fenster über anderen, indem sie regelmäßig nach vorne
//  gehoben werden (AX Raise + App frontmost). Cross-App-Pinning via WindowLevel
//  ist über AX nicht zuverlässig setzbar, daher Polling-Ansatz.
//

import AppKit
import ApplicationServices
import Carbon.HIToolbox
import SwiftUI

final class AlwaysOnTopToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "always-on-top",
        name: "Always on Top",
        tagline: "Hält das fokussierte Fenster über allen anderen.",
        symbol: "pin.fill",
        accent: "#BF5AF2",
        category: .system
    )

    @Published private(set) var isRunning = false
    @Published private(set) var needsPermission = false
    @Published private(set) var pinnedCount = 0

    private var hotkeyID: UInt32?
    private let settings = AlwaysOnTopSettings.shared
    private var raiseTimer: Timer?
    private var pinnedIDs: Set<CGWindowID> = []

    var status: ToyStatus {
        if needsPermission { return .needsPermission("Bedienhilfen") }
        return isRunning ? .on : .off
    }

    // MARK: - Toy Lifecycle

    func start() {
        guard Permissions.hasAccessibility() else {
            needsPermission = true
            Permissions.requestAccessibility()
            return
        }
        needsPermission = false
        isRunning = true
        hotkeyID = HotkeyManager.shared.register(settings.hotkey) { [weak self] in
            self?.togglePinned()
        }
        startRaiseTimer()
        MacToysLog.info("Always on Top gestartet.", category: "aot")
    }

    func stop() {
        if let hotkeyID { HotkeyManager.shared.unregister(hotkeyID) }
        hotkeyID = nil
        raiseTimer?.invalidate()
        raiseTimer = nil
        pinnedIDs.removeAll()
        pinnedCount = 0
        isRunning = false
        MacToysLog.info("Always on Top gestoppt.", category: "aot")
    }

    // MARK: - Pinnen

    /// Hauptaktion: aktiviert bei Bedarf und toggelt das fokussierte Fenster.
    @MainActor func execute() {
        if !isRunning { ToyRegistry.shared.setEnabled(descriptor.id, true) }
        togglePinned()
    }

    /// Toggelt den Pin-Status des fokussierten Fensters.
    func togglePinned() {
        guard isRunning else { return }
        guard let window = WindowManagerWindowService().focusedWindow() else { return }

        if pinnedIDs.contains(window.id) {
            pinnedIDs.remove(window.id)
            pinnedCount = max(0, pinnedCount - 1)
        } else {
            pinnedIDs.insert(window.id)
            pinnedCount += 1
            WindowManagerWindowService().raise(window)
        }
    }

    // MARK: - Raise-Polling

    private func startRaiseTimer() {
        raiseTimer?.invalidate()
        raiseTimer = Timer(timeInterval: 1.2, repeats: true) { [weak self] timer in
            guard let self, self.isRunning, !self.pinnedIDs.isEmpty else { return }
            let svc = WindowManagerWindowService()
            for window in svc.allVisibleWindows() where self.pinnedIDs.contains(window.id) {
                svc.raise(window)
            }
        }
        RunLoop.main.add(raiseTimer!, forMode: .common)
    }

    @MainActor
    func settingsView() -> AnyView {
        AnyView(AlwaysOnTopSettingsView(toy: self))
    }
}

final class AlwaysOnTopSettings: ObservableObject {
    static let shared = AlwaysOnTopSettings()
    @Published var hotkey: HotkeyConfig {
        didSet { save() }
    }
    private let key = "mactoys.alwaysontop.config"
    private init() {
        let ctrl = UInt32(controlKey)
        let opt = UInt32(optionKey)
        let m = ctrl | opt
        hotkey = HotkeyConfig(keyCode: UInt32(kVK_ANSI_T), modifiers: m, label: "⌃⌥T")
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(HotkeyConfig.self, from: data) {
            hotkey = decoded
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(hotkey) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct AlwaysOnTopSettingsView: View {
    @ObservedObject var toy: AlwaysOnTopToy
    @ObservedObject private var settings = AlwaysOnTopSettings.shared

    var body: some View {
        Form {
            Section("Berechtigung") {
                if toy.status == .needsPermission("Bedienhilfen") {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        Text("Bedienhilfen benötigt.")
                        Spacer()
                        Button("Öffnen") { Permissions.openAccessibilitySettings() }
                    }
                } else {
                    Label("Bedienhilfen aktiv", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            Section("Hotkey") {
                HStack {
                    Text("Fenster pinnen / lösen")
                    Spacer()
                    Text(settings.hotkey.label).font(.callout.monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
            }
            Section("Status") {
                Text("\(toy.pinnedCount) Fenster derzeit gepinnt")
                    .foregroundStyle(.secondary)
            }
            Section("Tipp") {
                Text("Fokussiere ein Fenster und drücke den Hotkey, um es über allen anderen zu halten. Erneut drücken, um es zu lösen.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
