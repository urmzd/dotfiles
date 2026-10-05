mod catalog;
mod chezmoi;
mod commands;
mod doctor;
mod identity;
mod ui;

use std::process::ExitCode;

use clap::{Args, Parser, Subcommand, ValueEnum};

/// Manage urmzd/dotfiles: pick optional packages, run their setup, apply, update.
#[derive(Parser)]
#[command(name = "dotfiles", version, about, propagate_version = true)]
struct Cli {
    /// Output format for commands that emit data
    #[arg(long, global = true, default_value = "human", value_enum)]
    format: Format,

    /// Show what would change without writing or applying
    #[arg(long, global = true)]
    dry_run: bool,

    #[command(subcommand)]
    command: Command,
}

#[derive(Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum Format {
    Human,
    Json,
}

#[derive(Subcommand)]
enum Command {
    /// Optional packages: pick (default), add, remove, list, setup, update
    #[command(visible_aliases = ["packages", "pkg"])]
    Package {
        #[command(subcommand)]
        action: Option<PackageCmd>,
        /// Picker only: save the selection without running chezmoi apply
        #[arg(long)]
        no_apply: bool,
    },
    /// Set up this machine's GitHub identity: gh sign-in, SSH and GPG keys
    /// created and uploaded, signing key saved, then a signed test commit
    Identity {
        /// GitHub account this machine pushes as; saved as github_username
        #[arg(long)]
        account: Option<String>,
    },
    /// Show pending changes, confirm, then chezmoi apply
    Apply {
        /// Skip the confirmation
        #[arg(short, long)]
        yes: bool,
    },
    /// Show pending changes in full
    Diff,
    /// Re-run the setup questions (saved answers are kept), then apply
    Config,
    /// Selection, machine type, and installed tool versions
    Status,
    /// Health check: chezmoi, catalog, CLI version, pending changes, Python,
    /// gh account, commit signing, shadowed CLIs, pending package setup
    Doctor,
    /// Open the dotfiles source in $EDITOR
    Edit,
    /// Remove regenerable build artifacts and caches under ~/github
    Clean {
        /// Skip the confirmation
        #[arg(short, long)]
        yes: bool,
    },
    /// Update everything: this CLI, then pull the dotfiles and apply
    Update {
        /// Old `dotfiles update <target>` form; points at `dotfiles package update`
        #[arg(hide = true)]
        legacy_target: Option<String>,
    },
    /// Update only this CLI to the latest release
    SelfUpdate,
    /// Print the version
    Version,

    // Old top-level forms, kept working but hidden: use `dotfiles package ...`.
    #[command(hide = true)]
    Add(AddArgs),
    #[command(hide = true)]
    Remove(RemoveArgs),
    #[command(hide = true)]
    List(ListArgs),
    #[command(hide = true)]
    Setup(SetupArgs),
}

#[derive(Subcommand)]
enum PackageCmd {
    /// Search and toggle optional packages, then apply (same as `dotfiles package`)
    Pick {
        /// Save the selection without running chezmoi apply
        #[arg(long)]
        no_apply: bool,
    },
    /// Select packages by id (no ids: pick from the unselected ones)
    Add(AddArgs),
    /// Deselect packages by id (no ids: pick from the selected ones)
    Remove(RemoveArgs),
    /// List the catalog with the current selection
    List(ListArgs),
    /// Run pending setup (sign-in, interactive installers) for selected packages
    Setup(SetupArgs),
    /// Update installed packages, then apply
    Update {
        #[arg(value_enum, default_value = "all")]
        target: UpdateTarget,
    },
}

#[derive(Args)]
struct AddArgs {
    ids: Vec<String>,
    /// Save the selection without running chezmoi apply
    #[arg(long)]
    no_apply: bool,
}

#[derive(Args)]
struct RemoveArgs {
    ids: Vec<String>,
    /// Also brew uninstall what the packages installed
    #[arg(long)]
    uninstall: bool,
    /// Save the selection without running chezmoi apply
    #[arg(long)]
    no_apply: bool,
}

#[derive(Args)]
struct ListArgs {
    /// Only selected packages
    #[arg(long)]
    selected: bool,
}

#[derive(Args)]
struct SetupArgs {
    /// Limit to these ids (default: every selected package)
    ids: Vec<String>,
    /// Rerun setup even when its check already passes
    #[arg(long)]
    force: bool,
}

#[derive(Clone, Copy, ValueEnum)]
pub enum UpdateTarget {
    /// Homebrew packages, AI coding CLIs, then apply
    All,
    /// brew update + upgrade, then apply
    #[value(alias = "packages")]
    Brew,
    /// The selected AI coding CLIs (Homebrew ones upgraded, installers re-run)
    Ai,
}

/// Exit codes (cli-standards): 0 ok, 1 error, 2 no-op, 130 interrupted.
pub enum Outcome {
    Done,
    NoChange,
}

fn main() -> ExitCode {
    let cli = Cli::parse();
    let ctx = commands::Ctx {
        format: cli.format,
        dry_run: cli.dry_run,
    };
    let result = match cli.command {
        Command::Package { action, no_apply } => match action {
            None => commands::packages(&ctx, no_apply),
            Some(PackageCmd::Pick { no_apply }) => commands::packages(&ctx, no_apply),
            Some(PackageCmd::Add(a)) => commands::add(&ctx, a.ids, a.no_apply),
            Some(PackageCmd::Remove(r)) => commands::remove(&ctx, r.ids, r.uninstall, r.no_apply),
            Some(PackageCmd::List(l)) => commands::list(&ctx, l.selected),
            Some(PackageCmd::Setup(s)) => commands::setup(&ctx, s.ids, s.force),
            Some(PackageCmd::Update { target }) => commands::update(&ctx, target),
        },
        Command::Add(a) => commands::add(&ctx, a.ids, a.no_apply),
        Command::Remove(r) => commands::remove(&ctx, r.ids, r.uninstall, r.no_apply),
        Command::List(l) => commands::list(&ctx, l.selected),
        Command::Setup(s) => commands::setup(&ctx, s.ids, s.force),
        Command::Identity { account } => identity::run(&ctx, account),
        Command::Apply { yes } => commands::apply(&ctx, yes),
        Command::Diff => commands::diff(),
        Command::Config => commands::config(&ctx),
        Command::Status => commands::status(&ctx),
        Command::Doctor => doctor::run(&ctx),
        Command::Edit => commands::edit(),
        Command::Clean { yes } => commands::clean(&ctx, yes),
        Command::Update {
            legacy_target: Some(target),
        } => Err(anyhow::anyhow!(
            "`dotfiles update` updates the CLI and dotfiles; for packages run: dotfiles package update {target}"
        )),
        Command::Update {
            legacy_target: None,
        } => commands::update_all(&ctx),
        Command::SelfUpdate => commands::self_update(),
        Command::Version => {
            println!("dotfiles v{}", env!("CARGO_PKG_VERSION"));
            Ok(Outcome::Done)
        }
    };
    match result {
        Ok(Outcome::Done) => ExitCode::SUCCESS,
        Ok(Outcome::NoChange) => ExitCode::from(2),
        Err(err) if commands::is_interrupt(&err) => {
            ui::skip("cancelled; nothing changed");
            ExitCode::from(130)
        }
        Err(err) => {
            ui::fail(&format!("{err:#}"));
            ExitCode::FAILURE
        }
    }
}
