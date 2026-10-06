//! `catalog.toml` at the dotfiles repo root: every optional package,
//! how it installs, and what setup it needs. Each pack can add its own
//! `catalog.toml` in the same format; its entries join the picker, and
//! `required = true` ones install on every machine using that pack.
//! Bundles (`[[bundle]]`) group packages; selecting one selects its packages.

use std::collections::BTreeSet;
use std::path::PathBuf as AppPath;
use std::path::{Path, PathBuf};

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

use crate::chezmoi::Pack;

#[derive(Debug, Deserialize)]
pub struct Catalog {
    #[serde(rename = "package")]
    pub packages: Vec<Package>,
    #[serde(rename = "bundle", default)]
    pub bundles: Vec<Bundle>,
    /// What happened to each pack's catalog, in pack order.
    #[serde(skip)]
    pub packs: Vec<PackCatalog>,
}

/// One pack's catalog.toml, as loaded.
#[derive(Debug)]
pub struct PackCatalog {
    pub spec: String,
    pub path: PathBuf,
    /// Ids this pack added to the catalog.
    pub added: Vec<String>,
    /// Ids already taken, with who has them ("the dotfiles catalog" or the
    /// earlier pack's name).
    pub skipped: Vec<(String, String)>,
    /// Present but unusable; all its entries are ignored (the templates never
    /// see it either: they read only validated copies).
    pub error: Option<String>,
}

/// Validated copies of pack catalogs that the chezmoi templates read, one
/// per pack, named by `Pack::key`. Written only after a file parses, so a
/// broken pack file cannot break apply.
pub const PACK_COPIES: &str = ".local/share/dotfiles/packs";

/// A named group of packages. Selecting it selects every member. Its
/// `presets` field is read only by .chezmoi.toml.tmpl on first init.
#[derive(Debug, Clone, Deserialize)]
pub struct Bundle {
    pub id: String,
    pub name: String,
    pub description: String,
    pub packages: Vec<String>,
}

impl Bundle {
    /// Every member selected.
    pub fn is_selected(&self, selected: &BTreeSet<String>) -> bool {
        self.packages.iter().all(|id| selected.contains(id))
    }
}

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
    /// Cask -> app bundle ("1Password.app"). When the app already exists in
    /// /Applications or ~/Applications, the cask is skipped and counted as
    /// installed (it was installed by hand, or has self-updated past the cask).
    #[serde(default)]
    pub apps: std::collections::BTreeMap<String, String>,
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
    /// Agent skills: a bare name is a dotfiles skill (dot_agents/skills), an
    /// `owner/repo[@path]` an agentspec source.
    #[serde(default)]
    pub skills: Vec<String>,
    /// Work pack only: installs on every machine using the pack, selected or not.
    #[serde(default)]
    pub required: bool,
    /// The pack this entry came from (its folder name), if any.
    #[serde(skip)]
    pub pack: Option<String>,
}

impl Package {
    /// The app bundle for `cask`, when it is already on this machine
    /// (/Applications or ~/Applications).
    pub fn existing_app(&self, cask: &str) -> Option<AppPath> {
        let home = std::env::var_os("HOME").map(AppPath::from);
        let dirs: Vec<AppPath> = std::iter::once(AppPath::from("/Applications"))
            .chain(home.map(|h| h.join("Applications")))
            .collect();
        self.existing_app_in(cask, &dirs)
    }

