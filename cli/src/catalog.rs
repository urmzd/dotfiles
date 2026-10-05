//! `catalog.toml` at the dotfiles repo root: every optional package,
//! how it installs, and what setup it needs. A work pack can add its own
//! `catalog.toml` in the same format; its entries join the picker, and
//! `required = true` ones install on every machine using that pack.

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct Catalog {
    #[serde(rename = "package")]
    pub packages: Vec<Package>,
    /// What happened to the work pack's catalog, if it has one.
    #[serde(skip)]
    pub work: WorkCatalog,
}

#[derive(Debug, Default)]
pub enum WorkCatalog {
    #[default]
    None,
    Loaded {
        path: PathBuf,
        count: usize,
    },
    /// Present but unusable; its entries are ignored (the apply never sees
    /// them either: templates read only the validated copy).
    Invalid {
        path: PathBuf,
        error: String,
    },
}

/// Validated copy of the work pack's catalog that the chezmoi templates read.
/// Written only after it parses, so a broken company file cannot break apply.
pub const WORK_COPY: &str = ".local/share/dotfiles/work-catalog.toml";

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Package {
    pub id: String,
    pub name: String,
    pub description: String,
    pub category: String,
    #[serde(default)]
    pub tap: Vec<String>,
    #[serde(default)]
    pub brew: Vec<String>,
    #[serde(default)]
    pub cask: Vec<String>,
    #[serde(default)]
    pub adopt: bool,
    /// Linux package names, per package manager.
    #[serde(default)]
    pub apt: Vec<String>,
    #[serde(default)]
    pub dnf: Vec<String>,
    #[serde(default)]
    pub pacman: Vec<String>,
    /// Node CLIs, `npm -g` into fnm's default Node.
    #[serde(default)]
    pub npm: Vec<String>,
    /// Python CLIs, `uv tool install`.
    #[serde(default)]
    pub uv: Vec<String>,
    /// Installer URL run during apply when `check` fails (Claude Code, agy, ...).
    #[serde(default)]
    pub script: Option<String>,
    #[serde(default)]
    pub script_shell: Option<String>,
    #[serde(default)]
    pub script_args: Vec<String>,
    /// Command run after a successful script install.
    #[serde(default)]
    pub post: Option<String>,
    /// npm packages for Linux only (macOS gets the brew/cask entries).
    #[serde(default)]
    pub linux_npm: Vec<String>,
    /// Interactive commands (sign-in, TTY installers) run by `dotfiles package setup`.
    #[serde(default)]
    pub setup: Vec<String>,
    /// Shell test that passes once setup is done.
    #[serde(default)]
    pub check: Option<String>,
    #[serde(default)]
    pub presets: Vec<String>,
    #[serde(default)]
    pub machines: Vec<String>,
    /// Work pack only: installs on every machine using the pack, selected or not.
    #[serde(default)]
    pub required: bool,
    /// Set for entries that came from the work pack.
    #[serde(skip)]
    pub work: bool,
}

impl Package {
    /// What installs on this platform, for display: Homebrew formulae and
    /// casks on macOS, otherwise every Linux package name the entry lists,
    /// plus npm and uv tools on both.
    pub fn installs(&self) -> Vec<String> {
        let mut names: Vec<String> = if cfg!(target_os = "macos") {
            self.brew.iter().chain(&self.cask).cloned().collect()
        } else {
            let mut linux: Vec<String> = self
                .apt
                .iter()
                .chain(&self.dnf)
                .chain(&self.pacman)
                .cloned()
                .collect();
            linux.sort();
            linux.dedup();
            linux
        };
        if !cfg!(target_os = "macos") {
            names.extend(self.linux_npm.iter().map(|p| format!("{p} (npm)")));
        }
        names.extend(self.npm.iter().map(|p| format!("{p} (npm)")));
        names.extend(self.uv.iter().map(|p| format!("{p} (uv)")));
        if let Some(url) = &self.script {
            names.push(format!("installer {url}"));
        }
        names
    }

