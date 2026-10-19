//
//  WorkspacesToy.swift
//  MacToys — Workspaces
//
//  Startet Gruppen von Anwendungen für verschiedene Szenarien
//  (z. B. "Arbeit", "Kreativ", "Code"). Eigene, bearbeitbare Profile.
//

import AppKit
import SwiftUI

final class WorkspacesToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "workspaces",
        name: "Workspaces",
        tagline: "App-Gruppen für verschiedene Vorhaben mit einem Klick starten.",
        symbol: "square.stack.3d.up.fill",
        accent: "#30D158",
        category: .workflow
    )

    @Published private(set) var isRunning = false
    @Published var profiles: [Workspace] = []

    private let key = "mactoys.workspaces"

    func start() {
        isRunning = true
        load()
    }
    func stop() { isRunning = false }

    // MARK: - Profile

    func add(name: String, apps: [URL]) {
        profiles.append(Workspace(id: UUID(), name: name, apps: apps))
        save()
    }
    func remove(_ id: UUID) {
        profiles.removeAll { $0.id == id }
        save()
    }

    func launch(_ workspace: Workspace) {
        let config = NSWorkspace.OpenConfiguration()
        for url in workspace.apps {
            NSWorkspace.shared.openApplication(at: url, configuration: config)
        }
        MacToysLog.info("Workspace '\(workspace.name)' gestartet (\(workspace.apps.count) Apps).", category: "workspaces")
    }

    // MARK: - Persistenz

    private func save() {
        let arr: [[String: Any]] = profiles.map {
            ["id": $0.id.uuidString, "name": $0.name, "apps": $0.apps.map { $0.path }]
        }
        UserDefaults.standard.set(arr, forKey: key)
    }
    private func load() {
        guard let arr = UserDefaults.standard.array(forKey: key) as? [[String: Any]] else {
            profiles = defaultProfiles(); return
        }
        profiles = arr.compactMap { d in
            guard let idStr = d["id"] as? String, let id = UUID(uuidString: idStr),
                  let name = d["name"] as? String,
                  let paths = d["apps"] as? [String] else { return nil }
            return Workspace(id: id, name: name, apps: paths.map { URL(fileURLWithPath: $0) })
        }
        if profiles.isEmpty { profiles = defaultProfiles() }
    }

    private func defaultProfiles() -> [Workspace] {
        let safari = URL(fileURLWithPath: "/Applications/Safari.app")
        let mail = URL(fileURLWithPath: "/System/Applications/Mail.app")
        let notes = URL(fileURLWithPath: "/System/Applications/Notes.app")
        let calc = URL(fileURLWithPath: "/System/Applications/Calculator.app")
        let xcode = URL(fileURLWithPath: "/Applications/Xcode.app")
        let term = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
        return [
            Workspace(id: UUID(), name: "Arbeit", apps: [safari, mail, notes]),
            Workspace(id: UUID(), name: "Entwicklung", apps: [xcode, term, safari]),
            Workspace(id: UUID(), name: "Schnell", apps: [safari, calc]),
        ]
    }

    @MainActor
    func settingsView() -> AnyView { AnyView(WorkspacesView(toy: self)) }
}

struct Workspace: Identifiable, Hashable {
    let id: UUID
    var name: String
    var apps: [URL]
}

struct WorkspacesView: View {
    @ObservedObject var toy: WorkspacesToy
    @State private var newName = ""
    @State private var newApps: [URL] = []

    var body: some View {
        Form {
            Section("Profile") {
                if toy.profiles.isEmpty {
                    Text("Noch keine Workspaces.").foregroundStyle(.secondary)
                }
                ForEach(toy.profiles) { ws in
                    HStack {
                        Image(systemName: "square.stack.3d.up.fill").foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text(ws.name).font(.headline)
                            Text("\(ws.apps.count) Apps").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Starten") { toy.launch(ws) }
                        Button { toy.remove(ws.id) } label: { Image(systemName: "trash") }
                    }
                    .padding(.vertical, 2)
                }
            }
            Section("Neuer Workspace") {
                TextField("Name", text: $newName)
                HStack {
                    Button("Apps hinzufügen…") {
                        let panel = NSOpenPanel()
                        panel.allowedContentTypes = [.application]
                        panel.directoryURL = URL(fileURLWithPath: "/Applications")
                        panel.allowsMultipleSelection = true
                        if panel.runModal() == .OK { newApps.append(contentsOf: panel.urls) }
                    }
                    Text("\(newApps.count) ausgewählt").font(.caption).foregroundStyle(.secondary)
                }
                Button("Workspace anlegen") {
                    guard !newName.isEmpty, !newApps.isEmpty else { return }
                    toy.add(name: newName, apps: newApps)
                    newName = ""; newApps = []
                }
                .disabled(newName.isEmpty || newApps.isEmpty)
            }
        }
    }
}
