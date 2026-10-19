//
//  WindowManagerWindowService.swift
//  MacToys — Window Manager
//
//  Enumeriert und steuert echte Fenster via Accessibility-API (AXUIElement).
//  Benötigt Accessibility-Berechtigung (Bedienhilfen).
//

import AppKit
import ApplicationServices

/// Ein erfasstes Fenster mit AX-Referenz und aktuellem Frame.
struct ManagedWindow {
    let id: CGWindowID
    let pid: pid_t
    let ref: AXUIElement
    let appRef: AXUIElement
    let title: String
    let ownerName: String
    var frame: CGRect
}

final class WindowManagerWindowService {

    private let myPID = ProcessInfo.processInfo.processIdentifier

    // MARK: - Bildschirm

    /// Aktiver Screen (mit Maus) — dort wird standardmäßig layoutet.
    func activeScreen() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main ?? NSScreen.screens.first!
    }

    /// visibleFrame eines Screens (ohne Dock/Menüleiste).
    func visibleFrame(of screen: NSScreen) -> CGRect {
        screen.visibleFrame
    }

    // MARK: - Fenster-Enumeration

    /// Liefert das fokussierte (vorderste) Fenster.
    func focusedWindow() -> ManagedWindow? {
        allVisibleWindows().first
    }

    /// Enumeriert alle sichtbaren, normalen Fenster aller Apps (außer MacToys).
    func allVisibleWindows() -> [ManagedWindow] {
        guard let info = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] else { return [] }

        var result: [ManagedWindow] = []
        for entry in info {
            guard let layer = entry[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = entry[kCGWindowOwnerPID as String] as? Int32, pid != myPID else { continue }
            guard let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat],
                  let wid = entry[kCGWindowNumber as String] as? CGWindowID else { continue }

            let bounds = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: boundsDict["Width"] ?? 0,
                height: boundsDict["Height"] ?? 0
            )
            if bounds.width < 50 || bounds.height < 50 { continue }

            let app = AXUIElementCreateApplication(pid)
            guard let winRef = axWindow(app, wid: wid, fallbackBounds: bounds) else { continue }

            let title = (entry[kCGWindowName as String] as? String) ?? ""
            let owner = (entry[kCGWindowOwnerName as String] as? String) ?? ""
            result.append(ManagedWindow(id: wid, pid: pid, ref: winRef, appRef: app,
                                        title: title, ownerName: owner, frame: bounds))
        }
        return result
    }

    /// Findet das AX-Fenster zur CGWindowID. Fallback: Position-Matching.
    private func axWindow(_ app: AXUIElement, wid: CGWindowID, fallbackBounds: CGRect) -> AXUIElement? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &ref) == .success,
              let windows = ref as? [AXUIElement] else { return nil }

        // 1) Direkt über _AXWindowID (private, aber zuverlässig verfügbar).
        for win in windows {
            var idVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(win, "_AXWindowID" as CFString, &idVal) == .success,
               let idNum = idVal as? NSNumber {
                if idNum.uint32Value == wid { return win }
            }
        }
        // 2) Fallback: erstes Fenster mit passender Position.
        for win in windows {
            var posVal: CFTypeRef?
            if AXUIElementCopyAttributeValue(win, kAXPositionAttribute as CFString, &posVal) == .success,
               let pos = posVal {
                var p = CGPoint.zero
                if AXValueGetValue(pos as! AXValue, .cgPoint, &p),
                   abs(p.x - fallbackBounds.origin.x) < 5,
                   abs(p.y - fallbackBounds.origin.y) < 5 {
                    return win
                }
            }
        }
        // 3) Letzter Strohhalm: erstes Fenster der App.
        return windows.first
    }

    // MARK: - Fenster steuern

    /// Setzt Position & Größe eines Fensters hart (nicht animiert).
    func setFrame(_ frame: CGRect, for window: ManagedWindow) {
        var origin = frame.origin
        if let pos = withUnsafePointer(to: &origin, { AXValueCreate(.cgPoint, $0) }) {
            AXUIElementSetAttributeValue(window.ref, kAXPositionAttribute as CFString, pos)
        }
        var size = frame.size
        if let sz = withUnsafePointer(to: &size, { AXValueCreate(.cgSize, $0) }) {
            AXUIElementSetAttributeValue(window.ref, kAXSizeAttribute as CFString, sz)
        }
    }

    /// Hebt ein Fenster nach vorne (Raise + App aktivieren).
    func raise(_ window: ManagedWindow) {
        AXUIElementSetAttributeValue(window.ref, kAXMainAttribute as CFString, kCFBooleanTrue)
        AXUIElementSetAttributeValue(window.appRef, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
    }

    // MARK: - Berechtigung

    func hasAccessibility() -> Bool { AXIsProcessTrusted() }

    func requestAccessibility() {
        let opts: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        _ = AXIsProcessTrustedWithOptions(opts)
    }
}
