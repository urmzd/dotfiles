//! `dotfiles theme`: the color theme for Ghostty, Neovim, tmux, and dotfiles'
//! own output. Themes are `themes/<name>.toml` in the dotfiles repo plus any
//! pack's `theme.toml`; `.chezmoitemplates/theme` resolves the machine's
//! theme the same way `resolve` does here (keep the two in sync).

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};

use anyhow::{Result, bail};
use serde::Deserialize;
use serde_json::json;

use crate::chezmoi::{Config, Pack, Paths};
use crate::{Format, Outcome, ui};

/// The default theme, and the base every other theme is merged onto.
pub const DEFAULT: &str = "cyberdream";

/// Validated copies of pack themes, read by the templates; one per pack,
/// named by `Pack::key`. Written only after a file parses.
const PACK_THEMES: &str = ".local/share/dotfiles/pack-themes";

#[derive(Deserialize)]
struct Header {
    name: String,
    #[serde(default)]
    description: String,
}

#[derive(Debug, Clone)]
pub struct Theme {
    pub name: String,
    pub description: String,
    /// "built-in" or the pack's name.
    pub source: String,
}

/// Every available theme: built-ins, then pack themes in pack order. Bad
/// pack files are returned as (spec, error) and skipped. Good pack files
/// are copied for the templates; copies of removed packs go.
pub fn discover(source: &Path, packs: &[Pack], home: &Path) -> (Vec<Theme>, Vec<(String, String)>) {
    let mut themes = Vec::new();
    let mut files: Vec<PathBuf> = std::fs::read_dir(source.join("themes"))
        .map(|d| d.flatten().map(|e| e.path()).collect())
        .unwrap_or_default();
    files.sort();
    for path in files
        .iter()
        .filter(|p| p.extension().is_some_and(|e| e == "toml"))
    {
        if let Some(h) = read_header(path) {
            themes.push(Theme {
                name: h.name,
                description: h.description,
                source: "built-in".into(),
            });
        }
    }
    let copies = home.join(PACK_THEMES);
    let mut keep = BTreeSet::new();
    let mut errors = Vec::new();
    for pack in packs {
        let path = pack.dir.join("theme.toml");
        let Ok(text) = std::fs::read_to_string(&path) else {
            continue;
        };
        let file = format!("{}.toml", pack.key);
        keep.insert(file.clone());
        match toml::from_str::<Header>(&text) {
            Ok(h) if !h.name.is_empty() => {
                let copy = copies.join(&file);
                if std::fs::read_to_string(&copy).ok().as_deref() != Some(text.as_str()) {
                    let _ = std::fs::create_dir_all(&copies);
                    let _ = std::fs::write(&copy, &text);
                }
                themes.push(Theme {
                    name: h.name,
                    description: h.description,
                    source: format!("pack {}", pack.name()),
                });
            }
            Ok(_) => errors.push((pack.spec.clone(), "missing string field `name`".into())),
            Err(e) => errors.push((pack.spec.clone(), e.message().to_string())),
        }
    }
    if let Ok(entries) = std::fs::read_dir(&copies) {
        for entry in entries.flatten() {
            if !keep.contains(&entry.file_name().to_string_lossy().to_string()) {
                let _ = std::fs::remove_file(entry.path());
            }
        }
    }
    (themes, errors)
}

fn read_header(path: &Path) -> Option<Header> {
    toml::from_str(&std::fs::read_to_string(path).ok()?).ok()
}

/// The theme in effect and why: the `theme` setting when it names a known
/// theme (built-ins win a name clash), else the last pack theme, else the
/// default. The bool is false when `theme` names something unknown.
pub fn resolve<'a>(
    setting: Option<&str>,
    themes: &'a [Theme],
) -> (Option<&'a Theme>, &'static str, bool) {
    let builtin = |n: &str| {
        themes
            .iter()
            .find(|t| t.name == n && t.source == "built-in")
    };
    let from_pack = |n: &str| {
        themes
            .iter()
            .rev()
            .find(|t| t.name == n && t.source != "built-in")
    };
    if let Some(name) = setting {
        if let Some(t) = builtin(name).or_else(|| from_pack(name)) {
            return (Some(t), "set on this machine", true);
        }
        return (
            builtin(DEFAULT),
            "default (the setting names an unknown theme)",
            false,
        );
    }
    if let Some(t) = themes.iter().rev().find(|t| t.source != "built-in") {
        return (Some(t), "from the last pack with a theme", true);
    }
    (builtin(DEFAULT), "default", true)
}

