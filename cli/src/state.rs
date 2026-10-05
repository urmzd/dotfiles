//! Desired vs observed package state, the way Terraform plans: the desired
//! set is the saved selection plus required pack entries, the observed
//! set is probed from the machine on every run (brew, npm, uv, the Linux
//! package manager, or a package's `check`), and the plan is the difference.
//! Nothing records "installed", so a failed install can never be marked done.
//!
//! The one thing stored is ownership (`~/.local/state/dotfiles/managed.json`):
//! packages this CLI has seen selected and installed. Only those are offered
//! for removal when deselected; software installed by hand is never pruned.

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

use crate::catalog::{Catalog, Package};

/// Puts fnm's default Node (where npm globals live) on PATH for one command.
const FNM_ENV: &str = "if command -v fnm >/dev/null 2>&1; then eval \"$(fnm env --shell bash 2>/dev/null)\" >/dev/null 2>&1; fnm use default >/dev/null 2>&1; fi;";

/// Linux package manager on this machine.
#[derive(Clone, Copy, PartialEq)]
enum Linux {
    Apt,
    Dnf,
    Pacman,
}

/// Everything installed right now, read once per run.
pub struct Inventory {
    formulae: BTreeSet<String>,
    casks: BTreeSet<String>,
    npm: BTreeSet<String>,
    uv: BTreeSet<String>,
    linux: Option<Linux>,
    linux_pkgs: BTreeSet<String>,
}

fn lines(cmd: &str) -> BTreeSet<String> {
    Command::new("bash")
        .args(["-c", cmd])
        .stderr(Stdio::null())
        .output()
        .ok()
        .filter(|o| o.status.success())
        .map(|o| {
            String::from_utf8_lossy(&o.stdout)
                .lines()
                .map(str::trim)
                .filter(|l| !l.is_empty())
                .map(String::from)
                .collect()
        })
        .unwrap_or_default()
}

fn has(tool: &str) -> bool {
    Command::new("sh")
        .args(["-c", &format!("command -v {tool}")])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

/// Slow path for a name `brew list` did not print: an alias (kubectl is
/// kubernetes-cli) or a renamed cask. Homebrew resolves those itself.
fn brew_has(kind: &str, name: &str) -> bool {
    !cfg!(test)
        && Command::new("brew")
            .args(["list", kind, "--versions", name])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|s| s.success())
}

/// `tap/name/formula` and `formula` are the same installed formula.
fn short(name: &str) -> &str {
    name.rsplit('/').next().unwrap_or(name)
}

fn quote(s: &str) -> String {
    format!("'{}'", s.replace('\'', r"'\''"))
}

impl Inventory {
    pub fn read() -> Self {
        let mac = cfg!(target_os = "macos");
        let linux = if mac {
            None
        } else if has("apt-get") {
            Some(Linux::Apt)
        } else if has("dnf") {
            Some(Linux::Dnf)
        } else if has("pacman") {
            Some(Linux::Pacman)
        } else {
            None
        };
        let linux_pkgs = match linux {
            Some(Linux::Apt) => lines("dpkg-query -W -f='${Package}\\n'"),
            Some(Linux::Dnf) => lines("rpm -qa --qf '%{NAME}\\n'"),
            Some(Linux::Pacman) => lines("pacman -Qq"),
            None => BTreeSet::new(),
        };
        Self {
            formulae: if mac {
                lines("brew list --formula -1")
            } else {
                BTreeSet::new()
            },
            casks: if mac {
                lines("brew list --cask -1")
            } else {
                BTreeSet::new()
            },
            npm: lines(&format!(
                "{FNM_ENV} npm ls -g --depth=0 --parseable | sed -n '2,$p' | sed 's#.*/node_modules/##'"
            )),
            uv: lines("uv tool list | grep -v '^-' | cut -d' ' -f1"),
            linux,
            linux_pkgs,
        }
    }

