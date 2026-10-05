//! `dotfiles identity`: make this machine's GitHub identity complete, so its
//! commits push over SSH and show as verified.
//!
//! The account and email come from the chezmoi config (`machine`,
//! `github_username`, `email` / `work_email`), so a work laptop gets the work
//! account and work key and never a personal one. Every step checks first and
//! does nothing when already done, so it is safe to re-run.

use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{Context, Result, bail};

use crate::chezmoi::{self, Config, Paths};
use crate::commands::{Ctx, require_tty};
use crate::{Outcome, ui};

/// gh token scopes needed to upload keys and read email verification. Each
/// entry lists the scopes that satisfy it (admin implies write).
const SCOPES: &[(&str, &[&str])] = &[
    ("write:gpg_key", &["write:gpg_key", "admin:gpg_key"]),
    (
        "admin:public_key",
        &["admin:public_key", "write:public_key"],
    ),
    ("user:email", &["user:email", "user"]),
];

/// The SSH key ~/.ssh/config uses for github.com.
const SSH_KEY: &str = ".ssh/github";

struct Identity {
    work: bool,
    name: String,
    email: String,
    account: String,
    /// chezmoi data key the signing key is saved under.
    key_field: &'static str,
}

impl Identity {
    fn from_config(config: &Config) -> Result<Self> {
        let work = config.machine().as_deref() == Some("work");
        let (email_field, key_field) = if work {
            ("work_email", "work_signing_key")
        } else {
            ("email", "gpg_signing_key")
        };
        let email = config.data_str(email_field).with_context(|| {
            format!("no `{email_field}` in the chezmoi config; run `dotfiles config` first")
        })?;
        Ok(Self {
            work,
            name: config.data_str("name").unwrap_or_else(|| email.clone()),
            email,
            account: config
                .data_str("github_username")
                .context("no `github_username` in the chezmoi config; run `dotfiles config`")?,
            key_field,
        })
    }
}

pub fn run(ctx: &Ctx, account: Option<String>) -> Result<Outcome> {
    let paths = Paths::discover()?;
    let mut config = Config::load(&paths.config)?;
    // --account overrides github_username: in memory for a dry run (so the
    // plan shows the new account), saved otherwise.
    let mut account_changed = false;
    if let Some(account) =
        account.filter(|a| config.data_str("github_username").as_deref() != Some(a.as_str()))
    {
        config.set_data_str("github_username", &account)?;
        if ctx.dry_run {
            ui::skip(&format!("would set github_username = {account}"));
        } else {
            config.save()?;
            account_changed = true;
        }
    }
    let mut id = Identity::from_config(&config)?;
    let home = std::env::var_os("HOME")
        .map(PathBuf::from)
        .context("HOME is not set")?;

    ui::section("GitHub identity");
    ui::ok(&format!(
        "{} machine: account {}, email {}",
        if id.work { "work" } else { "personal" },
        id.account,
        id.email
    ));
    for tool in ["gh", "gpg", "ssh-keygen", "git"] {
        if !on_path(tool) {
            bail!(
                "`{tool}` is not installed; run `chezmoi apply` (it installs the core tools) first"
            );
        }
    }
    if !ctx.dry_run {
        require_tty("`dotfiles identity` (it may open a browser and ask for passphrases)")?;
    }

    let mut changed = account_changed;
    if account_changed {
        ui::ok(&format!(
            "this machine now pushes as {} (saved as github_username)",
            id.account
        ));
        let gitconfig = home.join(".gitconfig");
        if !chezmoi::run(&["apply", "--no-tty", &gitconfig.to_string_lossy()])?.success() {
            bail!("chezmoi apply ~/.gitconfig failed");
        }
    }
    changed |= ensure_gh(ctx, &mut id, &mut config, &paths)?;
    changed |= ensure_ssh(ctx, &id, &home)?;
    let fingerprint = ensure_gpg(ctx, &id)?;
    check_email_verified(&id);

    // Save the signing key where chezmoi's gitconfig template reads it.
    match &fingerprint {
        Some(fpr) if config.data_str(id.key_field).as_deref() != Some(fpr.as_str()) => {
            if ctx.dry_run {
                ui::skip(&format!(
                    "would save {} = {fpr} and re-apply ~/.gitconfig",
                    id.key_field
                ));
            } else {
                config.set_data_str(id.key_field, fpr)?;
                config.save()?;
                ui::ok(&format!(
                    "saved {} in {}",
                    id.key_field,
                    paths.config.display()
                ));
                let gitconfig = home.join(".gitconfig");
                if !chezmoi::run(&["apply", "--no-tty", &gitconfig.to_string_lossy()])?.success() {
                    bail!("chezmoi apply ~/.gitconfig failed");
                }
                ui::ok("re-applied ~/.gitconfig with the signing key");
                changed = true;
            }
        }
        Some(_) => ui::skip(&format!("{} already saved", id.key_field)),
        None => {}
    }

    if !ctx.dry_run && fingerprint.is_some() {
        verify_signing()?;
    }
    Ok(if changed {
        Outcome::Done
    } else {
        Outcome::NoChange
    })
}

