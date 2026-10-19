//
//  RulerOverlay.swift
//  MacToys — Screen Ruler
//
//  Vollbild-Overlay mit Live-Maßanzeige während der Auswahl.
//  Zeichnet Auswahlrechteck + Dimensions-Labels.
//

import AppKit

final class RulerOverlay {
    private var done = false

    func runModal(onComplete: @escaping (CGRect) -> Void) {
        guard let screen = NSScreen.main else { return }
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = NSColor(white: 0, alpha: 0.001)
        window.hasShadow = false
        window.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]

        let view = RulerView(onComplete: { rect in
            window.close()
            NSApp.stopModal()
            onComplete(rect)
        }, onCancel: {
            window.close()
            NSApp.stopModal()
        })
        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        NSApp.runModal(for: window)
    }
}

private final class RulerView: NSView {
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
        if rect.width < 4 || rect.height < 4 { onCancel(); return }
        let screen = NSScreen.main?.frame ?? .zero
        let cgRect = CGRect(x: rect.minX, y: screen.height - rect.maxY,
                            width: rect.width, height: rect.height)
        onComplete(cgRect)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { onCancel() }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 0, alpha: 0.25).setFill()
        bounds.fill()
        guard let s = start, let c = current else { return }
        let r = NSRect(x: min(s.x, c.x), y: min(s.y, c.y),
                       width: abs(c.x - s.x), height: abs(c.y - s.y))
        NSColor(calibratedRed: 1, green: 0.84, blue: 0.04, alpha: 0.18).setFill()
        r.fill()
        NSColor(calibratedRed: 1, green: 0.84, blue: 0.04, alpha: 1).setStroke()
        let path = NSBezierPath(rect: r); path.lineWidth = 2; path.stroke()

        // Dimension-Labels
        let w = Int(r.width)
        let h = Int(r.height)
        let label = "\(w) × \(h) px"
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor.white,
        ]
        let str = NSAttributedString(string: label, attributes: attrs)
        let size = str.size()
        let labelOrigin = NSPoint(x: r.midX - size.width / 2,
                                  y: r.maxY + 8)
        let bgRect = NSRect(x: labelOrigin.x - 6, y: labelOrigin.y - 3,
                            width: size.width + 12, height: size.height + 6)
        NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.7).setFill()
        NSBezierPath(roundedRect: bgRect, xRadius: 6, yRadius: 6).fill()
        str.draw(at: labelOrigin)
    }
}
