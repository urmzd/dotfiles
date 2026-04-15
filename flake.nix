{
  description = "Urmzd's development environment flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Adds completions for every package in the shell that exposes zsh functions
        completionHook = packages:
          let
            siteFunctionPkgs = pkgs.lib.filter (pkg: builtins.pathExists "${pkg}/share/zsh/site-functions") packages;
            addSiteFunctions = pkgs.lib.concatStringsSep "\n" (map
              (pkg: ''fpath=("${pkg}/share/zsh/site-functions" ''${fpath[@]})'')
              siteFunctionPkgs);

            gcloudCompletion = if pkgs.lib.elem pkgs.google-cloud-sdk packages then ''
              if [ -f "${pkgs.google-cloud-sdk}/share/google-cloud-sdk/completion.zsh.inc" ]; then
                source "${pkgs.google-cloud-sdk}/share/google-cloud-sdk/completion.zsh.inc"
              fi
            '' else "";

            fzfCompletion = if pkgs.lib.elem pkgs.fzf packages then ''
              if [ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]; then
                source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
              fi
              if [ -f "${pkgs.fzf}/share/fzf/completion.zsh" ]; then
                source "${pkgs.fzf}/share/fzf/completion.zsh"
              fi
            '' else "";

            terraformCompletion = if pkgs.lib.elem pkgs.terraform packages then ''
              autoload -U +X bashcompinit && bashcompinit
              complete -o nospace -C "${pkgs.terraform}/bin/terraform" terraform
            '' else "";

            direnvHook = if pkgs.lib.elem pkgs.direnv packages then ''
              eval "$(${pkgs.direnv}/bin/direnv hook zsh)"
            '' else "";

            zshOnly = pkgs.lib.concatStringsSep "\n" (pkgs.lib.filter (s: s != "") [
              addSiteFunctions
              gcloudCompletion
              fzfCompletion
              terraformCompletion
              direnvHook
            ]);
          in if zshOnly != "" then ''
            if [ -n "''${ZSH_VERSION-}" ]; then
              ${zshOnly}
            fi
          '' else "";

        npmConfig = ''
          export NPM_CONFIG_PREFIX="$HOME/.local/npm"
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
        '';

        ensureAiTools = ''
          _ensure_ai_tools() {
            if ! command -v claude &>/dev/null; then
              echo "Installing Claude Code..."
              curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1
            fi

            local packages=(
              "@openai/codex"
              "@google/gemini-cli"
              "@github/copilot"
            )

            for pkg in "''${packages[@]}"; do
              if ! npm list -g "$pkg" >/dev/null 2>&1; then
                echo "Installing $pkg..."
                npm install -g "$pkg" 2>&1 | grep -v "npm WARN"
              fi
            done
          }

          _ensure_ai_tools &
        '';

        corePackages = with pkgs; [
          tealdeer
          git
          gh
          fzf
          ripgrep
          tree
          curl
          jq
          yq-go
          just
          direnv
          nix-direnv
          chezmoi
          tmux
          gnupg
          tree-sitter
          uv
        ];

        cloudPackages = with pkgs; [
          google-cloud-sdk
          awscli2
          terraform
          colima
          docker
          docker-buildx
          docker-compose
          kubectl
          kubernetes-helm
          k9s
        ];

        jsPackages = with pkgs; [
          fnm
          deno
        ];

        goPackages = with pkgs; [
          go
          golangci-lint
          gotools
        ];

        luaPackages = with pkgs; [
          lua5_4
          luajitPackages.luacheck
          stylua
          luarocks
        ];

        allPackages = corePackages ++ cloudPackages ++ jsPackages ++ goPackages;

        mkDevShell = name: packages: extra: pkgs.mkShell {
          inherit name;
          buildInputs = corePackages ++ packages;
          shellHook = ''
            unset PYTHONPATH
            ${completionHook (corePackages ++ packages)}
            ${npmConfig}
            export RUST_BACKTRACE=1
            if [ -d "$HOME/.cargo/bin" ]; then
              export PATH="$HOME/.cargo/bin:$PATH"
            fi
            ${extra}
          '';
        };

        fnmHook = ''
          eval "$(fnm env --use-on-cd --corepack-enabled)"
        '';

        goHook = ''
          export GO111MODULE=on
          export GOPATH="$HOME/go"
          export PATH="$GOPATH/bin:$PATH"
        '';

      in {
        devShells = {
          default = mkDevShell "dev" (cloudPackages ++ jsPackages ++ goPackages) ''
            ${fnmHook}
            ${goHook}
            ${ensureAiTools}
          '';
          js = mkDevShell "js" jsPackages fnmHook;
          go = mkDevShell "go" goPackages goHook;
          lua = mkDevShell "lua" luaPackages "";
          cloud = mkDevShell "cloud" cloudPackages "";
          full = mkDevShell "full" (cloudPackages ++ jsPackages ++ goPackages ++ luaPackages) ''
            ${fnmHook}
            ${goHook}
            ${ensureAiTools}
          '';
        };

        packages.default = pkgs.buildEnv {
          name = "dev-env";
          paths = allPackages;
        };

        apps.setup = flake-utils.lib.mkApp {
          drv = pkgs.writeShellScriptBin "setup" ''
            echo "Setting up Nix development environment..."
            if ! grep -q "nix-direnv" ~/.config/direnv/direnvrc 2>/dev/null; then
              mkdir -p ~/.config/direnv
              echo "source /etc/profiles/per-user/$USER/share/nix-direnv/direnvrc" >> ~/.config/direnv/direnvrc
              echo "Configured direnv for Nix"
            fi
            if [ ! -f .envrc ]; then
              echo "use flake" > .envrc
              echo "Created .envrc — run 'direnv allow' to activate"
            fi
            echo "Setup complete!"
          '';
        };
      }
    );
}
