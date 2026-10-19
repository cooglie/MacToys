# 🪟→🍎 Windows-Workflow-Migration

Von Windows auf den Mac gewechselt und vermisst deine Lieblings-Tools?
Diese Tabelle zeigt, womit du unter macOS das gleiche Workflow-Erlebnis bekommst —
entweder direkt mit **MacToys** oder mit nativen macOS-Mitteln.

## Schnellreferenz

| Windows-Tool | macOS-Äquivalent | Typ |
|---|---|---|
| **PowerToys** (gesamt) | **MacToys** | 🧰 MacToys |
| PowerToys Run | **Quick Launcher** (⌘Space) | 🧰 MacToys |
| PowerToys FancyZones | **Window Manager** | 🧰 MacToys |
| PowerToys PowerRename | **Power Rename** | 🧰 MacToys |
| PowerToys Color Picker | **Color Picker** (⌃⌥P) | 🧰 MacToys |
| PowerToys Text Extractor | **Text Extractor** (⌃⌥E) | 🧰 MacToys |
| PowerToys Always on Top | **Always on Top** (⌃⌥T) | 🧰 MacToys |
| PowerToys Image Resizer | **Image Resizer** | 🧰 MacToys |
| PowerToys Measure Tool | **Screen Ruler** (⌃⌥R) | 🧰 MacToys |
| PowerToys Awake | **Awake** | 🧰 MacToys |
| PowerToys Workspaces | **Workspaces** | 🧰 MacToys |
| PowerToys Keyboard Manager | **Keyboard Tools** | 🧰 MacToys |
| **AutoHotkey** | siehe unten | 🍎 macOS / 🧰 |
| **EarTrumpet** | macOS-Lautstärke-Mixer | 🍎 macOS |
| **WizTree / WizFile** | Spotlight / GrandPerspective | 🍎 macOS / 🧰 |
| Windows-Suche | **Desktop Search** / Spotlight | 🧰 / 🍎 |
| Windows-Schnellvorschau | **Quick Preview** / Quick Look | 🧰 / 🍎 |

Legende: 🧰 = in MacToys enthalten · 🍎 = nativ in macOS enthalten.

---

## 🔧 AutoHotkey → macOS

AutoHotkey ist auf Windows das Schweizer Taschenmesser für Automatisierung,
Textbausteine, Hotkeys und Window-Management. macOS hat kein direktes
Skript-Äquivalent mit identischer Syntax, aber mehrere Wege zum gleichen Ziel:

| AutoHotkey-Funktion | macOS-Lösung |
|---|---|
| Globale Hotkeys | **MacToys → Keyboard Tools** + Carbon-Hotkey-API; oder Systemeinstellungen → Tastatur → Tastaturkurzbefehle |
| Fenster verschieben/andocken | **MacToys → Window Manager** (FancyZones-Style) |
| Textbausteine / Auto-Ersetzung | macOS-Eingabe: *Systemeinstellungen → Tastatur → Text → Ersetzen* (z. B. `mfg` → `Mit freundlichen Grüßen`) |
| Skript-Automatisierung | **Shortcuts.app** (macOS-eigen), **AppleScript** / **JXA**, oder Shell-Skripte (zsh/bash) |
| Tasten-Mapping (z. B. Caps→Ctrl) | *Systemeinstellungen → Tastatur → Funktionstasten* / **Karabiner-Elements** (erweitert) |
| App-Starter / Schnellsuche | **MacToys → Quick Launcher** (⌘Space) |
| Always-on-Top | **MacToys → Always on Top** (⌃⌥T) |

**Tipp:** Für komplexe AutoHotkey-Skripte, die Text verarbeiten oder Apps
fernsteuern, ist **AppleScript** + **Shortcuts.app** die beste Kombination.
MacToys übernimmt dabei den Hotkey-Teil (globale Tastenkürzel + schnelle Aktionen).

---

## 🔊 EarTrumpet → macOS

EarTrumpet ersetzt auf Windows den Lautstärke-Mixer pro App. macOS hat das
*pro-App*-Mischen ab macOS 12 direkt im System integriert:

