//
//  AwakeToy.swift
//  MacToys — Awake
//
//  Verhindert den automatischen Schlaf des Mac (Display + System) mittels
//  einer IOPMAssertion (DisplaySleep/DarkWake). Aktivierbar per Toggle.
//

import AppKit
import IOKit.pwr_mgt
import SwiftUI

final class AwakeToy: ObservableObject, Toy {

    let descriptor = ToyDescriptor(
        id: "awake",
        name: "Awake",
        tagline: "Verhindert den automatischen Schlaf — Display bleibt an.",
        symbol: "cup.and.saucer.fill",
        accent: "#FF9F0A",
        category: .system
    )

    @Published private(set) var isRunning = false

    private var assertionID: IOPMAssertionID = 0

    // MARK: - Toy Lifecycle

    func start() {
        guard !isRunning else { return }
        let reason: CFString = "MacToys — Awake hält den Mac wach." as CFString
        let assertionType: CFString = kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString
        let result = IOPMAssertionCreateWithName(
            assertionType,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        if result == kIOReturnSuccess {
            isRunning = true
            MacToysLog.info("Awake aktiviert (Assertion \(assertionID)).", category: "awake")
        } else {
            MacToysLog.warning("Awake: Assertion fehlgeschlagen (\(result)).", category: "awake")
        }
    }

    func stop() {
        if isRunning {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
            isRunning = false
            MacToysLog.info("Awake deaktiviert.", category: "awake")
        }
    }

    @MainActor
    func settingsView() -> AnyView {
        AnyView(AwakeSettingsView(toy: self))
    }
}

struct AwakeSettingsView: View {
    @ObservedObject var toy: AwakeToy

    var body: some View {
        Form {
            Section("Status") {
                HStack {
                    Image(systemName: toy.isRunning ? "moon.zzz.fill" : "moon.fill")
                        .foregroundStyle(toy.isRunning ? .green : .secondary)
                    Text(toy.isRunning ? "Schlaf verhindert — der Mac wacht nicht ab." : "Inaktiv — der Mac darf wie gewohnt schlafen.")
                    Spacer()
                }
            }
            Section("Hinweis") {
                Text("Solange Awake aktiv ist, wird der Bildschirm nicht automatisch gesperrt bzw. der Mac geht nicht in den Ruhezustand. Schalte es aus, sobald du es nicht mehr brauchst.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
