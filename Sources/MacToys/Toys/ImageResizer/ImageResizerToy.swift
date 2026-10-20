//
//  ImageResizerToy.swift
//  MacToys — Image Resizer
//
//  Skaliert und konvertiert Bilder stapelweise via ImageIO.
//  Unterstützt Breite/Höhe, Skalierungsfaktor, Format (PNG/JPEG/HEIC) und Qualität.
//

import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

final class ImageResizerToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "image-resizer",
        name: "Image Resizer",
        tagline: "Bilder stapelweise skalieren & konvertieren — PNG, JPEG, HEIC.",
        symbol: "photo.on.rectangle.angled",
        accent: "#30D158",
        category: .media
    )

    @Published private(set) var isRunning = false
    @Published var files: [URL] = []
    @Published var mode: ResizeMode = .width
    @Published var targetWidth: Int = 1280
    @Published var targetHeight: Int = 720
    @Published var scale: Double = 50
    @Published var format: OutputFormat = .keep
    @Published var quality: Double = 0.85
    @Published var keepAspect: Bool = true
    @Published var result: String = ""

    enum ResizeMode: String, CaseIterable, Identifiable {
        case width, height, scale
        var id: String { rawValue }
        var label: String {
            switch self { case .width: return "Auf Breite"; case .height: return "Auf Höhe"; case .scale: return "Skalierung %" }
        }
    }

    enum OutputFormat: String, CaseIterable, Identifiable {
        case keep, png, jpeg, heic
        var id: String { rawValue }
        var label: String {
            switch self { case .keep: return "Original"; case .png: return "PNG"; case .jpeg: return "JPEG"; case .heic: return "HEIC" }
        }
        var utype: CFString? {
            switch self {
            case .keep: return nil
            case .png: return UTType.png.identifier as CFString
            case .jpeg: return UTType.jpeg.identifier as CFString
            case .heic: return "public.heic" as CFString
            }
        }
    }

    func start() { isRunning = true }
    func stop() { isRunning = false }

    // MARK: - Verarbeiten

    func execute() {
        var ok = 0, fail = 0
        for url in files {
            if process(url) { ok += 1 } else { fail += 1 }
        }
        result = "Fertig: \(ok) verarbeitet, \(fail) fehlgeschlagen."
        files = []
    }

    private func process(_ url: URL) -> Bool {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
              let w = props[kCGImagePropertyPixelWidth] as? Int,
              let h = props[kCGImagePropertyPixelHeight] as? Int,
              let cgImage = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return false }

        let (newW, newH) = computeTarget(width: w, height: h)

        guard let cs = CGColorSpaceCreateDeviceRGB() as CGColorSpace?,
              let ctx = CGContext(data: nil, width: newW, height: newH, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        ctx.interpolationQuality = .high
        // Bitmap-Kontext hat Bottom-Left-Ursprung (y↑). Ohne Flip würde das
        // Bild kopfstehend gerendert. CTM vertikal spiegeln, damit das Bild
        // aufrecht steht.
        ctx.translateBy(x: 0, y: CGFloat(newH))
        ctx.scaleBy(x: 1, y: -1)
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: newW, height: newH))
        guard let out = ctx.makeImage() else { return false }

        let outType: CFString = format.utype ?? (CGImageSourceGetType(src) ?? UTType.jpeg.identifier as CFString)
        let base = url.deletingPathExtension().lastPathComponent
        let ext = extFor(format: outType)
        let destURL = url.deletingLastPathComponent().appendingPathComponent("\(base)_\(newW)x\(newH).\(ext)")

        guard let dest = CGImageDestinationCreateWithURL(destURL as CFURL, outType, 1, nil) else { return false }
        var propsOut: [CFString: Any] = [:]
        if outType == UTType.jpeg.identifier as CFString || outType == "public.heic" as CFString {
            propsOut[kCGImageDestinationLossyCompressionQuality] = quality
        }
        CGImageDestinationAddImage(dest, out, propsOut as CFDictionary)
        return CGImageDestinationFinalize(dest)
    }

    private func computeTarget(width: Int, height: Int) -> (Int, Int) {
        switch mode {
        case .width:
            let nW = targetWidth
            let nH = keepAspect ? Int(Double(nW) * Double(height) / Double(width)) : targetHeight
            return (max(1, nW), max(1, nH))
        case .height:
            let nH = targetHeight
            let nW = keepAspect ? Int(Double(nH) * Double(width) / Double(height)) : targetWidth
            return (max(1, nW), max(1, nH))
        case .scale:
            let f = scale / 100.0
            return (max(1, Int(Double(width) * f)), max(1, Int(Double(height) * f)))
        }
    }

    private func extFor(format: CFString) -> String {
        if format == UTType.png.identifier as CFString { return "png" }
        if format == UTType.jpeg.identifier as CFString { return "jpg" }
        if format == "public.heic" as CFString { return "heic" }
        return "img"
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(ImageResizerView(toy: self)) }
}

