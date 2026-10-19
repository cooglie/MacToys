//
//  TextExtractorToy.swift
//  MacToys — Text Extractor
//
//  Extrahiert Text aus einem Bildschirmausschnitt via Vision (OCR).
//  Nutzer zieht einen Auswahlrahmen auf; Screenshot wird erzeugt und per
//  VNRecognizeTextRequest verarbeitet. Ergebnis kopierbar.
//

import AppKit
import Carbon.HIToolbox
import SwiftUI
import Vision

final class TextExtractorToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "text-extractor",
        name: "Text Extractor",
        tagline: "Text aus dem Bildschirm extrahieren — OCR via Vision.",
        symbol: "doc.text.viewfinder",
        accent: "#FFD60A",
        category: .workflow
    )

    @Published private(set) var isRunning = false
    @Published var extractedText: String = ""
    @Published private(set) var lastRun: Date?

    private var hotkeyID: UInt32?
    private let settings = TextExtractorSettings.shared

    func start() {
        isRunning = true
        hotkeyID = HotkeyManager.shared.register(settings.hotkey) { [weak self] in
            self?.captureAndRecognize()
        }
        MacToysLog.info("Text Extractor gestartet.", category: "ocr")
    }

    func stop() {
        if let hotkeyID { HotkeyManager.shared.unregister(hotkeyID) }
        hotkeyID = nil
        isRunning = false
    }

    // MARK: - Capture + OCR

    /// Hauptaktion: aktiviert bei Bedarf und startet die OCR-Auswahl.
    @MainActor func execute() {
        if !isRunning { ToyRegistry.shared.setEnabled(descriptor.id, true) }
        captureAndRecognize()
    }

    func captureAndRecognize() {
        guard isRunning else { return }
        guard let rect = selectRegion() else { return }
        guard let image = CGDisplayCreateImage(CGMainDisplayID(), rect: rect) else {
            MacToysLog.warning("Text Extractor: Screenshot fehlgeschlagen.", category: "ocr")
            return
        }
        recognize(image: image)
    }

    /// Zeigt einen borderless Overlay-Window zur Auswahl eines Rechtecks.
    private func selectRegion() -> CGRect? {
        let overlay = RegionSelectionOverlay()
        return overlay.runModal()
    }

    private func recognize(image: CGImage) {
        let request = VNRecognizeTextRequest { [weak self] request, _ in
            let observations = request.results as? [VNRecognizedTextObservation] ?? []
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async {
                self?.extractedText = text
                self?.lastRun = Date()
                if self?.settings.autoCopy ?? true {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                MacToysLog.info("Text Extractor: \(text.count) Zeichen erkannt.", category: "ocr")
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["de-DE", "en-US"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(TextExtractorSettingsView(toy: self)) }
}

final class TextExtractorSettings: ObservableObject {
    static let shared = TextExtractorSettings()
    @Published var hotkey: HotkeyConfig { didSet { save() } }
    @Published var autoCopy: Bool {
        didSet { UserDefaults.standard.set(autoCopy, forKey: "mactoys.ocr.autocopy") }
    }
    private let key = "mactoys.ocr.config"
    private init() {
        let ctrl = UInt32(controlKey), opt = UInt32(optionKey)
        let m = ctrl | opt
        autoCopy = UserDefaults.standard.object(forKey: "mactoys.ocr.autocopy") as? Bool ?? true
        hotkey = HotkeyConfig(keyCode: UInt32(kVK_ANSI_E), modifiers: m, label: "⌃⌥E")
        if let data = UserDefaults.standard.data(forKey: key),
           let d = try? JSONDecoder().decode(HotkeyConfig.self, from: data) { hotkey = d }
    }
    private func save() { if let d = try? JSONEncoder().encode(hotkey) { UserDefaults.standard.set(d, forKey: key) } }
}

struct TextExtractorSettingsView: View {
    @ObservedObject var toy: TextExtractorToy
    @ObservedObject private var settings = TextExtractorSettings.shared
    var body: some View {
        Form {
            Section("Hotkey") {
                HStack { Text("Region auswählen & OCR"); Spacer()
                    Text(settings.hotkey.label).font(.callout.monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 2).background(.quaternary, in: Capsule())
                }
                Button("Jetzt ausführen") { toy.captureAndRecognize() }
            }
            Section("Optionen") {
                Toggle("Erkannten Text automatisch kopieren", isOn: $settings.autoCopy)
            }
            Section("Ergebnis") {
                if toy.extractedText.isEmpty {
                    Text("Noch kein Text erkannt.").foregroundStyle(.secondary)
                } else {
                    TextEditor(text: .constant(toy.extractedText)).font(.callout.monospaced()).frame(minHeight: 120)
                    Button("Kopieren") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(toy.extractedText, forType: .string)
                    }
                    if let last = toy.lastRun {
                        Text("Letzte Ausführung: \(last.formatted(.dateTime))").font(.caption).foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }
}
