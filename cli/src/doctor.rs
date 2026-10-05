//! `dotfiles doctor`: one health report for the machine, each finding with the
//! command that fixes it. Read-only.

use std::process::{Command, Stdio};

use anyhow::Result;
use serde::Serialize;

use crate::catalog::Catalog;
use crate::chezmoi::{self, Config, Paths};
use crate::commands::Ctx;
use crate::identity::{gh_login, output};
use crate::{Format, Outcome, ui};

#[derive(Serialize, Clone, Copy, PartialEq)]
#[serde(rename_all = "lowercase")]
enum Level {
    Ok,
    Warn,
    Fail,
}

#[derive(Serialize)]
struct Finding {
    check: &'static str,
    level: Level,
    detail: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    fix: Option<String>,
}

#[derive(Default)]
struct Report(Vec<Finding>);

impl Report {
    fn ok(&mut self, check: &'static str, detail: impl Into<String>) {
        self.0.push(Finding {
            check,
            level: Level::Ok,
            detail: detail.into(),
            fix: None,
        });
    }
    fn warn(&mut self, check: &'static str, detail: impl Into<String>, fix: impl Into<String>) {
        self.0.push(Finding {
            check,
            level: Level::Warn,
            detail: detail.into(),
            fix: Some(fix.into()),
        });
    }
    fn fail(&mut self, check: &'static str, detail: impl Into<String>, fix: impl Into<String>) {
        self.0.push(Finding {
            check,
            level: Level::Fail,
            detail: detail.into(),
            fix: Some(fix.into()),
        });
    }
}

/// AI coding CLIs that have been installed more than one way at some point.
const SHADOW_CANDIDATES: &[&str] = &[
    "claude",
    "codex",
    "copilot",
    "agy",
    "opencode",
    "gemini",
    "cursor-agent",
    "amp",
];

pub fn run(ctx: &Ctx) -> Result<Outcome> {
    let mut r = Report::default();
    let paths = Paths::discover()?;

    check_chezmoi(&mut r);
    let catalog = Catalog::load(&paths.source).ok();
    let config = Config::load(&paths.config).ok();
    check_catalog(&mut r, catalog.as_ref(), config.as_ref());
    check_cli_version(&mut r);
    check_pending(&mut r);
    check_python(&mut r);
    if let Some(config) = &config {
        check_gh_account(&mut r, config);
    }
    check_signing(&mut r);
    check_shadowing(&mut r);
    if let (Some(catalog), Some(config)) = (&catalog, &config) {
        check_packages(&mut r, catalog, config);
    }

    if ctx.format == Format::Json {
        println!("{}", serde_json::to_string_pretty(&r.0)?);
    } else {
        ui::section("Doctor");
        for f in &r.0 {
            let line = format!("{}: {}", f.check, f.detail);
            match f.level {
                Level::Ok => ui::ok(&line),
                Level::Warn => ui::warn(&line),
                Level::Fail => ui::fail(&line),
            }
            if let Some(fix) = &f.fix {
                ui::hint(&format!("fix: {fix}"));
            }
        }
        let count = |l: Level| r.0.iter().filter(|f| f.level == l).count();
        let (warns, fails) = (count(Level::Warn), count(Level::Fail));
        if warns + fails == 0 {
            ui::ok("everything looks healthy");
        } else {
            ui::hint(&format!(
                "{fails} failing, {warns} warning; full chezmoi report: chezmoi doctor"
            ));
        }
    }
    let failing = r.0.iter().any(|f| f.level == Level::Fail);
    if failing {
        anyhow::bail!("doctor found failing checks");
    }
    Ok(Outcome::Done)
}

/// Only chezmoi doctor's warnings and errors; its full table is long.
fn check_chezmoi(r: &mut Report) {
    let Ok(out) = Command::new("chezmoi")
        .arg("doctor")
        .stderr(Stdio::null())
        .output()
    else {
        r.fail(
            "chezmoi",
            "chezmoi is not installed",
            "rerun the bootstrap (install.sh)",
        );
        return;
    };
    let text = String::from_utf8_lossy(&out.stdout);
    let mut problems = 0;
    for line in text.lines() {
        let mut cols = line.split_whitespace();
        let (Some(level), Some(name)) = (cols.next(), cols.next()) else {
            continue;
        };
        let message = cols.collect::<Vec<_>>().join(" ");
        match level {
            "warning" if name == "latest-version" => {
                r.warn(
                    "chezmoi",
                    format!("newer chezmoi available ({message})"),
                    "brew upgrade chezmoi",
                );
                problems += 1;
            }
            "warning" if message.contains("dirty") => {
                r.warn(
                    "chezmoi",
                    format!("{name}: {message}"),
                    "commit or stash the changes in ~/.local/share/chezmoi",
                );
                problems += 1;
            }
            "warning" => {
                r.warn("chezmoi", format!("{name}: {message}"), "chezmoi doctor");
                problems += 1;
            }
            "error" | "failed" => {
                r.fail("chezmoi", format!("{name}: {message}"), "chezmoi doctor");
                problems += 1;
            }
            _ => {}
        }
    }
    if problems == 0 {
        r.ok("chezmoi", "chezmoi doctor reports no problems");
    }
}