    /// Shell command that downloads the installer, refuses an empty download,
    /// then runs it (never `curl | sh`, which "succeeds" on a failed download).
    pub fn installer_command(&self) -> Option<String> {
        let url = self.script.as_ref()?;
        let shell = self.script_shell.as_deref().unwrap_or("sh");
        let args: String = self.script_args.iter().map(|a| format!(" '{a}'")).collect();
        Some(format!(
            "t=$(mktemp) && curl -fsSL --retry 2 '{url}' -o \"$t\" && [ -s \"$t\" ] && {shell} \"$t\"{args}; rc=$?; rm -f \"$t\"; exit $rc"
        ))
    }
}

/// TOML errors span several lines (location, source excerpt, carets, message);
/// keep the location and the message.
fn one_line(err: &str) -> String {
    let lines: Vec<&str> = err
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty())
        .collect();
    match (lines.first(), lines.last()) {
        (Some(first), Some(last)) if lines.len() > 1 => format!("{first}: {last}"),
        _ => err.trim().to_string(),
    }
}

impl Catalog {
    /// The dotfiles catalog plus, when `work_dir` holds one, the work pack's.
    /// A bad work catalog never fails the load: it is recorded in `work` and
    /// skipped. A good one is copied to `home/WORK_COPY` for the templates.
    pub fn load(source_dir: &Path, work_dir: Option<&Path>, home: &Path) -> Result<Self> {
        let path = source_dir.join("catalog.toml");
        let text = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        let mut catalog =
            Self::parse(&text).with_context(|| format!("parsing {}", path.display()))?;
        let copy = home.join(WORK_COPY);
        let work_path = work_dir.map(|d| d.join("catalog.toml"));
        match work_path.filter(|p| p.is_file()) {
            Some(path) => match catalog.merge_work(&path) {
                Ok(text) => {
                    let count = catalog.packages.iter().filter(|p| p.work).count();
                    if std::fs::read_to_string(&copy).ok().as_deref() != Some(text.as_str()) {
                        if let Some(dir) = copy.parent() {
                            let _ = std::fs::create_dir_all(dir);
                        }
                        let _ = std::fs::write(&copy, &text);
                    }
                    catalog.work = WorkCatalog::Loaded { path, count };
                }
                Err(err) => {
                    catalog.work = WorkCatalog::Invalid {
                        path,
                        error: one_line(&format!("{err:#}")),
                    }
                }
            },
            None => {
                let _ = std::fs::remove_file(&copy);
            }
        }
        Ok(catalog)
    }

    /// Parse the work pack catalog and append its entries; returns its text.
    fn merge_work(&mut self, path: &Path) -> Result<String> {
        let text = std::fs::read_to_string(path)?;
        let work = Self::parse(&text)?;
        for pkg in &work.packages {
            if self.get(&pkg.id).is_some() {
                bail!("id `{}` is already in the dotfiles catalog", pkg.id);
            }
        }
        self.packages.extend(work.packages.into_iter().map(|mut p| {
            p.work = true;
            p
        }));
        Ok(text)
    }

    /// Everything that installs: the saved selection plus required work entries.
    pub fn effective(&self, selected: &[String]) -> BTreeSet<String> {
        self.packages
            .iter()
            .filter(|p| p.required || selected.contains(&p.id))
            .map(|p| p.id.clone())
            .collect()
    }

    pub fn parse(text: &str) -> Result<Self> {
        let catalog: Catalog = toml::from_str(text)?;
        let mut seen = std::collections::HashSet::new();
        for pkg in &catalog.packages {
            if !seen.insert(pkg.id.as_str()) {
                bail!("duplicate package id `{}`", pkg.id);
            }
        }
        Ok(catalog)
    }

    pub fn get(&self, id: &str) -> Option<&Package> {
        self.packages.iter().find(|p| p.id == id)
    }

    /// Resolve ids, failing on the first unknown one with a suggestion list.
    pub fn resolve<'a>(&'a self, ids: &[String]) -> Result<Vec<&'a Package>> {
        ids.iter()
            .map(|id| {
                self.get(id).ok_or_else(|| {
                    let known: Vec<&str> = self.packages.iter().map(|p| p.id.as_str()).collect();
                    anyhow::anyhow!("unknown package `{id}`; known: {}", known.join(", "))
                })
            })
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = r#"
[[package]]
id = "acli"
name = "Atlassian CLI"
description = "Jira from the terminal"
category = "work"
tap = ["atlassian/acli"]
brew = ["atlassian/acli/acli"]
setup = ["acli jira auth login --web"]

