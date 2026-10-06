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

/// Skill packs, teasr, and oag became catalog packages in v0.15.0. Configs
/// from before got all of them unasked; keep that, once (`skills_seeded`).
const LEGACY_STACK: [&str; 2] = ["teasr", "oag"];

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
    if !config.has_data("skills_seeded") {
        let mut ids = config.packages();
        let added: Vec<String> = catalog
            .packages
            .iter()
            .filter(|p| !p.skills.is_empty() || LEGACY_STACK.contains(&p.id.as_str()))
            .filter(|p| p.pack.is_none() && !ids.contains(&p.id))
            .map(|p| p.id.clone())
            .collect();
        ids.extend(added.iter().cloned());
        config.set_packages(&ids)?;
        config.set_data_bool("skills_seeded", true)?;
        if !added.is_empty() {
            changes.push(format!(
                "kept skill packs and stack CLIs: {}",
                added.join(", ")
            ));
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

    #[test]
    fn seeds_skill_packs_once() {
        let catalog = Catalog::parse(
            "[[package]]\nid = \"oag\"\nname = \"O\"\ndescription = \"d\"\ncategory = \"stack\"\n\n[[package]]\nid = \"skills-x\"\nname = \"S\"\ndescription = \"d\"\ncategory = \"skills\"\nskills = [\"a\"]\n\n[[package]]\nid = \"zig\"\nname = \"Z\"\ndescription = \"d\"\ncategory = \"languages\"\n",
        )
        .unwrap();
        let mut config =
            Config::parse("[data]\n    agents_seeded = true\n    packages = []\n").unwrap();
        run(&mut config, &catalog).unwrap();
        assert_eq!(config.packages(), vec!["oag", "skills-x"]);
        assert!(run(&mut config, &catalog).unwrap().is_empty());
    }
}
