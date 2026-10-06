//! Human output, matching `.chezmoitemplates/ui.sh` in this repo so the
//! CLI and `chezmoi apply` read as one program. Everything goes to stderr;
//! stdout is reserved for `--format json` data.
//!
//! Symbols and colors come from the machine's theme: `[ui]` in
//! `~/.config/dotfiles/theme.toml` (rendered by chezmoi, see `dotfiles
//! theme`), then the same environment overrides `ui.sh` reads:
//! `DOTFILES_UI_THEME=default|ascii|plain`, `DOTFILES_UI_<ROLE>` for a
//! symbol and `DOTFILES_UI_COLOR_<ROLE>` for a color (an ANSI SGR code such
//! as `1;36`, or a hex `#5ea1ff`).

use std::collections::BTreeMap;
use std::io::IsTerminal;
use std::sync::OnceLock;

use serde::Deserialize;

#[derive(Debug, Default, Deserialize)]
struct ThemeFile {
    #[serde(default)]
    ui: UiTable,
}

#[derive(Debug, Default, Deserialize)]
struct UiTable {
    preset: Option<String>,
    #[serde(flatten)]
    roles: BTreeMap<String, RoleTable>,
}

#[derive(Debug, Default, Deserialize)]
struct RoleTable {
    symbol: Option<String>,
    color: Option<String>,
}

/// One output role (ok, warn, ...): its marker and color escape.
struct Role {
    symbol: String,
    color: String,
}

struct Style {
    color: bool,
    roles: BTreeMap<&'static str, Role>,
}

/// role, default symbol, ASCII symbol, default ANSI color.
const ROLES: [(&str, &str, &str, &str); 10] = [
    ("section", "==>", "==>", "36"),
    ("step", "→", "->", "36"),
    ("ok", "✓", "ok", "32"),
    ("skip", "·", "..", "2"),
    ("warn", "!", "!", "33"),
    ("fail", "✗", "x", "31"),
    ("add", "+", "+", "32"),
    ("remove", "-", "-", "31"),
    ("change", "~", "~", "33"),
    ("dim", "", "", "2"),
];

/// An SGR escape for `1;36` or `#5ea1ff`; None for anything else.
fn sgr(spec: &str) -> Option<String> {
    let spec = spec.trim();
    if let Some(hex) = spec.strip_prefix('#') {
        if hex.len() != 6 {
            return None;
        }
        let byte = |i: usize| u8::from_str_radix(&hex[i..i + 2], 16).ok();
        return Some(format!("38;2;{};{};{}", byte(0)?, byte(2)?, byte(4)?));
    }
    (!spec.is_empty() && spec.chars().all(|c| c.is_ascii_digit() || c == ';'))
        .then(|| spec.to_string())
}

fn load_theme() -> UiTable {
    std::env::var_os("HOME")
        .map(|h| std::path::PathBuf::from(h).join(".config/dotfiles/theme.toml"))
        .and_then(|p| std::fs::read_to_string(p).ok())
        .and_then(|t| toml::from_str::<ThemeFile>(&t).ok())
        .map(|t| t.ui)
        .unwrap_or_default()
}

fn build(theme: &UiTable, env: &dyn Fn(&str) -> Option<String>, tty: bool) -> Style {
    let preset = env("DOTFILES_UI_THEME")
        .or_else(|| theme.preset.clone())
        .unwrap_or_else(|| "default".into());
    let color = tty && env("NO_COLOR").is_none() && preset != "plain";
    let roles = ROLES
        .iter()
        .map(|&(name, symbol, ascii, ansi)| {
            let themed = theme.roles.get(name);
            let upper = name.to_uppercase();
            let symbol = env(&format!("DOTFILES_UI_{upper}")).unwrap_or_else(|| {
                if preset == "default" {
                    themed
                        .and_then(|r| r.symbol.clone())
                        .unwrap_or_else(|| symbol.into())
                } else {
                    ascii.into()
                }
            });
            let color = env(&format!("DOTFILES_UI_COLOR_{upper}"))
                .or_else(|| themed.and_then(|r| r.color.clone()))
                .and_then(|c| sgr(&c))
                .unwrap_or_else(|| ansi.into());
            (name, Role { symbol, color })
        })
        .collect();
    Style { color, roles }
}