[[package]]
id = "notion"
name = "Notion"
description = "Docs app"
category = "apps"
cask = ["notion"]
adopt = true
"#;

    #[test]
    fn parses_defaults() {
        let c = Catalog::parse(SAMPLE).unwrap();
        assert_eq!(c.packages.len(), 2);
        let notion = c.get("notion").unwrap();
        assert!(notion.adopt && notion.setup.is_empty() && notion.tap.is_empty());
        if cfg!(target_os = "macos") {
            assert_eq!(
                c.get("acli").unwrap().installs(),
                vec!["atlassian/acli/acli"]
            );
        }
    }

    #[test]
    fn reads_linux_names() {
        let c = Catalog::parse(
            "[[package]]\nid = \"k8s\"\nname = \"K\"\ndescription = \"d\"\ncategory = \"c\"\nbrew = [\"kubectl\"]\napt = [\"kubectl\", \"helm\"]\npacman = [\"helm\"]\n",
        )
        .unwrap();
        let p = c.get("k8s").unwrap();
        assert!(p.npm.is_empty() && p.uv.is_empty());
        assert_eq!(p.apt, vec!["kubectl", "helm"]);
        if !cfg!(target_os = "macos") {
            assert_eq!(p.installs(), vec!["helm", "kubectl"]);
        }
    }

    #[test]
    fn rejects_duplicate_ids() {
        let dup = format!(
            "{SAMPLE}\n[[package]]\nid = \"notion\"\nname = \"x\"\ndescription = \"x\"\ncategory = \"x\"\n"
        );
        assert!(
            Catalog::parse(&dup)
                .unwrap_err()
                .to_string()
                .contains("duplicate")
        );
    }

    #[test]
    fn work_catalog_merges_and_requires() {
        let dir = std::env::temp_dir().join(format!("dotfiles-cat-{}", std::process::id()));
        let (src, work, home) = (dir.join("src"), dir.join("work"), dir.join("home"));
        for d in [&src, &work, &home] {
            std::fs::create_dir_all(d).unwrap();
        }
        std::fs::write(src.join("catalog.toml"), SAMPLE).unwrap();
        let entry = "[[package]]\nid = \"vpn\"\nname = \"VPN\"\ndescription = \"d\"\ncategory = \"work\"\nrequired = true\n";
        std::fs::write(work.join("catalog.toml"), entry).unwrap();

        let c = Catalog::load(&src, Some(&work), &home).unwrap();
        assert!(matches!(c.work, WorkCatalog::Loaded { count: 1, .. }));
        assert!(c.get("vpn").unwrap().work);
        assert_eq!(
            c.effective(&["notion".into()])
                .into_iter()
                .collect::<Vec<_>>(),
            vec!["notion", "vpn"]
        );
        assert_eq!(
            std::fs::read_to_string(home.join(WORK_COPY)).unwrap(),
            entry
        );

        // A clash or a syntax error is reported, ignored, and keeps the last good copy.
        std::fs::write(work.join("catalog.toml"), SAMPLE).unwrap();
        let c = Catalog::load(&src, Some(&work), &home).unwrap();
        assert!(matches!(c.work, WorkCatalog::Invalid { .. }) && c.get("vpn").is_none());
        assert_eq!(
            std::fs::read_to_string(home.join(WORK_COPY)).unwrap(),
            entry
        );

        // No work catalog: the copy goes too.
        std::fs::remove_file(work.join("catalog.toml")).unwrap();
        Catalog::load(&src, Some(&work), &home).unwrap();
        assert!(!home.join(WORK_COPY).exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn resolve_reports_unknown() {
        let c = Catalog::parse(SAMPLE).unwrap();
        let err = c.resolve(&["nope".into()]).unwrap_err().to_string();
        assert!(err.contains("unknown package `nope`") && err.contains("acli"));
    }
}
