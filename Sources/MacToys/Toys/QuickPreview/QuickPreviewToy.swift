//
//  QuickPreviewToy.swift
//  MacToys — Quick Preview
//
//  Zeigt eine Vorschau beliebiger Dateien via QLPreviewView (Quick Look).
//  Eigenes Fenster; Datei per Drag&Drop oder Dateiauswahl.
//

import AppKit
import Quartz
import SwiftUI
import UniformTypeIdentifiers

final class QuickPreviewToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "quick-preview",
        name: "Quick Preview",
        tagline: "Dateien schnell voranzeigen — ohne die zugehörige App zu öffnen.",
        symbol: "eye",
        accent: "#0A84FF",
        category: .files
    )

    @Published private(set) var isRunning = false
    @Published var previewURL: URL?

    private var previewPanel: QLPreviewPanel?

    func start() { isRunning = true }
    func stop() {
        previewPanel?.close()
        previewPanel = nil
        isRunning = false
    }

    /// Hauptaktion: aktiviert bei Bedarf und zeigt einen Datei-Auswahl-Dialog,
    /// dessen Auswahl sofort per Quick Look vorgeschaut wird.
    @MainActor func execute() {
        if !isRunning { ToyRegistry.shared.setEnabled(descriptor.id, true) }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            preview(url)
        }
    }

    func preview(_ url: URL) {
        previewURL = url
        showQuickLook(url)
    }

    private func showQuickLook(_ url: URL) {
        let panel = QLPreviewPanel.shared()!
        panel.dataSource = QuickPreviewDataSource(url: url)
        panel.makeKeyAndOrderFront(nil)
        previewPanel = panel
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(QuickPreviewView(toy: self)) }
}

private final class QuickPreviewDataSource: NSObject, QLPreviewPanelDataSource {
    let url: URL
    init(url: URL) { self.url = url }
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int { 1 }
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (QLPreviewItem)! {
        return url as NSURL
    }
}

struct QuickPreviewView: View {
    @ObservedObject var toy: QuickPreviewToy
    @State private var path = ""

    var body: some View {
        Form {
            Section("Datei") {
                TextField("Dateipfad", text: $path)
                HStack {
                    Button("Auswählen…") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = false
                        if panel.runModal() == .OK, let url = panel.url {
                            path = url.path
                            toy.preview(url)
                        }
                    }
                    Button("Vorschau zeigen") {
                        if !path.isEmpty { toy.preview(URL(fileURLWithPath: path)) }
                    }
                    .disabled(path.isEmpty)
                }
            }
            Section("Hinweis") {
                Text("Quick Preview nutzt die System-Quick-Look-Engine und unterstützt Bilder, PDFs, Text, Markdown, Filme u. v. m.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
