#!/bin/sh
# install.sh: Installs the dotfiles CLI binary (cli/ in urmzd/dotfiles) from GitHub releases.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/urmzd/dotfiles/main/cli/install.sh | sh
#
# Environment variables:
#   DOTFILES_VERSION    : version to install (e.g. "v1.2.0"); defaults to latest
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

    if [ -n "${DOTFILES_VERSION:-}" ]; then
        tag="$DOTFILES_VERSION"
    else
        tag=$(gh_curl "https://api.github.com/repos/$REPO/releases/latest" \
            | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
        if [ -z "$tag" ]; then
            err "Failed to fetch latest release tag"
        fi
    fi

    artifact="dotfiles-${target}"
    url="https://github.com/$REPO/releases/download/${tag}/${artifact}"

    install_dir="${DOTFILES_INSTALL_DIR:-$HOME/.local/bin}"
    mkdir -p "$install_dir"

    echo "Downloading dotfiles $tag for $target..."
    gh_curl "$url" -o "$install_dir/dotfiles"

    # Expected checksum: DOTFILES_SHA256 if set, else the release's .sha256 file.
    if [ -z "${DOTFILES_SHA256:-}" ]; then
        DOTFILES_SHA256=$(gh_curl "${url}.sha256" 2>/dev/null | awk '{print $1}') || DOTFILES_SHA256=""
    fi

    if [ -n "${DOTFILES_SHA256:-}" ]; then
        if command -v sha256sum >/dev/null 2>&1; then
            actual=$(sha256sum "$install_dir/dotfiles" | awk '{print $1}')
        elif command -v shasum >/dev/null 2>&1; then
            actual=$(shasum -a 256 "$install_dir/dotfiles" | awk '{print $1}')
        else
            err "sha256sum or shasum required for checksum verification"
        fi
        if [ "$actual" != "$DOTFILES_SHA256" ]; then
            rm -f "$install_dir/dotfiles"
            err "SHA256 mismatch: expected $DOTFILES_SHA256, got $actual"
        fi
        echo "SHA256 verified: $actual"
    fi

    chmod +x "$install_dir/dotfiles"

    echo "Installed dotfiles to $install_dir/dotfiles"

    case ":$PATH:" in
        *":$install_dir:"*) ;;
        *) add_to_path "$install_dir" ;;
    esac
}

add_to_path() {
    install_dir="$1"

    case "$(basename "$SHELL")" in
        zsh)  profile="$HOME/.zshrc" ;;
        bash)
            if [ -f "$HOME/.bashrc" ]; then
                profile="$HOME/.bashrc"
            else
                profile="$HOME/.profile"
            fi
            ;;
        fish) profile="$HOME/.config/fish/config.fish" ;;
        *)    profile="$HOME/.profile" ;;
    esac

    if [ "$(basename "$SHELL")" = "fish" ]; then
        if ! grep -q "$install_dir" "$profile" 2>/dev/null; then
            mkdir -p "$(dirname "$profile")"
            echo "" >> "$profile"
            echo "# Added by the dotfiles CLI installer" >> "$profile"
            echo "set -Ux fish_user_paths $install_dir \$fish_user_paths" >> "$profile"
            echo "Added $install_dir to $profile"
            echo "Restart your shell or run: source $profile"
        fi
    elif [ -n "$profile" ] && ! grep -q "$install_dir" "$profile" 2>/dev/null; then
        echo "" >> "$profile"
        echo "# Added by the dotfiles CLI installer" >> "$profile"
        echo "export PATH=\"$install_dir:\$PATH\"" >> "$profile"
        echo "Added $install_dir to $profile"
        echo "Restart your shell or run: source $profile"
    fi
}

err() {
    echo "Error: $1" >&2
    exit 1
}

main
