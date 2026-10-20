//
//  LauncherPanelController.swift
//  MacToys — Quick Launcher
//
//  Das schwebende Suchfenster (Palette). Borderless, zentriert, mit
//  Textfeld + Ergebnisliste. Behandelt Eingabe: Berechnung, App-Start,
//  Web-Suche, Datei-/App-Suche. Volle Tastatur-Navigation (↑↓/Enter/Esc),
//  Recents-Ranking, erweiterte App-Suche über alle Standard-Ordner.
//

import AppKit
import Carbon
import SwiftUI

@MainActor
final class LauncherPanelController {

    private var panel: NSPanel?
    private let viewModel = LauncherViewModel()
    private var keyMonitor: Any?

    var isVisible: Bool { panel?.isVisible ?? false }

    func show() {
        viewModel.reset()
        if panel == nil {
            buildPanel()
        }
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyMonitor()
    }

    func close() {
        panel?.orderOut(nil)
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    /// Fängt Pfeil-oben/unten, Enter und Esc global ab, solange das Panel
    /// sichtbar ist. SwiftUI .onKeyPress gibt es erst ab macOS 14, daher der
    /// klassische Local-Monitor (macOS 12-kompatibel).
    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible else { return event }
            switch event.keyCode {
            case UInt16(kVK_DownArrow):
                self.viewModel.moveSelection(1)
                return nil  // Event konsumieren
            case UInt16(kVK_UpArrow):
                self.viewModel.moveSelection(-1)
                return nil
            case UInt16(kVK_Return), UInt16(kVK_ANSI_KeypadEnter):
                if self.viewModel.activateSelected() { self.close() }
                return nil
            case UInt16(kVK_Escape):
                self.close()
                return nil
            default:
                return event
            }
        }
    }

    private func buildPanel() {
        guard let screen = NSScreen.main else { return }
        let width: CGFloat = 600
        let height: CGFloat = 440
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
        panel.becomesKeyOnlyIfNeeded = false
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.collectionBehavior = [.fullScreenAuxiliary, .canJoinAllSpaces]
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true

        let hosting = NSHostingController(rootView:
            LauncherView(viewModel: viewModel, onClose: { [weak self] in self?.close() })
        )
        panel.contentViewController = hosting
        self.panel = panel
    }
}

@MainActor
final class LauncherViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var results: [LauncherItem] = []
    @Published var selected: Int = 0

    func reset() {
        query = ""
        results = []
        selected = 0
    }

    func update() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { results = []; selected = 0; return }

        var items: [LauncherItem] = []

        // 1) Taschenrechner
        if let value = evaluate(q) {
            items.append(LauncherItem(title: "= \(value)", subtitle: "Ergebnis kopieren",
                                      symbol: "equals", kind: .calc(value)))
        }

        // 2) Web-Suche (g <query>)
        if q.hasPrefix("g ") {
            let term = String(q.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            if !term.isEmpty {
                let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
                items.append(LauncherItem(title: "Google: \(term)", subtitle: "Im Browser öffnen",
                                          symbol: "magnifyingglass",
                                          kind: .web("https://www.google.com/search?q=\(encoded)")))
            }
        }

        // 3) Apps — Recents werden bevorzugt gerankt
        let apps = searchApps(matching: q)
        items.append(contentsOf: apps.prefix(8))

        results = items
        selected = 0
    }

    func moveSelection(_ delta: Int) {
        guard !results.isEmpty else { return }
        selected = (selected + delta + results.count) % results.count
    }

    func activateSelected() -> Bool {
        guard !results.isEmpty, selected < results.count else { return false }
        activate(results[selected])
        return true
    }

    func activate(_ item: LauncherItem) {
        switch item.kind {
        case .calc(let v):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(v, forType: .string)
        case .web(let url):
            if let u = URL(string: url) { NSWorkspace.shared.open(u) }
        case .app(let url):
            LauncherRecents.shared.record(url)
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

        // NSExpression(format:) wirft bei syntaktisch ungültigen Ausdrücken
        // (z. B. "2++2", "()", "2*") eine NSException, die sich in Swift nicht
        // per do/catch abfangen lässt → App-Crash. Daher vorab syntaktisch
        // validieren: Klammern balanciert, kein Operator am Ende, keine zwei
        // Operatoren (außer Vorzeichen) direkt nacheinander.
        guard isSyntacticallyValid(expr) else { return nil }

        let cleaned = expr.replacingOccurrences(of: "^", with: "**")
            .replacingOccurrences(of: ",", with: ".")
        let fmt = NSExpression(format: cleaned)
        guard let val = fmt.expressionValue(with: nil, context: nil) as? Double,
              !val.isNaN, !val.isInfinite else { return nil }
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(val))
        }
        return String(format: "%g", val)
    }

    /// Grob-Syntaxprüfung, damit NSExpression(format:) nicht crasht.
    private func isSyntacticallyValid(_ expr: String) -> Bool {
        var depth = 0
        var prev: Character = " "
        let ops = Set<Character>(["+", "-", "*", "/", "%", "^"])
        for ch in expr {
            if ch == "(" {
                depth += 1
                if prev != " " && ops.contains(prev) == false && prev != "(" {
                    return false
                }
            } else if ch == ")" {
                depth -= 1
                if depth < 0 { return false }            // mehr ')' als '('
                if ops.contains(prev) { return false }   // Operator direkt vor ')'
            } else if ops.contains(ch) {
                if ch != "-" && ch != "+" && ops.contains(prev) { return false }
            }
            prev = ch
        }
        if depth != 0 { return false }                  // unausgewogene Klammern
        if ops.contains(prev) { return false }          // Operator am Ende
        return true
    }

    // MARK: - Apps

    private func searchApps(matching q: String) -> [LauncherItem] {
        let lq = q.lowercased()
        let recents = LauncherRecents.shared.urls
        let all = Self.allApps

        // Gefilterte Treffer + Score berechnen.
        struct Scored { let url: URL; let score: Int }
        var scored: [Scored] = []
        for url in all {
            let name = url.deletingPathExtension().lastPathComponent.lowercased()
            guard name.contains(lq) else { continue }
            // Score: exakter Treffer > Präfix > contains; Recents-Bonus dazu.
            var s = 0
            if name == lq { s += 1000 }
            else if name.hasPrefix(lq) { s += 500 }
            else { s += 100 }
            if let rank = recents.firstIndex(where: { $0 == url }) {
                s += max(1, 10 - rank)
            }
            scored.append(Scored(url: url, score: s))
        }
        scored.sort { $0.score > $1.score }

        return scored.map { scored in
            let url = scored.url
            return LauncherItem(title: url.deletingPathExtension().lastPathComponent,
                                subtitle: url.deletingLastPathComponent().path,
                                symbol: "app", kind: .app(url))
        }
    }

    private static let allApps: [URL] = {
        let fm = FileManager.default
        var dirs: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: "/System/Applications/Utilities"),
            URL(fileURLWithPath: "/Applications/Utilities"),
        ]
        // Benutzer-Applications-Ordner, falls vorhanden.
        let home = fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        dirs.append(home)
        var urls: [URL] = []
        for dir in dirs {
            // Nur direkte Kinder mit Endung .app.
            guard let items = try? fm.contentsOfDirectory(at: dir,
                    includingPropertiesForKeys: nil) else { continue }
            for item in items where item.pathExtension == "app" {
                urls.append(item)
            }
        }
        // Deduplizieren (ein App kann in mehreren Ordnern liegen).
        var seen = Set<String>()
        return urls.filter { seen.insert($0.path).inserted }
    }()
}

