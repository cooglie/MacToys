//
//  WindowManagerToy.swift
//  MacToys — Window Manager
//
//  Das Werkzeug selbst: implementiert `Toy`, hält WindowService + LayoutEngine,
//  registriert globale Hotkeys pro Layout, wendet Layouts animiert auf das
//  fokussierte Fenster an.
//

import AppKit
import Combine
import SwiftUI

final class WindowManagerToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "window-manager",
        name: "Window Manager",
        tagline: "Fenster in Layouts einschnappen — Halblinks/-rechts, Viertel, Maximize, Zentrieren.",
        symbol: "rectangle.3.group",
        accent: "#0A84FF",
        category: .system
    )

    @Published private(set) var isRunning = false
    @Published private(set) var needsPermission = false

    private let windowService = WindowManagerWindowService()
    private let memory = LayoutMemory()
    private let settings = WindowManagerSettings.shared
    private var registeredHotkeys: [UInt32] = []
    private var animationTimer: Timer?

    var status: ToyStatus {
        if needsPermission { return .needsPermission("Bedienhilfen") }
        return isRunning ? .on : .off
    }

    // MARK: - Toy Lifecycle

    func start() {
        guard windowService.hasAccessibility() else {
            needsPermission = true
            windowService.requestAccessibility()
            MacToysLog.warning("Accessibility fehlt — Window Manager startet ohne Funktion.", category: "wm")
            return
        }
        needsPermission = false
        isRunning = true
        registerHotkeys()
        MacToysLog.info("Window Manager gestartet.", category: "wm")
    }

    func stop() {
        isRunning = false
        registeredHotkeys.forEach { HotkeyManager.shared.unregister($0) }
        registeredHotkeys.removeAll()
        animationTimer?.invalidate()
        MacToysLog.info("Window Manager gestoppt.", category: "wm")
    }

    // MARK: - Hotkeys

    private func registerHotkeys() {
        registeredHotkeys.forEach { HotkeyManager.shared.unregister($0) }
        registeredHotkeys.removeAll()

        for (layout, cfg) in settings.hotkeys {
            let id = HotkeyManager.shared.register(cfg) { [weak self] in
                self?.apply(layout)
            }
            if let id { registeredHotkeys.append(id) }
        }
    }

    // MARK: - Layout anwenden

    /// Wendet ein Layout auf das fokussierte Fenster an.
    func apply(_ layout: WindowLayout) {
        guard isRunning else { return }
        guard windowService.hasAccessibility() else {
            needsPermission = true
            Permissions.showAccessibilityAlert()
            return
        }

        guard let window = windowService.focusedWindow() else {
            MacToysLog.info("Kein fokussiertes Fenster gefunden.", category: "wm")
            return
        }

        let screen = windowService.visibleFrame(of: windowService.activeScreen())
        let engine = LayoutEngine(gap: settings.gap)

        // Restore: gemerkten Frame zurückholen.
        if layout == .restore {
            if let original = memory.recall(window) {
                windowService.setFrame(original, for: window)
            }
            return
        }

        // Vorherigen Frame merken (für Restore).
        memory.remember(window)

        // Center: aktuelle Größe behalten, nur positionieren.
        if layout == .center {
            let f = window.frame
            let target = CGRect(
                x: screen.midX - f.width / 2,
                y: screen.midY - f.height / 2,
                width: f.width,
                height: f.height
            )
            windowService.setFrame(target, for: window)
            return
        }

        let target = engine.frame(for: layout, in: screen)
        if settings.animate {
            animate(window: window, to: target)
        } else {
            windowService.setFrame(target, for: window)
        }
        windowService.raise(window)
    }

    /// Sanfte Animation des Fensters (~0.18s, Smoothstep).
    private func animate(window: ManagedWindow, to target: CGRect) {
        animationTimer?.invalidate()
        let from = window.frame
        let duration: TimeInterval = 0.18
        let steps = 12
        var step = 0

        animationTimer = Timer(timeInterval: duration / TimeInterval(steps), repeats: true) { [weak self] timer in
            guard let self else { timer.invalidate(); return }
            step += 1
            let t = self.smoothstep(CGFloat(step) / CGFloat(steps))
            let f = CGRect(
                x: from.minX + (target.minX - from.minX) * t,
                y: from.minY + (target.minY - from.minY) * t,
                width: from.width + (target.width - from.width) * t,
                height: from.height + (target.height - from.height) * t
            )
            self.windowService.setFrame(f, for: window)
            if step >= steps { timer.invalidate() }
        }
        RunLoop.main.add(animationTimer!, forMode: .common)
    }

    private func smoothstep(_ t: CGFloat) -> CGFloat { t * t * (3 - 2 * t) }

    // MARK: - Settings View

    @MainActor
    func settingsView() -> AnyView {
        AnyView(WindowManagerSettingsView(toy: self))
    }
}
