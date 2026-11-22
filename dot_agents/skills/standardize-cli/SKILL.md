---
name: standardize-cli
description: >
  Make a CLI tool meet the tool contract, so every tool is installed, set up, updated
  and used by agents the same way: the standard verbs (init, update, version,
  completions, doctor, bootstrap, mcp serve, mcp tools), the skill bundled in the
  binary, the MCP server, and the README lines that go with them. Includes a script
  that audits a tool against the contract. Use when creating a new CLI, adding a verb,
  a skill or an MCP server to one, checking why a tool does not behave like the
  others, or when the user mentions "bootstrap", "mcp serve", "tool contract",
  "standard verbs", or "same way as the other tools". Loads on top of build-cli,
  which owns how to implement output, --format, self-update and install.sh. Do NOT
  use to register or debug someone else's MCP server (use agentspec-usage), to write
  the skill's prose (use create-oss-skill), or for README structure (use write-readme).
allowed-tools: Read, Grep, Glob, Edit, Write, Bash(cargo *), Bash(go *), Bash(git *), Bash(agentspec *), Bash(jq *), Bash(sh *audit-cli.sh *)
user-invocable: true
metadata:
  title: Standardize CLI
  category: development
  order: 4
---

# Standardize CLI

A tool is one binary with the same surfaces as every other tool. A person or an agent who knows one tool can then guess the commands of the next.

```text
install.sh ──> binary
                 ├─ verbs          init, <domain>, update, version, completions, doctor
                 ├─ --format json  the same document for scripts, CI and agents
                 ├─ action.yml     CI
                 ├─ skill          bundled in the binary, installed by `bootstrap`
                 └─ mcp serve      agents call the tool; registered by `bootstrap`
```

## Audit first

Run the audit before you change a tool, and again when you finish.

```sh
sh "${CLAUDE_SKILL_DIR:-$HOME/.agents/skills/standardize-cli}/scripts/audit-cli.sh" <binary> <repo-dir>
sh ".../audit-cli.sh" <binary> <repo-dir> --format json | jq '.checks[] | select(.result == "fail")'
```

It runs the binary only with `--help`, `--version`, `version` and `mcp tools`. Exit code 0 means every required check passed.

## The verbs

One name for one job. A synonym is a defect: `setup`, `upgrade`, `completion`.

| Verb | Required | Job |
|------|----------|-----|
| `init` | when the tool reads a config file | Write the config file |
| the domain verb | yes | The tool's main job: `run`, `generate`, `release` |
| `update` | yes | Update the binary itself |
| `version` and `--version` | yes, both | Print the version |
| `completions <shell>` | no | Print shell completions on stdout |
| `doctor` | when the tool needs other programs | Check that the tool can work here |
| `bootstrap` | yes | Install the bundled skill; register the MCP server |
| `mcp serve`, `mcp tools` | when agents call the tool | Serve the tool over MCP |

Every verb that prints data accepts `--format json` and then prints one JSON document on stdout. Human text goes to stderr. `build-cli` owns that rule.

### `init`

- Write `<tool>.toml` or `<tool>.yaml` in the working directory and print its path.
- Refuse to overwrite an existing file. `--force` overwrites.
- The file it writes must pass the tool's own validation with no edit.
- Offer named templates with a positional argument and `--list`, as `sr init` does.
- Never ask a question when stdin is not a terminal.

### `update`

- Replace the binary with the latest GitHub release. `build-cli` has the code.
- Exit 0 when already current, and say so.
- With `--format json`, print `{"from": "...", "to": "...", "updated": true}`.
- Use `self-update` only when `update` already means something else in the tool, as in `dotfiles`.

### `version`

- `<tool> version` prints `<tool> v<version>` on stdout. `<tool> --version` works too.
- With `--format json`, print `{"name": "<tool>", "version": "<version>"}`.
- A build with no version (`dev`, `unknown`) is a release defect. Inject the version at build time.

### `doctor`

