//
//  LayoutEngine.swift
//  MacToys — Window Manager
//
//  Definiert Snap-Layouts (Halblinks/-rechts, Viertel, Maximize, Center) und
//  berechnet Ziel-Frames innerhalb des visibleFrame eines Screens.
//

import Foundation
import CoreGraphics

/// Eine Layout-Vorlage für das fokussierte Fenster.
enum WindowLayout: String, CaseIterable, Identifiable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize, center, restore

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .leftHalf:    return "rectangle.lefthalf.filled"
        case .rightHalf:   return "rectangle.righthalf.filled"
        case .topHalf:     return "rectangle.tophalf.filled"
        case .bottomHalf:  return "rectangle.bottomhalf.filled"
        case .topLeft:     return "rectangle.split.3x1.slash"
        case .topRight:    return "rectangle.split.3x1.backslash"
        case .bottomLeft:  return "rectangle.split.3x1.backslash"
        case .bottomRight: return "rectangle.split.3x1.slash"
        case .maximize:    return "rectangle.expand.vertical"
        case .center:      return "rectangle.center.inset.filled"
        case .restore:     return "arrow.uturn.backward.circle"
        }
    }
    var label: String {
        switch self {
        case .leftHalf:    return "Halblinks"
        case .rightHalf:   return "Halbrechts"
        case .topHalf:     return "Halboben"
        case .bottomHalf:  return "Halbunten"
        case .topLeft:     return "Oben links"
        case .topRight:    return "Oben rechts"
        case .bottomLeft:  return "Unten links"
        case .bottomRight: return "Unten rechts"
        case .maximize:    return "Maximieren"
        case .center:      return "Zentrieren"
        case .restore:     return "Wiederherstellen"
        }
    }
}

/// Merkt sich den letzten Frame vor einem Layout-Wechsel (für "restore").
final class LayoutMemory {
    private var lastFrames: [CGWindowID: CGRect] = [:]

    func remember(_ window: ManagedWindow) {
        lastFrames[window.id] = window.frame
    }
    func recall(_ window: ManagedWindow) -> CGRect? {
        lastFrames[window.id]
    }
}

struct LayoutEngine {

    let gap: CGFloat   // kleiner Abstand zwischen Fenster und Bildschirmrand

    init(gap: CGFloat = 0) { self.gap = gap }

    /// Berechnet den Ziel-Frame für ein Layout innerhalb von `screen`.
    func frame(for layout: WindowLayout, in screen: CGRect) -> CGRect {
        let g = gap
        let x = screen.minX + g
        let y = screen.minY + g
        let w = screen.width - 2 * g
        let h = screen.height - 2 * g
        let hw = w / 2
        let hh = h / 2

        switch layout {
        case .leftHalf:    return CGRect(x: x, y: y, width: hw, height: h)
        case .rightHalf:   return CGRect(x: x + hw, y: y, width: hw, height: h)
        case .topHalf:     return CGRect(x: x, y: y + hh, width: w, height: hh)
        case .bottomHalf:  return CGRect(x: x, y: y, width: w, height: hh)
        case .topLeft:     return CGRect(x: x, y: y + hh, width: hw, height: hh)
        case .topRight:    return CGRect(x: x + hw, y: y + hh, width: hw, height: hh)
        case .bottomLeft:  return CGRect(x: x, y: y, width: hw, height: hh)
        case .bottomRight: return CGRect(x: x + hw, y: y, width: hw, height: hh)
        case .maximize:    return CGRect(x: x, y: y, width: w, height: h)
        case .center, .restore:
            // center wird im WindowManagerToy mit Originalgröße berechnet.
            return CGRect(x: screen.midX - 400, y: screen.midY - 300, width: 800, height: 600)
        }
    }
}
