# The MCP server

The MCP server is one surface of the tool contract in [SKILL.md](../SKILL.md). It reuses the others: a tool call does what a CLI verb does.

```text
binary (install.sh, update)
  ├─ CLI verbs        people and scripts     --format json|human
  ├─ action.yml       CI
  ├─ skills/<tool>/   agents: when and how to use the tool
  └─ mcp serve        agents: call the tool
```

## Rules

| # | Rule |
|---|------|
| 1 | The server is a verb of the same binary: `<tool> mcp serve`. No second binary, no wrapper script. |
| 2 | stdio is the default transport and must always work. |
| 3 | A tool does what one CLI verb does and returns the JSON that verb prints with `--format json`. |
| 4 | Limits are flags of `mcp serve`. A caller cannot widen them in a call. |
| 5 | A failure the caller caused is a tool result with `isError: true`. It is never a protocol error. |
| 6 | stdout carries protocol messages only. Logs and progress go to stderr. |
| 7 | Every tool has annotations and a schema with no `$ref`. |

## Verbs

| Verb | Does |
|------|------|
| `<tool> mcp serve` | Serves the tools on stdio until stdin closes. |
| `<tool> mcp tools` | Prints what `tools/list` returns, as JSON on stdout. No client needed. |

`mcp` with no subcommand prints help. Do not make it start the server: a server that starts by accident blocks on stdin.

`mcp tools` exists because clients pin tools by schema hash. A person must be able to see the schema, and a test must be able to compare it, without a running client.

## Transport and library

| Language | Use | Reference |
|----------|-----|-----------|
| Go | `github.com/modelcontextprotocol/go-sdk` | `saige/cmd/saige-mcp/bridge.go` |
| Rust, stdio only, few tools | newline-delimited JSON-RPC on `serde_json` | `teasr/crates/teasr-cli/src/mcp.rs` |

- A hand-written server handles `initialize`, `ping`, `tools/list`, `tools/call`. It ignores every notification. It answers an unknown method with `-32601` and bad JSON with `-32700` and `id: null`.
- `initialize` echoes the client's `protocolVersion` when the server knows it. Otherwise it returns the newest version the server knows.
- Add HTTP only when a remote caller needs it. Then require a bearer token and refuse a non-loopback address without TLS, as `saige-mcp` does.

## Tools

- Few tools. One tool for one job. Start with one.
- `snake_case`, a verb or `verb_noun`: `capture`, `kg_search`, `eval_run`.
- Do not put the tool's own name in the tool name. Clients add the server name: `teasr__capture`.
- The description says what the tool returns, what it needs, and what the server refuses. A model reads nothing else.

### Input schema

- `type: object`, `additionalProperties: false` at the top, and a `description` on every property.
- No `$ref`, no `$defs`. Not every client resolves them. Repeat the fragment.
- Build the schema from the limits. If `--allow web` is set, the `type` enum lists only `web`. The model then cannot ask for what the server refuses.
- The schema must be the same bytes on every run with the same flags. Do not put a timestamp, a path, or a version in it.
- A schema change breaks every client that pinned the hash. Say so in the commit and the changelog.
- Parse arguments into a struct that rejects unknown fields. A typo then fails with the field name.

### Result

```json
{
  "content": [
    { "type": "text", "text": "<the same JSON as structuredContent, pretty-printed>" },
    { "type": "image", "data": "<base64>", "mimeType": "image/png" }
  ],
  "structuredContent": { "...": "the --format json document" },
  "isError": false
}
```

- Always send the text block. Older clients read only that.
- `structuredContent` is the `--format json` document of the matching CLI verb. One shape for scripts and agents.
- Paths in a result are absolute.
- Send an image only when the model must look at it. Cap the count and the size, and say the cap in the schema.
- `isError: true` when the call did not do the job: bad arguments, a refused request, every item failed. A partial result is not an error: report each failed item inside the document.

### Annotations

Set all four on every tool. A client uses them to decide what needs approval.

| Annotation | True when |
|------------|-----------|
| `readOnlyHint` | The tool changes nothing: no file, no network write, no state. |
| `destructiveHint` | The tool can delete or overwrite something that is not its own output. |
| `idempotentHint` | The same call twice leaves the same state as one call. |
| `openWorldHint` | The tool reaches something outside the machine, for example a URL. |

## Limits

A caller is a model that may have read hostile text. Decide what it may do when the server starts.

| Limit | Flag | Default |
|-------|------|---------|
| What kinds of work run | `--allow <kind,...>` | the safest kind only |
| No tool that writes | `--read-only` | off, for a tool that only reads |
| Which files may be read | `--root <dir>` | the working directory |
| Where output goes | `--output <dir>` | one new directory for each call |
| How long one call may run | `--timeout <ms>` | 60000 |

- Resolve symbolic links before the `--root` check. A link inside the root can point outside.
- A name that becomes a file name matches `^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`. No path separator can pass.
- Anything that runs a shell command or records the screen is off by default.
- Check the raw arguments against the limits before parsing the rest. A refused request must not be half read.
- Say in the README what the limits do not stop. The limits are not a sandbox.

## Tests

| Test | Proves |
|------|--------|
| Handler unit tests | Each refusal returns `isError` with a message that names the field. |
| Golden schema | `mcp tools` output equals a checked-in file. A schema change shows in the diff. |
| Protocol | A notification gets no reply. An unknown method and bad JSON get the right code. |
| Round trip | `initialize`, `tools/list`, `tools/call` over real stdio. Every stdout line parses as JSON. |

Run the round trip against a real client once before release. Go: `mcp.NewInMemoryTransports()` or `mcp.CommandTransport` from the go-sdk. A hand-written server most needs this test.

## Docs

- README: an `MCP Server` section with the `mcp serve` flags, the limits table, one example call, and this snippet:

```json
{ "mcpServers": { "<tool>": { "command": "<tool>", "args": ["mcp", "serve"] } } }
```

- `skills/<tool>/SKILL.md`: an `MCP Server` section with the same snippet.
- AGENTS.md: where the server code is, and that stdout is the transport.

## Checklist

- [ ] `<tool> mcp serve` runs on stdio; `<tool> mcp` alone prints help
- [ ] `<tool> mcp tools` prints the tool list as JSON
- [ ] Each tool returns the `--format json` document as text and as `structuredContent`
- [ ] Each tool has the four annotations
- [ ] The schema has no `$ref`, rejects unknown top-level fields, and is byte-stable
- [ ] Unsafe kinds are off by default; `--root` follows symbolic links before it checks
- [ ] No log line reaches stdout
- [ ] Unit, golden schema, protocol and round-trip tests pass

## Gotchas

- `echo` of progress to stdout breaks the client with a parse error that names no cause. Send every log to stderr, including the logging library's default writer.
- `serde_json` sorts object keys unless `preserve_order` is on, and Go's `encoding/json` sorts map keys. Any other map type can give a new schema hash on every run.
- A missing local file fails the `--root` check, because the check must resolve the path. Report it as "file not found", not as "outside the root".
- Do not register the server with a relative command path. Tools start it from their own working directory.
- A tool that starts a browser or a child process must stop it when the call times out.
