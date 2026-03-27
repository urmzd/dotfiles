---
name: test-code
description: >
  Testing philosophy, test types, per-language conventions, file organization,
  fixtures/mocks, CI strategy, and what NOT to test. Use when writing tests,
  reviewing test coverage, setting up test infrastructure, or deciding what to test.
allowed-tools: Read Grep Glob Bash Edit Write
metadata:
  title: Testing Practices
  category: development
  order: 5
---

# Testing Practices

## Philosophy

Test your software, or your users will.

- **Test against contracts, not implementations** — assert what it should do, not how it does it. Tests that break on every refactor are coupling to internals.
- **State coverage > line coverage** — exercise meaningful paths and edge cases, not just lines. We intentionally use no coverage tools — percentage targets create false confidence.
- **Tests are the first users of your API** — if tests are hard to write, the design is wrong. Refactor the interface, not the test.
- **Property-based testing finds edges you didn't think of** — complement example-based tests with fuzz and property tests where the input space is large.
- **Tests should be boring** — a test that's hard to read is a test nobody trusts. Inline data, obvious assertions, no clever abstractions.

See `review-design` for the underlying Pragmatic Programmer principles (design by contract, pragmatic paranoia).

## Test Types

| Type | What It Verifies | When to Use | Codebase Example |
|------|-----------------|-------------|------------------|
| **Unit** | Single function/module in isolation | Always. Every public function. | `sr/crates/sr-core/src/version.rs` — `#[cfg(test)] mod tests` |
| **Integration** | Multiple modules working together | Cross-layer interactions, real I/O | `sr/crates/sr-git/tests/integration.rs` — TempDir + real git CLI |
| **Snapshot/Golden** | Output hasn't changed unexpectedly | Templates, code generation, formatters | `incipit/generators/golden_test.go` — `-update` flag to regenerate |
| **Fuzz** | No panics/crashes on arbitrary input | Parsers, deserializers, sanitizers | `incipit/resume/adapter_fuzz_test.go` — Go native `testing.F` |
| **Property-based** | Invariants hold for generated inputs | Mathematical properties, roundtrip encode/decode | Use `proptest` (Rust), `testing/quick` (Go), `hypothesis` (Python) |
| **Benchmark** | Performance characteristics | Hot paths, algorithms, throughput | `linear-gp/crates/lgp/benches/` — criterion framework |
| **Smoke** | Basic environment sanity | CI gate, post-deploy check | `linear-gp/crates/lgp/tests/smoke_tests.rs` — 2 generations, no crash |
| **E2E** | Full system from user perspective | Critical user flows | `teasr` CI — real Chrome + xvfb-run dogfood |

### Golden File Pattern (Go)

```go
var update = flag.Bool("update", false, "update golden files")

func TestGolden(t *testing.T) {
    got := generate(input)
    golden := filepath.Join("testdata", "golden", name)
    if *update {
        os.WriteFile(golden, got, 0644)
        return
    }
    want, _ := os.ReadFile(golden)
    if diff := cmp.Diff(string(want), string(got)); diff != "" {
        t.Errorf("mismatch (-want +got):\n%s", diff)
    }
}
```

Run `go test -update ./...` to regenerate, then commit the diffs.

### Fuzz Pattern (Go)

```go
func FuzzParseInput(f *testing.F) {
    // Seed corpus: valid, empty, edge cases
    f.Add([]byte(`{"name": "Jane"}`))
    f.Add([]byte(`{}`))
    f.Add([]byte(``))

    f.Fuzz(func(t *testing.T, data []byte) {
        // Should never panic — errors are fine
        _, _ = ParseInput(data)
    })
}
```

CI: `go test -fuzz=FuzzParseInput -fuzztime=10s -timeout=60s ./...`

### Benchmark Pattern (Rust)

```rust
use criterion::{criterion_group, criterion_main, Criterion};

fn bench_transform(c: &mut Criterion) {
    let input = load_fixture();
    c.bench_function("transform", |b| {
        b.iter(|| transform(&input))
    });
}

criterion_group!(benches, bench_transform);
criterion_main!(benches);
```

Place in `benches/` directory. Run with `cargo bench`.

## Per-Language Conventions

### Rust

| Aspect | Convention |
|--------|-----------|
| Framework | `cargo test` (built-in) |
| Unit tests | `#[cfg(test)] mod tests` inline with source |
| Integration | `tests/*.rs` (separate binary, full crate access) |
| Benchmarks | `benches/*.rs` with `criterion` crate |
| Assertions | `assert_eq!`, `assert!(matches!(...))`, `assert!(result.is_err())` |
| Error testing | `#[should_panic(expected = "message")]` or match on `Result::Err` |
| CI command | `cargo test --workspace` |
| Async tests | `#[tokio::test]` attribute |

Fixtures: `tempfile::TempDir` for filesystem tests (drops on scope exit). `include_str!()` for static test data.

### Go

| Aspect | Convention |
|--------|-----------|
| Framework | `go test` (built-in) |
| Unit tests | `*_test.go` co-located with source |
| Table-driven | `[]struct{name string; input X; want Y}` + `t.Run(tt.name, ...)` |
| Fuzz tests | `Fuzz*` functions with `testing.F` (Go 1.18+) |
| Benchmarks | `Benchmark*` functions with `testing.B` |
| Golden files | `testdata/golden/` with `-update` flag |
| CI command | `go test ./...` |
| Parallel | `t.Parallel()` at top of each independent test |