// ---- gh -------------------------------------------------------------------------

/// Signed in as the machine's account, with the scopes the later steps need.
fn ensure_gh(ctx: &Ctx, id: &mut Identity, config: &mut Config, paths: &Paths) -> Result<bool> {
    let mut changed = false;
    let login = gh_login();
    if login.as_deref() == Some(id.account.as_str()) {
        ui::skip(&format!("gh already signed in as {}", id.account));
    } else if ctx.dry_run {
        ui::skip(&format!(
            "would switch or sign gh in as {} (now: {})",
            id.account,
            login.as_deref().unwrap_or("signed out")
        ));
        return Ok(false);
    } else if gh_accounts().contains(&id.account) && gh_switch(&id.account) {
        // gh keeps several accounts per host; this one was signed in already.
        ui::ok(&format!("switched gh to {}", id.account));
        changed = true;
    } else {
        changed |= resolve_account(id, login, config, paths)?;
    }
    if !changed && !ctx.dry_run && gh_login().as_deref() != Some(id.account.as_str()) {
        bail!("gh is not signed in as {}", id.account);
    }

    let missing = missing_scopes(&gh_scopes());
    if missing.is_empty() {
        ui::skip("gh token already has the key and email scopes");
    } else if ctx.dry_run {
        ui::skip(&format!("would add gh scopes: {}", missing.join(", ")));
    } else {
        ui::step(&format!("adding gh scopes: {}", missing.join(", ")));
        let status = Command::new("gh")
            .args([
                "auth",
                "refresh",
                "--hostname",
                "github.com",
                "--scopes",
                &missing.join(","),
            ])
            .status()
            .context("running gh auth refresh")?;
        if !status.success() {
            bail!("gh auth refresh failed");
        }
        ui::ok("gh scopes updated");
        changed = true;
    }
    Ok(changed)
}

/// gh signed in as some other account (or nobody) than this machine's. Ask
/// which side is right: sign gh in as the configured account, or adopt gh's
/// account as this machine's (rewrites github_username, re-applies gitconfig).
fn resolve_account(
    id: &mut Identity,
    login: Option<String>,
    config: &mut Config,
    paths: &Paths,
) -> Result<bool> {
    let sign_in = format!(
        "Sign gh in as {} (this machine's configured account)",
        id.account
    );
    let mut options = vec![sign_in.clone()];
    let adopt = login
        .as_ref()
        .map(|l| format!("Use {l} for this machine instead (updates github_username)"));
    if let Some(a) = &adopt {
        options.push(a.clone());
    }
    let question = match &login {
        Some(l) => format!(
            "gh is signed in as {l}, but this machine pushes as {}. Which is right?",
            id.account
        ),
        None => format!("gh is signed out; this machine pushes as {}.", id.account),
    };
    let choice = inquire::Select::new(&question, options).prompt()?;

    if Some(&choice) == adopt.as_ref() {
        let new_account = login.expect("adopt implies a login");
        config.set_data_str("github_username", &new_account)?;
        config.save()?;
        ui::ok(&format!(
            "this machine now pushes as {new_account} (saved in {})",
            paths.config.display()
        ));
        let home = std::env::var_os("HOME")
            .map(PathBuf::from)
            .context("HOME is not set")?;
        let gitconfig = home.join(".gitconfig");
        if !chezmoi::run(&["apply", "--no-tty", &gitconfig.to_string_lossy()])?.success() {
            bail!("chezmoi apply ~/.gitconfig failed");
        }
        id.account = new_account;
        return Ok(true);
    }

    // The browser signs in whoever it is already signed in as, which is why a
    // plain `gh auth login` kept returning the other account.
    ui::hint(&format!(
        "in the browser, switch to {} first (avatar menu > Switch account, or a private window)",
        id.account
    ));
    let scopes: Vec<&str> = SCOPES.iter().map(|(s, _)| *s).collect();
    for attempt in 1..=2 {
        ui::step(&format!(
            "signing gh in as {} (attempt {attempt} of 2)",
            id.account
        ));
        let status = Command::new("gh")
            .args([
                "auth",
                "login",
                "--hostname",
                "github.com",
                "--git-protocol",
                "ssh",
                "--skip-ssh-key",
                "--web",
            ])
            .args(["--scopes", &scopes.join(",")])
            .status()
            .context("running gh auth login")?;
        let now = gh_login();
        if status.success() && now.as_deref() == Some(id.account.as_str()) {
            ui::ok(&format!("gh signed in as {}", id.account));
            return Ok(true);
        }
        // gh keeps the extra account; make sure the right one ends up active.
        if gh_accounts().contains(&id.account) && gh_switch(&id.account) {
            ui::ok(&format!(
                "gh signed in as {} and switched to it",
                id.account
            ));
            return Ok(true);
        }
        ui::warn(&format!(
            "the browser authorized {}, not {}",
            now.as_deref().unwrap_or("nobody"),
            id.account
        ));
    }
    bail!(
        "could not sign gh in as {}; switch accounts in the browser (or use a private window), then rerun: dotfiles identity",
        id.account
    )
}

