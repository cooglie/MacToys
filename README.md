# 🧰 MacToys

> **More power to your Mac.** Free forever. Open source by design.

MacToys ist eine kostenlose, quelloffene Sammlung produktiver macOS-Werkzeuge —
inspiriert von Microsoft PowerToys, aber von Grund auf nativ für macOS gebaut.
Fenster-Layouts, Quick Launcher, Power Rename, Color Picker, Text Extractor (OCR),
Always-on-Top, Image Resizer und mehr — alles in einer leichten, nativen App.

## Kernprinzipien

- **100 % kostenlos** — jedes Feature für alle, ohne Abo oder Paywall.
- **Open Source** — öffentlicher Code, transparente Entwicklung, Community-Beiträge.
- **Nativ** — Swift/SwiftUI, Apple Silicon + Intel (Universal Binary), macOS 13+.
- **Privacy first** — Verarbeitung lokal, keine Konten, kein Telemetry.
- **Modular** — nur die Werkzeuge aktivieren, die man braucht.
- **Community driven** — Issues, Feature Requests, Pull Requests willkommen.

## Geplante Werkzeuge

| Werkzeug | Status |
|---|---|
| Window Manager | ✅ Erster Anker |
| Quick Launcher | 🚧 geplant |
| Power Rename | 🚧 geplant |
| Color Picker | 🚧 geplant |
| Text Extractor (OCR) | 🚧 geplant |
| Always on Top | 🚧 geplant |
| Image Resizer | 🚧 geplant |
| Screen Ruler | 🚧 geplant |
| Desktop Search | 🚧 geplant |
| Keyboard Tools | 🚧 geplant |
| Awake | 🚧 geplant |
| Workspaces | 🚧 geplant |
| Quick Preview | 🚧 geplant |

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
