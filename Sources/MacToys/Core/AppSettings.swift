//
//  AppSettings.swift
//  MacToys
//
//  Globale, persistente App-Einstellungen (UserDefaults-backed).
//  Appearance, Launch-at-Login, Dashboard-Verhalten.
//

import AppKit
import Combine
import Foundation
#if canImport(ServiceManagement)
import ServiceManagement
#endif

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Hell"
        case .dark:   return "Dunkel"
        }
    }
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light:  return NSAppearance(named: .aqua)
        case .dark:   return NSAppearance(named: .darkAqua)
        }
    }
}

final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let appearance      = "mactoys.appearance"
        static let launchAtLogin   = "mactoys.launchAtLogin"
        static let showDashboardAtLaunch = "mactoys.showDashboardAtLaunch"
    }

    // MARK: - Published

    @Published var appearance: Appearance {
        didSet {
            defaults.set(appearance.rawValue, forKey: Key.appearance)
            applyAppearance()
        }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Key.launchAtLogin)
            applyLaunchAtLogin()
        }
    }
    @Published var showDashboardAtLaunch: Bool {
        didSet { defaults.set(showDashboardAtLaunch, forKey: Key.showDashboardAtLaunch) }
    }

    // MARK: - Init

    private init() {
        let appRaw = defaults.string(forKey: Key.appearance).flatMap(Appearance.init(rawValue:)) ?? .system
        appearance = appRaw
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        showDashboardAtLaunch = defaults.object(forKey: Key.showDashboardAtLaunch) as? Bool ?? true

        applyAppearance()
    }

    // MARK: - Appearance

    func applyAppearance() {
        NSApp.appearance = appearance.nsAppearance
    }

    // MARK: - Launch at Login

    private func applyLaunchAtLogin() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                return
            } catch {
                MacToysLog.warning("SMAppService fehlgeschlagen, Legacy-Pfad: \(error)", category: "settings")
            }
        }
        setLoginItemLegacy(enable: launchAtLogin, bundlePath: Bundle.main.bundlePath)
    }

    private func setLoginItemLegacy(enable: Bool, bundlePath: String) {
        let verb = enable ? "add" : "delete"
        let script = """
        tell application "System Events"
            if not (exists login item whose path is "\(bundlePath)") and "\(verb)" is "add" then
                make login item at end with properties {path:"\(bundlePath)", hidden:false}
            else if (exists login item whose path is "\(bundlePath)") and "\(verb)" is "delete" then
                delete (login item whose path is "\(bundlePath)")
            end if
        end tell
        """
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}