/// Accounts gh is signed in to on github.com, from `gh auth status`.
fn gh_accounts() -> Vec<String> {
    parse_accounts(&gh_scopes())
}

fn parse_accounts(status: &str) -> Vec<String> {
    status
        .lines()
        .filter_map(|l| l.split(" account ").nth(1))
        .filter_map(|rest| rest.split_whitespace().next())
        .map(String::from)
        .collect()
}

fn gh_switch(account: &str) -> bool {
    Command::new("gh")
        .args([
            "auth",
            "switch",
            "--hostname",
            "github.com",
            "--user",
            account,
        ])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

pub(crate) fn gh_login() -> Option<String> {
    output("gh", &["api", "user", "--jq", ".login"]).filter(|s| !s.is_empty())
}

fn gh_scopes() -> String {
    // gh prints status on stderr in some versions, stdout in others.
    Command::new("gh")
        .args(["auth", "status", "--hostname", "github.com"])
        .output()
        .map(|o| {
            format!(
                "{}{}",
                String::from_utf8_lossy(&o.stdout),
                String::from_utf8_lossy(&o.stderr)
            )
        })
        .unwrap_or_default()
}

/// Required scopes absent from `gh auth status` output.
fn missing_scopes(status: &str) -> Vec<&'static str> {
    let granted: Vec<String> = status
        .lines()
        .filter(|l| l.contains("Token scopes"))
        .flat_map(|l| {
            l.split(':')
                .skip(1)
                .collect::<Vec<_>>()
                .join(":")
                .split(',')
                .map(|s| s.trim().trim_matches('\'').to_string())
                .collect::<Vec<_>>()
        })
        .collect();
    SCOPES
        .iter()
        .filter(|(_, any)| !any.iter().any(|s| granted.iter().any(|g| g == s)))
        .map(|(want, _)| *want)
        .collect()
}

// ---- SSH ------------------------------------------------------------------------

