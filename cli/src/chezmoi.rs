//! Where chezmoi keeps things, running it, and the package selection stored at
//! `[data].packages` in the local chezmoi config.

use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};

use anyhow::{Context, Result, bail};
use toml_edit::{Array, DocumentMut, Item, Value};

/// One pack entry, resolved like `.chezmoitemplates/packs` (keep in sync):
///   `~/folder` or `/folder`  -> that folder, used in place
///   `<git url>`              -> the repo, cloned to ~/.config/packs/<repo>
///   `<git url>//<folder>`    -> one folder of that repo
#[derive(Debug, Clone, PartialEq)]
pub struct Pack {
    pub spec: String,
    /// The folder whose files are read.
    pub dir: PathBuf,
    /// Git URL to clone, for repo packs.
    pub url: Option<String>,
    /// Where the repo is cloned, for repo packs.
    pub repo_dir: Option<PathBuf>,
    /// File-name-safe id, the validated catalog copy's name.
    pub key: String,
}

impl Pack {
    pub fn parse(spec: &str, home: &Path) -> Self {
        let (dir, url, repo_dir) = if let Some(rest) = spec.strip_prefix('~') {
            (home.join(rest.trim_start_matches('/')), None, None)
        } else if spec.starts_with('/') {
            (PathBuf::from(spec), None, None)
        } else {
            // Split `//folder` off after the scheme's own `://`.
            let scheme_end = spec.find("://").map_or(0, |i| i + 3);
            let (scheme, rest) = spec.split_at(scheme_end);
            let (repo, sub) = rest.split_once("//").unwrap_or((rest, ""));
            let name = repo.rsplit(['/', ':']).next().unwrap_or(repo);
            let repo_dir = home
                .join(".config/packs")
                .join(name.trim_end_matches(".git"));
            let dir = if sub.is_empty() {
                repo_dir.clone()
            } else {
                repo_dir.join(sub)
            };
            (dir, Some(format!("{scheme}{repo}")), Some(repo_dir))
        };
        let rel = dir.strip_prefix(home).unwrap_or(&dir).to_string_lossy();
        let key = rel
            .split(|c: char| !c.is_ascii_alphanumeric())
            .filter(|s| !s.is_empty())
            .collect::<Vec<_>>()
            .join("-");
        Self {
            spec: spec.to_string(),
            dir,
            url,
            repo_dir,
            key,
        }
    }

    /// Short label: the pack folder's name (backend-engineer, acme-setup).
    pub fn name(&self) -> String {
        self.dir
            .file_name()
            .map_or_else(|| self.spec.clone(), |n| n.to_string_lossy().into_owned())
    }
}

/// Resolved locations. Both can be overridden for tests and odd layouts.
pub struct Paths {
    pub home: PathBuf,
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
        Ok(Self {
            home,
            source,
            config,
        })
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

/// Managed files that applying would change (`chezmoi status`). Scripts are
/// excluded: run_after scripts run on every apply, so chezmoi always lists
/// them and they would make every machine look out of date.
pub fn pending_files() -> Result<Vec<String>> {
    Ok(chezmoi_output(&["status", "--exclude", "scripts"])?
        .lines()
        .filter(|l| !l.trim().is_empty())
        .map(String::from)
        .collect())
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
#[derive(Clone)]
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

    /// A config held in memory only (tests).
    #[cfg(test)]
    pub fn parse(text: &str) -> Result<Self> {
        Ok(Self {
            path: PathBuf::new(),
            doc: text.parse::<DocumentMut>()?,
        })
    }

    /// Whether [data] has `key` at all, whatever its value.
    pub fn has_data(&self, key: &str) -> bool {
        self.doc.get("data").and_then(|d| d.get(key)).is_some()
    }

    pub fn set_data_bool(&mut self, key: &str, val: bool) -> Result<()> {
        let data = self
            .doc
            .get_mut("data")
            .and_then(Item::as_table_like_mut)
            .with_context(|| format!("no [data] table in {}", self.path.display()))?;
        match data.get_mut(key) {
            Some(item) => *item = Item::Value(Value::from(val)),
            None => {
                data.insert(key, Item::Value(Value::from(val)));
            }
        }
        Ok(())
    }

    /// Selected package ids. Missing key means nothing selected yet.
    pub fn packages(&self) -> Vec<String> {
        self.data_list("packages")
    }

    /// A list of strings under [data]; empty when missing.
    pub fn data_list(&self, key: &str) -> Vec<String> {
        self.doc
            .get("data")
            .and_then(|d| d.get(key))
            .and_then(Item::as_array)
            .map(|a| {
                a.iter()
                    .filter_map(|v| v.as_str().map(String::from))
                    .collect()
            })
            .unwrap_or_default()
    }

    /// Pack entries as written in the config. Configs from before the list
    /// keep working like `.chezmoitemplates/packs`: a `work_pack` string is a
    /// one-pack list, and a hand-made ~/.config/work on a work machine with
    /// neither set is the pack.
    pub fn pack_specs(&self, home: &Path) -> Vec<String> {
        if self.has_data("packs") {
            return self.data_list("packs");
        }
        if let Some(legacy) = self.data_str("work_pack") {
            return vec![legacy];
        }
        if self.machine().as_deref() == Some("work") && home.join(".config/work").is_dir() {
            return vec!["~/.config/work".into()];
        }
        Vec::new()
    }

    pub fn packs(&self, home: &Path) -> Vec<Pack> {
        self.pack_specs(home)
            .iter()
            .map(|s| Pack::parse(s, home))
            .collect()
    }

    /// Replace the pack list, keeping its order.
    pub fn set_packs(&mut self, specs: &[String]) -> Result<()> {
        self.set_data_list("packs", specs)
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
        let mut ids = ids.to_vec();
        ids.sort_unstable();
        ids.dedup();
        self.set_data_list("packages", &ids)
    }

    /// Set a list of strings under [data], in the given order.
    pub fn set_data_list(&mut self, key: &str, items: &[String]) -> Result<()> {
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
        let array: Array = items.iter().map(String::as_str).collect();
        match data.get_mut(key) {
            Some(item) => *item = Item::Value(Value::Array(array)),
            None => {
                data.insert(key, Item::Value(Value::Array(array)));
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
    fn parses_pack_specs_like_the_template() {
        let home = Path::new("/h");
        let p = Pack::parse(
            "git@github.com:acme/dev-setup.git//teams/backend-engineer",
            home,
        );
        assert_eq!(p.url.as_deref(), Some("git@github.com:acme/dev-setup.git"));
        assert_eq!(
            p.repo_dir,
            Some(PathBuf::from("/h/.config/packs/dev-setup"))
        );
        assert_eq!(
            p.dir,
            PathBuf::from("/h/.config/packs/dev-setup/teams/backend-engineer")
        );
        assert_eq!(p.key, "config-packs-dev-setup-teams-backend-engineer");
        assert_eq!(p.name(), "backend-engineer");
        let p = Pack::parse("https://github.com/acme/dev-setup.git", home);
        assert_eq!(
            p.url.as_deref(),
            Some("https://github.com/acme/dev-setup.git")
        );
        assert_eq!(p.dir, PathBuf::from("/h/.config/packs/dev-setup"));
        let p = Pack::parse("~/my-overrides", home);
        assert_eq!(
            (p.dir, p.url, p.key),
            (
                PathBuf::from("/h/my-overrides"),
                None,
                "my-overrides".into()
            )
        );
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
