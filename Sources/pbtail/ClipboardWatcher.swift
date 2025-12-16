// SPDX-License-Identifier: 0BSD

import Foundation

import class Cocoa.NSPasteboard

public actor ClipboardWatcher: Sendable {
    private let outputFormat: OutputFormat
    private let outputModes: [OutputMode]
    private let pollingInterval: Int
    private let pasteboard: NSPasteboard

    private var changeCount: Int
    private var shouldKeepRunning = true
    private var lastContent: String?

    public init(
        pasteboard: NSPasteboard = .general,
        outputFormat: OutputFormat,
        outputModes: [OutputMode],
        pollingInterval: Int
    ) {
        self.outputFormat = outputFormat
        self.outputModes = outputModes
        self.pollingInterval = pollingInterval
        self.pasteboard = pasteboard
        self.changeCount = pasteboard.changeCount
        self.lastContent = nil
    }

    func watch() async {
        if outputModes.contains(.printInitialValue) {
            await echo()
        }

        while shouldKeepRunning {
            do {
                try await Task.sleep(nanoseconds: UInt64(pollingInterval) * 1_000_000)
            } catch {
                break
            }

            if changeCount != pasteboard.changeCount {
                changeCount = pasteboard.changeCount
                await echo()
            }
        }
    }

    func stop() {
        shouldKeepRunning = false
    }

    public func makeNextOutput() async -> String? {
        let content: String? =
            switch pasteboard.string(forType: .string) {
            case nil where outputModes.contains(.allowEmpty): ""
            case let content: content
            }

        guard let content = content else {
            lastContent = nil
            return nil
        }

        if outputModes.contains(.dedupe) && lastContent == content {
            return nil
        }

        lastContent = content

        return serialize(content, outputFormat: outputFormat)
    }

    func echo() async {
        guard let output = await makeNextOutput() else { return }
        let terminator = terminatorForOutput(output, outputFormat: outputFormat)

        print(output, terminator: terminator)
        fflush(stdout)
    }
}

public func serialize(_ content: String, outputFormat: OutputFormat) -> String {
    switch outputFormat {
    case .json, .jsonValue:
        var json: [String: Any] = ["content": content]

        if outputFormat == .jsonValue,
            let data = content.data(using: .utf8),
            let parsed = try? JSONSerialization.jsonObject(
                with: data, options: [.fragmentsAllowed])
        {
            json["value"] = parsed
        }

        let data = try! JSONSerialization.data(
            withJSONObject: json,
            options: [.sortedKeys, .withoutEscapingSlashes])

        return String(data: data, encoding: .utf8)!
    default:
        return content
    }
}

public func terminatorForOutput(_ output: String, outputFormat: OutputFormat) -> String {
    switch outputFormat {
    case .newline: output.hasSuffix("\n") ? "" : "\n"
    case .newlineAlways: "\n"
    case .nul: "\0"
    case .raw: ""
    case .json: "\n"
    case .jsonValue: "\n"
    }
}