fn ensure_ssh(ctx: &Ctx, id: &Identity, home: &Path) -> Result<bool> {
    let key = home.join(SSH_KEY);
    let public = key.with_extension("pub");
    let mut changed = false;
    if public.exists() {
        ui::skip(&format!("SSH key {} exists", public.display()));
    } else if ctx.dry_run {
        ui::skip(&format!("would create SSH key {}", key.display()));
        return Ok(false);
    } else {
        ui::step(&format!(
            "creating SSH key {} (choose a passphrase; macOS keeps it in Keychain)",
            key.display()
        ));
        std::fs::create_dir_all(key.parent().unwrap_or(home)).ok();
        let status = Command::new("ssh-keygen")
            .args(["-t", "ed25519", "-C", &id.email, "-f"])
            .arg(&key)
            .status()
            .context("running ssh-keygen")?;
        if !status.success() {
            bail!("ssh-keygen failed");
        }
        ui::ok("SSH key created");
        changed = true;
    }

    let local = std::fs::read_to_string(&public)
        .with_context(|| format!("reading {}", public.display()))?;
    let uploaded = output("gh", &["api", "user/keys", "--jq", ".[].key"]).unwrap_or_default();
    if ssh_key_listed(&local, &uploaded) {
        ui::skip(&format!("SSH key already on GitHub ({})", id.account));
    } else if ctx.dry_run {
        ui::skip("would upload the SSH key to GitHub");
    } else {
        let title = format!("{} (dotfiles)", hostname());
        match upload_ssh_key(&public, &title)? {
            Upload::Done => {}
            // GitHub allows one SSH key per account; this one belongs to
            // another account (e.g. a copied ~/.ssh). Offer a dedicated key.
            Upload::InUseElsewhere => {
                let question = format!(
                    "{} is already registered to another GitHub account. Create a new key for {}?",
                    public.display(),
                    id.account
                );
                let create = inquire::Confirm::new(&question)
                    .with_default(true)
                    .with_help_message("the old key is kept as ~/.ssh/github.old and keeps working for that account")
                    .prompt()?;
                if !create {
                    bail!(
                        "SSH key not uploaded: it belongs to another account; remove it there or rerun and create a new key"
                    );
                }
                let old = key.with_extension("old");
                let old_pub = key.with_extension("old.pub");
                if old.exists() || old_pub.exists() {
                    bail!(
                        "{} already exists; move it aside, then rerun dotfiles identity",
                        old.display()
                    );
                }
                std::fs::rename(&key, &old).with_context(|| format!("moving {}", key.display()))?;
                std::fs::rename(&public, &old_pub)
                    .with_context(|| format!("moving {}", public.display()))?;
                ui::ok(&format!("kept the old key as {}", old.display()));
                ui::step(&format!(
                    "creating SSH key {} for {}",
                    key.display(),
                    id.account
                ));
                if !Command::new("ssh-keygen")
                    .args(["-t", "ed25519", "-C", &id.email, "-f"])
                    .arg(&key)
                    .status()
                    .context("running ssh-keygen")?
                    .success()
                {
                    bail!("ssh-keygen failed (the old key is at {})", old.display());
                }
                if upload_ssh_key(&public, &title)? != Upload::Done {
                    bail!("the new SSH key was rejected too; check gh auth status");
                }
            }
        }
        ui::ok(&format!("uploaded the SSH key as \"{title}\""));
        changed = true;
    }
    Ok(changed)
}

#[derive(PartialEq)]
enum Upload {
    Done,
    InUseElsewhere,
}

/// `gh ssh-key add`, telling GitHub's "key is already in use" (HTTP 422: the
/// key is on another account) apart from other failures.
fn upload_ssh_key(public: &Path, title: &str) -> Result<Upload> {
    let out = Command::new("gh")
        .args(["ssh-key", "add"])
        .arg(public)
        .args(["--title", title])
        .output()
        .context("running gh ssh-key add")?;
    if out.status.success() {
        return Ok(Upload::Done);
    }
    let err = String::from_utf8_lossy(&out.stderr);
    // The API says "key is already in use" (HTTP 422); gh's wording around it
    // varies by version, so match either.
    if err.contains("already in use") || err.contains("HTTP 422") {
        return Ok(Upload::InUseElsewhere);
    }
    bail!(
        "gh ssh-key add failed: {}",
        err.lines().next().unwrap_or("").trim()
    )
}

/// Whether a local `.pub` line's key material is among GitHub's keys.
fn ssh_key_listed(local_pub: &str, github_keys: &str) -> bool {
    let Some(body) = local_pub.split_whitespace().nth(1) else {
        return false;
    };
    github_keys
        .lines()
        .any(|k| k.split_whitespace().nth(1) == Some(body))
}

// ---- GPG ------------------------------------------------------------------------

