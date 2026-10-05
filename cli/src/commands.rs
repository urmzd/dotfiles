use std::collections::BTreeSet;
use std::fmt;
use std::io::IsTerminal;
use std::path::PathBuf;
use std::process::Command;

use anyhow::{Context, Result, bail};
use inquire::{Confirm, InquireError, MultiSelect};
use serde_json::json;

use crate::catalog::{Catalog, Package, WorkCatalog};
use crate::chezmoi::{self, Config, Paths};
use crate::{Format, Outcome, UpdateTarget, ui};

pub struct Ctx {
    pub format: Format,
    pub dry_run: bool,
}

/// Release binaries (dotfiles-<target> + .sha256) are attached to dotfiles releases.
const REPO: &str = "urmzd/dotfiles";

pub fn is_interrupt(err: &anyhow::Error) -> bool {
    matches!(
        err.downcast_ref::<InquireError>(),
        Some(InquireError::OperationCanceled | InquireError::OperationInterrupted)
    )
}

fn load() -> Result<(Paths, Catalog, Config)> {
    let paths = Paths::discover()?;
    let config = Config::load(&paths.config)?;
    let work = config.work_pack_dir(&paths.home);
    let catalog = Catalog::load(&paths.source, work.as_deref(), &paths.home)?;
    if let WorkCatalog::Invalid { path, error } = &catalog.work {
        ui::warn(&format!(
            "work catalog ignored ({}): {error}",
            path.display()
        ));
    }
    Ok((paths, catalog, config))
}

pub fn require_tty(what: &str) -> Result<()> {
    if !std::io::stdin().is_terminal() {
        bail!("{what} needs a terminal");
    }
    Ok(())
}

fn confirm(question: &str, default: bool) -> Result<bool> {
    require_tty("confirmation (pass --yes to skip it)")?;
    Ok(Confirm::new(question).with_default(default).prompt()?)
}

fn home() -> Result<PathBuf> {
    std::env::var_os("HOME")
        .map(PathBuf::from)
        .context("HOME is not set")
}

/// Run a shell command with inherited stdio, reporting the outcome.
fn sh(label: &str, cmd: &str) -> Result<bool> {
    ui::step(label);
    let status = Command::new("sh")
        .args(["-c", cmd])
        .status()
        .with_context(|| format!("running `{cmd}`"))?;
    if status.success() {
        ui::ok(label);
    } else {
        ui::fail(&format!("{label} (exit {})", status.code().unwrap_or(1)));
    }
    Ok(status.success())
}

/// Shell test that succeeds quietly, e.g. a package's `check`.
fn passes(check: &str) -> bool {
    Command::new("sh")
        .args(["-c", check])
        .stdout(std::process::Stdio::null())
        .stderr(std::process::Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

fn chezmoi_apply() -> Result<()> {
    ui::section("Applying");
    // --keep-going: without it chezmoi stops at the first failing script and
    // skips the rest; with it every step runs and failed one-time scripts are
    // not recorded, so the next apply retries them.
    if !chezmoi::run(&["apply", "--keep-going"])?.success() {
        bail!(
            "some steps failed (listed above); everything else was applied. Retry with: dotfiles apply"
        );
    }
    Ok(())
}

// ---- Package selection --------------------------------------------------------

/// One picker row. The Display text is what the search matches against.
struct Choice<'a> {
    pkg: &'a Package,
    width: usize,
    /// Room left for the description so rows never wrap.
    room: usize,
}

impl fmt::Display for Choice<'_> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let label = format!("{} ({})", self.pkg.name, self.pkg.id);
        let setup = if self.pkg.setup.is_empty() {
            ""
        } else {
            "  [setup]"
        };
        let work = if self.pkg.work { "  [work pack]" } else { "" };
        let text = format!("{}{setup}{work}", self.pkg.description);
        let text = if text.chars().count() > self.room {
            let cut: String = text.chars().take(self.room.saturating_sub(1)).collect();
            format!("{cut}…")
        } else {
            text
        };
        write!(
            f,
            "{label:<width$}  {:<9}  {text}",
            self.pkg.category,
            width = self.width
        )
    }
}