    fn linux_names<'a>(&self, p: &'a Package) -> &'a [String] {
        match self.linux {
            Some(Linux::Apt) => &p.apt,
            Some(Linux::Dnf) => &p.dnf,
            Some(Linux::Pacman) => &p.pacman,
            None => &[],
        }
    }
}

/// Whether a package's pieces for this platform are all present.
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum Presence {
    Installed,
    Missing,
    /// Nothing installs on this platform (setup-only, or macOS-only on Linux).
    NotApplicable,
}

/// Names skipped by `pkg_exclude` in the chezmoi config (comma-separated).
pub fn excludes(raw: Option<String>) -> BTreeSet<String> {
    raw.unwrap_or_default()
        .split(',')
        .map(str::trim)
        .filter(|s| !s.is_empty())
        .map(String::from)
        .collect()
}

fn passes(check: &str) -> bool {
    Command::new("sh")
        .args(["-c", check])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

pub fn presence(p: &Package, inv: &Inventory, exclude: &BTreeSet<String>) -> Presence {
    let mac = cfg!(target_os = "macos");
    let mut wanted = 0;
    let mut missing = false;
    let mut need = |present: bool| {
        wanted += 1;
        missing |= !present;
    };
    let kept = |names: &[String]| -> Vec<String> {
        names
            .iter()
            .filter(|n| !exclude.contains(short(n)))
            .cloned()
            .collect()
    };
    if mac {
        for n in kept(&p.brew) {
            need(inv.formulae.contains(short(&n)) || brew_has("--formula", &n));
        }
        for n in kept(&p.cask) {
            need(inv.casks.contains(short(&n)) || brew_has("--cask", &n));
        }
    } else {
        for n in kept(inv.linux_names(p)) {
            need(inv.linux_pkgs.contains(&n));
        }
        for n in kept(&p.linux_npm) {
            need(inv.npm.contains(&n));
        }
    }
    for n in kept(&p.npm) {
        need(inv.npm.contains(&n));
    }
    for n in kept(&p.uv) {
        need(inv.uv.contains(&n));
    }
    if let (Some(_), Some(check)) = (&p.script, &p.check) {
        need(passes(check));
    }
    match (wanted, missing) {
        (0, _) => Presence::NotApplicable,
        (_, true) => Presence::Missing,
        _ => Presence::Installed,
    }
}

/// The difference between desired and observed, by package id.
#[derive(Debug, Default, Serialize)]
pub struct Plan {
    /// Desired, not installed: `dotfiles apply` installs them.
    pub install: Vec<String>,
    /// Managed here, deselected, still installed: `dotfiles apply --prune`.
    pub remove: Vec<String>,
    /// Desired and installed, sign-in not done: `dotfiles package setup`.
    pub setup: Vec<String>,
    /// Installed by hand, not selected: left alone (adopt with `package add`).
    pub unmanaged: Vec<String>,
}

impl Plan {
    pub fn has_work(&self, prune: bool) -> bool {
        !self.install.is_empty() || (prune && !self.remove.is_empty())
    }
}

pub fn plan(
    catalog: &Catalog,
    selected: &[String],
    inv: &Inventory,
    exclude: &BTreeSet<String>,
    managed: &Managed,
) -> Plan {
    let desired = catalog.effective(selected);
    let mut plan = Plan::default();
    for p in &catalog.packages {
        let want = desired.contains(&p.id);
        match (want, presence(p, inv, exclude)) {
            (true, Presence::Missing) => plan.install.push(p.id.clone()),
            (true, Presence::Installed) | (true, Presence::NotApplicable) => {
                let setup_pending = !p.setup.is_empty()
                    && p.script.is_none()
                    && p.check.as_deref().is_some_and(|c| !passes(c));
                if setup_pending {
                    plan.setup.push(p.id.clone());
                }
            }
            (false, Presence::Installed) if managed.ids.contains(&p.id) => {
                plan.remove.push(p.id.clone())
            }
            (false, Presence::Installed) => plan.unmanaged.push(p.id.clone()),
            _ => {}
        }
    }
    plan
}

/// Shell command that installs a package's pieces for this platform.
pub fn install_command(p: &Package, inv: &Inventory, exclude: &BTreeSet<String>) -> String {
    let kept = |names: &[String]| -> Vec<String> {
        names
            .iter()
            .filter(|n| !exclude.contains(short(n)))
            .map(|n| quote(n))
            .collect()
    };
    let mut steps = Vec::new();
    let mut npm = kept(&p.npm);
    if cfg!(target_os = "macos") {
        steps.extend(p.tap.iter().map(|t| format!("brew tap {}", quote(t))));
        let brew = kept(&p.brew);
        if !brew.is_empty() {
            steps.push(format!("brew install {}", brew.join(" ")));
        }
        let cask = kept(&p.cask);
        if !cask.is_empty() {
            let adopt = if p.adopt { " --adopt" } else { "" };
            steps.push(format!("brew install --cask{adopt} {}", cask.join(" ")));
        }
    } else {
        let names = kept(inv.linux_names(p));
        if !names.is_empty() {
            let names = names.join(" ");
            steps.push(match inv.linux {
                Some(Linux::Apt) => format!("sudo apt-get install -y {names}"),
                Some(Linux::Dnf) => format!("sudo dnf install -y {names}"),
                _ => format!("sudo pacman -S --noconfirm {names}"),
            });
        }
        npm.extend(kept(&p.linux_npm));
    }
    if !npm.is_empty() {
        steps.push(format!("{{ {FNM_ENV} npm install -g {}; }}", npm.join(" ")));
    }
    steps.extend(kept(&p.uv).iter().map(|n| format!("uv tool install {n}")));
    if let Some(installer) = p.installer_command() {
        let post = p
            .post
            .as_deref()
            .map(|c| format!(" && {{ {c}; true; }}"))
            .unwrap_or_default();
        steps.push(format!("( {installer} ){post}"));
    }
    steps.join(" && ")
}

/// Shell command that removes a package, or None when it came from an
/// installer script (no uninstaller to call).
pub fn uninstall_command(p: &Package, inv: &Inventory) -> Option<String> {
    let q = |names: &[String]| names.iter().map(|n| quote(n)).collect::<Vec<_>>();
    let mut steps = Vec::new();
    let mut npm = q(&p.npm);
    if cfg!(target_os = "macos") {
        let brew = q(&p.brew);
        if !brew.is_empty() {
            steps.push(format!("brew uninstall {}", brew.join(" ")));
        }
        let cask = q(&p.cask);
        if !cask.is_empty() {
            steps.push(format!("brew uninstall --cask {}", cask.join(" ")));
        }
    } else {
        let names = q(inv.linux_names(p));
        if !names.is_empty() {
            let names = names.join(" ");
            steps.push(match inv.linux {
                Some(Linux::Apt) => format!("sudo apt-get remove -y {names}"),
                Some(Linux::Dnf) => format!("sudo dnf remove -y {names}"),
                _ => format!("sudo pacman -R --noconfirm {names}"),
            });
        }
        npm.extend(q(&p.linux_npm));
    }
    if !npm.is_empty() {
        steps.push(format!(
            "{{ {FNM_ENV} npm uninstall -g {}; }}",
            npm.join(" ")
        ));
    }
    steps.extend(q(&p.uv).iter().map(|n| format!("uv tool uninstall {n}")));
    (!steps.is_empty()).then(|| steps.join(" && "))
}

/// Package ids this CLI owns: seen selected and installed, and not since
/// uninstalled. Deselecting keeps ownership until the software is gone.
#[derive(Debug, Default, Deserialize, Serialize)]
pub struct Managed {
    pub ids: BTreeSet<String>,
    #[serde(skip)]
    path: PathBuf,
}

impl Managed {
    pub fn load(home: &Path) -> Self {
        let path = home.join(".local/state/dotfiles/managed.json");
        let mut m: Managed = std::fs::read_to_string(&path)
            .ok()
            .and_then(|t| serde_json::from_str(&t).ok())
            .unwrap_or_default();
        m.path = path;
        m
    }

    /// Recompute from what is on the machine now.
    pub fn refresh(
        &mut self,
        catalog: &Catalog,
        selected: &[String],
        inv: &Inventory,
        exclude: &BTreeSet<String>,
    ) {
        let desired = catalog.effective(selected);
        self.ids = catalog
            .packages
            .iter()
            .filter(|p| desired.contains(&p.id) || self.ids.contains(&p.id))
            .filter(|p| presence(p, inv, exclude) == Presence::Installed)
            .map(|p| p.id.clone())
            .collect();
    }

    pub fn save(&self) -> Result<()> {
        if let Some(dir) = self.path.parent() {
            std::fs::create_dir_all(dir)?;
        }
        std::fs::write(&self.path, serde_json::to_string_pretty(self)?)
            .with_context(|| format!("writing {}", self.path.display()))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn inv(formulae: &[&str], casks: &[&str], npm: &[&str]) -> Inventory {
        let set = |v: &[&str]| v.iter().map(|s| s.to_string()).collect();
        Inventory {
            formulae: set(formulae),
            casks: set(casks),
            npm: set(npm),
            uv: BTreeSet::new(),
            linux: None,
            linux_pkgs: BTreeSet::new(),
        }
    }

    const CAT: &str = r#"
[[package]]
id = "acli"
name = "Atlassian CLI"
description = "d"
category = "work"
brew = ["atlassian/acli/acli"]

[[package]]
id = "notion"
name = "Notion"
description = "d"
category = "apps"
cask = ["notion"]

[[package]]
id = "slack"
name = "Slack"
description = "d"
category = "chat"
cask = ["slack"]

[[package]]
id = "mint"
name = "Mintlify"
description = "d"
category = "docs"
npm = ["mint"]
"#;

    #[test]
    fn plans_install_remove_and_unmanaged() {
        if !cfg!(target_os = "macos") {
            return;
        }
        let c = Catalog::parse(CAT).unwrap();
        // acli installed (tap-qualified name matches), notion missing,
        // slack installed by hand, mint deselected but owned.
        let i = inv(&["acli"], &["slack"], &["mint"]);
        let managed = Managed {
            ids: ["mint".to_string()].into(),
            ..Default::default()
        };
        let sel = vec!["acli".to_string(), "notion".to_string()];
        let p = plan(&c, &sel, &i, &BTreeSet::new(), &managed);
        assert_eq!(p.install, vec!["notion"]);
        assert_eq!(p.remove, vec!["mint"]);
        assert_eq!(p.unmanaged, vec!["slack"]);
        assert!(p.has_work(false));

        // Excluded names count as satisfied.
        let ex = excludes(Some("notion, k9s".into()));
        assert!(plan(&c, &sel, &i, &ex, &managed).install.is_empty());
    }

    #[test]
    fn ownership_follows_the_machine() {
        if !cfg!(target_os = "macos") {
            return;
        }
        let c = Catalog::parse(CAT).unwrap();
        let mut m = Managed {
            ids: ["mint".to_string(), "slack".to_string()].into(),
            ..Default::default()
        };
        // notion selected and now installed: owned. slack uninstalled: dropped.
        // mint deselected but still installed: kept, so --prune can remove it.
        m.refresh(
            &c,
            &["notion".into()],
            &inv(&[], &["notion"], &["mint"]),
            &BTreeSet::new(),
        );
        assert_eq!(
            m.ids.into_iter().collect::<Vec<_>>(),
            vec!["mint", "notion"]
        );
    }

    #[test]
    fn install_command_covers_each_source() {
        let c = Catalog::parse(CAT).unwrap();
        let i = inv(&[], &[], &[]);
        let cmd = install_command(c.get("mint").unwrap(), &i, &BTreeSet::new());
        assert!(cmd.contains("npm install -g 'mint'") && cmd.contains("fnm"));
        if cfg!(target_os = "macos") {
            let cmd = install_command(c.get("acli").unwrap(), &i, &BTreeSet::new());
            assert_eq!(cmd, "brew install 'atlassian/acli/acli'");
        }
    }
}