/// The signing key's fingerprint, created and uploaded if needed. None only in
/// a dry run that would create one.
fn ensure_gpg(ctx: &Ctx, id: &Identity) -> Result<Option<String>> {
    let mut fpr = gpg_fingerprint(&id.email);
    match &fpr {
        Some(f) => ui::skip(&format!("GPG key for {} exists ({f})", id.email)),
        None if ctx.dry_run => {
            ui::skip(&format!(
                "would create a GPG signing key for {} <{}>",
                id.name, id.email
            ));
            return Ok(None);
        }
        None => {
            ui::step(&format!(
                "creating a GPG signing key for {} (choose a passphrase in the dialog)",
                id.email
            ));
            let uid = format!("{} <{}>", id.name, id.email);
            let status = Command::new("gpg")
                .args(["--quick-gen-key", &uid, "ed25519", "sign", "2y"])
                .status()
                .context("running gpg --quick-gen-key")?;
            if !status.success() {
                bail!("gpg key generation failed");
            }
            fpr = gpg_fingerprint(&id.email);
            let Some(f) = &fpr else {
                bail!("created a GPG key but cannot find it for {}", id.email)
            };
            ui::ok(&format!("GPG key created ({f})"));
        }
    }
    let fpr = fpr.expect("set above");

    let uploaded = output(
        "gh",
        &[
            "api",
            "user/gpg_keys",
            "--jq",
            ".[] | .key_id, (.subkeys[]?.key_id)",
        ],
    )
    .unwrap_or_default();
    if gpg_key_listed(&fpr, &uploaded) {
        ui::skip(&format!("GPG key already on GitHub ({})", id.account));
    } else if ctx.dry_run {
        ui::skip("would upload the GPG key to GitHub");
    } else {
        let armored = Command::new("gpg")
            .args(["--armor", "--export", &fpr])
            .output()
            .context("exporting the GPG key")?;
        if !armored.status.success() || armored.stdout.is_empty() {
            bail!("gpg --export returned nothing for {fpr}");
        }
        let mut child = Command::new("gh")
            .args([
                "gpg-key",
                "add",
                "-",
                "--title",
                &format!("{} (dotfiles)", hostname()),
            ])
            .stdin(Stdio::piped())
            .spawn()
            .context("running gh gpg-key add")?;
        use std::io::Write;
        child
            .stdin
            .take()
            .context("gh stdin")?
            .write_all(&armored.stdout)?;
        if !child.wait()?.success() {
            bail!("gh gpg-key add failed");
        }
        ui::ok("uploaded the GPG key");
    }
    Ok(Some(fpr))
}

/// First usable (not expired, revoked, or disabled) secret key for `email`.
fn gpg_fingerprint(email: &str) -> Option<String> {
    let listing = output(
        "gpg",
        &[
            "--list-secret-keys",
            "--with-colons",
            "--",
            &format!("<{email}>"),
        ],
    )?;
    parse_fingerprint(&listing)
}

/// From `gpg --with-colons` output: the fingerprint following the first `sec`
/// record whose validity (field 2) is not e/r/d/i.
fn parse_fingerprint(listing: &str) -> Option<String> {
    let mut usable = false;
    for line in listing.lines() {
        let fields: Vec<&str> = line.split(':').collect();
        match fields.first() {
            Some(&"sec") => usable = !matches!(fields.get(1), Some(&"e" | &"r" | &"d" | &"i")),
            Some(&"fpr") if usable => {
                return fields
                    .get(9)
                    .filter(|f| f.len() >= 40)
                    .map(|f| f.to_string());
            }
            Some(&"ssb") => usable = false,
            _ => {}
        }
    }
    None
}

/// GitHub lists 16-hex-digit key ids; match against the fingerprint's tail.
fn gpg_key_listed(fingerprint: &str, github_ids: &str) -> bool {
    github_ids
        .lines()
        .map(str::trim)
        .any(|k| !k.is_empty() && fingerprint.to_uppercase().ends_with(&k.to_uppercase()))
}

fn check_email_verified(id: &Identity) {
    let q = format!(".[] | select(.email == \"{}\") | .verified", id.email);
    match output("gh", &["api", "user/emails", "--jq", &q]).as_deref() {
        Some("true") => ui::ok(&format!("{} is verified on {}", id.email, id.account)),
        Some("false") => {
            ui::warn(&format!(
                "{} is on {} but not verified; signed commits show as unverified",
                id.email, id.account
            ));
            ui::hint("verify it: https://github.com/settings/emails");
        }
        Some(_) => {
            ui::warn(&format!(
                "{} is not an email on {}; signed commits show as unverified",
                id.email, id.account
            ));
            ui::hint("add and verify it: https://github.com/settings/emails");
        }
        // The call fails without the user:email scope (e.g. in a dry run that
        // has not added it yet); that is "unknown", not "missing".
        None => ui::skip(&format!(
            "could not check whether {} is verified (gh token lacks user:email)",
            id.email
        )),
    }
}