- **Per-App-Lautstärke:** *Systemeinstellungen → Ton →* beim Ausgabegerät auf
  die App-Liste klicken — jede App bekommt einen eigenen Regler.
- **Schneller Mixer:** Ton-Symbol in der Menüleiste zeigt aktive Audio-Apps
  mit Einzellautstärke.
- **Alternativ-Tool:** [**Background Music**](https://github.com/kyleneideck/background-music)
  (open source) für einen EarTrumpet-artigen Menüleisten-Mixer mit Auto-Pause.

MacToys selbst bietet keinen Audio-Mixer (macOS deckt das nativ ab), aber der
**Awake**-Toy verhindert zuverlässig den Schlaf während langer Audio-Sessions.

---

## 💾 WizTree / WizFile → macOS

WizTree/WizFile sind Festplatten-Analyse- und Datei-Suchtools. Auf dem Mac:

| Funktion | macOS-Äquivalent |
|---|---|
| Datei blitzschnell finden | **MacToys → Desktop Search** (Spotlight-Index, Typfilter) · oder nativ ⌘Space (Spotlight) |
| Speicherplatz-Analyse (Baum/Heatmap) | [**GrandPerspective**](https://grandperspectiv.sourceforge.net) (open source, Visualisierung) · [**OmniDiskSweeper**](https://www.omnigroup.com/more) (Liste nach Größe) |
| Große Dateien finden | Finder → *Ablage → Suchen* → Größenfilter · oder Speicher-Übersicht: * → Über diesen Mac → Speicher → Verwalten* |
| Duplikate finden | [**dupeGuru**](https://dupeguru.voltaicideas.net) (open source) |

**Empfehlung:** MacToys' **Desktop Search** für die tägliche Dateisuche (schnell,
typgefiltert), GrandPerspective für die einmalige Speicher-Visualisierung.

---

## 🪟 Windows-Suche → Desktop Search / Spotlight

- **MacToys → Desktop Search** — Spotlight-Anbindung mit Typfilter (Apps, Dokumente, Bilder …)
  und zentraler Palette.
- **Spotlight (⌘Space)** — nativ, deckt Apps, Dateien, Rechnen, Wörterbuch ab.
- **Quick Preview** — Datei-Vorschau per Leertaste (Quick Look), ohne die App zu öffnen.

---

## 🧰 PowerToys-Set → MacToys (1:1)

Die häufigsten PowerToys-Module haben direkte MacToys-Pendants:

| PowerToys-Modul | MacToys-Werkzeug | Hotkey |
|---|---|---|
| Run (App-Launcher) | Quick Launcher | ⌘Space |
| FancyZones (Window-Layouts) | Window Manager | — |
| PowerRename (Batch-Rename) | Power Rename | — |
| Color Picker | Color Picker | ⌃⌥P |
| Text Extractor (OCR) | Text Extractor | ⌃⌥E |
| Always on Top | Always on Top | ⌃⌥T |
| Image Resizer | Image Resizer | — |
| Measure Tool | Screen Ruler | ⌃⌥R |
| Awake (Sleep verhindern) | Awake | — |
| Workspaces (App-Gruppen) | Workspaces | — |
| Keyboard Manager | Keyboard Tools | — |

Module, die macOS bereits nativ anbietet (z. B. File Explorer-Addons über
Quick Look), werden nicht dupliziert — MacToys ergänzt nur, wo macOS Lücken hat.

---

## 🚀 Schnellstart für Umsteiger

1. **MacToys installieren** → [Releases](https://github.com/cooglie/MacToys/releases).
2. Im Dashboard die Werkzeuge aktivieren, die du auf Windows genutzt hast.
3. Berechtigungen erteilen (Bedienhilfen / Bildschirmaufnahme) — siehe README.
4. **Quick Launcher** auf ⌘Space legen (ersetzt PowerToys Run / Windows-Suche).
5. **Window Manager** für FancyZones-ähnliche Layouts konfigurieren.
6. Optional: **Background Music** (EarTrumpet-Alternative) + **GrandPerspective**
   (WizTree-Alternative) installieren — beides open source.

---

**MacToys — More power to your Mac.** Free forever. Open source by design.
