//
//  ColorPickerToy.swift
//  MacToys — Color Picker
//
//  Sampelt Farben vom Bildschirm via NSColorSampler (System-Lupen-UI).
//  Kopiert HEX/RGB ins Clipboard und merkt den Verlauf.
//

import AppKit
import Carbon.HIToolbox
import SwiftUI

final class ColorPickerToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "color-picker",
        name: "Color Picker",
        tagline: "Bildschirmfarben abtasten — HEX/RGB kopieren, Verlauf speichern.",
        symbol: "eyedropper",
        accent: "#FF375F",
        category: .media
    )

    @Published private(set) var isRunning = false
    @Published private(set) var history: [PickedColor] = []
    @Published private(set) var lastPicked: PickedColor?

    private var hotkeyID: UInt32?
    private let settings = ColorPickerSettings.shared

    // MARK: - Toy Lifecycle

    func start() {
        isRunning = true
        hotkeyID = HotkeyManager.shared.register(settings.hotkey) { [weak self] in
            self?.pick()
        }
        loadHistory()
        MacToysLog.info("Color Picker gestartet.", category: "color")
    }

    func stop() {
        if let hotkeyID { HotkeyManager.shared.unregister(hotkeyID) }
        hotkeyID = nil
        isRunning = false
        MacToysLog.info("Color Picker gestoppt.", category: "color")
    }

    // MARK: - Pick

    /// Hauptaktion: aktiviert bei Bedarf und tastet eine Farbe ab.
    @MainActor func execute() {
        if !isRunning { ToyRegistry.shared.setEnabled(descriptor.id, true) }
        pick()
    }

    func pick() {
        guard isRunning else { return }
        let sampler = NSColorSampler()
        sampler.show { [weak self] color in
            guard let self, let color else { return }
            let picked = PickedColor(nsColor: color)
            self.lastPicked = picked
            self.history.insert(picked, at: 0)
            if self.history.count > 50 { self.history = Array(self.history.prefix(50)) }
            self.saveHistory()
            self.copyToClipboard(picked, format: self.settings.copyFormat)
        }
    }

    private func copyToClipboard(_ color: PickedColor, format: ColorPickerSettings.Format) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(color.string(format: format), forType: .string)
    }

    // MARK: - Persistenz

    private func saveHistory() {
        let data = history.map { ["hex": $0.hex, "r": $0.r, "g": $0.g, "b": $0.b] }
        UserDefaults.standard.set(data, forKey: "mactoys.colorpicker.history")
    }
    private func loadHistory() {
        guard let arr = UserDefaults.standard.array(forKey: "mactoys.colorpicker.history") as? [[String: Any]] else { return }
        history = arr.compactMap { d in
            guard let hex = d["hex"] as? String,
                  let r = d["r"] as? Int, let g = d["g"] as? Int, let b = d["b"] as? Int else { return nil }
            return PickedColor(hex: hex, r: r, g: g, b: b)
        }
    }

    @MainActor
    func settingsView() -> AnyView {
        AnyView(ColorPickerSettingsView(toy: self))
    }
}

struct PickedColor: Identifiable, Hashable {
    let id = UUID()
    let hex: String
    let r: Int, g: Int, b: Int
    init(hex: String, r: Int, g: Int, b: Int) {
        self.hex = hex; self.r = r; self.g = g; self.b = b
    }
    init(nsColor: NSColor) {
        let c = nsColor.usingColorSpace(.sRGB) ?? nsColor
        let r = Int((c.redComponent * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        self.r = r; self.g = g; self.b = b
        self.hex = String(format: "#%02X%02X%02X", r, g, b)
    }
    var nsColor: NSColor { NSColor(srgbRed: CGFloat(r)/255, green: CGFloat(g)/255, blue: CGFloat(b)/255, alpha: 1) }
    func string(format: ColorPickerSettings.Format) -> String {
        switch format {
        case .hex:   return hex
        case .rgb:   return "rgb(\(r), \(g), \(b))"
        case .hsl:   return hslString()
        }
    }
    private func hslString() -> String {
        let r = Double(r)/255, g = Double(g)/255, b = Double(b)/255
        let mx = max(r,g,b), mn = min(r,g,b)
        let l = (mx+mn)/2
        var h: Double = 0, s: Double = 0
        if mx != mn {
            let d = mx-mn
            s = l > 0.5 ? d/(2-mx-mn) : d/(mx+mn)
            if mx == r { h = (g-b)/d + (g < b ? 6 : 0) }
            else if mx == g { h = (b-r)/d + 2 }
            else { h = (r-g)/d + 4 }
            h /= 6
        }
        return "hsl(\(Int(h*360)), \(Int(s*100))%, \(Int(l*100))%)"
    }
}

final class ColorPickerSettings: ObservableObject {
    static let shared = ColorPickerSettings()
    enum Format: String, CaseIterable, Identifiable {
        case hex, rgb, hsl
        var id: String { rawValue }
        var label: String {
            switch self { case .hex: return "HEX"; case .rgb: return "RGB"; case .hsl: return "HSL" }
        }
    }
    @Published var copyFormat: Format {
        didSet { UserDefaults.standard.set(copyFormat.rawValue, forKey: "mactoys.colorpicker.format") }
    }
    @Published var hotkey: HotkeyConfig {
        didSet { save() }
    }
    private let key = "mactoys.colorpicker.config"
    private init() {
        let ctrl = UInt32(controlKey), opt = UInt32(optionKey)
        let m = ctrl | opt
        copyFormat = .hex
        if let raw = UserDefaults.standard.string(forKey: "mactoys.colorpicker.format"),
           let f = Format(rawValue: raw) { copyFormat = f }
        hotkey = HotkeyConfig(keyCode: UInt32(kVK_ANSI_P), modifiers: m, label: "⌃⌥P")
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(HotkeyConfig.self, from: data) { hotkey = decoded }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(hotkey) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

struct ColorPickerSettingsView: View {
    @ObservedObject var toy: ColorPickerToy
    @ObservedObject private var settings = ColorPickerSettings.shared

    var body: some View {
        Form {
            Section("Hotkey") {
                HStack {
                    Text("Farbe abtasten")
                    Spacer()
                    Text(settings.hotkey.label).font(.callout.monospaced())
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(.quaternary, in: Capsule())
                }
                Button("Jetzt abtasten") { toy.pick() }
            }
            Section("Kopierformat") {
                Picker("Format", selection: $settings.copyFormat) {
                    ForEach(ColorPickerSettings.Format.allCases) { f in Text(f.label).tag(f) }
                }
                .pickerStyle(.segmented)
            }
            Section("Verlauf (\(toy.history.count))") {
                if toy.history.isEmpty {
                    Text("Noch keine Farben abgetastet.").foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 8) {
                            ForEach(toy.history) { c in
                                VStack(spacing: 4) {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(nsColor: c.nsColor))
                                        .frame(height: 40)
                                    Text(c.hex).font(.caption2.monospaced())
                                }
                                .onTapGesture(count: 2) {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(c.string(format: settings.copyFormat), forType: .string)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            Section("Tipp") {
                Text("Doppelklick auf eine Farbe im Verlauf kopiert sie erneut im gewählten Format.")
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
