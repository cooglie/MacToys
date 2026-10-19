//
//  RegionSelectionOverlay.swift
//  MacToys — Text Extractor / Screen Ruler
//
//  Ein borderless Overlay über dem gesamten Bildschirm, in dem der Nutzer
//  ein Rechteck aufzieht. Liefert das gewählte Rechteck (in Screen-Koordinaten)
//  zurück oder nil bei Abbruch (Esc).
//

import AppKit

final class RegionSelectionOverlay {

    private var result: CGRect?
    private var done = false

    /// Blockiert bis Auswahl getroffen oder abgebrochen.
    func runModal() -> CGRect? {
        guard let screen = NSScreen.main else { return nil }
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0, alpha: 0.001)
        window.ignoresMouseEvents = false
        window.hasShadow = false
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]

        let view = SelectionView(onComplete: { [weak self] rect in
            self?.result = rect
            self?.done = true
            window.close()
            NSApp.stopModal()
        }, onCancel: { [weak self] in
            self?.result = nil
            self?.done = true
            window.close()
            NSApp.stopModal()
        })
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        NSApp.runModal(for: window)
        return result
    }
}

private final class SelectionView: NSView {
    private var start: NSPoint?
    private var current: NSPoint?
    private let onComplete: (CGRect) -> Void
    private let onCancel: () -> Void

    init(onComplete: @escaping (CGRect) -> Void, onCancel: @escaping () -> Void) {
        self.onComplete = onComplete
        self.onCancel = onCancel
        super.init(frame: .zero)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        start = convert(event.locationInWindow, from: nil)
        current = start
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        current = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard let s = start, let c = current else { onCancel(); return }
        let rect = NSRect(x: min(s.x, c.x), y: min(s.y, c.y),
                          width: abs(c.x - s.x), height: abs(c.y - s.y))
        if rect.width < 8 || rect.height < 8 { onCancel(); return }
        // Konvertiere View-Koordinaten (NSPoint, origin unten-links) in CG-Koordinaten
        let screen = NSScreen.main?.frame ?? .zero
        let cgRect = CGRect(
            x: rect.minX,
            y: screen.height - rect.maxY,
            width: rect.width,
            height: rect.height
        )
        onComplete(cgRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel() } // Esc
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 0, alpha: 0.3).setFill()
        dirtyRect.fill()
        if let s = start, let c = current {
            let r = NSRect(x: min(s.x, c.x), y: min(s.y, c.y),
                           width: abs(c.x - s.x), height: abs(c.y - s.y))
            NSColor.clear.setFill(); r.fill()
            NSColor(calibratedRed: 0.3, green: 0.6, blue: 1, alpha: 0.3).setFill()
            r.fill()
            NSColor(calibratedRed: 0.3, green: 0.6, blue: 1, alpha: 1).setStroke()
            let path = NSBezierPath(rect: r); path.lineWidth = 2; path.stroke()
        }
    }
}
