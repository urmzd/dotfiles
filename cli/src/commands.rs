use std::collections::BTreeSet;
use std::fmt;
use std::io::IsTerminal;
use std::path::PathBuf;
use std::process::Command;

use anyhow::{Context, Result, bail};
use inquire::{Confirm, InquireError, MultiSelect};
use serde_json::json;

use crate::catalog::{Bundle, Catalog, Package};
use crate::chezmoi::{self, Config, Paths};
use crate::migrate;
use crate::state::{self, Inventory, Managed, Plan};
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
    let packs = config.packs(&paths.home);
    let catalog = Catalog::load(&paths.source, &packs, &paths.home)?;
    for pack in &catalog.packs {
        if let Some(error) = &pack.error {
            ui::warn(&format!("{}: catalog ignored: {error}", pack.spec));
        }
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

pub fn chezmoi_apply() -> Result<()> {
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
        let pack = self
            .pkg
            .pack
            .as_ref()
            .map(|p| format!("  [pack: {p}]"))
            .unwrap_or_default();
        let text = format!("{}{setup}{pack}", self.pkg.description);
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

/// One bundle row: checked when every member is selected.
struct BundleChoice<'a> {
    bundle: &'a Bundle,
    width: usize,
}

impl fmt::Display for BundleChoice<'_> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let label = format!("{} ({})", self.bundle.name, self.bundle.id);
        write!(
            f,
            "{label:<width$}  {}",
            self.bundle.description,
            width = self.width
        )
    }
}

/// Toggle whole bundles: a bundle turned on adds its packages, one turned
/// off removes them; untouched bundles change nothing.
fn pick_bundles(catalog: &Catalog, current: &BTreeSet<String>) -> Result<BTreeSet<String>> {
    let mut next = current.clone();
    if catalog.bundles.is_empty() {
        return Ok(next);
    }
    let width = catalog
        .bundles
        .iter()
        .map(|b| b.name.len() + b.id.len() + 3)
        .max()
        .unwrap_or(0);
    let choices: Vec<BundleChoice> = catalog
        .bundles
        .iter()
        .map(|bundle| BundleChoice { bundle, width })
        .collect();
    let was: Vec<usize> = catalog
        .bundles
        .iter()
        .enumerate()
        .filter(|(_, b)| b.is_selected(current))
        .map(|(i, _)| i)
        .collect();
    let picked: BTreeSet<String> = MultiSelect::new("Bundles", choices)
        .with_default(&was)
        .with_formatter(&|picked| format!("{} selected", picked.len()))
        .with_help_message(
            "space to toggle, enter for the package list (refine there), esc to cancel",
        )
        .prompt()?
        .into_iter()
        .map(|c| c.bundle.id.clone())
        .collect();
    for (i, b) in catalog.bundles.iter().enumerate() {
        match (was.contains(&i), picked.contains(&b.id)) {
            (false, true) => next.extend(b.packages.iter().cloned()),
            (true, false) => b.packages.iter().for_each(|id| {
                next.remove(id);
            }),
            _ => {}
        }
    }
    Ok(next)
}

