//
//  PowerRenameToy.swift
//  MacToys — Power Rename
//
//  Batch-Umbenennung von Dateien: Suchen & Ersetzen, Regex, Nummerierung,
//  Fall-Änderung. Eigenes Fenster mit Vorschau (Original → Neu).
//

import AppKit
import SwiftUI

final class PowerRenameToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "power-rename",
        name: "Power Rename",
        tagline: "Dateien stapelweise umbenennen — Suchen/Ersetzen, Regex, Nummerierung.",
        symbol: "textformat.abc.dottedunderline",
        accent: "#64D2FF",
        category: .files
    )

    @Published private(set) var isRunning = false
    @Published var files: [URL] = []
    @Published var search: String = ""
    @Published var replacement: String = ""
    @Published var useRegex: Bool = false
    @Published var caseSensitive: Bool = true
    @Published var numbering: Bool = false
    @Published var startNumber: Int = 1
    @Published var numberDigits: Int = 2
    @Published var caseChange: CaseChange = .keep

    enum CaseChange: String, CaseIterable, Identifiable {
        case keep, lower, upper, title
        var id: String { rawValue }
        var label: String {
            switch self {
            case .keep: return "Beibehalten"; case .lower: return "Kleinbuchstaben"
            case .upper: return "GROSSBUCHSTABEN"; case .title: return "Titelschreibweise"
            }
        }
    }

    func start() { isRunning = true }
    func stop() { isRunning = false }

    // MARK: - Vorschau

    struct RenamePreview: Identifiable {
        let id = UUID()
        let original: String
        var newName: String
        var conflict: Bool
    }

    var preview: [RenamePreview] {
        var seen: [String: Int] = [:]
        var idx = startNumber
        let fmt = "%0\(max(1,numberDigits))d"
        return files.map { url in
            let base = url.deletingPathExtension().lastPathComponent
            let ext = url.pathExtension
            var name = base
            if useRegex {
                if let re = try? NSRegularExpression(pattern: search, options: caseSensitive ? [] : .caseInsensitive) {
                    let range = NSRange(location: 0, length: name.utf16.count)
                    name = re.stringByReplacingMatches(in: name, range: range, withTemplate: replacement)
                }
            } else {
                name = base.replacingOccurrences(
                    of: search,
                    with: replacement,
                    options: caseSensitive ? .literal : [.literal, .caseInsensitive]
                )
            }
            name = applyCaseChange(name)
            if numbering {
                let num = String(format: fmt, idx)
                idx += 1
                name = "\(name) \(num)"
            }
            let full = ext.isEmpty ? name : "\(name).\(ext)"
            seen[full, default: 0] += 1
            return RenamePreview(original: url.lastPathComponent, newName: full, conflict: seen[full]! > 1)
        }
    }

    private func applyCaseChange(_ s: String) -> String {
        switch caseChange {
        case .keep: return s
        case .lower: return s.lowercased()
        case .upper: return s.uppercased()
        case .title: return s.capitalized
        }
    }

    // MARK: - Ausführen

    @Published var result: String = ""

    /// Protokoll-Hauptaktion: öffnet das Fenster (UI-Toy).
    @MainActor func execute() {
        ToyRegistry.shared.requestOpenSettings(for: descriptor.id)
    }

    /// Führt die Umbenennung durch und setzt die Ergebnis-Anzeige.
    func performRename() {
        let fm = FileManager.default
        var renamed = 0, failed = 0
        let pv = preview
        for (url, p) in zip(files, pv) where !p.conflict {
            let dest = url.deletingLastPathComponent().appendingPathComponent(p.newName)
            do {
                try fm.moveItem(at: url, to: dest)
                renamed += 1
            } catch {
                failed += 1
                MacToysLog.warning("Rename fehlgeschlagen: \(url.lastPathComponent) → \(error)", category: "rename")
            }
        }
        result = "Fertig: \(renamed) umbenannt, \(failed) fehlgeschlagen."
        files = []
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(PowerRenameView(toy: self)) }
}

struct PowerRenameView: View {
    @ObservedObject var toy: PowerRenameToy
    @State private var dropActive = false

    var body: some View {
        Form {
            Section("Dateien") {
                DropArea(toy: toy, active: $dropActive)
                if !toy.files.isEmpty {
                    Text("\(toy.files.count) Datei(en) ausgewählt").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Suchen & Ersetzen") {
                TextField("Suchen nach", text: $toy.search)
                TextField("Ersetzen durch", text: $toy.replacement)
                Toggle("Regulärer Ausdruck", isOn: $toy.useRegex)
                Toggle("Groß-/Kleinschreibung", isOn: $toy.caseSensitive)
            }
            Section("Nummerierung") {
                Toggle("Nummerierung anhängen", isOn: $toy.numbering)
                if toy.numbering {
                    Stepper("Start: \(toy.startNumber)", value: $toy.startNumber, in: 0...99999)
                    Stepper("Stellen: \(toy.numberDigits)", value: $toy.numberDigits, in: 1...6)
                }
            }
            Section("Schreibweise") {
                Picker("Groß-/Kleinschreibung", selection: $toy.caseChange) {
                    ForEach(PowerRenameToy.CaseChange.allCases) { c in Text(c.label).tag(c) }
                }
            }
            Section("Vorschau") {
                if toy.preview.isEmpty {
                    Text("Dateien hinzufügen für Vorschau.").foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(toy.preview) { p in
                                HStack {
                                    Text(p.original).lineLimit(1).truncationMode(.middle)
                                    Image(systemName: "arrow.right").foregroundStyle(.tertiary)
                                    Text(p.newName).lineLimit(1).truncationMode(.middle)
                                        .foregroundStyle(p.conflict ? .red : .primary)
                                    if p.conflict { Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.red) }
                                }
                                .font(.callout.monospaced())
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
            }
            Section {
                Button("Umbenennen") { toy.performRename() }
                    .disabled(toy.files.isEmpty || toy.preview.contains { $0.conflict })
                if !toy.result.isEmpty { Text(toy.result).foregroundStyle(.secondary) }
            }
        }
    }
}

struct DropArea: View {
    @ObservedObject var toy: PowerRenameToy
    @Binding var active: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(active ? Color.accentColor.opacity(0.1) : Color.clear)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(active ? Color.accentColor : Color.secondary.opacity(0.4))
            VStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down.fill").font(.title2)
                Text("Dateien hierher ziehen oder auswählen").font(.caption)
            }
        }
        .frame(height: 64)
        .onDrop(of: [.fileURL], isTargeted: $active) { providers in
            let urls = providers.compactMap { try? $0.loadItem(forTypeIdentifier: "public.file-url") as? Data }
                .compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
            toy.files.append(contentsOf: urls)
            return true
        }
        .onTapGesture {
            let panel = NSOpenPanel()
            panel.allowsMultipleSelection = true
            panel.canChooseDirectories = false
            if panel.runModal() == .OK { toy.files.append(contentsOf: panel.urls) }
        }
    }
}