struct ImageResizerView: View {
    @ObservedObject var toy: ImageResizerToy

    var body: some View {
        Form {
            Section("Dateien") {
                ImageDropArea(toy: toy)
                if !toy.files.isEmpty {
                    Text("\(toy.files.count) Bild(er)").font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Skalierung") {
                Picker("Modus", selection: $toy.mode) {
                    ForEach(ImageResizerToy.ResizeMode.allCases) { m in Text(m.label).tag(m) }
                }.pickerStyle(.segmented)
                switch toy.mode {
                case .width:
                    Stepper("Breite: \(toy.targetWidth) px", value: $toy.targetWidth, in: 16...16384, step: 16)
                case .height:
                    Stepper("Höhe: \(toy.targetHeight) px", value: $toy.targetHeight, in: 16...16384, step: 16)
                case .scale:
                    Slider(value: $toy.scale, in: 1...200, step: 1) { Text("Skalierung \(Int(toy.scale))%") }
                }
                Toggle("Seitenverhältnis beibehalten", isOn: $toy.keepAspect)
            }
            Section("Format & Qualität") {
                Picker("Ausgabeformat", selection: $toy.format) {
                    ForEach(ImageResizerToy.OutputFormat.allCases) { f in Text(f.label).tag(f) }
                }
                if toy.format == .jpeg || toy.format == .heic {
                    Slider(value: $toy.quality, in: 0.1...1.0) { Text("Qualität \(Int(toy.quality*100))%") }
                }
            }
            Section {
                Button("Verarbeiten") { toy.execute() }
                    .disabled(toy.files.isEmpty)
                if !toy.result.isEmpty { Text(toy.result).foregroundStyle(.secondary) }
            }
        }
    }
}

struct ImageDropArea: View {
    @ObservedObject var toy: ImageResizerToy
    @State private var active = false
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(active ? Color.accentColor.opacity(0.1) : Color.clear)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                .foregroundStyle(active ? Color.accentColor : Color.secondary.opacity(0.4))
            VStack(spacing: 6) {
                Image(systemName: "photo.badge.arrow.down").font(.title2)
                Text("Bilder hierher ziehen oder auswählen").font(.caption)
            }
        }
        .frame(height: 64)
        .onDrop(of: [.fileURL], isTargeted: $active) { providers in
            var urls: [URL] = []
            let g = DispatchGroup()
            for p in providers {
                g.enter()
                p.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
                    defer { g.leave() }
                    if let data = item as? Data,
                       let u = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(u)
                    } else if let u = item as? URL {
                        urls.append(u)
                    } else if let s = item as? String, let u = URL(string: s) {
                        urls.append(u)
                    }
                }
            }
            g.notify(queue: .main) { toy.files.append(contentsOf: urls) }
            return true
        }
        .onTapGesture {
            let panel = NSOpenPanel()
            panel.allowedContentTypes = [UTType.png, UTType.jpeg, UTType.heic, UTType.tiff, UTType.image]
            panel.allowsMultipleSelection = true
            if panel.runModal() == .OK { toy.files.append(contentsOf: panel.urls) }
        }
    }
}