/// Search-as-you-type multi-select over `pool`, with `checked` pre-selected.
fn pick(prompt: &str, pool: &[&Package], checked: &BTreeSet<String>) -> Result<Vec<String>> {
    require_tty("the package picker (or pass ids: dotfiles package add <id>...)")?;
    if pool.is_empty() {
        return Ok(Vec::new());
    }
    let width = pool
        .iter()
        .map(|p| p.name.len() + p.id.len() + 3)
        .max()
        .unwrap_or(0);
    // Row prefix: "> [x] " (6) + label + 2 + category (9) + 2.
    let cols = crossterm::terminal::size().map_or(100, |(c, _)| usize::from(c));
    let room = cols.saturating_sub(6 + width + 2 + 9 + 2 + 1).max(12);
    let choices: Vec<Choice> = pool
        .iter()
        .map(|&pkg| Choice { pkg, width, room })
        .collect();
    let defaults: Vec<usize> = pool
        .iter()
        .enumerate()
        .filter(|(_, p)| checked.contains(&p.id))
        .map(|(i, _)| i)
        .collect();
    let picked = MultiSelect::new(prompt, choices)
        .with_default(&defaults)
        .with_page_size(15)
        .with_formatter(&|picked| format!("{} selected", picked.len()))
        .with_help_message(
            "type to search, space to toggle, → all, ← none, enter to save, esc to cancel",
        )
        .prompt()?;
    Ok(picked.into_iter().map(|c| c.pkg.id.clone()).collect())
}

pub fn packages(ctx: &Ctx, no_apply: bool) -> Result<Outcome> {
    let (paths, catalog, mut config) = load()?;
    let current: BTreeSet<String> = config.packages().into_iter().collect();
    // Required work pack entries always install; they are not a choice.
    let pool: Vec<&Package> = catalog.packages.iter().filter(|p| !p.required).collect();
    let next: BTreeSet<String> = pick("Optional packages", &pool, &current)?
        .into_iter()
        .collect();
    commit(
        ctx,
        &paths,
        &catalog,
        &mut config,
        &current,
        &next,
        false,
        no_apply,
    )
}

pub fn add(ctx: &Ctx, ids: Vec<String>, no_apply: bool) -> Result<Outcome> {
    let (paths, catalog, mut config) = load()?;
    let current: BTreeSet<String> = config.packages().into_iter().collect();
    let ids = if ids.is_empty() {
        let pool: Vec<&Package> = catalog
            .packages
            .iter()
            .filter(|p| !p.required && !current.contains(&p.id))
            .collect();
        pick("Add packages", &pool, &BTreeSet::new())?
    } else {
        not_required(
            catalog.resolve(&ids)?,
            "already installs (required by the work pack)",
        )
    };
    let next = current.iter().cloned().chain(ids).collect();
    commit(
        ctx,
        &paths,
        &catalog,
        &mut config,
        &current,
        &next,
        false,
        no_apply,
    )
}

pub fn remove(ctx: &Ctx, ids: Vec<String>, uninstall: bool, no_apply: bool) -> Result<Outcome> {
    let (paths, catalog, mut config) = load()?;
    let current: BTreeSet<String> = config.packages().into_iter().collect();
    let ids: BTreeSet<String> = if ids.is_empty() {
        let pool: Vec<&Package> = catalog
            .packages
            .iter()
            .filter(|p| !p.required && current.contains(&p.id))
            .collect();
        pick("Remove packages", &pool, &BTreeSet::new())?
            .into_iter()
            .collect()
    } else {
        not_required(
            catalog.resolve(&ids)?,
            "is required by the work pack; remove it there",
        )
        .into_iter()
        .collect()
    };
    let next = current.difference(&ids).cloned().collect();
    commit(
        ctx,
        &paths,
        &catalog,
        &mut config,
        &current,
        &next,
        uninstall,
        no_apply,
    )
}