pub fn packages(ctx: &Ctx, no_apply: bool) -> Result<Outcome> {
    let (paths, catalog, mut config) = load()?;
    let current: BTreeSet<String> = config.packages().into_iter().collect();
    require_tty("the package picker (or pass ids: dotfiles package add <id>...)")?;
    let bundled = pick_bundles(&catalog, &current)?;
    // Required pack entries always install; they are not a choice.
    let pool: Vec<&Package> = catalog.packages.iter().filter(|p| !p.required).collect();
    let next: BTreeSet<String> = pick("Optional packages", &pool, &bundled)?
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
            "already installs (required by its pack)",
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
            "is required by its pack; change the pack or remove the pack",
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

/// Ids of `pkgs`, skipping (with a note) packs' required entries.
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
    let leftovers: Vec<String> = removed.iter().flat_map(|p| p.brew_names()).collect();
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
        let files = chezmoi_apply();
        converge(paths, catalog, config, false).and(files)?;
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
                    "pack": p.pack, "required": p.required,
                })
            })
            .collect();
        println!("{}", serde_json::to_string_pretty(&data)?);
        return Ok(Outcome::Done);
    }

    let id_width = rows
        .iter()
        .map(|p| p.id.len())
        .chain(catalog.bundles.iter().map(|b| b.id.len()))
        .max()
        .unwrap_or(0);
    let bundles: Vec<&Bundle> = catalog
        .bundles
        .iter()
        .filter(|b| !selected_only || b.packages.iter().any(|id| selected.contains(id)))
        .collect();
    if !bundles.is_empty() {
        ui::section("bundles");
        for b in bundles {
            let have = b
                .packages
                .iter()
                .filter(|id| selected.contains(*id))
                .count();
            let line = format!(
                "{:<id_width$}  {} ({have}/{})  {}",
                b.id,
                b.name,
                b.packages.len(),
                ui::dim(&b.packages.join(", "))
            );
            if have == b.packages.len() {
                ui::ok(&line)
            } else {
                ui::skip(&line)
            }
        }
    }
    let name_width = rows
        .iter()
        .map(|p| p.name.chars().count() + tag(p).chars().count())
        .max()
        .unwrap_or(0);
    let mut category = "";
    for p in rows {
        if p.category != category {
            category = &p.category;
            ui::section(category);
        }
        let label = format!("{}{}", p.name, tag(p));
        let line = format!(
            "{:<id_width$}  {:<name_width$}  {}",
            p.id,
            label,
            ui::dim(&p.description)
        );
        if selected.contains(&p.id) {
            ui::ok(&line)
        } else {
            ui::skip(&line)
        }
    }
    ui::hint("change: dotfiles package");
    Ok(Outcome::Done)
}

fn tag(p: &Package) -> String {
    match (&p.pack, p.required) {
        (Some(pack), true) => format!(" (pack {pack}, required)"),
        (Some(pack), false) => format!(" (pack {pack})"),
        _ => String::new(),
    }
}

// ---- Packs ----------------------------------------------------------------------

pub fn pack_list(ctx: &Ctx) -> Result<Outcome> {
    let (paths, catalog, config) = load()?;
    let packs = config.packs(&paths.home);
    let status = |spec: &str| catalog.packs.iter().find(|c| c.spec == spec);
    if ctx.format == Format::Json {
        let data: Vec<_> = packs
            .iter()
            .map(|p| {
                let c = status(&p.spec);
                let skipped: Vec<_> = c
                    .map(|c| {
                        c.skipped
                            .iter()
                            .map(|(id, owner)| json!({"id": id, "taken_by": owner}))
                            .collect()
                    })
                    .unwrap_or_default();
                json!({
                    "spec": p.spec, "dir": p.dir, "url": p.url, "present": p.dir.is_dir(),
                    "adds": c.map(|c| c.added.clone()).unwrap_or_default(),
                    "skipped": skipped,
                    "error": c.and_then(|c| c.error.clone()),
                })
            })
            .collect();
        println!("{}", serde_json::to_string_pretty(&data)?);
        return Ok(Outcome::Done);
    }
    ui::section("Packs (stacked in this order; later ones win)");
    if packs.is_empty() {
        ui::skip("none; add one: dotfiles pack add <git url | url//folder | ~/folder>");
        return Ok(Outcome::NoChange);
    }
    for (i, p) in packs.iter().enumerate() {
        let head = format!("{}. {}", i + 1, p.spec);
        if !p.dir.is_dir() {
            ui::warn(&format!("{head}  not fetched yet"));
            ui::hint(if p.url.is_some() {
                "dotfiles apply clones it (repo access: dotfiles identity)"
            } else {
                "create the folder, or: dotfiles pack remove <spec>"
            });
            continue;
        }
        let Some(c) = status(&p.spec) else {
            ui::ok(&format!("{head}  {}", ui::dim("no catalog")));
            continue;
        };
        if let Some(error) = &c.error {
            ui::warn(&format!("{head}  catalog ignored"));
            ui::hint(&format!("{error}; fix {}", c.path.display()));
            continue;
        }
        let adds: Vec<String> = c
            .added
            .iter()
            .map(|id| match catalog.get(id) {
                Some(pkg) if pkg.required => format!("{id} (required)"),
                _ => id.clone(),
            })
            .collect();
        let detail = if adds.is_empty() {
            "adds no packages".to_string()
        } else {
            format!("adds {}", adds.join(", "))
        };
        ui::ok(&format!("{head}  {}", ui::dim(&detail)));
        if !c.skipped.is_empty() {
            ui::hint(&format!("skipped: {}", crate::doctor::taken(&c.skipped)));
        }
    }
    Ok(Outcome::Done)
}

