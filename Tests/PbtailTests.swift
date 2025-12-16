import Testing
import pbtail

import class Cocoa.NSPasteboard

func uniquePasteboardAndName() -> (NSPasteboard, NSPasteboard.Name) {
    let pasteboard = NSPasteboard.withUniqueName()
    return (pasteboard, pasteboard.name)
}

@Suite
struct ClipboardWatcherTests {
    @Test("pbtail (with string)")
    func withString() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.setString("hello", forType: .string)

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [],
            pollingInterval: 50
        )

        let output = await watcher.makeNextOutput()
        #expect(output == "hello")
    }

    @Test("pbtail (with empty string)")
    func withEmptyString() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.setString("", forType: .string)

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [],
            pollingInterval: 50
        )

        let output = await watcher.makeNextOutput()
        #expect(output == "")
    }

    @Test("pbtail (without content)")
    func withoutContent() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.clearContents()

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [],
            pollingInterval: 50
        )

        let output = await watcher.makeNextOutput()
        #expect(output == nil)
    }

    @Test("pbtail --allow-empty (without content)")
    func withoutContentAllowingEmpty() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.clearContents()

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [.allowEmpty],
            pollingInterval: 50
        )

        let output = await watcher.makeNextOutput()
        #expect(output == "")
    }

    @Test("pbtail (with duplicated string)")
    func withDuplicatedString() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.setString("hello", forType: .string)

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [],
            pollingInterval: 50
        )

        let output1 = await watcher.makeNextOutput()
        NSPasteboard(name: name).setString("hello", forType: .string)
        let output2 = await watcher.makeNextOutput()

        #expect(output1 == "hello")
        #expect(output2 == "hello")
    }

    @Test("pbtail --dedupe (with duplicated string)")
    func dedupeWithDuplicatedString() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.setString("hello", forType: .string)

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [.dedupe],
            pollingInterval: 50
        )

        let output1 = await watcher.makeNextOutput()
        NSPasteboard(name: name).setString("hello", forType: .string)
        let output2 = await watcher.makeNextOutput()

        #expect(output1 == "hello")
        #expect(output2 == nil)
    }

    @Test("pbtail --dedupe (with different string)")
    func dedupeWithDifferentString() async {
        let (pasteboard, name) = uniquePasteboardAndName()
        defer { NSPasteboard(name: name).releaseGlobally() }

        pasteboard.setString("hello", forType: .string)

        let watcher = ClipboardWatcher(
            pasteboard: pasteboard,
            outputFormat: .raw,
            outputModes: [.dedupe],
            pollingInterval: 50
        )

        let output1 = await watcher.makeNextOutput()
        NSPasteboard(name: name).setString("world", forType: .string)
        let output2 = await watcher.makeNextOutput()

        #expect(output1 == "hello")
        #expect(output2 == "world")
    }
}

@Suite
struct SerializeTests {
    @Test(arguments: [.newline, .newlineAlways, .nul, .raw] as [OutputFormat])
    func plainText(_ outputFormat: OutputFormat) {
        let result = serialize("hello world", outputFormat: outputFormat)
        #expect(result == "hello world")
    }

    @Test
    func json() {
        let result = serialize("hello", outputFormat: .json)
        #expect(result == #"{"content":"hello"}"#)
    }

    @Test
    func jsonWithSpecialChars() {
        let result = serialize(#"I said "hello world""#, outputFormat: .json)
        #expect(result.contains(#"{"content":"I said \"hello world\""}"#))
    }

    @Test
    func jsonValueWithValidJSON() {
        let result = serialize(#"{"key":"value"}"#, outputFormat: .jsonValue)
        #expect(result == #"{"content":"{\"key\":\"value\"}","value":{"key":"value"}}"#)
    }

    @Test
    func jsonValueWithInvalidJSON() {
        let result = serialize("not json", outputFormat: .jsonValue)
        #expect(result == #"{"content":"not json"}"#)
    }
}

@Suite
struct TerminatorForOutputTests {
    @Test
    func newline() {
        let terminator1 = terminatorForOutput("hello", outputFormat: .newline)
        let terminator2 = terminatorForOutput("hello\n", outputFormat: .newline)
        #expect(terminator1 == "\n")
        #expect(terminator2 == "")
    }

    @Test
    func newlineAlways() {
        let terminator1 = terminatorForOutput("hello", outputFormat: .newlineAlways)
        let terminator2 = terminatorForOutput("hello\n", outputFormat: .newlineAlways)
        #expect(terminator1 == "\n")
        #expect(terminator2 == "\n")
    }

    @Test
    func nul() {
        let terminator1 = terminatorForOutput("hello", outputFormat: .nul)
        let terminator2 = terminatorForOutput("hello\0", outputFormat: .nul)
        #expect(terminator1 == "\0")
        #expect(terminator2 == "\0")
    }

    @Test
    func raw() {
        let terminator = terminatorForOutput("hello", outputFormat: .raw)
        #expect(terminator == "")
    }

    @Test
    func json() {
        let terminator = terminatorForOutput("{\"content\":\"hello\"}", outputFormat: .json)
        #expect(terminator == "\n")
    }

    @Test
    func jsonValue() {
        let terminator = terminatorForOutput(
            "{\"content\":\"hello\"}", outputFormat: .jsonValue)
        #expect(terminator == "\n")
    }
}