fn check_catalog(r: &mut Report, catalog: Option<&Catalog>, config: Option<&Config>) {
    let Some(catalog) = catalog else {
        r.fail(
            "catalog",
            "catalog.toml is missing or invalid",
            "git -C ~/.local/share/chezmoi pull",
        );
        return;
    };
    let Some(config) = config else {
        r.fail("config", "no chezmoi config", "chezmoi init");
        return;
    };
    let unknown: Vec<String> = config
        .packages()
        .into_iter()
        .filter(|id| catalog.get(id).is_none())
        .collect();
    if unknown.is_empty() {
        r.ok(
            "catalog",
            format!(
                "{} packages, every selected id exists",
                catalog.packages.len()
            ),
        );
    } else {
        r.warn(
            "catalog",
            format!("selected but not in the catalog: {}", unknown.join(", ")),
            format!("dotfiles package remove {}", unknown.join(" ")),
        );
    }
}

fn check_cli_version(r: &mut Report) {
    let current = env!("CARGO_PKG_VERSION");
    let latest = output(
        "gh",
        &[
            "api",
            "repos/urmzd/dotfiles/releases/latest",
            "--jq",
            ".tag_name",
        ],
    )
    .or_else(|| {
        output(
            "curl",
            &[
                "-fsSL",
                "--max-time",
                "5",
                "https://api.github.com/repos/urmzd/dotfiles/releases/latest",
            ],
        )
        .and_then(|j| serde_json::from_str::<serde_json::Value>(&j).ok())
        .and_then(|v| v["tag_name"].as_str().map(String::from))
    });
    match latest.as_deref().map(|t| t.trim_start_matches('v')) {
        Some(latest) if newer(latest, current) => r.warn(
            "cli",
            format!("dotfiles v{current}; v{latest} is available"),
            "dotfiles update",
        ),
        Some(_) => r.ok("cli", format!("dotfiles v{current} is the latest release")),
        None => r.ok(
            "cli",
            format!("dotfiles v{current} (could not check for a newer release)"),
        ),
    }
}

/// Whether dotted version `a` is newer than `b`.
fn newer(a: &str, b: &str) -> bool {
    let parse = |v: &str| {
        v.split('.')
            .map(|p| p.parse::<u64>().unwrap_or(0))
            .collect::<Vec<_>>()
    };
    parse(a) > parse(b)
}

fn check_pending(r: &mut Report) {
    if chezmoi::config_template_changed() {
        r.warn(
            "config",
            "the setup questions changed since this machine's config was generated",
            "chezmoi init (saved answers are kept), then dotfiles apply",
        );
    }
    match chezmoi::has_pending_changes() {
        Ok(true) => r.warn(
            "apply",
            "the dotfiles have changes not applied yet",
            "dotfiles apply",
        ),
        Ok(false) => r.ok("apply", "everything is applied"),
        Err(_) => r.warn(
            "apply",
            "could not compute pending changes",
            "chezmoi diff --use-builtin-diff",
        ),
    }
}

fn check_python(r: &mut Report) {
    let version = output("python3", &["--version"]).unwrap_or_default();
    let numbers: Vec<u64> = version
        .trim_start_matches("Python ")
        .split('.')
        .take(2)
        .filter_map(|p| p.parse().ok())
        .collect();
    if numbers.len() < 2 {
        r.warn(
            "python",
            "python3 not found",
            "chezmoi apply (installs the default Python with uv)",
        );
    } else if (numbers[0], numbers[1]) < (3, 12) {
        r.warn(
            "python",
            format!("python3 is {version}; gcloud components need 3.12+"),
            "open a new shell, or chezmoi apply (default Python via uv)",
        );
    } else {
        r.ok(
            "python",
            format!("python3 is {}", version.trim_start_matches("Python ")),
        );
    }
    match std::env::var("CLOUDSDK_PYTHON") {
        Ok(p) if std::path::Path::new(&p).exists() => {
            r.ok("gcloud", format!("CLOUDSDK_PYTHON = {p}"))
        }
        Ok(p) => r.warn(
            "gcloud",
            format!("CLOUDSDK_PYTHON points at a missing file: {p}"),
            "chezmoi apply",
        ),
        Err(_) if on_path("gcloud") => r.warn(
            "gcloud",
            "CLOUDSDK_PYTHON is not set; gcloud may pick macOS's Python 3.9",
            "open a new shell",
        ),
        Err(_) => {}
    }
}

