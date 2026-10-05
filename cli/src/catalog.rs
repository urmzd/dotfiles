//! `catalog.toml` at the dotfiles repo root: every optional package,
//! how it installs, and what setup it needs.

use std::path::Path;

use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct Catalog {
    #[serde(rename = "package")]
    pub packages: Vec<Package>,
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
    /// Interactive commands (sign-in, TTY installers) run by `dotfiles setup`.
    #[serde(default)]
    pub setup: Vec<String>,
    /// Shell test that passes once setup is done.
    #[serde(default)]
    pub check: Option<String>,
    #[serde(default)]
    pub presets: Vec<String>,
    #[serde(default)]
    pub machines: Vec<String>,
}

impl Package {
    /// Everything Homebrew installs for this package, for display.
    pub fn installs(&self) -> Vec<String> {
        self.brew.iter().chain(&self.cask).cloned().collect()
    }
}

impl Catalog {
    pub fn load(source_dir: &Path) -> Result<Self> {
        let path = source_dir.join("catalog.toml");
        let text = std::fs::read_to_string(&path)
            .with_context(|| format!("reading {}", path.display()))?;
        Self::parse(&text).with_context(|| format!("parsing {}", path.display()))
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
        assert_eq!(
            c.get("acli").unwrap().installs(),
            vec!["atlassian/acli/acli"]
        );
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
    fn resolve_reports_unknown() {
        let c = Catalog::parse(SAMPLE).unwrap();
        let err = c.resolve(&["nope".into()]).unwrap_err().to_string();
        assert!(err.contains("unknown package `nope`") && err.contains("acli"));
    }
}