/// Zuletzt gestartete Apps — persists in UserDefaults, beeinflusst Ranking.
@MainActor
final class LauncherRecents {
    static let shared = LauncherRecents()
    private let key = "mactoys.launcher.recents"
    private(set) var urls: [URL] = []

    private init() {
        if let arr = UserDefaults.standard.array(forKey: key) as? [String] {
            urls = arr.compactMap { URL(string: $0) }
        }
    }

    func record(_ url: URL) {
        urls.removeAll { $0 == url }
        urls.insert(url, at: 0)
        if urls.count > 10 { urls = Array(urls.prefix(10)) }
        UserDefaults.standard.set(urls.map { $0.absoluteString }, forKey: key)
    }
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
    @FocusState private var queryFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Suchfeld
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary).font(.title3)
                TextField("Suchen, rechnen, starten…", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($queryFocused)
                    .onChange(of: viewModel.query) { _ in viewModel.update() }
                    .onSubmit { if viewModel.activateSelected() { onClose() } }
                Button(action: onClose) { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.borderless).foregroundStyle(.tertiary)
            }
            .padding(16)
            Divider()

            if viewModel.results.isEmpty {
                // Empty-State
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 32)).foregroundStyle(.tertiary)
                    Text("Tippe, um zu suchen")
                        .font(.headline).foregroundStyle(.secondary)
                    Text("App-Name · 2+2·5 · g katzen")
                        .font(.caption).foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
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

            // Status-/Key-Hint-Leiste
            Divider()
            HStack(spacing: 16) {
                HintKey(key: "↑↓", label: "Auswahl")
                HintKey(key: "↵", label: "Öffnen")
                HintKey(key: "esc", label: "Schließen")
                Spacer()
                Text("\(viewModel.results.count) Treffer")
                    .font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
        }
        .frame(minWidth: 560, minHeight: 400)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear { queryFocused = true }
        .onChange(of: viewModel.query) { _ in if !queryFocused { queryFocused = true } }
    }
}

private struct HintKey: View {
    let key: String
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.caption.monospaced())
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
            Text(label).font(.caption).foregroundStyle(.tertiary)
        }
    }
}

struct LauncherRow: View {
    let item: LauncherItem
    let selected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.symbol)
                    .foregroundStyle(.tint)
                    .font(.title3)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
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
