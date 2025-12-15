# pbtail

`pbtail` watches system clipboard and prints text content to stdout.

## Installation

```sh
swift build -c release
cp .build/release/pbtail /usr/local/bin/
```

Or download a prebuilt binary from <https://github.com/uasi/pbtail/releases>.

## Usage

```sh
pbtail [options]
```

### Output format options

- `-n, --newline` - Add newline if output doesn't already end with one. (default)
- `-N, --newline-always` - Always add newline.
- `-0, --nul` - Use NUL character as terminator.
- `-r, --raw` - No terminator.
- `-j, --json` - Output as JSON with `{"content": string}`.
- `-J, --json-value` - Output as JSON with `{"content": string, "value": content parsed as JSON}`. (value is unset if content is not valid JSON)

### Output mode options

- `-a, --allow-empty` - Print even when clipboard has no string representation. Without this, printing is skipped.
- `-d, --dedupe` - Skip printing if content is identical to the last printed content.
- `-i, --print-initial-value` - Print the initial clipboard value on startup.
- `-1, --print-and-exit` - Print the clipboard value and exit immediately.

### Other options

- `--polling-interval <msecs>` - Polling interval in milliseconds. (default: 50)

## Examples

Watch clipboard and print when it changes. Stops when user hits Ctrl+C:

```
$ pbtail
hello world
lorem ipsum
goodbye
^C
```

Print current clipboard as JSON and exit:

```
$ pbtail -1 -j
{"content":"hello world"}
```

Output as JSON with initial value, allowing empty content:

```
$ pbtail -a -i -j
{"content":"yawn"}
{"content":"hello world"}
{"content":""}
{"content":"lorem ipsum"}
{"content":"goodbye"}
^C
```
