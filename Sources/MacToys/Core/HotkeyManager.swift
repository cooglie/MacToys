//
//  HotkeyManager.swift
//  MacToys
//
//  Verwaltung globaler Carbon-Hotkeys. Jedes Toy kann einen Hotkey registrieren;
//  die Registrierung liefert eine ID, mit der er wieder entfernt wird.
//

import Carbon.HIToolbox
import Foundation

/// Ein registrierbarer globaler Hotkey (Carbon-basiert).
struct HotkeyConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32     // cmdKey | shiftKey | optionKey | controlKey
    var label: String         // z. B. "⌃⌥←"

    static let none = HotkeyConfig(keyCode: 0, modifiers: 0, label: "—")
}

final class HotkeyManager {

    static let shared = HotkeyManager()

    private var nextID: UInt32 = 1
    private var registry: [UInt32: (ref: EventHotKeyRef, action: () -> Void)] = [:]
    private var handlerInstalled = false

    private init() {}

    // MARK: - Registrierung

    /// Registriert einen globalen Hotkey. Liefert eine ID oder nil bei Fehler/ungültig.
    @discardableResult
    func register(_ config: HotkeyConfig, action: @escaping () -> Void) -> UInt32? {
        guard config.keyCode != 0 || config.modifiers != 0 else { return nil }

        installHandlerIfNeeded()

        let id = nextID
        nextID += 1

        var ref: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D545853), // "MTXS"
                                     id: id)
        let err = RegisterEventHotKey(config.keyCode, config.modifiers, hotKeyID,
                                      GetApplicationEventTarget(), 0, &ref)
        guard err == noErr, let ref else {
            MacToysLog.warning("Hotkey-Registrierung fehlgeschlagen (\(config.label))", category: "hotkey")
            return nil
        }
        registry[id] = (ref, action)
        return id
    }

    func unregister(_ id: UInt32) {
        if let entry = registry.removeValue(forKey: id) {
            UnregisterEventHotKey(entry.ref)
        }
    }

    func unregisterAll() {
        for (_, entry) in registry {
            UnregisterEventHotKey(entry.ref)
        }
        registry.removeAll()
    }

    // MARK: - Carbon Event Handler

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        handlerInstalled = true

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, eventRef, userData in
                guard let userData else { return noErr }
                let me = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return me.handle(eventRef)
            },
            1,
            &eventSpec,
            selfPtr,
            nil
        )
    }

    private func handle(_ eventRef: EventRef?) -> OSStatus {
        guard let eventRef else { return noErr }
        // kEventDirectObject ('----') ist in Swift nicht gebrückt → literal.
        let kParamDirectObject: EventParamName = EventParamName(0x2D2D2D2D)
        var hotID = EventHotKeyID()
        let err = GetEventParameter(eventRef,
                                    kParamDirectObject,
                                    EventParamType(typeEventHotKeyID),
                                    nil,
                                    MemoryLayout<EventHotKeyID>.size,
                                    nil,
                                    &hotID)
        guard err == noErr else { return noErr }
        if let entry = registry[hotID.id] {
            DispatchQueue.main.async { entry.action() }
        }
        return noErr
    }
}
