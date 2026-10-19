//
//  AppDelegate.swift
//  MacToys
//
//  Lebenszyklus der App: Menüleisten-Item (NSStatusItem), Dashboard-Fenster,
//  Start der aktivierten Toys, globale Hotkeys.
//

import AppKit
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var dashboardController: NSWindowController?

    private let registry = ToyRegistry.shared
    private let settings = AppSettings.shared
    private var bag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()

        // Aktiviert markierte Toys live starten.
        registry.startEnabled()

        // Öffnen-Anfragen aus Toys (Standard-execute) empfangen.
        AppEvents.shared.openSettingsRequests
            .receive(on: RunLoop.main)
            .sink { [weak self] id in self?.showToySettings(id: id) }
            .store(in: &bag)

        // Dashboard beim ersten Start einmal zeigen, damit der Nutzer es findet.
        if settings.showDashboardAtLaunch {
            showDashboard()
        }

        MacToysLog.info("MacToys gestartet. \(registry.toys.count) Werkzeuge registriert.", category: "app")
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregisterAll()
        registry.stopAll()
    }

    // MARK: - Menüleisten-Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(
                systemSymbolName: "hammer.fill",
                accessibilityDescription: "MacToys"
            )
            button.image?.isTemplate = true
        }

        rebuildMenu()
        // Menü aktualisieren, wenn sich Toy-Status ändert.
        registry.$enabled
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &bag)
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        menu.addItem(withTitle: "MacToys Dashboard", action: #selector(showDashboard), keyEquivalent: "")
        menu.addItem(.separator())

        // Schnellzugriff auf jedes Toy — Klick führt die Hauptaktion aus.
        let header = NSMenuItem(title: "Werkzeuge (Klick = ausführen)", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        for toy in registry.toys {
            let id = toy.descriptor.id
            let on = registry.enabled[id] ?? false
            let item = NSMenuItem(title: "\(toy.descriptor.name)",
                                  action: #selector(executeToy(_:)),
                                  keyEquivalent: "")
            item.representedObject = id
            item.state = on ? .on : .off
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())

        // An/Aus-Übersicht: jedes Toy per Häkchen schalten.
        let toggleHeader = NSMenuItem(title: "Aktivieren / Deaktivieren", action: nil, keyEquivalent: "")
        toggleHeader.isEnabled = false
        menu.addItem(toggleHeader)
        for toy in registry.toys {
            let id = toy.descriptor.id
            let on = registry.enabled[id] ?? false
            let item = NSMenuItem(title: "\(toy.descriptor.name)",
                                  action: #selector(toggleToy(_:)),
                                  keyEquivalent: "")
            item.representedObject = id
            item.state = on ? .on : .off
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(withTitle: "Einstellungen …", action: #selector(showSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Über MacToys", action: #selector(showAbout), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "MacToys beenden", action: #selector(quitApp), keyEquivalent: "q")
        menu.items.forEach { if $0.action == nil { $0.target = self } }
        statusItem.menu = menu
    }

    @objc private func toggleToy(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        registry.toggle(id)
    }

    /// Klick auf ein Werkzeug im Menü: führt dessen Hauptaktion aus.
    @objc private func executeToy(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let toy = registry.toy(id: id) else { return }
        Task { @MainActor in toy.execute() }
    }

    // MARK: - Dashboard / Fenster

    @objc func showDashboard() {
        if dashboardController == nil {
            let view = DashboardView()
                .environmentObject(registry)
                .environmentObject(settings)
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = "MacToys"
            window.titlebarAppearsTransparent = true
            window.styleMask = [.titled, .closable, .miniaturizable, .fullSizeContentView]
            window.setFrameAutosaveName("mactoys.dashboard")
            window.center()
            dashboardController = NSWindowController(window: window)
        }
        dashboardController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func showSettings() {
        let view = SettingsView()
            .environmentObject(registry)
            .environmentObject(settings)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "MacToys — Einstellungen"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setFrameAutosaveName("mactoys.settings")
        window.setContentSize(NSSize(width: 720, height: 520))
        window.center()
        NSWindowController(window: window).showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "MacToys",
            .applicationVersion: "0.1",
            .credits: "More power to your Mac.\nFree forever. Open source by design."
        ])
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Werkzeug-Einstellungen (für Standard-execute)

    /// Öffnet das Einstellungs-Fenster eines einzelnen Werkzeugs (für UI-Toys,
    /// deren Hauptaktion das Fenster selbst ist, z. B. Power Rename).
    @MainActor private func showToySettings(id: String) {
        guard let toy = registry.toy(id: id) else { return }
        let view = ToySettingsSheet(toy: toy)
            .environmentObject(registry)
            .environmentObject(settings)
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "\(toy.descriptor.name) — MacToys"
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.setFrameAutosaveName("mactoys.toy.\(id)")
        window.setContentSize(NSSize(width: 620, height: 520))
        window.center()
        NSWindowController(window: window).showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
