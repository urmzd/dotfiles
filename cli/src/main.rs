mod catalog;
mod chezmoi;
mod commands;
mod identity;
mod ui;

use std::process::ExitCode;

use clap::{Parser, Subcommand, ValueEnum};

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
    /// Search and toggle optional packages, then apply
    #[command(visible_alias = "pkg")]
    Packages {
        /// Save the selection without running chezmoi apply
        #[arg(long)]
        no_apply: bool,
    },
    /// Select packages by id (no ids: pick from the unselected ones)
    Add {
        ids: Vec<String>,
        /// Save the selection without running chezmoi apply
        #[arg(long)]
        no_apply: bool,
    },
    /// Deselect packages by id (no ids: pick from the selected ones)
    Remove {
        ids: Vec<String>,
        /// Also brew uninstall what the packages installed
        #[arg(long)]
        uninstall: bool,
        /// Save the selection without running chezmoi apply
        #[arg(long)]
        no_apply: bool,
    },
    /// List the catalog with the current selection
    List {
        /// Only selected packages
        #[arg(long)]
        selected: bool,
    },
    /// Run pending setup (sign-in, interactive installers) for selected packages
    Setup {
        /// Limit to these ids (default: every selected package)
        ids: Vec<String>,
        /// Rerun setup even when its check already passes
        #[arg(long)]
        force: bool,
    },
    /// Set up this machine's GitHub identity: gh sign-in, SSH and GPG keys
    /// created and uploaded, signing key saved, then a signed test commit
    Identity,
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
    /// Update installed software, then apply
    Update {
        #[arg(value_enum, default_value = "all")]
        target: UpdateTarget,
    },
    /// Selection, machine type, and installed tool versions
    Status,
    /// chezmoi doctor plus catalog and selection checks
    Doctor,
    /// Open the dotfiles source in $EDITOR
    Edit,
    /// Remove regenerable build artifacts and caches under ~/github
    Clean {
        /// Skip the confirmation
        #[arg(short, long)]
        yes: bool,
    },
    /// Update this binary to the latest release
    SelfUpdate,
    /// Print the version
    Version,
}

#[derive(Clone, Copy, ValueEnum)]
pub enum UpdateTarget {
    /// Homebrew packages, AI CLIs, then apply
    All,
    /// brew update + upgrade, then apply
    Packages,
    /// Reinstall AI CLIs (Claude Code, agy, Copilot, OpenCode)
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
        Command::Packages { no_apply } => commands::packages(&ctx, no_apply),
        Command::Add { ids, no_apply } => commands::add(&ctx, ids, no_apply),
        Command::Remove {
            ids,
            uninstall,
            no_apply,
        } => commands::remove(&ctx, ids, uninstall, no_apply),
        Command::List { selected } => commands::list(&ctx, selected),
        Command::Setup { ids, force } => commands::setup(&ctx, ids, force),
        Command::Identity => identity::run(&ctx),
        Command::Apply { yes } => commands::apply(&ctx, yes),
        Command::Diff => commands::diff(),
        Command::Config => commands::config(&ctx),
        Command::Update { target } => commands::update(&ctx, target),
        Command::Status => commands::status(&ctx),
        Command::Doctor => commands::doctor(),
        Command::Edit => commands::edit(),
        Command::Clean { yes } => commands::clean(&ctx, yes),
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