/// Ids of `pkgs`, skipping (with a note) the work pack's required entries.
fn not_required(pkgs: Vec<&Package>, why: &str) -> Vec<String> {
    pkgs.into_iter()
        .filter(|p| {
            if p.required {
                ui::skip(&format!("{} {why}", p.name));
            }
            !p.required
        })
        .map(|p| p.id.clone())
        .collect()
}

/// Save a new selection, apply it, and offer setup for what was added.
#[allow(clippy::too_many_arguments)]
fn commit(
    ctx: &Ctx,
    paths: &Paths,
    catalog: &Catalog,
    config: &mut Config,
    current: &BTreeSet<String>,
    next: &BTreeSet<String>,
    uninstall: bool,
    no_apply: bool,
) -> Result<Outcome> {
    let added: Vec<&Package> = next
        .difference(current)
        .filter_map(|id| catalog.get(id))
        .collect();
    let removed: Vec<&Package> = current
        .difference(next)
        .filter_map(|id| catalog.get(id))
        .collect();
    if added.is_empty() && removed.is_empty() {
        ui::skip("selection unchanged");
        return Ok(Outcome::NoChange);
    }

    ui::section("Packages");
    for p in &added {
        let installs = p.installs();
        let what = if installs.is_empty() {
            "setup only".to_string()
        } else {
            installs.join(", ")
        };
        ui::ok(&format!("+ {} ({what})", p.name));
    }
    for p in &removed {
        ui::ok(&format!("- {}", p.name));
    }
    if ctx.dry_run {
        ui::skip("dry run; nothing saved");
        return Ok(Outcome::Done);
    }

    config.set_packages(&next.iter().cloned().collect::<Vec<_>>())?;
    config.save()?;
    ui::ok(&format!("saved to {}", paths.config.display()));

    // brew bundle never uninstalls, so deselecting alone leaves software behind.
    let leftovers: Vec<String> = removed.iter().flat_map(|p| p.installs()).collect();
    if !leftovers.is_empty() {
        if uninstall {
            sh(
                "brew uninstall",
                &format!("brew uninstall {}", leftovers.join(" ")),
            )?;
        } else {
            ui::hint(&format!(
                "still installed; to remove: brew uninstall {}",
                leftovers.join(" ")
            ));
        }
    }

    if no_apply {
        ui::hint("apply later: dotfiles apply");
    } else {
        chezmoi_apply()?;
    }

    let needs_setup: Vec<&Package> = added.into_iter().filter(|p| !p.setup.is_empty()).collect();
    if !needs_setup.is_empty() {
        let ids: Vec<String> = needs_setup.iter().map(|p| p.id.clone()).collect();
        if !no_apply
            && std::io::stdin().is_terminal()
            && confirm(&format!("Run setup now for {}?", ids.join(", ")), true)?
        {
            return run_setup(ctx, &needs_setup, false);
        }
        ui::hint(&format!(
            "finish setup: dotfiles package setup {}",
            ids.join(" ")
        ));
    }
    Ok(Outcome::Done)
}

