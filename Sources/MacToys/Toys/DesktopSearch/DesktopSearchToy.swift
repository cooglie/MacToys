//
//  DesktopSearchToy.swift
//  MacToys — Desktop Search
//
//  Schnelle Dateisuche via Spotlight (NSMetadataQuery). Filter nach Typ,
//  Sortierung, Öffnen und Im Finder zeigen.
//

import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class DesktopSearchToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "desktop-search",
        name: "Desktop Search",
        tagline: "Dateien blitzschnell finden — Spotlight mit Filtern.",
        symbol: "magnifyingglass",
        accent: "#5E5CE6",
        category: .files
    )

    @Published private(set) var isRunning = false
    @Published var query: String = ""
    @Published var results: [SearchResult] = []
    @Published var typeFilter: TypeFilter = .all
    @Published var searching = false

    enum TypeFilter: String, CaseIterable, Identifiable {
        case all, apps, images, documents, archives, code
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "Alle"; case .apps: return "Apps"; case .images: return "Bilder"
            case .documents: return "Dokumente"; case .archives: return "Archive"; case .code: return "Code"
            }
        }
        var predicate: String {
            switch self {
            case .all: return "kMDItemFSName == '*'"
            case .apps: return "kMDItemContentType == 'com.apple.application-bundle'"
            case .images: return "kMDItemContentTypeTree == 'public.image'"
            case .documents: return "kMDItemContentTypeTree == 'public.text'"
            case .archives: return "kMDItemContentTypeTree == 'public.archive'"
            case .code: return "kMDItemContentTypeTree == 'public.source-code'"
            }
        }
    }

    private var mdQuery: NSMetadataQuery?

    func start() { isRunning = true }
    func stop() {
        mdQuery?.stop()
        mdQuery = nil
        isRunning = false
    }

    func runSearch() {
        mdQuery?.stop()
        results = []
        guard !query.isEmpty else { return }
        searching = true

        let q = NSMetadataQuery()
        q.searchScopes = [NSMetadataQueryUserHomeScope]
        q.predicate = NSPredicate(format: "(kMDItemDisplayName LIKE[cd] %@) AND (\(typeFilter.predicate))", "*\(query)*")
        q.sortDescriptors = [NSSortDescriptor(key: "kMDItemFSContentChangeDate", ascending: false)]
        q.valueListAttributes = [NSMetadataItemURLKey]

        NotificationCenter.default.addObserver(self, selector: #selector(found), name: .NSMetadataQueryDidFinishGathering, object: q)
        NotificationCenter.default.addObserver(self, selector: #selector(found), name: .NSMetadataQueryDidUpdate, object: q)
        mdQuery = q
        q.start()
    }

    @objc private func found() {
        guard let q = mdQuery else { return }
        var res: [SearchResult] = []
        q.disableUpdates()
        for i in 0..<min(q.resultCount, 200) {
            guard let item = q.result(at: i) as? NSMetadataItem else { continue }
            guard let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL else { continue }
            let name = item.value(forAttribute: NSMetadataItemDisplayNameKey) as? String ?? url.lastPathComponent
            let path = url.path
            let kind = (item.value(forAttribute: NSMetadataItemContentTypeKey) as? String) ?? ""
            res.append(SearchResult(name: name, path: path, url: url, kind: kind))
        }
        q.enableUpdates()
        results = res
        searching = false
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(DesktopSearchView(toy: self)) }
}

struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let url: URL
    let kind: String
}

struct DesktopSearchView: View {
    @ObservedObject var toy: DesktopSearchToy

    var body: some View {
        Form {
            Section("Suche") {
                TextField("Suchbegriff…", text: $toy.query)
                    .onSubmit { toy.runSearch() }
                Picker("Filter", selection: $toy.typeFilter) {
                    ForEach(DesktopSearchToy.TypeFilter.allCases) { f in Text(f.label).tag(f) }
                }
                Button("Suchen") { toy.runSearch() }
            }
            Section("Ergebnisse (\(toy.results.count))") {
                if toy.searching {
                    ProgressView("Suche…")
                } else if toy.results.isEmpty {
                    Text("Keine Ergebnisse.").foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(toy.results) { r in
                                HStack {
                                    Image(systemName: iconFor(r.kind))
                                        .foregroundStyle(.secondary)
                                    VStack(alignment: .leading) {
                                        Text(r.name).lineLimit(1)
                                        Text(r.path).font(.caption).foregroundStyle(.tertiary).lineLimit(1)
                                    }
                                    Spacer()
                                    Button("Öffnen") { NSWorkspace.shared.open(r.url) }
                                    Button("Finder") { NSWorkspace.shared.activateFileViewerSelecting([r.url]) }
                                }
                            }
                        }
                    }.frame(maxHeight: 220)
                }
            }
        }
    }

    private func iconFor(_ kind: String) -> String {
        if kind.contains("image") { return "photo" }
        if kind.contains("pdf") { return "doc.richtext" }
        if kind.contains("archive") { return "doc.zipper" }
        if kind.contains("application") { return "app" }
        if kind.contains("source-code") { return "chevron.left.forwardslash.chevron.right" }
        return "doc"
    }
}
