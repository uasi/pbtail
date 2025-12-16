import ArgumentParser
import Foundation

@main
private struct Pbtail: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "pbtail watches system clipboard and prints text content to stdout."
    )

    @OptionGroup(title: "OUTPUT FORMAT OPTIONS")
    var outputFormatOptions: OutputFormatOptions

    struct OutputFormatOptions: ParsableArguments {
        @Flag var value: OutputFormat = .newline
    }

    @OptionGroup(title: "OUTPUT MODE OPTIONS")
    var outputModeOptions: OutputModeOptions

    struct OutputModeOptions: ParsableArguments {
        @Flag var values: [OutputMode] = []
    }

    @Option(help: ArgumentHelp("Polling interval in milliseconds.", valueName: "msecs"))
    var pollingInterval: Int = 50

    mutating func run() async throws {
        let watcher = ClipboardWatcher(
            outputFormat: outputFormatOptions.value,
            outputModes: outputModeOptions.values,
            pollingInterval: pollingInterval
        )

        if outputModeOptions.values.contains(.printAndExit) {
            await watcher.echo()
            return
        }

        setSignalHandler(watcher: watcher)

        await watcher.watch()
    }
}

public enum OutputFormat: EnumerableFlag, Sendable {
    case newline
    case newlineAlways
    case nul
    case raw
    case json
    case jsonValue

    public static func name(for value: Self) -> NameSpecification {
        switch value {
        case .newline:
            return [.customShort("n"), .long]
        case .newlineAlways:
            return [.customShort("N"), .long]
        case .nul:
            return [.customShort("0"), .long]
        case .raw:
            return [.customShort("r"), .long]
        case .json:
            return [.customShort("j"), .long]
        case .jsonValue:
            return [.customShort("J"), .long]
        }
    }

    public static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .newline:
            return "Add newline if output doesn't already end with one."
        case .newlineAlways:
            return "Always add newline."
        case .nul:
            return "Use NUL character as terminator."
        case .raw:
            return "No terminator."
        case .json:
            return "Output as JSON with `{\"content\": string}`."
        case .jsonValue:
            return
                "Output as JSON with `{\"content\": string, \"value\": content parsed as JSON}`. (value is unset if content is not valid JSON)"
        }
    }
}

public enum OutputMode: EnumerableFlag, Sendable {
    case allowEmpty
    case dedupe
    case printInitialValue
    case printAndExit

    public static func name(for value: Self) -> NameSpecification {
        switch value {
        case .allowEmpty:
            return [.customShort("a"), .long]
        case .dedupe:
            return [.customShort("d"), .long]
        case .printInitialValue:
            return [.customShort("i"), .long]
        case .printAndExit:
            return [.customShort("1"), .long]
        }
    }

    public static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .allowEmpty:
            return
                "Print even when clipboard has no string representation. Without this, printing is skipped."
        case .dedupe:
            return "Skip printing if content is identical to the last printed content."
        case .printInitialValue:
            return "Print the initial clipboard value on startup."
        case .printAndExit:
            return "Print the clipboard value and exit immediately."
        }
    }
}

private func setSignalHandler(watcher: ClipboardWatcher) {
    signal(SIGINT, SIG_DFL)

    let source = DispatchSource.makeSignalSource(signal: SIGINT)

    source.setEventHandler {
        Task {
            await watcher.stop()
        }
    }
    source.resume()
}