pub fn pack_add(ctx: &Ctx, specs: Vec<String>) -> Result<Outcome> {
    let (paths, _, mut config) = load()?;
    let mut list = config.pack_specs(&paths.home);
    let new: Vec<String> = specs
        .into_iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty() && !list.contains(s))
        .collect();
    if new.is_empty() {
        ui::skip("already in the pack list");
        return Ok(Outcome::NoChange);
    }
    ui::section("Packs");
    for s in &new {
        ui::change('+', s);
    }
    if ctx.dry_run {
        ui::skip("dry run; nothing saved");
        return Ok(Outcome::Done);
    }
    list.extend(new);
    save_packs(&paths, &mut config, &list)
}

pub fn pack_remove(ctx: &Ctx, specs: Vec<String>) -> Result<Outcome> {
    let (paths, _, mut config) = load()?;
    let list = config.pack_specs(&paths.home);
    let unknown: Vec<&String> = specs.iter().filter(|s| !list.contains(s)).collect();
    if !unknown.is_empty() {
        bail!(
            "not in the pack list: {}; see: dotfiles pack list",
            unknown
                .iter()
                .map(|s| s.as_str())
                .collect::<Vec<_>>()
                .join(", ")
        );
    }
    ui::section("Packs");
    for s in &specs {
        ui::change('-', s);
    }
    if ctx.dry_run {
        ui::skip("dry run; nothing saved");
        return Ok(Outcome::Done);
    }
    let next: Vec<String> = list.into_iter().filter(|s| !specs.contains(s)).collect();
    save_packs(&paths, &mut config, &next)?;
    ui::hint("its clone stays under ~/.config/packs; delete it by hand if unused");
    Ok(Outcome::Done)
}

