# 🧰 MacToys

> **More power to your Mac.** Free forever. Open source by design.

MacToys ist eine kostenlose, quelloffene Sammlung produktiver macOS-Werkzeuge —
inspiriert von Microsoft PowerToys, aber von Grund auf nativ für macOS gebaut.
13 Werkzeuge: Fenster-Layouts, Quick Launcher, Power Rename, Color Picker, Text
Extractor (OCR), Always-on-Top, Image Resizer, Screen Ruler, Desktop Search,
Keyboard Tools, Awake, Workspaces und Quick Preview — alles in einer leichten,
nativen App.

## Kernprinzipien

- **100 % kostenlos** — jedes Feature für alle, ohne Abo oder Paywall.
- **Open Source** — öffentlicher Code, transparente Entwicklung, Community-Beiträge.
- **Nativ** — Swift/SwiftUI, Apple Silicon + Intel (Universal Binary), macOS 13+.
- **Privacy first** — Verarbeitung lokal, keine Konten, kein Telemetry.
- **Modular** — nur die Werkzeuge aktivieren, die man braucht.
- **Community driven** — Issues, Feature Requests, Pull Requests willkommen.

## Werkzeuge

| Werkzeug | Beschreibung | Hotkey |
|---|---|---|
| Window Manager | Fenster in benutzerdefinierte Layouts ordnen | — |
| Quick Launcher | Apps starten, rechnen, suchen (schwebende Palette) | ⌘Space |
| Power Rename | Batch-Umbenennung mit Suche/Ersetzen, Regex, Nummerierung | — |
| Color Picker | Bildschirmfarben sampeln, HEX/RGB/HSL kopieren | ⌃⌥P |
| Text Extractor | Text per OCR auswählen (Vision, de+en) | ⌃⌥E |
| Always on Top | Fenster über allen anderen halten | ⌃⌥T |
| Image Resizer | Bilder stapelweise skalieren/konvertieren (PNG/JPEG/HEIC) | — |
| Screen Ruler | Pixel-Messung auf dem Bildschirm | ⌃⌥R |
| Desktop Search | Dateien via Spotlight finden | — |
| Keyboard Tools | Tasten-Inspektor + zentrale Hotkey-Übersicht | — |
| Awake | Automatischen Schlaf verhindern | — |
| Workspaces | App-Gruppen-Profile starten | — |
| Quick Preview | Datei-Vorschau via Quick Look | — |

## Architektur

```
Sources/MacToys/
├── App/                     # @main, AppDelegate, Menüleisten-Item
├── Core/                    # Toy-Protokoll, Registry, Settings, Hotkeys, Permissions, Logger, Theme
├── UI/                      # Dashboard, Karten, Einstellungen (SwiftUI)
└── Toys/                    # Werkzeuge (jedes modular & eigenständig)
    └── WindowManager/       # Fenster-Layouts via Accessibility-API
```

Jedes Werkzeug implementiert das `Toy`-Protokoll und registriert sich beim Start
in der `ToyRegistry`. Aktivierbar/deaktivierbar vom Dashboard, mit eigenem Hotkey
und eigener Einstellungs-View.

## Build

```bash
cd MacToys
bash build.sh
```

Baut ein Universal Binary (arm64 + x86_64), verpackt es als `.app`, signiert
ad-hoc und legt es auf dem Desktop ab.

> **Hinweis:** Für den Window Manager benötigt MacToys die Berechtigung
> *Bedienhilfen* (Systemeinstellungen → Datenschutz & Sicherheit → Bedienhilfen).
> Die App fragt beim ersten Aktivieren automatisch danach.

## Lizenz

MIT — siehe [LICENSE](LICENSE).