pub fn list(ctx: &Ctx, selected_only: bool) -> Result<Outcome> {
    let (_, catalog, config) = load()?;
    let selected = catalog.effective(&config.packages());
    let rows: Vec<&Package> = catalog
        .packages
        .iter()
        .filter(|p| !selected_only || selected.contains(&p.id))
        .collect();

    if ctx.format == Format::Json {
        let data: Vec<_> = rows
            .iter()
            .map(|p| {
                json!({
                    "id": p.id, "name": p.name, "category": p.category,
                    "description": p.description, "selected": selected.contains(&p.id),
                    "installs": p.installs(), "setup": p.setup,
                    "work_pack": p.work, "required": p.required,
                })
            })
            .collect();
        println!("{}", serde_json::to_string_pretty(&data)?);
        return Ok(Outcome::Done);
    }

    let mut category = "";
    for p in rows {
        if p.category != category {
            category = &p.category;
            ui::section(category);
        }
        let tag = match (p.work, p.required) {
            (true, true) => " (work pack, required)",
            (true, false) => " (work pack)",
            _ => "",
        };
        let line = format!("{:<12} {}{tag}  {}", p.id, p.name, ui::dim(&p.description));
        if selected.contains(&p.id) {
            ui::ok(&line)
        } else {
            ui::skip(&line)
        }
    }
    ui::hint("change: dotfiles package");
    Ok(Outcome::Done)
}

// ---- Setup ----------------------------------------------------------------------

pub fn setup(ctx: &Ctx, ids: Vec<String>, force: bool) -> Result<Outcome> {
    let (_, catalog, config) = load()?;
    let targets: Vec<&Package> = if ids.is_empty() {
        let selected = catalog.effective(&config.packages());
        catalog
            .packages
            .iter()
            .filter(|p| selected.contains(&p.id) && !p.setup.is_empty())
            .collect()
    } else {
        catalog.resolve(&ids)?
    };
    run_setup(ctx, &targets, force)
}

fn run_setup(ctx: &Ctx, targets: &[&Package], force: bool) -> Result<Outcome> {
    ui::section("Setup");
    let mut ran = false;
    let mut failed = Vec::new();
    for p in targets {
        if p.setup.is_empty() {
            ui::skip(&format!("{}: no setup needed", p.name));
            continue;
        }
        if !force && p.check.as_deref().is_some_and(passes) {
            ui::skip(&format!("{}: already set up", p.name));
            continue;
        }
        ran = true;
        for cmd in &p.setup {
            if ctx.dry_run {
                ui::skip(&format!("{}: would run `{cmd}`", p.name));
                continue;
            }
            require_tty("setup (it may open a browser or ask questions)")?;
            if !sh(&format!("{}: {cmd}", p.name), cmd)? {
                failed.push(p.id.clone());
                break;
            }
        }
    }
    if !failed.is_empty() {
        bail!(
            "setup failed for {}; rerun: dotfiles package setup {}",
            failed.join(", "),
            failed.join(" ")
        );
    }
    Ok(if ran {
        Outcome::Done
    } else {
        Outcome::NoChange
    })
}

// ---- chezmoi wrappers -----------------------------------------------------------

pub fn apply(ctx: &Ctx, yes: bool) -> Result<Outcome> {
    if !chezmoi::has_pending_changes()? {
        ui::ok("already up to date");
        return Ok(Outcome::NoChange);
    }
    ui::section("Pending changes");
    chezmoi::run(&["status", "--exclude", "scripts"])?;
    if ctx.dry_run {
        ui::skip("dry run; nothing applied");
        return Ok(Outcome::Done);
    }
    if !yes && !confirm("Apply these changes? (dotfiles diff shows details)", false)? {
        ui::skip("cancelled; nothing applied");
        return Ok(Outcome::NoChange);
    }
    chezmoi_apply()?;
    Ok(Outcome::Done)
}

pub fn diff() -> Result<Outcome> {
    chezmoi::run(&["diff", "--use-builtin-diff"])?;
    Ok(Outcome::Done)
}

pub fn config(ctx: &Ctx) -> Result<Outcome> {
    ui::section("Re-running setup questions (saved answers are kept)");
    if ctx.dry_run {
        ui::skip("dry run; would run chezmoi init, then apply");
        return Ok(Outcome::Done);
    }
    if !chezmoi::run(&["init"])?.success() {
        bail!("chezmoi init failed");
    }
    chezmoi_apply()?;
    Ok(Outcome::Done)
}

