# 🧰 MacToys

> **More power to your Mac.** Free forever. Open source by design.

[![Release](https://img.shields.io/github/v/release/cooglie/MacToys?label=Release)](https://github.com/cooglie/MacToys/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://github.com/cooglie/MacToys/blob/main/LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2012%2B-blue)](https://github.com/cooglie/MacToys)
[![Architecture](https://img.shields.io/badge/Arch-Universal%20%28arm64%20%2B%20x86__64%29-green)](https://github.com/cooglie/MacToys)

MacToys ist eine kostenlose, quelloffene Sammlung produktiver macOS-Werkzeuge —
inspiriert von Microsoft PowerToys, aber von Grund auf nativ für macOS gebaut.
13 Werkzeuge in einer leichten, nativen App: Fenster-Layouts, Quick Launcher,
Power Rename, Color Picker, Text Extractor (OCR), Always-on-Top, Image Resizer,
Screen Ruler, Desktop Search, Keyboard Tools, Awake, Workspaces und Quick Preview.

## Kernprinzipien

- **100 % kostenlos** — jedes Feature für alle, ohne Abo oder Paywall.
- **Open Source** — öffentlicher Code, transparente Entwicklung, Community-Beiträge.
- **Nativ** — Swift/SwiftUI, Apple Silicon + Intel (Universal Binary), macOS 12.0+.
- **Privacy first** — Verarbeitung lokal, keine Konten, kein Telemetry.
- **Modular** — nur die Werkzeuge aktivieren, die man braucht.
- **Community driven** — Issues, Feature Requests, Pull Requests willkommen.

## 📥 Download & Installation

### Fertiger Build (empfohlen)

1. **Download:** [MacToys-v1.0.0.zip](https://github.com/cooglie/MacToys/releases/download/v1.0.0/MacToys-v1.0.0.zip)
   von der [Releases-Seite](https://github.com/cooglie/MacToys/releases).
2. Zip entpacken → `MacToys.app` in den `Programme`-Ordner verschieben.
3. Beim ersten Start: *Systemeinstellungen → Datenschutz & Sicherheit →*
   MacToys erlauben (ad-hoc-signiert).
4. Für bestimmte Werkzeuge (siehe unten) **Bedienhilfen** und/oder
   **Bildschirmaufnahme** aktivieren.

### Selber bauen

```bash
git clone https://github.com/cooglie/MacToys.git
cd MacToys
bash build.sh
```

`build.sh` baut ein Universal Binary (arm64 + x86_64), verpackt es als `.app`,
signiert ad-hoc und legt es auf dem Desktop ab.

## 🔧 Werkzeuge

| Werkzeug | Beschreibung | Hotkey |
|---|---|---|
| **Window Manager** | Fenster in benutzerdefinierte Layouts ordnen (Accessibility-API) | — |
| **Quick Launcher** | Apps starten, rechnen, suchen — schwebende Palette | ⌘Space |
| **Power Rename** | Batch-Umbenennung: Suche/Ersetzen, Regex, Nummerierung, Case | — |
| **Color Picker** | Bildschirmfarben sampeln, HEX/RGB/HSL kopieren, Verlauf | ⌃⌥P |
| **Text Extractor** | Text per OCR auswählen (Vision-Framework, de + en), Auto-Copy | ⌃⌥E |
| **Always on Top** | Fenster über allen anderen halten | ⌃⌥T |
| **Image Resizer** | Bilder stapelweise skalieren/konvertieren (PNG/JPEG/HEIC) | — |
| **Screen Ruler** | Pixel-Messung auf dem Bildschirm, Copy | ⌃⌥R |
| **Desktop Search** | Dateien via Spotlight finden (Typfilter) | — |
| **Keyboard Tools** | Tasten-Inspektor + zentrale Hotkey-Übersicht aller Werkzeuge | — |
| **Awake** | Automatischen Schlaf verhindern (DisplaySleep) | — |
| **Workspaces** | App-Gruppen-Profile starten | — |
| **Quick Preview** | Datei-Vorschau via Quick Look | — |

## 🔐 Berechtigungen

Einige Werkzeuge benötigen macOS-Berechtigungen, um systemweit zu funktionieren.
Die App fragt beim ersten Aktivieren automatisch danach.

| Werkzeug | Bedienhilfen | Bildschirmaufnahme |
|---|:---:|:---:|
| Window Manager | ✅ | |
| Always on Top | ✅ | |
| Text Extractor | ✅ | ✅ |
| Screen Ruler | ✅ | ✅ |
| Color Picker | | |

*Systemeinstellungen → Datenschutz & Sicherheit → Bedienhilfen / Bildschirmaufnahme → MacToys aktivieren.*

## 🏗️ Architektur

```
Sources/MacToys/
├── App/                         # @main, AppDelegate, Menüleisten-Item (LSUIElement)
│   ├── main.swift
│   └── AppDelegate.swift
├── Core/                        # Toy-Protokoll, Registry, Settings, Hotkeys, Permissions, Logger
│   ├── Toy.swift                # Das Protokoll, das jedes Werkzeug implementiert
│   ├── ToyRegistry.swift        # bootstrap() — ein register(...) pro Werkzeug
│   ├── HotkeyManager.swift      # Globale Tastenkürzel (Carbon HotKey-API)
│   ├── AppSettings.swift        # UserDefaults-Wrapper
│   ├── Permissions.swift        # Bedienhilfen-/Aufnahme-Checks
│   └── Logger.swift
├── UI/                          # SwiftUI-Dashboard, Karten, Einstellungen, Theme
│   ├── DashboardView.swift
│   ├── ToyCard.swift
│   ├── SettingsView.swift
│   └── Theme.swift
└── Toys/                        # Werkzeuge (jedes modular & eigenständig)
    ├── WindowManager/           # Fenster-Layouts via Accessibility-API
    ├── QuickLauncher/           # Schwebende Palette (⌘Space)
    ├── PowerRename/             # Batch-Rename: Regex, Nummerierung, Case
    ├── ColorPicker/             # NSColorSampler, HEX/RGB/HSL
    ├── TextExtractor/           # Vision OCR + Rechteck-Auswahl-Overlay
    ├── AlwaysOnTop/             # AX-Raise-Polling
    ├── ImageResizer/            # ImageIO / CGImageDestination
    ├── ScreenRuler/             # Vollbild-Overlay mit Live-Maßanzeige
    ├── DesktopSearch/           # NSMetadataQuery (Spotlight)
    ├── KeyboardTools/           # Tasten-Inspektor + Hotkey-Übersicht
    ├── Awake/                   # IOPMAssertion (DisplaySleep)
    ├── Workspaces/              # App-Gruppen-Profile
    └── QuickPreview/            # QLPreviewPanel
```

Jedes Werkzeug implementiert das `Toy`-Protokoll (`descriptor`, `isRunning`,
`status`, `start`/`stop`, `settingsView`) und registriert sich beim App-Start
in `ToyRegistry.bootstrap()` — eine Zeile pro Werkzeug. Vom Dashboard aus
aktivierbar/deaktivierbar, mit eigenem Hotkey und eigener Einstellungs-View.

**Ein neues Werkzeug hinzufügen** = ein Ordner unter `Toys/` + eine
`register(...)`-Zeile in `ToyRegistry.bootstrap()`. Siehe
[`CONTRIBUTING.md`](CONTRIBUTING.md) für Details.

## 🧪 Technisches

- **Sprache:** Swift 5, SwiftUI + AppKit.
- **Frameworks:** AppKit, SwiftUI, Vision, Quartz (Quick Look), IOKit (PM),
  UniformTypeIdentifiers, Carbon (Hotkeys).
- **Deployment Target:** macOS 12.0.
- **Architekturen:** arm64 + x86_64 (Universal Binary).
- **Signierung:** Ad-hoc (für eigene Builds via `build.sh`).
- **Privatsphäre:** 100 % lokal — keine Konten, kein Telemetry, keine Cloud.

## 🤝 Beitragen

Contributions sind willkommen! Siehe [`CONTRIBUTING.md`](CONTRIBUTING.md).

- 🐛 **Bug melden:** [Issues](https://github.com/cooglie/MacToys/issues)
- 💡 **Feature vorschlagen:** [Issues](https://github.com/cooglie/MacToys/issues)
- 🔧 **Code beisteuern:** [Pull Requests](https://github.com/cooglie/MacToys/pulls)

## 📄 Lizenz

MIT — siehe [LICENSE](LICENSE).

---

**MacToys — More power to your Mac.**

Free forever. Open source by design.