fn style() -> &'static Style {
    static STYLE: OnceLock<Style> = OnceLock::new();
    STYLE.get_or_init(|| {
        build(
            &load_theme(),
            &|k| std::env::var(k).ok().filter(|v| !v.is_empty()),
            std::io::stderr().is_terminal(),
        )
    })
}

fn role(name: &str) -> &'static Role {
    &style().roles[name]
}

fn paint_code(code: &str, text: &str) -> String {
    if style().color {
        format!("\x1b[{code}m{text}\x1b[0m")
    } else {
        text.to_string()
    }
}

fn paint(name: &str, text: &str) -> String {
    paint_code(&role(name).color, text)
}

fn marker(name: &str) -> String {
    paint(name, &role(name).symbol)
}

/// `==> Title`, one per command phase.
pub fn section(msg: &str) {
    eprintln!("{} {}", marker("section"), paint_code("1", msg));
}

/// `→ msg`, slow work starting.
pub fn step(msg: &str) {
    eprintln!("  {} {msg}", marker("step"));
}

/// `✓ msg`, something changed or was verified.
pub fn ok(msg: &str) {
    eprintln!("  {} {msg}", marker("ok"));
}

/// `· msg`, nothing to do.
pub fn skip(msg: &str) {
    eprintln!(
        "  {}",
        paint("skip", &format!("{} {msg}", role("skip").symbol))
    );
}

/// `! msg`, degraded but continuing.
pub fn warn(msg: &str) {
    eprintln!("  {} {msg}", marker("warn"));
}

/// `✗ msg`, failed.
pub fn fail(msg: &str) {
    eprintln!("  {} {msg}", marker("fail"));
}

/// A planned change: `+` adds, `-` removes, `~` needs a hand. Plan output
/// uses these instead of the ok marker, which means "done".
pub fn change(sign: char, msg: &str) {
    let name = match sign {
        '+' => "add",
        '-' => "remove",
        _ => "change",
    };
    eprintln!("  {} {msg}", marker(name));
}

/// Indented next step under a warning or failure.
pub fn hint(msg: &str) {
    eprintln!("    {}", paint("dim", msg));
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
    paint("dim", text)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn theme(text: &str) -> UiTable {
        toml::from_str::<ThemeFile>(text).unwrap().ui
    }

    #[test]
    fn colors_parse_as_sgr_or_hex() {
        assert_eq!(sgr("#9ece6a").as_deref(), Some("38;2;158;206;106"));
        assert_eq!(sgr("1;36").as_deref(), Some("1;36"));
        assert_eq!(sgr("red"), None);
        assert_eq!(sgr("#12"), None);
    }

    #[test]
    fn theme_then_env_then_presets() {
        let t = theme("[ui]\nok = { symbol = \"[ok]\", color = \"#9ece6a\" }\n");
        let none = |_: &str| None;
        let s = build(&t, &none, true);
        assert_eq!(s.roles["ok"].symbol, "[ok]");
        assert_eq!(s.roles["ok"].color, "38;2;158;206;106");
        assert_eq!(s.roles["warn"].symbol, "!");
        assert!(s.color);

        let env = |k: &str| match k {
            "DOTFILES_UI_THEME" => Some("plain".to_string()),
            "DOTFILES_UI_WARN" => Some("WARN".to_string()),
            _ => None,
        };
        let s = build(&t, &env, true);
        assert!(!s.color);
        assert_eq!(s.roles["ok"].symbol, "ok");
        assert_eq!(s.roles["warn"].symbol, "WARN");
    }
}