    /// `existing_app`, searching `dirs`.
    pub fn existing_app_in(&self, cask: &str, dirs: &[AppPath]) -> Option<AppPath> {
        let app = self.apps.get(cask)?;
        dirs.iter().map(|dir| dir.join(app)).find(|p| p.exists())
    }

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
        names.extend(self.skills.iter().map(|s| format!("{s} (skill)")));
        names
    }

    /// What `installs` lists that Homebrew can uninstall (no skills).
    pub fn brew_names(&self) -> Vec<String> {
        self.installs()
            .into_iter()
            .filter(|n| !n.ends_with(" (skill)"))
            .collect()
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
    /// The dotfiles catalog plus each pack's, in pack order. A bad pack file
    /// never fails the load: it is recorded in `packs` and skipped, and an id
    /// that is already taken is skipped alone. Good files are copied to
    /// `home/PACK_COPIES` for the templates; copies of removed packs go.
    pub fn load(source_dir: &Path, packs: &[Pack], home: &Path) -> Result<Self> {
        let path = source_dir.join("catalog.toml");
        let text = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        let mut catalog =
            Self::parse(&text).with_context(|| format!("parsing {}", path.display()))?;
        let copies = home.join(PACK_COPIES);
        let mut keep = BTreeSet::new();
        for pack in packs {
            let path = pack.dir.join("catalog.toml");
            if !path.is_file() {
                continue;
            }
            keep.insert(format!("{}.toml", pack.key));
            let loaded = std::fs::read_to_string(&path)
                .map_err(anyhow::Error::from)
                .and_then(|text| Self::parse(&text).map(|c| (text, c)));
            let status = match loaded {
                Ok((text, pack_catalog)) => {
                    let copy = copies.join(format!("{}.toml", pack.key));
                    if std::fs::read_to_string(&copy).ok().as_deref() != Some(text.as_str()) {
                        let _ = std::fs::create_dir_all(&copies);
                        let _ = std::fs::write(&copy, &text);
                    }
                    let (mut added, mut skipped) = (Vec::new(), Vec::new());
                    for mut p in pack_catalog.packages {
                        if let Some(taken) = catalog.get(&p.id) {
                            let owner = taken
                                .pack
                                .clone()
                                .unwrap_or_else(|| "the dotfiles catalog".into());
                            skipped.push((p.id, owner));
                            continue;
                        }
                        p.pack = Some(pack.name());
                        added.push(p.id.clone());
                        catalog.packages.push(p);
                    }
                    for b in pack_catalog.bundles {
                        if catalog.get(&b.id).is_some() || catalog.bundle(&b.id).is_some() {
                            skipped.push((b.id, "the dotfiles catalog".into()));
                            continue;
                        }
                        added.push(b.id.clone());
                        catalog.bundles.push(b);
                    }
                    PackCatalog {
                        spec: pack.spec.clone(),
                        path,
                        added,
                        skipped,
                        error: None,
                    }
                }
                Err(err) => PackCatalog {
                    spec: pack.spec.clone(),
                    path,
                    added: Vec::new(),
                    skipped: Vec::new(),
                    error: Some(one_line(&format!("{err:#}"))),
                },
            };
            catalog.packs.push(status);
        }
        if let Ok(entries) = std::fs::read_dir(&copies) {
            for entry in entries.flatten() {
                if !keep.contains(&entry.file_name().to_string_lossy().to_string()) {
                    let _ = std::fs::remove_file(entry.path());
                }
            }
        }
        let _ = std::fs::remove_file(home.join(".local/share/dotfiles/work-catalog.toml"));
        Ok(catalog)
    }

    /// Everything that installs: the saved selection plus required pack entries.
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
        for id in catalog
            .packages
            .iter()
            .map(|p| &p.id)
            .chain(catalog.bundles.iter().map(|b| &b.id))
        {
            if !seen.insert(id.as_str()) {
                bail!("duplicate package or bundle id `{id}`");
            }
        }
        Ok(catalog)
    }

    pub fn get(&self, id: &str) -> Option<&Package> {
        self.packages.iter().find(|p| p.id == id)
    }

    pub fn bundle(&self, id: &str) -> Option<&Bundle> {
        self.bundles.iter().find(|b| b.id == id)
    }

    /// Resolve package or bundle ids (a bundle becomes its packages), failing
    /// on the first unknown one with a suggestion list.
    pub fn resolve<'a>(&'a self, ids: &[String]) -> Result<Vec<&'a Package>> {
        let mut out: Vec<&Package> = Vec::new();
        for id in ids {
            let members: Vec<&String> = match self.bundle(id) {
                Some(b) => b.packages.iter().collect(),
                None => vec![id],
            };
            for m in members {
                let p = self.get(m).ok_or_else(|| {
                    let known: Vec<&str> = self
                        .bundles
                        .iter()
                        .map(|b| b.id.as_str())
                        .chain(self.packages.iter().map(|p| p.id.as_str()))
                        .collect();
                    anyhow::anyhow!("unknown package `{m}`; known: {}", known.join(", "))
                })?;
                if !out.iter().any(|q| q.id == p.id) {
                    out.push(p);
                }
            }
        }
        Ok(out)
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
    fn pack_catalogs_stack_in_order() {
        let dir = std::env::temp_dir().join(format!("dotfiles-cat-{}", std::process::id()));
        let _ = std::fs::remove_dir_all(&dir);
        let (src, home) = (dir.join("src"), dir.join("home"));
        let (eng, backend) = (home.join("eng"), home.join("backend"));
        for d in [&src, &eng, &backend] {
            std::fs::create_dir_all(d).unwrap();
        }
        std::fs::write(src.join("catalog.toml"), SAMPLE).unwrap();
        let entry = |id: &str, extra: &str| {
            format!(
                "[[package]]\nid = \"{id}\"\nname = \"{id}\"\ndescription = \"d\"\ncategory = \"work\"\n{extra}\n"
            )
        };
        std::fs::write(eng.join("catalog.toml"), entry("vpn", "required = true")).unwrap();
        // backend reuses `vpn` (taken by eng) and `notion` (dotfiles catalog).
        let backend_text = format!(
            "{}{}{}",
            entry("vpn", ""),
            entry("notion", ""),
            entry("pg", "")
        );
        std::fs::write(backend.join("catalog.toml"), &backend_text).unwrap();
        let packs = vec![Pack::parse("~/eng", &home), Pack::parse("~/backend", &home)];

        let c = Catalog::load(&src, &packs, &home).unwrap();
        assert_eq!(c.packs[0].added, vec!["vpn"]);
        assert_eq!(c.packs[1].added, vec!["pg"]);
        assert_eq!(
            c.packs[1].skipped,
            vec![
                ("vpn".to_string(), "eng".to_string()),
                ("notion".to_string(), "the dotfiles catalog".to_string())
            ]
        );
        assert_eq!(c.get("vpn").unwrap().pack.as_deref(), Some("eng"));
        assert_eq!(
            c.effective(&["pg".into()]).into_iter().collect::<Vec<_>>(),
            vec!["pg", "vpn"]
        );
        let copy = |p: &Pack| home.join(PACK_COPIES).join(format!("{}.toml", p.key));
        assert_eq!(
            std::fs::read_to_string(copy(&packs[1])).unwrap(),
            backend_text
        );

        // A syntax error is reported, ignored, and keeps the last good copy.
        std::fs::write(backend.join("catalog.toml"), "[[package]]\nid = 1").unwrap();
        let c = Catalog::load(&src, &packs, &home).unwrap();
        assert!(c.packs[1].error.is_some() && c.get("pg").is_none());
        assert_eq!(
            std::fs::read_to_string(copy(&packs[1])).unwrap(),
            backend_text
        );

        // A pack removed from the list loses its copy.
        Catalog::load(&src, &packs[..1], &home).unwrap();
        assert!(!copy(&packs[1]).exists() && copy(&packs[0]).exists());
        let _ = std::fs::remove_dir_all(&dir);
    }

    #[test]
    fn resolve_reports_unknown() {
        let c = Catalog::parse(SAMPLE).unwrap();
        let err = c.resolve(&["nope".into()]).unwrap_err().to_string();
        assert!(err.contains("unknown package `nope`") && err.contains("acli"));
    }

    #[test]
    fn resolve_expands_bundles() {
        let text = format!(
            "{SAMPLE}\n[[bundle]]\nid = \"apps\"\nname = \"Apps\"\ndescription = \"d\"\npackages = [\"notion\", \"acli\"]\n"
        );
        let c = Catalog::parse(&text).unwrap();
        let ids: Vec<&str> = c
            .resolve(&["acli".into(), "apps".into()])
            .unwrap()
            .iter()
            .map(|p| p.id.as_str())
            .collect();
        assert_eq!(ids, vec!["acli", "notion"]);
        let selected: BTreeSet<String> = ["notion".to_string()].into();
        assert!(!c.bundle("apps").unwrap().is_selected(&selected));
        let clash = format!(
            "{text}\n[[bundle]]\nid = \"notion\"\nname = \"x\"\ndescription = \"x\"\npackages = []\n"
        );
        assert!(Catalog::parse(&clash).is_err());
    }

    /// The repo's catalog.toml: bundle members exist, and every bare skill
    /// name is a dot_agents/skills directory listed by one package only.
    #[test]
    fn repo_catalog_is_consistent() {
        let root = Path::new(env!("CARGO_MANIFEST_DIR")).join("..");
        let c =
            Catalog::parse(&std::fs::read_to_string(root.join("catalog.toml")).unwrap()).unwrap();
        for b in &c.bundles {
            for id in &b.packages {
                assert!(c.get(id).is_some(), "bundle {}: unknown package {id}", b.id);
            }
        }
        let mut seen = BTreeSet::new();
        for p in &c.packages {
            for s in p.skills.iter().filter(|s| !s.contains('/')) {
                assert!(
                    root.join("dot_agents/skills")
                        .join(s)
                        .join("SKILL.md")
                        .is_file(),
                    "{}: no skill {s}",
                    p.id
                );
                assert!(seen.insert(s.clone()), "skill {s} is in two packages");
            }
        }
    }
}
