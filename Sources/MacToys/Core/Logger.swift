//
//  Logger.swift
//  MacToys
//
//  Leichter Logger mit Kategorie-Tag. Schreibt nach os_log (System-Console)
//  und hält die Ausgabe in Xcode/Console.app sichtbar.
//

import Foundation
import os

enum LogLevel: Int { case debug, info, warning, error }

enum MacToysLog {
    static let log = OSLog(subsystem: "local.mactoys.app", category: "app")

    static func debug(_ msg: String, category: String = "core") {
        write(.debug, msg, category: category)
    }
    static func info(_ msg: String, category: String = "core") {
        write(.info, msg, category: category)
    }
    static func warning(_ msg: String, category: String = "core") {
        write(.warning, msg, category: category)
    }
    static func error(_ msg: String, category: String = "core") {
        write(.error, msg, category: category)
    }

    private static func write(_ level: LogLevel, _ msg: String, category: String) {
        let prefix: String
        switch level {
        case .debug:   prefix = "🐛"
        case .info:    prefix = "ℹ️"
        case .warning: prefix = "⚠️"
        case .error:   prefix = "❌"
        }
        let line = "[MacToys:\(category)] \(prefix) \(msg)"
        let type: OSLogType
        switch level {
        case .debug:   type = .debug
        case .info:    type = .info
        case .warning: type = .default
        case .error:   type = .error
        }
        os_log("%{public}@", log: log, type: type, line)
    }
}
