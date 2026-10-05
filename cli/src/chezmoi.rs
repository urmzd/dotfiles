//! Where chezmoi keeps things, running it, and the package selection stored at
//! `[data].packages` in the local chezmoi config.

use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};

use anyhow::{Context, Result, bail};
use toml_edit::{Array, DocumentMut, Item, Value};

/// Resolved locations. Both can be overridden for tests and odd layouts.
pub struct Paths {
    pub source: PathBuf,
    pub config: PathBuf,
}

impl Paths {
    pub fn discover() -> Result<Self> {
        let home = std::env::var_os("HOME")
            .map(PathBuf::from)
            .context("HOME is not set")?;
        let source = match std::env::var_os("DOTFILES_SOURCE") {
            Some(dir) => PathBuf::from(dir),
            None => chezmoi_output(&["source-path"])
                .map(|s| PathBuf::from(s.trim()))
                .unwrap_or_else(|_| home.join(".local/share/chezmoi")),
        };
        let config = match std::env::var_os("DOTFILES_CHEZMOI_CONFIG") {
            Some(file) => PathBuf::from(file),
            None => std::env::var_os("XDG_CONFIG_HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|| home.join(".config"))
                .join("chezmoi/chezmoi.toml"),
        };
        Ok(Self { source, config })
    }
}

/// Run chezmoi with inherited stdio (so its prompts and script output show).
pub fn run(args: &[&str]) -> Result<ExitStatus> {
    Command::new("chezmoi")
        .args(args)
        .status()
        .context("running chezmoi (is it installed and on PATH?)")
}

fn chezmoi_output(args: &[&str]) -> Result<String> {
    let out = Command::new("chezmoi")
        .args(args)
        .stderr(Stdio::null())
        .output()?;
    if !out.status.success() {
        bail!("chezmoi {} failed", args.join(" "));
    }
    Ok(String::from_utf8_lossy(&out.stdout).into_owned())
}

/// True when applying would change something. Uses the builtin diff: the
/// configured diff.command (nvim) hangs when its output is captured.
/// Scripts are excluded: run_after scripts run on every apply, so chezmoi
/// always lists them and they would make every machine look out of date.
pub fn has_pending_changes() -> Result<bool> {
    Ok(!chezmoi_output(&[
        "diff",
        "--use-builtin-diff",
        "--no-pager",
        "--exclude",
        "scripts",
    ])?
    .trim()
    .is_empty())
}

/// chezmoi's warning that .chezmoi.toml.tmpl changed since the config was
/// generated, i.e. `chezmoi init` would pick up new or changed questions.
pub fn config_template_changed() -> bool {
    Command::new("chezmoi")
        .args(["status", "--exclude", "scripts"])
        .stdout(Stdio::null())
        .output()
        .map(|o| String::from_utf8_lossy(&o.stderr).contains("config file template has changed"))
        .unwrap_or(false)
}

/// The local chezmoi config, edited in place with formatting and comments kept.
pub struct Config {
    path: PathBuf,
    doc: DocumentMut,
}

impl Config {
    pub fn load(path: &Path) -> Result<Self> {
        let text = std::fs::read_to_string(path).with_context(|| {
            format!(
                "reading {} (run `dotfiles config` to create it)",
                path.display()
            )
        })?;
        let doc = text
            .parse::<DocumentMut>()
            .with_context(|| format!("parsing {}", path.display()))?;
        Ok(Self {
            path: path.to_path_buf(),
            doc,
        })
    }

    /// Selected package ids. Missing key means nothing selected yet.
    pub fn packages(&self) -> Vec<String> {
        self.doc
            .get("data")
            .and_then(|d| d.get("packages"))
            .and_then(Item::as_array)
            .map(|a| {
                a.iter()
                    .filter_map(|v| v.as_str().map(String::from))
                    .collect()
            })
            .unwrap_or_default()
    }

    pub fn machine(&self) -> Option<String> {
        self.data_str("machine")
    }

    /// A string under [data]; None when missing or empty.
    pub fn data_str(&self, key: &str) -> Option<String> {
        self.doc
            .get("data")?
            .get(key)?
            .as_str()
            .filter(|s| !s.is_empty())
            .map(String::from)
    }