pub fn update(ctx: &Ctx, target: UpdateTarget) -> Result<Outcome> {
    let mut steps: Vec<(String, String)> = Vec::new();
    if matches!(target, UpdateTarget::All | UpdateTarget::Brew) {
        steps.push(("brew update".into(), "brew update".into()));
        steps.push(("brew upgrade".into(), "brew upgrade".into()));
    }
    if matches!(target, UpdateTarget::All | UpdateTarget::Ai) {
        // The selected AI coding CLIs (catalog category "agents"): Homebrew
        // ones are upgraded in place, installer-based ones re-run their
        // installer, which updates them.
        let (_, catalog, config) = load()?;
        let selected = config.packages();
        let agents: Vec<&Package> = catalog
            .packages
            .iter()
            .filter(|p| p.category == "agents" && selected.contains(&p.id))
            .collect();
        let brewed: Vec<&str> = agents
            .iter()
            .flat_map(|p| p.brew.iter().chain(&p.cask))
            .map(String::as_str)
            .collect();
        if cfg!(target_os = "macos") && !brewed.is_empty() && matches!(target, UpdateTarget::Ai) {
            steps.push(("brew update".into(), "brew update".into()));
            steps.push((
                format!("upgrade {}", brewed.join(", ")),
                format!("brew upgrade {}", brewed.join(" ")),
            ));
        }
        for p in agents {
            if let Some(cmd) = p.installer_command() {
                steps.push((format!("update {}", p.name), cmd));
            }
        }
    }

    ui::section("Updating");
    if ctx.dry_run {
        for (label, cmd) in &steps {
            ui::skip(&format!("would run {label}: {cmd}"));
        }
        ui::skip("would run chezmoi apply");
        return Ok(Outcome::Done);
    }
    for (label, cmd) in &steps {
        if !sh(label, cmd)? {
            bail!("{label} failed; fix it, then rerun: dotfiles package update");
        }
    }
    chezmoi_apply()?;
    Ok(Outcome::Done)
}

// ---- Inspection -----------------------------------------------------------------

fn version_of(bin: &str) -> Option<String> {
    let out = Command::new(bin).arg("--version").output().ok()?;
    out.status.success().then(|| {
        String::from_utf8_lossy(&out.stdout)
            .lines()
            .next()
            .unwrap_or("")
            .trim()
            .to_string()
    })
}

pub fn status(ctx: &Ctx) -> Result<Outcome> {
    let (_, catalog, config) = load()?;
    let selected = config.packages();
    let pending: Vec<&str> = catalog
        .packages
        .iter()
        .filter(|p| selected.contains(&p.id) && !p.setup.is_empty())
        .filter(|p| !p.check.as_deref().is_some_and(passes))
        .map(|p| p.id.as_str())
        .collect();
    let tools = [
        "chezmoi", "claude", "codex", "agy", "copilot", "opencode", "cortex",
    ];
    let versions: Vec<(&str, Option<String>)> = tools.iter().map(|t| (*t, version_of(t))).collect();

    if ctx.format == Format::Json {
        let tools: serde_json::Map<String, serde_json::Value> = versions
            .iter()
            .map(|(t, v)| (t.to_string(), json!(v)))
            .collect();
        let data = json!({
            "version": env!("CARGO_PKG_VERSION"),
            "machine": config.machine(),
            "packages": selected,
            "setup_pending": pending,
            "tools": tools,
        });
        println!("{}", serde_json::to_string_pretty(&data)?);
        return Ok(Outcome::Done);
    }

    ui::section("Dotfiles");
    ui::ok(&format!(
        "machine: {}",
        config.machine().unwrap_or_else(|| "unknown".into())
    ));
    ui::ok(&format!(
        "packages: {}",
        if selected.is_empty() {
            "none".into()
        } else {
            selected.join(", ")
        }
    ));
    if !pending.is_empty() {
        ui::warn(&format!("setup pending: {}", pending.join(", ")));
        ui::hint("finish it: dotfiles package setup");
    }
    ui::section("Tools");
    for (tool, version) in versions {
        match version {
            Some(v) => ui::ok(&format!("{tool}: {v}")),
            None => ui::skip(&format!("{tool}: not installed")),
        }
    }
    Ok(Outcome::Done)
}