fn check_gh_account(r: &mut Report, config: &Config) {
    let Some(want) = config.data_str("github_username") else {
        return;
    };
    if !on_path("gh") {
        return;
    }
    match gh_login() {
        Some(login) if login == want => r.ok("github", format!("gh signed in as {want}")),
        Some(login) => r.warn(
            "github",
            format!("gh is signed in as {login}, but this machine pushes as {want}"),
            "dotfiles identity",
        ),
        None => r.warn(
            "github",
            format!("gh is not signed in (this machine pushes as {want})"),
            "dotfiles identity",
        ),
    }
}

fn check_signing(r: &mut Report) {
    let key =
        output("git", &["config", "--global", "--get", "user.signingkey"]).unwrap_or_default();
    if key.is_empty() {
        r.warn(
            "signing",
            "no commit signing key configured",
            "dotfiles identity",
        );
        return;
    }
    let has_secret = Command::new("gpg")
        .args(["--list-secret-keys", &key])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success());
    if has_secret {
        r.ok("signing", format!("commits signed with {key}"));
    } else {
        r.fail(
            "signing",
            format!("signing key {key} is not in this machine's GPG keyring"),
            "dotfiles identity",
        );
    }
}

/// The same CLI installed twice: the first one on PATH wins, possibly stale.
fn check_shadowing(r: &mut Report) {
    let mut shadowed = Vec::new();
    for tool in SHADOW_CANDIDATES {
        let Some(all) = output("sh", &["-c", &format!("which -a {tool} 2>/dev/null")]) else {
            continue;
        };
        let mut real: Vec<String> = Vec::new();
        for path in all.lines() {
            let resolved = std::fs::canonicalize(path)
                .map(|p| p.display().to_string())
                .unwrap_or_else(|_| path.into());
            if !real.contains(&resolved) {
                real.push(resolved);
            }
        }
        if real.len() > 1 {
            shadowed.push(format!(
                "{tool} ({} copies; {} wins)",
                real.len(),
                all.lines().next().unwrap_or("")
            ));
        }
    }
    if shadowed.is_empty() {
        r.ok("path", "no AI CLI is installed twice");
    } else {
        r.warn(
            "path",
            format!("installed more than once: {}", shadowed.join("; ")),
            "remove the stale copy (often an npm global in fnm's Node); chezmoi apply migrates known ones",
        );
    }
}

fn check_packages(r: &mut Report, catalog: &Catalog, config: &Config) {
    let selected = config.packages();
    let passes = |check: &str| {
        Command::new("sh")
            .args(["-c", check])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|s| s.success())
    };
    let mut missing = Vec::new();
    let mut setup = Vec::new();
    for p in catalog.packages.iter().filter(|p| selected.contains(&p.id)) {
        let Some(check) = &p.check else { continue };
        if passes(check) {
            continue;
        }
        if p.script.is_some() {
            missing.push(p.id.clone());
        } else if !p.setup.is_empty() {
            setup.push(p.id.clone());
        }
    }
    if missing.is_empty() {
        r.ok("packages", "selected installer-based packages are present");
    } else {
        r.warn(
            "packages",
            format!("selected but not installed: {}", missing.join(", ")),
            "dotfiles apply",
        );
    }
    if !setup.is_empty() {
        r.warn(
            "setup",
            format!("sign-in pending: {}", setup.join(", ")),
            "dotfiles package setup",
        );
    }
}

fn on_path(tool: &str) -> bool {
    output("sh", &["-c", &format!("command -v {tool}")]).is_some()
}

#[cfg(test)]
mod tests {
    use super::newer;

    #[test]
    fn compares_versions_numerically() {
        assert!(newer("0.10.0", "0.9.9"));
        assert!(newer("1.0.0", "0.99.0"));
        assert!(!newer("0.4.0", "0.4.0"));
        assert!(!newer("0.3.9", "0.4.0"));
    }
}