fn load() -> Result<(Paths, Config, Vec<Theme>)> {
    let paths = Paths::discover()?;
    let config = Config::load(&paths.config)?;
    let packs = config.packs(&paths.home);
    let (themes, errors) = discover(&paths.source, &packs, &paths.home);
    for (spec, error) in errors {
        ui::warn(&format!("{spec}: theme ignored: {error}"));
    }
    Ok((paths, config, themes))
}

pub fn list(ctx: &crate::commands::Ctx) -> Result<Outcome> {
    let (_, config, themes) = load()?;
    let setting = config.data_str("theme");
    let (current, why, _) = resolve(setting.as_deref(), &themes);
    let current = current.map(|t| (t.name.clone(), t.source.clone()));
    if ctx.format == Format::Json {
        let data: Vec<_> = themes
            .iter()
            .map(|t| {
                json!({
                    "name": t.name, "description": t.description, "source": t.source,
                    "current": current.as_ref() == Some(&(t.name.clone(), t.source.clone())),
                })
            })
            .collect();
        println!(
            "{}",
            serde_json::to_string_pretty(&json!({ "setting": setting, "themes": data }))?
        );
        return Ok(Outcome::Done);
    }
    ui::section("Themes (Ghostty, Neovim, tmux, dotfiles output)");
    let width = themes.iter().map(|t| t.name.len()).max().unwrap_or(0);
    for t in &themes {
        let line = format!(
            "{:<width$}  {}  {}",
            t.name,
            ui::dim(&t.source),
            t.description
        );
        if current.as_ref() == Some(&(t.name.clone(), t.source.clone())) {
            ui::ok(&format!("{line}  ({why})"));
        } else {
            ui::skip(&line);
        }
    }
    ui::hint("switch: dotfiles theme set <name>; follow packs again: dotfiles theme set auto");
    Ok(Outcome::Done)
}

pub fn set(ctx: &crate::commands::Ctx, name: &str) -> Result<Outcome> {
    let (paths, mut config, themes) = load()?;
    let value = if name == "auto" { "" } else { name };
    if !value.is_empty() && !themes.iter().any(|t| t.name == value) {
        let known: Vec<&str> = themes.iter().map(|t| t.name.as_str()).collect();
        bail!(
            "unknown theme `{name}`; known: {} (or auto)",
            known.join(", ")
        );
    }
    if config.data_str("theme").unwrap_or_default() == value {
        ui::skip(&format!("theme already {name}"));
        return Ok(Outcome::NoChange);
    }
    ui::section("Theme");
    ui::change('~', &format!("theme: {name}"));
    if ctx.dry_run {
        ui::skip("dry run; nothing saved");
        return Ok(Outcome::Done);
    }
    config.set_data_str("theme", value)?;
    config.save()?;
    ui::ok(&format!("saved to {}", paths.config.display()));
    crate::commands::chezmoi_apply()?;
    ui::hint(
        "open a new Ghostty window and restart Neovim; tmux: prefix + r (or tmux kill-server)",
    );
    Ok(Outcome::Done)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn t(name: &str, source: &str) -> Theme {
        Theme {
            name: name.into(),
            description: String::new(),
            source: source.into(),
        }
    }

    #[test]
    fn resolves_setting_then_packs_then_default() {
        let themes = vec![
            t("cyberdream", "built-in"),
            t("tokyonight", "built-in"),
            t("acme", "pack base"),
            t("acme-dark", "pack backend"),
        ];
        assert_eq!(
            resolve(Some("tokyonight"), &themes).0.unwrap().name,
            "tokyonight"
        );
        assert_eq!(resolve(Some("acme"), &themes).0.unwrap().name, "acme");
        assert_eq!(resolve(None, &themes).0.unwrap().name, "acme-dark");
        let (theme, _, known) = resolve(Some("nope"), &themes);
        assert_eq!((theme.unwrap().name.as_str(), known), ("cyberdream", false));
        assert_eq!(resolve(None, &themes[..2]).0.unwrap().name, "cyberdream");
    }
}