/// Save the list and apply twice: the first apply fetches new packs, the
/// second renders what they contain (AGENTS.md, Brewfile, catalog).
fn save_packs(paths: &Paths, config: &mut Config, list: &[String]) -> Result<Outcome> {
    config.set_packs(list)?;
    config.save()?;
    ui::ok(&format!("saved to {}", paths.config.display()));
    let first = chezmoi_apply();
    let (paths, catalog, config) = load()?;
    let second = chezmoi_apply();
    let packages = converge(&paths, &catalog, &config, false);
    first.and(second).and(packages)?;
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

/// Desired vs observed, computed fresh: pending migrations (applied in
/// memory), managed files that differ, and the package plan.
struct Pending {
    migrations: Vec<String>,
    files: Vec<String>,
    plan: Plan,
}

impl Pending {
    fn compute(paths: &Paths, catalog: &Catalog, config: &mut Config) -> Result<Self> {
        let migrations = migrate::run(config, catalog)?;
        let files = chezmoi::pending_files()?;
        let exclude = state::excludes(config.data_str("pkg_exclude"));
        let plan = state::plan(
            catalog,
            &config.packages(),
            &Inventory::read(),
            &exclude,
            &Managed::load(&paths.home),
        );
        Ok(Self {
            migrations,
            files,
            plan,
        })
    }

    fn has_work(&self, prune: bool) -> bool {
        !self.migrations.is_empty() || !self.files.is_empty() || self.plan.has_work(prune)
    }

    fn show(&self, catalog: &Catalog, prune: bool) {
        let name = |id: &String| catalog.get(id).map_or(id.clone(), |p| p.name.clone());
        if !self.migrations.is_empty() {
            ui::section("Config migrations");
            for m in &self.migrations {
                ui::change('+', m);
            }
        }
        if !self.files.is_empty() {
            ui::section(&format!(
                "Files ({} to update)",
                ui::count(self.files.len(), "file")
            ));
            // A fresh machine changes every file; the full list is `dotfiles diff`.
            const SHOWN: usize = 10;
            for f in self.files.iter().take(SHOWN) {
                // `chezmoi status` lines are "<2 status columns> <path>".
                let path = f.get(3..).unwrap_or(f).trim();
                ui::change('~', &format!("~/{path}"));
            }
            if self.files.len() > SHOWN {
                ui::skip(&format!(
                    "and {} more (dotfiles diff)",
                    self.files.len() - SHOWN
                ));
            }
        }
        let plan = &self.plan;
        if !(plan.install.is_empty() && plan.remove.is_empty() && plan.setup.is_empty()) {
            ui::section("Packages");
        }
        for id in &plan.install {
            ui::change(
                '+',
                &format!("{} ({id}): selected, not installed", name(id)),
            );
        }
        for id in &plan.remove {
            if prune {
                ui::change(
                    '-',
                    &format!("{} ({id}): deselected, will be uninstalled", name(id)),
                );
            } else {
                ui::change(
                    '-',
                    &format!(
                        "{} ({id}): deselected, still installed (remove with --prune)",
                        name(id)
                    ),
                );
            }
        }
        for id in &plan.setup {
            ui::change(
                '~',
                &format!(
                    "{} ({id}): sign-in pending (dotfiles package setup {id})",
                    name(id)
                ),
            );
        }
        if !plan.unmanaged.is_empty() {
            ui::section("Not managed (installed by hand, left alone)");
            ui::skip(&format!(
                "{} (adopt: dotfiles package add <id>)",
                plan.unmanaged.join(", ")
            ));
        }
    }

    fn json(&self) -> serde_json::Value {
        json!({ "migrations": self.migrations, "files": self.files, "packages": self.plan })
    }
}

pub fn plan(ctx: &Ctx, prune: bool) -> Result<Outcome> {
    let (paths, catalog, mut config) = load()?;
    let pending = Pending::compute(&paths, &catalog, &mut config)?;
    if ctx.format == Format::Json {
        println!("{}", serde_json::to_string_pretty(&pending.json())?);
    } else if pending.has_work(prune) {
        pending.show(&catalog, prune);
        ui::hint("apply: dotfiles apply");
    } else {
        // Verdict first, then the informational extras.
        ui::section("Plan");
        ui::ok("up to date: files applied, every selected package installed");
        pending.show(&catalog, prune);
    }
    Ok(if pending.has_work(prune) {
        Outcome::Done
    } else {
        Outcome::NoChange
    })
}

/// Make the machine match the desired state: config migrations, managed
/// files (chezmoi apply), then any selected package still missing.
pub fn apply(ctx: &Ctx, yes: bool, prune: bool) -> Result<Outcome> {
    let (paths, catalog, mut config) = load()?;
    let pending = Pending::compute(&paths, &catalog, &mut config)?;
    if !pending.has_work(prune) {
        ui::section("Apply");
        ui::ok("already up to date");
        pending.show(&catalog, prune);
        // Still record ownership, so a later deselect can be pruned.
        if !ctx.dry_run {
            let mut managed = Managed::load(&paths.home);
            let exclude = state::excludes(config.data_str("pkg_exclude"));
            managed.refresh(&catalog, &config.packages(), &Inventory::read(), &exclude);
            managed.save()?;
        }
        return Ok(Outcome::NoChange);
    }
    pending.show(&catalog, prune);
    if ctx.dry_run {
        ui::skip("dry run; nothing applied");
        return Ok(Outcome::Done);
    }
    if !yes && !confirm("Apply these changes?", true)? {
        ui::skip("cancelled; nothing applied");
        return Ok(Outcome::NoChange);
    }
    if !pending.migrations.is_empty() {
        config.save()?;
    }
    let files = if pending.files.is_empty() && pending.migrations.is_empty() {
        Ok(())
    } else {
        chezmoi_apply()
    };
    // Converge even when chezmoi reported a failed step: packages are independent.
    let packages = converge(&paths, &catalog, &config, prune);
    files.and(packages)?;
    Ok(Outcome::Done)
}

/// Install what the plan says is missing (and, with `prune`, uninstall what
/// was deselected), probing again first since chezmoi apply may have just
/// installed some of it. Records ownership afterwards.
fn converge(paths: &Paths, catalog: &Catalog, config: &Config, prune: bool) -> Result<()> {
    let selected = config.packages();
    let exclude = state::excludes(config.data_str("pkg_exclude"));
    let mut managed = Managed::load(&paths.home);
    let inv = Inventory::read();
    let plan = state::plan(catalog, &selected, &inv, &exclude, &managed);
    let mut failed = Vec::new();
    if plan.has_work(prune) {
        ui::section("Packages");
    }
    for id in &plan.install {
        let Some(p) = catalog.get(id) else { continue };
        let cmd = state::install_command(p, &inv, &exclude);
        if cmd.is_empty() || !sh(&format!("install {}", p.name), &cmd)? {
            failed.push(id.clone());
        }
    }
    if prune {
        for id in &plan.remove {
            let Some(p) = catalog.get(id) else { continue };
            match state::uninstall_command(p, &inv) {
                Some(cmd) => {
                    if !sh(&format!("uninstall {}", p.name), &cmd)? {
                        failed.push(id.clone());
                    }
                }
                None => ui::warn(&format!(
                    "{} came from an installer script; remove it by hand",
                    p.name
                )),
            }
        }
    }
    managed.refresh(catalog, &selected, &Inventory::read(), &exclude);
    managed.save()?;
    if !failed.is_empty() {
        bail!(
            "could not install or remove: {}; retry: dotfiles apply (dotfiles doctor shows the state)",
            failed.join(", ")
        );
    }
    Ok(())
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
        short_version(
            String::from_utf8_lossy(&out.stdout)
                .lines()
                .next()
                .unwrap_or(""),
        )
    })
}