    /// Set a string under [data], keeping the line's existing formatting and
    /// trailing comment.
    pub fn set_data_str(&mut self, key: &str, val: &str) -> Result<()> {
        let data = self
            .doc
            .get_mut("data")
            .and_then(Item::as_table_like_mut)
            .with_context(|| format!("no [data] table in {}", self.path.display()))?;
        let mut new = Value::from(val);
        match data.get_mut(key) {
            Some(item) => {
                if let Some(old) = item.as_value() {
                    *new.decor_mut() = old.decor().clone();
                }
                *item = Item::Value(new);
            }
            None => {
                data.insert(key, Item::Value(new));
            }
        }
        Ok(())
    }

    /// Replace the selection, sorted and de-duplicated.
    pub fn set_packages(&mut self, ids: &[String]) -> Result<()> {
        let mut ids: Vec<&str> = ids.iter().map(String::as_str).collect();
        ids.sort_unstable();
        ids.dedup();
        let data = self
            .doc
            .get_mut("data")
            .and_then(Item::as_table_like_mut)
            .with_context(|| {
                format!(
                    "no [data] table in {} (run `dotfiles config`)",
                    self.path.display()
                )
            })?;
        let array: Array = ids.into_iter().collect();
        match data.get_mut("packages") {
            Some(item) => *item = Item::Value(Value::Array(array)),
            None => {
                data.insert("packages", Item::Value(Value::Array(array)));
            }
        }
        Ok(())
    }

    pub fn save(&self) -> Result<()> {
        let tmp = self.path.with_extension("toml.dotfiles-tmp");
        std::fs::write(&tmp, self.doc.to_string())
            .with_context(|| format!("writing {}", tmp.display()))?;
        std::fs::rename(&tmp, &self.path)
            .with_context(|| format!("replacing {}", self.path.display()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const CONFIG: &str = r#"# Chezmoi configuration
[data]
    name = "A"
    machine = "work"
    # Optional packages
    packages = ["docker", "obsidian"]
    pkg_exclude = ""

[git]
    autoCommit = true
"#;

    fn write(text: &str) -> (tempfile::TempDir, PathBuf) {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("chezmoi.toml");
        std::fs::write(&path, text).unwrap();
        (dir, path)
    }

    #[test]
    fn reads_selection_and_machine() {
        let (_d, path) = write(CONFIG);
        let cfg = Config::load(&path).unwrap();
        assert_eq!(cfg.packages(), vec!["docker", "obsidian"]);
        assert_eq!(cfg.machine().as_deref(), Some("work"));
    }

    #[test]
    fn rewrites_only_the_selection() {
        let (_d, path) = write(CONFIG);
        let mut cfg = Config::load(&path).unwrap();
        cfg.set_packages(&["twg".into(), "acli".into(), "acli".into()])
            .unwrap();
        cfg.save().unwrap();
        let text = std::fs::read_to_string(&path).unwrap();
        assert!(text.contains(r#"packages = ["acli", "twg"]"#), "{text}");
        assert!(text.contains("# Optional packages") && text.contains("autoCommit = true"));
        assert_eq!(Config::load(&path).unwrap().packages(), vec!["acli", "twg"]);
    }

    #[test]
    fn sets_strings_keeping_format() {
        let (_d, path) = write(CONFIG);
        let mut cfg = Config::load(&path).unwrap();
        assert_eq!(cfg.data_str("name").as_deref(), Some("A"));
        assert_eq!(cfg.data_str("missing"), None);
        cfg.set_data_str("name", "B").unwrap();
        cfg.set_data_str("work_signing_key", "ABC123").unwrap();
        cfg.save().unwrap();
        let text = std::fs::read_to_string(&path).unwrap();
        assert!(text.contains("    name = \"B\""), "{text}");
        let cfg = Config::load(&path).unwrap();
        assert_eq!(cfg.data_str("work_signing_key").as_deref(), Some("ABC123"));
        assert_eq!(cfg.packages(), vec!["docker", "obsidian"]);
    }

    #[test]
    fn inserts_missing_key() {
        let (_d, path) = write("[data]\n    name = \"A\"\n");
        let mut cfg = Config::load(&path).unwrap();
        assert!(cfg.packages().is_empty());
        cfg.set_packages(&["notion".into()]).unwrap();
        cfg.save().unwrap();
        assert_eq!(Config::load(&path).unwrap().packages(), vec!["notion"]);
    }
}