Fixtures: `t.TempDir()` for temp directories (auto-cleanup). `testdata/` for static files (ignored by Go toolchain).

### Python

| Aspect | Convention |
|--------|-----------|
| Framework | `pytest` |
| Test files | `tests/test_*.py` |
| Parametrize | `@pytest.mark.parametrize("name", [...])` |
| Fixtures | `@pytest.fixture` in `conftest.py` |
| Assertions | Plain `assert` (pytest rewrites for readable diffs) |
| CI command | `uv run pytest` |
| Config | `[tool.pytest.ini_options]` in `pyproject.toml` |

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
pythonpath = ["src"]
```

### TypeScript

| Aspect | Convention |
|--------|-----------|
| Framework | `vitest` |
| Test files | `*.test.ts` co-located with source |
| Structure | `describe()` / `it()` / `expect()` |
| Mocks | `vi.fn()`, `vi.mock()`, `mockResolvedValue()` |
| CI command | `npx vitest run` |

## File Organization

| Test Type | Location |
|-----------|----------|
| Unit (Rust) | Inline `#[cfg(test)] mod tests` in source file |
| Unit (Go) | `*_test.go` in same package |
| Unit (Python) | `tests/test_<module>.py` |
| Unit (TS) | `<module>.test.ts` in same directory |
| Integration (Rust) | `tests/*.rs` at crate root |
| Integration (Go) | `*_test.go` with `//go:build integration` tag |
| Golden files | `testdata/golden/` (Go), `tests/fixtures/` (Rust/Python) |
| Benchmarks (Rust) | `benches/*.rs` |
| Fuzz corpus | `testdata/fuzz/` (auto-managed by Go toolchain) |

Test helpers go in the test file, unexported. Do not create shared `testutils/` packages — the duplication cost is lower than the coupling cost.

## Fixtures & Mocks

### Fixtures

| Language | Pattern | Example |
|----------|---------|---------|
| Rust | `tempfile::TempDir` | `let dir = TempDir::new().unwrap();` |
| Rust | `include_str!()` | `include_str!("fixtures/sample.yaml")` |
| Go | `t.TempDir()` | `dir := t.TempDir()` (auto-cleanup) |
| Go | `testdata/` | `filepath.Join("testdata", "input.json")` |
| Python | `@pytest.fixture` | Scoped setup/teardown in `conftest.py` |
| Python | `tmp_path` | Built-in pytest fixture for temp dirs |
| TS | Factory functions | `createMockFetch(200, {...})` |

### Mocking Rules

- **Prefer real implementations.** Use `TempDir` and real git commands over git mocks. Use real HTTP servers over fetch mocks when practical.
- **Mock at boundaries.** Only mock external services (APIs, databases) and only at the interface boundary.
- **Never mock what you own.** If you need to mock your own code, the design needs refactoring — extract an interface.
- Go: Use interfaces for test doubles. No mocking framework needed.
- Rust: Use trait objects or generic type parameters for test substitution.
- TypeScript: `vi.fn()` and `vi.mock()` for external dependencies only.

## CI Strategy

| Test Type | CI Stage | Trigger | Time Budget |
|-----------|----------|---------|-------------|
| Unit + lint | `ci.yml` | Every PR | < 5 min |
| Integration | `ci.yml` | Every PR | < 10 min (cached) |
| Fuzz smoke | `ci.yml` | Every PR | 10-30s per target |
| Full fuzz | Scheduled | Nightly/weekly | 5-30 min |
| Benchmarks | Manual | Release prep | Varies |
| E2E / dogfood | `release.yml` | Post-release | Varies |

All test types run with `just check` locally. CI mirrors `just check` exactly — no CI-only test logic.

## What NOT to Test

- **Third-party behavior** — don't test that `serde` serializes correctly or that `os.MkdirAll` creates directories
- **Private implementation details** — if you need to export something just for testing, the boundary is wrong
- **Generated code** — oag generates TypeScript clients; test the generator, not the output
- **Trivial accessors** — a getter that returns a field does not need a test
- **Implementation mirrors** — if your test duplicates the logic it tests, it proves nothing
- **Exact error messages** — test error *types* or *categories*, not wording (it changes)

## Gotchas

- **Float comparison:** Never `assert_eq!(f64, f64)`. Use an epsilon: `assert!((a - b).abs() < 1e-10)`
- **Go parallel + shared state:** `t.Parallel()` runs subtests concurrently. Shared fixtures must be immutable or use `sync.Mutex`.
- **Python src/ discovery:** Without `pythonpath = ["src"]` in pytest config, imports fail. Always configure this in `pyproject.toml`.
- **Rust integration tests:** Each file in `tests/` compiles as a separate binary. Group related tests in one file to reduce compile time.
- **Go golden file diffs:** Use `go-cmp` for readable diffs instead of `reflect.DeepEqual` — the error messages are vastly better.
- **Flaky tests:** If a test fails intermittently, it's a design problem (shared state, timing, network). Fix the root cause; do not retry.