- Check each thing the tool needs: a program on `PATH`, a browser, a font, a token.
- Check the agent surface too: the installed skill matches this binary, and the MCP server is registered.
- Print one line for each check, with the command that fixes a failed one.
- Exit 1 when a required check fails. With `--format json`, print `{"checks": [{"id", "ok", "detail", "fix"}]}`.
- Do not install anything. `doctor` reads; `bootstrap` and `init` write.

### `bootstrap`

`bootstrap` makes a fresh install usable by agents with one command. The skill ships inside the binary, so the skill and the binary always have the same version.

1. Embed `skills/<tool>/SKILL.md` in the binary at build time: `include_str!` in Rust, `embed` in Go.
2. Write it to `~/.agents/skills/<tool>/SKILL.md`. Overwrite a copy that an earlier `bootstrap` wrote. Keep a same-named skill the user wrote, unless `--force` is set.
3. Run `agentspec manage add ~/.agents/skills/<tool> --all-tools`.
4. If the tool serves MCP, run `agentspec mcp add <tool> --command <tool> --args "mcp serve"`.
5. If `agentspec` is not on `PATH`, print those commands and the JSON snippet, and exit 0.

`bootstrap` is idempotent and takes `--force` and `--dry-run`. Reference for steps 1 and 2: `agentspec/crates/agentspec/src/ops/bootstrap.rs`.

## The bundled skill

- One skill is named after the binary: `skills/<tool>/SKILL.md`. It is the usage skill, and it is the one `bootstrap` installs.
- It tells an agent when to use the tool, the verbs, the `--format json` shapes, and the gotchas. It does not repeat `--help`.
- A tool can ship more skills beside it, for example `skills/<tool>-dev/` for people who change the tool. `bootstrap` does not install those.
- Change the skill in the same pull request as the behaviour it describes.
- `create-oss-skill` owns how to write it.

## The MCP server

Read [references/mcp-server.md](references/mcp-server.md) before you add or review one. In short:

- `<tool> mcp serve` on stdio, in the same binary. `<tool> mcp tools` prints the tool list.
- A tool call does what one CLI verb does and returns that verb's `--format json` document.
- Limits are flags of `mcp serve`. Unsafe work is off by default.
- A failure the caller caused is a tool result with `isError`, not a protocol error.

## README lines

`write-readme` owns the structure. The contract needs these lines to exist:

| Section | Must show |
|---------|-----------|
| Installation | the `install.sh` one-liner |
| Quick Start | `<tool> init`, then the domain verb |
| Agent Skill | `<tool> bootstrap`, and what it installs |
| MCP Server | the `mcp serve` flags and the client snippet, when the tool serves MCP |

"Once installed, use `/<tool>`" with no install command is the defect this section prevents.

## Workflow

- [ ] Run the audit and read every `FAIL`
- [ ] Add or rename verbs. Keep an old name as a hidden alias for one release when people use it
- [ ] Make each verb honour `--format json`
- [ ] Move the usage skill to `skills/<tool>/` and embed it
- [ ] Add `bootstrap`, then `doctor` when the tool needs other programs
- [ ] Add the MCP server when agents call the tool
- [ ] Update the README lines and the skill
- [ ] Run the audit again: exit code 0

## Who owns what

| Topic | Skill |
|-------|-------|
| The contract: which verbs and surfaces exist, and what each must do | `standardize-cli` |
| How to implement output, `--format`, self-update, `install.sh` | `build-cli` |
| Project files, CI and the release pipeline | `scaffold-<lang>`, `sync-release` |
| README structure | `write-readme` |
| Writing a skill | `create-oss-skill` |
| Registering a server or a skill in AI tools | `agentspec-usage` |

## Gotchas

- A verb name that is already taken changes the rule, not the name. `agentspec mcp` manages other servers, so `agentspec` would serve with `agentspec mcp serve` beside `mcp add`.
- Do not start the server from bare `<tool> mcp`. Print help. A server started by accident blocks on stdin.
- Some argument parsers print the long help layout for every flag when one enum value has a doc comment. Check `--help` after you add `--format`.
- The logging library can write to stdout by default. Point it at stderr, or `--format json` and `mcp serve` both break.
- An installer that skips a tool because the binary exists never updates it. The update path is `<tool> update`.
