# Mitwirken bei MacToys

Danke, dass du MacToys mitgestalten möchtest! 🙌

## Grundregeln

- **Kostenlos & offen** — keine bezahlten Features, keine Locks. Jeder Beitrag
  bleibt frei und quelloffen.
- **Nativ** — Swift/SwiftUI, macOS-First. Keine Embed- oder Web-Wrapper.
- **Lokal & privat** — keine Pflichtkonten, kein Telemetry, keine Cloud-Aufrufe
  wo lokale APIs genügen.
- **Modular** — jedes Werkzeug in `Sources/MacToys/Toys/<Name>/`, implementiert
  das `Toy`-Protokoll und registriert sich selbst in `ToyRegistry`.

## Neues Werkzeug hinzufügen

1. Neuer Ordner `Sources/MacToys/Toys/MeinToy/`.
2. Ein `MeinToy.swift` mit `Toy`-Konformität (id, name, icon, isEnabled,
   settings view, activate/deactivate).
3. In `ToyRegistry.bootstrap` registrieren.
4. Übersetzungen/Kommentare auf Deutsch (wie der Rest des Projekts).
5. In der README-Tabelle eintragen.

## Build & Test

```bash
bash build.sh        # Universal Binary, .app auf den Desktop
```

Stelle sicher, dass der Build ohne Warnungen durchläuft.

## Commits

- Konventional-Commits (`feat:`, `fix:`, `docs:`, `refactor:` …).
- Kleine, fokussierte Pull Requests.
- Beschreibe *warum*, nicht nur *was*.