/// The version number from a `--version` line, with the tool's own
/// decoration (product name, commit, build date) kept only when there is no
/// recognizable number: `chezmoi version v2.70.5, commit ...` -> `v2.70.5`.
fn short_version(line: &str) -> String {
    line.split(|c: char| c.is_whitespace() || c == ',')
        .find(|w| {
            let w = w.trim_start_matches('v');
            w.contains('.') && w.chars().next().is_some_and(|c| c.is_ascii_digit())
        })
        .map(|w| w.trim_end_matches('.').to_string())
        .unwrap_or_else(|| line.trim().to_string())
}

pub fn status(ctx: &Ctx) -> Result<Outcome> {
    let (paths, catalog, config) = load()?;
    let selected = config.packages();
    let packs = config.pack_specs(&paths.home);
    let effective = catalog.effective(&selected);
    let pending: Vec<&str> = catalog
        .packages
        .iter()
        .filter(|p| effective.contains(&p.id) && !p.setup.is_empty())
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
            "packs": packs,
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
    ui::ok(&format!(
        "packs: {}",
        if packs.is_empty() {
            "none".into()
        } else {
            packs.join(", ")
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
    ui::section("Dotfiles (pull)");
    if !chezmoi::run(&["update", "--apply=false"])?.success() {
        ui::warn("could not pull the dotfiles; applying the current checkout");
        ui::hint("check: git -C \"$(chezmoi source-path)\" status");
    }
    // A fresh process would load the pulled catalog; this one reads it now.
    apply(ctx, true, false)
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

#[cfg(test)]
mod tests {
    #[test]
    fn short_versions() {
        use super::short_version;
        assert_eq!(
            short_version("chezmoi version v2.70.5, commit b81bd8d, built at 2026-06-03T21:59:37Z"),
            "v2.70.5"
        );
        assert_eq!(short_version("2.1.289 (Claude Code)"), "2.1.289");
        assert_eq!(short_version("GitHub Copilot CLI 1.0.91."), "1.0.91");
        assert_eq!(short_version("codex-cli 0.160.1"), "0.160.1");
        assert_eq!(short_version("nightly"), "nightly");
    }
}