fn verify_signing() -> Result<()> {
    let dir = std::env::temp_dir().join(format!("dotfiles-identity-{}", std::process::id()));
    std::fs::create_dir_all(&dir)?;
    let git = |args: &[&str]| Command::new("git").arg("-C").arg(&dir).args(args).output();
    let result = (|| -> Result<bool> {
        git(&["init", "-q"])?;
        let commit = git(&[
            "commit",
            "-q",
            "--allow-empty",
            "-m",
            "dotfiles identity check",
        ])?;
        if !commit.status.success() {
            ui::fail("a signed test commit failed");
            ui::hint(
                String::from_utf8_lossy(&commit.stderr)
                    .lines()
                    .next()
                    .unwrap_or("")
                    .trim(),
            );
            return Ok(false);
        }
        let log = git(&["log", "--show-signature", "-1"])?;
        let text = format!(
            "{}{}",
            String::from_utf8_lossy(&log.stdout),
            String::from_utf8_lossy(&log.stderr)
        );
        Ok(text.contains("Good signature"))
    })();
    std::fs::remove_dir_all(&dir).ok();
    if result? {
        ui::ok("signed test commit: Good signature");
        Ok(())
    } else {
        bail!(
            "the test commit is not signed with a good signature; check `git config --get user.signingkey`"
        )
    }
}

// ---- helpers --------------------------------------------------------------------

fn on_path(tool: &str) -> bool {
    Command::new("sh")
        .args(["-c", &format!("command -v {tool}")])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .is_ok_and(|s| s.success())
}

/// Trimmed stdout of a successful command, or None.
pub(crate) fn output(cmd: &str, args: &[&str]) -> Option<String> {
    let out = Command::new(cmd)
        .args(args)
        .stderr(Stdio::null())
        .output()
        .ok()?;
    out.status
        .success()
        .then(|| String::from_utf8_lossy(&out.stdout).trim().to_string())
}

fn hostname() -> String {
    output("hostname", &["-s"]).unwrap_or_else(|| "this machine".into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn finds_usable_fingerprint() {
        let listing = "\
sec:e:255:22:AAAA:1:2::u:::scSC:::+:::ed25519:::0:
fpr:::::::::1111111111111111111111111111111111111111:
sec:u:255:22:BBBB:1:2::u:::scSC:::+:::ed25519:::0:
fpr:::::::::2BC957C986975FDDD1C5B4576FF48BAF7E056027:
ssb:u:255:18:CCCC:1:2:::::e:::+:::cv25519::
fpr:::::::::3333333333333333333333333333333333333333:
";
        assert_eq!(
            parse_fingerprint(listing).as_deref(),
            Some("2BC957C986975FDDD1C5B4576FF48BAF7E056027")
        );
        assert_eq!(parse_fingerprint("sec:r:1\nfpr:::::::::FF\n"), None);
    }

    #[test]
    fn matches_github_key_ids() {
        let fpr = "2BC957C986975FDDD1C5B4576FF48BAF7E056027";
        assert!(gpg_key_listed(fpr, "1234567890ABCDEF\n6FF48BAF7E056027\n"));
        assert!(gpg_key_listed(fpr, "6ff48baf7e056027"));
        assert!(!gpg_key_listed(fpr, "1234567890ABCDEF\n\n"));
    }

    #[test]
    fn matches_ssh_key_material() {
        let local = "ssh-ed25519 AAAAC3NzaKEY me@example.com\n";
        assert!(ssh_key_listed(
            local,
            "ssh-rsa OTHER\nssh-ed25519 AAAAC3NzaKEY"
        ));
        assert!(!ssh_key_listed(local, "ssh-ed25519 DIFFERENT"));
        assert!(!ssh_key_listed("", "ssh-ed25519 AAAAC3NzaKEY"));
    }

    #[test]
    fn lists_signed_in_accounts() {
        let status = "github.com\n  ✓ Logged in to github.com account urmzd (keyring)\n  - Active account: true\n  ✓ Logged in to github.com account urmzd-acme (keyring)\n  - Active account: false\n";
        assert_eq!(parse_accounts(status), vec!["urmzd", "urmzd-acme"]);
        assert!(parse_accounts("You are not logged into any GitHub hosts.").is_empty());
    }

    #[test]
    fn reports_missing_scopes() {
        let full = "  - Token scopes: 'admin:gpg_key', 'admin:public_key', 'repo', 'user'";
        assert!(missing_scopes(full).is_empty());
        let partial = "  - Token scopes: 'gist', 'read:org', 'repo', 'write:gpg_key'";
        assert_eq!(
            missing_scopes(partial),
            vec!["admin:public_key", "user:email"]
        );
        assert_eq!(missing_scopes("not logged in").len(), 3);
    }
}
