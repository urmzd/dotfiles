//! Changes to a machine's saved selection that ship with new releases, so
//! they reach existing machines on `dotfiles update` / `dotfiles apply`
//! instead of waiting for someone to re-run `chezmoi init`. Each migration
//! decides from the config itself whether it already ran, so there is no
//! record to lose; `.chezmoi.toml.tmpl` applies the same rules on init.

use crate::catalog::Catalog;
use crate::chezmoi::Config;
use anyhow::Result;

/// AI coding CLIs became catalog packages in v0.8.0. Configs from before got
/// them from a one-time script that could fail silently; give them the set
/// that script installed, once (marked by `agents_seeded`).
const LEGACY_AGENTS: [&str; 5] = ["claude-code", "codex", "copilot", "agy", "opencode"];

/// Apply pending migrations to `config` in memory; returns what changed.
/// The caller saves.
pub fn run(config: &mut Config, catalog: &Catalog) -> Result<Vec<String>> {
    let mut changes = Vec::new();
    if !config.has_data("agents_seeded") {
        let mut ids = config.packages();
        let added: Vec<&str> = LEGACY_AGENTS
            .into_iter()
            .filter(|id| catalog.get(id).is_some() && !ids.iter().any(|s| s == id))
            .collect();
        ids.extend(added.iter().map(|s| s.to_string()));
        config.set_packages(&ids)?;
        config.set_data_bool("agents_seeded", true)?;
        if !added.is_empty() {
            changes.push(format!("selected AI coding CLIs: {}", added.join(", ")));
        }
    }
    Ok(changes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn seeds_agents_once() {
        let catalog = Catalog::parse(
            "[[package]]\nid = \"claude-code\"\nname = \"C\"\ndescription = \"d\"\ncategory = \"agents\"\n\n[[package]]\nid = \"codex\"\nname = \"X\"\ndescription = \"d\"\ncategory = \"agents\"\n",
        )
        .unwrap();
        let mut config = Config::parse("[data]\n    packages = [\"codex\"]\n").unwrap();
        let changes = run(&mut config, &catalog).unwrap();
        assert_eq!(changes, vec!["selected AI coding CLIs: claude-code"]);
        assert_eq!(config.packages(), vec!["claude-code", "codex"]);
        assert!(run(&mut config, &catalog).unwrap().is_empty());
    }
}
