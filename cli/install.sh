#!/bin/sh
# install.sh: Installs the dotfiles CLI binary (cli/ in urmzd/dotfiles) from GitHub releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/cli/install.sh | sh
#
# Environment variables:
#   DOTFILES_VERSION    : version to install (e.g. "v1.2.0"); defaults to the newest
#                         release with a binary for this platform, falling back to
#                         building from the dotfiles checkout (cli/) with cargo
#   DOTFILES_INSTALL_DIR: installation directory; defaults to $HOME/.local/bin
#   DOTFILES_SHA256     : expected SHA256 of the binary; defaults to the release's .sha256 file

set -eu

REPO="urmzd/dotfiles"

# curl with optional auth: uses GH_TOKEN or GITHUB_TOKEN if set.
gh_curl() {
    token="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
    if [ -n "$token" ]; then
        curl -fsSL -H "Authorization: token $token" "$@"
    else
        curl -fsSL "$@"
    fi
}

main() {
    os=$(uname -s)
    arch=$(uname -m)

    case "$os" in
        Linux)
            case "$arch" in
                x86_64)  target="x86_64-unknown-linux-musl" ;;
                aarch64) target="aarch64-unknown-linux-musl" ;;
                *)       err "Unsupported Linux architecture: $arch" ;;
            esac
            ;;
        Darwin)
            case "$arch" in
                x86_64)  target="x86_64-apple-darwin" ;;
                arm64)   target="aarch64-apple-darwin" ;;
                *)       err "Unsupported macOS architecture: $arch" ;;
            esac
            ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT)
            err "Windows is not supported by this installer. Download a binary from https://github.com/$REPO/releases/latest"
            ;;
        *)
            err "Unsupported operating system: $os"
            ;;
    esac

    install_dir="${DOTFILES_INSTALL_DIR:-$HOME/.local/bin}"
    mkdir -p "$install_dir"

    # Releases can be unavailable (the newest one has no binaries while its
    # build runs, or forever if that build failed; GitHub can be down), so:
    # newest release that has this platform's binary, else build from the
    # dotfiles checkout. A pinned DOTFILES_VERSION never falls back.
    if fetch_release "$target" "$install_dir/dotfiles"; then
        :
    elif [ -z "${DOTFILES_VERSION:-}" ] && build_from_source "$install_dir/dotfiles"; then
        :
    else
        err "could not download or build dotfiles; nothing else in the dotfiles needs it, so retry later"
    fi

    chmod +x "$install_dir/dotfiles"

    echo "Installed dotfiles to $install_dir/dotfiles"

    # Never edit shell startup files: the dotfiles manage PATH (~/.local/bin is
    # on it), and an edit behind chezmoi's back makes `chezmoi apply` stop to
    # ask about ~/.zshrc. Just say what to add.
    case ":$PATH:" in
        *":$install_dir:"*) ;;
        *) echo "Note: $install_dir is not on PATH; add it to use \`dotfiles\` by name." ;;
    esac
}

# Download the binary for $1 into $2, verified against the release's .sha256
# (or DOTFILES_SHA256). Returns non-zero when no download is possible; a
# checksum mismatch is fatal, never a reason to fall back.
fetch_release() {
    artifact="dotfiles-$1"
    dest="$2"
    if [ -n "${DOTFILES_VERSION:-}" ]; then
        url="https://github.com/$REPO/releases/download/$DOTFILES_VERSION/$artifact"
    else
        # Newest release that actually carries this platform's binary. The API
        # lists newest first; the pattern ends at the artifact name, so the
        # .sha256 companion never matches.
        url=$(gh_curl "https://api.github.com/repos/$REPO/releases?per_page=30" 2>/dev/null |
            grep -o "\"browser_download_url\": *\"[^\"]*/releases/download/[^\"]*/$artifact\"" |
            head -n 1 | sed 's/.*"\(https[^"]*\)"$/\1/') || url=""
        if [ -z "$url" ]; then
            echo "No release has a prebuilt $artifact (GitHub unreachable, or none built yet)." >&2
            return 1
        fi
    fi
    tag=$(printf '%s' "$url" | sed 's#.*/releases/download/\([^/]*\)/.*#\1#')

    echo "Downloading dotfiles $tag for $1..."
    tmp="$dest.download"
    if ! gh_curl "$url" -o "$tmp"; then
        rm -f "$tmp"
        echo "Download failed: $url" >&2
        return 1
    fi

    expected="${DOTFILES_SHA256:-}"
    if [ -z "$expected" ]; then
        expected=$(gh_curl "$url.sha256" 2>/dev/null | awk '{print $1}') || expected=""
    fi
    if [ -n "$expected" ]; then
        if command -v sha256sum >/dev/null 2>&1; then
            actual=$(sha256sum "$tmp" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            actual=$(shasum -a 256 "$tmp" | awk '{print $1}')
        else
            rm -f "$tmp"
            err "sha256sum or shasum required for checksum verification"
        fi
        if [ "$actual" != "$expected" ]; then
            rm -f "$tmp"
            err "SHA256 mismatch for $tag: expected $expected, got $actual"
        fi
        echo "SHA256 verified: $actual"
    fi
    mv "$tmp" "$dest"
}

# Build from the dotfiles checkout (cli/) with cargo into $1. The bootstrap
# installs rustup before this runs, so cargo is usually present.
build_from_source() {
    src="${DOTFILES_SOURCE:-${XDG_DATA_HOME:-$HOME/.local/share}/chezmoi}/cli"
    if [ ! -f "$src/Cargo.toml" ]; then
        echo "No dotfiles checkout at $src to build from." >&2
        return 1
    fi
    cargo="$(command -v cargo 2>/dev/null || echo "$HOME/.cargo/bin/cargo")"
    if [ ! -x "$cargo" ]; then
        echo "cargo not found; cannot build from $src." >&2
        return 1
    fi
    echo "No prebuilt binary available; building from $src (a minute or two)..."
    "$cargo" build --release --locked --quiet --manifest-path "$src/Cargo.toml" || return 1
    cp "$src/target/release/dotfiles" "$1"
    echo "Built from source: $("$1" version 2>/dev/null)"
}

err() {
    echo "Error: $1" >&2
    exit 1
}

main
