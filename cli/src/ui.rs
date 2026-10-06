//! Human output, matching `.chezmoitemplates/ui.sh` in this repo so the
//! CLI and `chezmoi apply` read as one program. Everything goes to stderr;
//! stdout is reserved for `--format json` data.

use std::io::IsTerminal;
use std::sync::OnceLock;

fn color() -> bool {
    static COLOR: OnceLock<bool> = OnceLock::new();
    *COLOR.get_or_init(|| std::io::stderr().is_terminal() && std::env::var_os("NO_COLOR").is_none())
}

fn paint(code: &str, text: &str) -> String {
    if color() {
        format!("\x1b[{code}m{text}\x1b[0m")
    } else {
        text.to_string()
    }
}

/// `==> Title`, one per command phase.
pub fn section(msg: &str) {
    eprintln!("{} {}", paint("36", "==>"), paint("1", msg));
}

/// `→ msg`, slow work starting.
pub fn step(msg: &str) {
    eprintln!("  {} {msg}", paint("36", "→"));
}

/// `✓ msg`, something changed or was verified.
pub fn ok(msg: &str) {
    eprintln!("  {} {msg}", paint("32", "✓"));
}

/// `· msg`, nothing to do.
pub fn skip(msg: &str) {
    eprintln!("  {}", paint("2", &format!("· {msg}")));
}

/// `! msg`, degraded but continuing.
pub fn warn(msg: &str) {
    eprintln!("  {} {msg}", paint("33", "!"));
}

/// `✗ msg`, failed.
pub fn fail(msg: &str) {
    eprintln!("  {} {msg}", paint("31", "✗"));
}

/// A planned change: `+` adds (green), `-` removes (red), `~` needs a hand
/// (yellow). Plan output uses these instead of ✓, which means "done".
pub fn change(sign: char, msg: &str) {
    let code = match sign {
        '+' => "32",
        '-' => "31",
        _ => "33",
    };
    eprintln!("  {} {msg}", paint(code, &sign.to_string()));
}

/// Indented next step under a warning or failure.
pub fn hint(msg: &str) {
    eprintln!("    {}", paint("2", msg));
}

/// `1 package`, `3 packages`.
pub fn count(n: usize, noun: &str) -> String {
    if n == 1 {
        format!("1 {noun}")
    } else {
        format!("{n} {noun}s")
    }
}

/// Dimmed text for inline detail, e.g. picker descriptions.
pub fn dim(text: &str) -> String {
    paint("2", text)
}
