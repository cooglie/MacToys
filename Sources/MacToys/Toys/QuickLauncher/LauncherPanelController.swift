//
//  LauncherPanelController.swift
//  MacToys — Quick Launcher
//
//  Das schwebende Suchfenster (Palette). Borderless, zentriert, mit
//  Textfeld + Ergebnisliste. Behandelt Eingabe: Berechnung, App-Start,
//  Web-Suche, Datei-/App-Suche.
//

import AppKit
import SwiftUI

@MainActor
final class LauncherPanelController {

    private var panel: NSPanel?
    private let viewModel = LauncherViewModel()

    var isVisible: Bool { panel?.isVisible ?? false }

    func show() {
        guard let screen = NSScreen.main else { return }
        let width: CGFloat = 560
        let height: CGFloat = 420
        let frame = NSRect(
            x: screen.frame.midX - width / 2,
            y: screen.frame.midY - height / 2,
            width: width, height: height
        )
        let panel = NSPanel(
            contentRect: frame,
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        panel.title = "Quick Launcher"
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let hosting = NSHostingController(rootView: LauncherView(viewModel: viewModel, onClose: { [weak self] in
            self?.close()
        }))
        panel.contentViewController = hosting
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.panel = panel
    }

    func close() {
        panel?.orderOut(nil)
        panel = nil
    }
}

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [LauncherItem] = []
    @Published var selected: Int = 0

    func update() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; return }

        var items: [LauncherItem] = []

        // 1) Taschenrechner
        if let value = evaluate(q) {
            items.append(LauncherItem(title: "= \(value)", subtitle: "Berechnung kopieren",
                                      symbol: "equals", kind: .calc(value)))
        }

        // 2) Web-Suche (g <query>)
        if q.hasPrefix("g ") {
            let term = String(q.dropFirst(2))
            let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
            items.append(LauncherItem(title: "Google: \(term)", subtitle: "Im Browser öffnen",
                                      symbol: "magnifyingglass",
                                      kind: .web("https://www.google.com/search?q=\(encoded)")))
        }

        // 3) Apps
        let apps = searchApps(matching: q)
        items.append(contentsOf: apps.prefix(6))

        results = items
        selected = 0
    }

    func activate(_ item: LauncherItem) {
        switch item.kind {
        case .calc(let v):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(v, forType: .string)
        case .web(let url):
            NSWorkspace.shared.open(URL(string: url)!)
        case .app(let url):
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        case .file(let url):
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Berechnung

    private func evaluate(_ expr: String) -> String? {
        // Nur rechnen, wenn der Ausdruck ausschließlich Math-Zeichen enthält
        // (Ziffern, Operatoren, Klammern, Punkt, Komma). Alles andere würde
        // NSExpression interpretieren (z. B. Funktionsnamen) oder crashen.
        let allowed = CharacterSet(charactersIn: "0123456789+-*/().%^,.")
        guard !expr.isEmpty,
              expr.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        // Mindestens ein Operator muss vorkommen, sonst ist es nur eine Zahl.
        let operators = CharacterSet(charactersIn: "+-*/%^")
        guard expr.unicodeScalars.contains(where: { operators.contains($0) }) else { return nil }

        let cleaned = expr.replacingOccurrences(of: "^", with: "**")
            .replacingOccurrences(of: ",", with: ".")
        // NSExpression ist kein failable Initializer — bei ungültiger Syntax
        // wirft es zur Laufzeit. Wir fangen das Ergebnis sicher ab.
        let fmt = NSExpression(format: cleaned)
        guard let val = fmt.expressionValue(with: nil, context: nil) as? Double,
              !val.isNaN, !val.isInfinite else { return nil }
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(val))
        }
        return String(format: "%g", val)
    }

    // MARK: - Apps

    private func searchApps(matching q: String) -> [LauncherItem] {
        let apps = Self.allApps
        let lq = q.lowercased()
        return apps
            .filter { $0.lastPathComponent.lowercased().contains(lq) }
            .sorted { a, b in
                let an = a.deletingPathExtension().lastPathComponent.lowercased()
                let bn = b.deletingPathExtension().lastPathComponent.lowercased()
                if an == lq { return true }
                if bn == lq { return false }
                return an < bn
            }
            .map { url in
                LauncherItem(title: url.deletingPathExtension().lastPathComponent,
                             subtitle: url.path, symbol: "app", kind: .app(url))
            }
    }

    private static let allApps: [URL] = {
        let dirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/Applications/Utilities"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
        ]
        var urls: [URL] = []
        for dir in dirs {
            if let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                urls.append(contentsOf: items.filter { $0.pathExtension == "app" })
            }
        }
        return urls
    }()
}

struct LauncherItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbol: String
    let kind: Kind
    enum Kind: Hashable {
        case calc(String)
        case web(String)
        case app(URL)
        case file(URL)
    }
}

struct LauncherView: View {
    @ObservedObject var viewModel: LauncherViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "command").foregroundStyle(.secondary)
                TextField("Suchen, rechnen, starten…", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onChange(of: viewModel.query) { _ in viewModel.update() }
                    .onSubmit { submit() }
                Button(action: onClose) { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.borderless).foregroundStyle(.tertiary)
            }
            .padding(16)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(viewModel.results.enumerated()), id: \.element.id) { idx, item in
                        LauncherRow(item: item, selected: idx == viewModel.selected) {
                            viewModel.activate(item)
                            onClose()
                        }
                        .onHover { _ in viewModel.selected = idx }
                    }
                }
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func submit() {
        guard !viewModel.results.isEmpty else { return }
        viewModel.activate(viewModel.results[viewModel.selected])
        onClose()
    }
}

struct LauncherRow: View {
    let item: LauncherItem
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: item.symbol).foregroundStyle(.tint).frame(width: 24)
                VStack(alignment: .leading) {
                    Text(item.title).foregroundStyle(.primary)
                    Text(item.subtitle).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? Color.accentColor.opacity(0.18) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}