pub fn edit() -> Result<Outcome> {
    let paths = Paths::discover()?;
    let editor = std::env::var("EDITOR").unwrap_or_else(|_| "nvim".into());
    Command::new(&editor)
        .arg(".")
        .current_dir(&paths.source)
        .status()
        .with_context(|| format!("running {editor}"))?;
    Ok(Outcome::Done)
}

pub fn clean(ctx: &Ctx, yes: bool) -> Result<Outcome> {
    let root = home()?.join("github");
    let root = root.display();
    let find = |name: &str, depth: u8| {
        format!("find '{root}' -maxdepth {depth} -name {name} -type d -prune")
    };
    ui::section(&format!("Clean regenerable artifacts under {root}"));
    if ctx.dry_run {
        sh(
            "would remove these directories",
            &format!(
                "{{ {}; {}; {}; }} 2>/dev/null",
                find("target", 3),
                find("node_modules", 3),
                find("__pycache__", 4)
            ),
        )?;
        ui::skip("would also clear go, pip, uv, and Homebrew caches");
        return Ok(Outcome::Done);
    }
    if !yes
        && !confirm(
            "Delete target/, node_modules/, __pycache__/ and tool caches?",
            false,
        )?
    {
        ui::skip("cancelled; nothing removed");
        return Ok(Outcome::NoChange);
    }
    sh("disk before", "df -h / | awk 'NR==2 {print $4 \" free\"}'")?;
    for (name, depth) in [("target", 3), ("node_modules", 3), ("__pycache__", 4)] {
        sh(
            &format!("removed {name}/ directories"),
            &format!(
                "{} -exec rm -rf {{}} + 2>/dev/null; true",
                find(name, depth)
            ),
        )?;
    }
    sh(
        "cleared tool caches",
        "go clean -cache 2>/dev/null; pip cache purge 2>/dev/null; uv cache clean 2>/dev/null; brew cleanup --prune=all -s 2>/dev/null; true",
    )?;
    sh("disk after", "df -h / | awk 'NR==2 {print $4 \" free\"}'")?;
    Ok(Outcome::Done)
}

/// `dotfiles update`: the CLI first (so the rest runs on the newest code
/// paths next time), then `chezmoi update`, which pulls the source repo and
/// applies. A failed CLI update only warns: the dotfiles still update.
pub fn update_all(ctx: &Ctx) -> Result<Outcome> {
    if ctx.dry_run {
        ui::skip("dry run; would update the CLI, then run chezmoi update");
        return Ok(Outcome::Done);
    }
    if let Err(err) = self_update() {
        ui::warn(&format!("CLI update failed: {err:#}"));
        ui::hint("retry later: dotfiles self-update");
    }
    ui::section("Dotfiles (pull + apply)");
    if !chezmoi::run(&["update", "--keep-going"])?.success() {
        bail!(
            "some steps failed (listed above); everything else was applied. Retry with: dotfiles update"
        );
    }
    Ok(Outcome::Done)
}

pub fn self_update() -> Result<Outcome> {
    ui::section("Self-update");
    ui::ok(&format!("current: v{}", env!("CARGO_PKG_VERSION")));
    match agentspec_update::self_update(REPO, env!("CARGO_PKG_VERSION"), "dotfiles")? {
        agentspec_update::UpdateResult::AlreadyUpToDate => {
            ui::skip("already up to date");
            Ok(Outcome::NoChange)
        }
        agentspec_update::UpdateResult::Updated { from, to } => {
            ui::ok(&format!("updated: {from} → {to}"));
            Ok(Outcome::Done)
        }
    }
}
