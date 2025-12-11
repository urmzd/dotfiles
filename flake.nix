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

        # Reusable toolsets keep shells small and composable
        toolsets = rec {
          common = with pkgs; [
            git
            gh
            fzf
            ripgrep
            tree
            curl
            wget
            jq
            yq
            just
            direnv
            nix-direnv
            chezmoi
            age
            neovim
            tmux
            gnupg
            coreutils
          ];

          ai = with pkgs; [
            claude-code
            gemini-cli
          ];

          cloud = with pkgs; [
            colima
            docker
            docker-compose
            google-cloud-sdk
          ];

          node = with pkgs; [
            nodejs_20
            nodePackages.npm
            nodePackages.yarn
            nodePackages.pnpm
            nodePackages.typescript
            nodePackages.typescript-language-server
            nodePackages.vscode-langservers-extracted
          ];

          python = with pkgs; [
            python313
            python313Packages.pip
            python313Packages.virtualenv
            python313Packages.pipx
            python313Packages.black
            python313Packages.flake8
            python313Packages.mypy
            python313Packages.pytest
            python313Packages.requests
            ruff
            uv
          ];

          rust = with pkgs; [
            rustc
            cargo
            rustfmt
            clippy
            rust-analyzer
            cargo-watch
            cargo-edit
            cargo-outdated
          ];

          go = with pkgs; [
            go
            gopls
            golangci-lint
            gotools
            go-migrate
            air
          ];

          devops = with pkgs; [
            terraform
            ansible
            kubectl
            kubernetes-helm
            k9s
            awscli2
          ];

          data = with pkgs; [
            python313
            python313Packages.pandas
            python313Packages.numpy
            python313Packages.jupyter
            python313Packages.matplotlib
            python313Packages.seaborn
            python313Packages.scikit-learn
            R
            rPackages.tidyverse
            rPackages.ggplot2
          ];

          lua = with pkgs; [
            lua5_4
            luajitPackages.luacheck
            stylua
            lua-language-server
            luarocks
          ];

          java = with pkgs; [
            jdk17_headless
          ];
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
          in pkgs.lib.concatStringsSep "\n" (pkgs.lib.filter (s: s != "") [
            addSiteFunctions
            gcloudCompletion
          ]);

        mkDevShell = { name, packages, welcome ? "", extraHook ? "" }:
          pkgs.mkShell {
            inherit name;
            buildInputs = packages;
            shellHook = pkgs.lib.concatStringsSep "\n" (pkgs.lib.filter (s: s != "") [
              (completionHook packages)
              welcome
              extraHook
            ]);
          };

        shells = {
          default = mkDevShell {
            name = "default-dev-shell";
            packages = toolsets.common ++ toolsets.ai ++ toolsets.cloud ++ toolsets.devops;
            welcome = ''
              if [[ -n "$NIX_DEVELOP_EXPLICIT" ]]; then
                echo "🚀 Welcome to Urmzd's development environment!"
                echo ""
                echo "Included tools:"
                echo "  • AI: claude-code, gemini-cli"
                echo "  • Cloud: gcloud, colima, docker"
                echo "  • DevOps: terraform, ansible, kubectl, helm, k9s, awscli"
                echo "  • CLI: git, gh, fzf, ripgrep, jq, yq, just"
                echo ""
                echo "Available specialized environments:"
                echo "  • nix develop .#node     - Node.js development"
                echo "  • nix develop .#python   - Python development"
                echo "  • nix develop .#rust     - Rust development"
                echo "  • nix develop .#go       - Go development"
                echo "  • nix develop .#devops   - DevOps/Infrastructure"
                echo "  • nix develop .#data     - Data science & ML"
                echo "  • nix develop .#lua      - Lua development"
                echo "  • nix develop .#full     - All tools combined"
              fi
            '';
          };

          node = mkDevShell {
            name = "nodejs-dev-shell";
            packages = toolsets.common ++ toolsets.node;
            welcome = ''
              echo "📦 Node.js Development Environment"
              echo "Node: $(node --version)"
              echo "npm: $(npm --version)"
              echo ""
            '';
            extraHook = ''export NODE_ENV=development'';
          };

          python = mkDevShell {
            name = "python-dev-shell";
            packages = toolsets.common ++ toolsets.python;
            welcome = ''
              echo "🐍 Python Development Environment"
              echo "Python: $(python --version)"
              echo "pip: $(pip --version)"
            '';
          };

          rust = mkDevShell {
            name = "rust-dev-shell";
            packages = toolsets.common ++ toolsets.rust;
            welcome = ''
              echo "🦀 Rust Development Environment"
              echo "Rust: $(rustc --version)"
              echo "Cargo: $(cargo --version)"
              echo ""
            '';
            extraHook = ''export RUST_BACKTRACE=1'';
          };

          go = mkDevShell {
            name = "go-dev-shell";
            packages = toolsets.common ++ toolsets.go;
            welcome = ''
              echo "🐹 Go Development Environment"
              echo "Go: $(go version)"
              echo ""
            '';
            extraHook = ''
              export GO111MODULE=on
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"
            '';
          };

          devops = mkDevShell {
            name = "devops-dev-shell";
            packages = toolsets.common ++ toolsets.cloud ++ toolsets.devops;
            welcome = ''
              echo "⚙️  DevOps/Infrastructure Environment"
              echo "Terraform: $(terraform version | head -1)"
              echo "Docker: $(docker --version)"
              echo "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl available')"
              echo "Cloud: gcloud"
              echo "Container runtime: colima (for macOS)"
              echo ""
            '';
          };

          data = mkDevShell {
            name = "data-science-shell";
            packages = toolsets.common ++ toolsets.data;
            welcome = ''
              echo "📊 Data Science Environment"
              echo "Python: $(python --version)"
              echo "R: $(R --version | head -1)"
              echo ""
              echo "Jupyter notebook: jupyter notebook"
              echo "R console: R"
            '';
          };

          lua = mkDevShell {
            name = "lua-dev-shell";
            packages = toolsets.common ++ toolsets.lua;
            welcome = ''
              echo "🌙 Lua Development Environment"
              echo "Lua: $(lua -v)"
              echo ""
              echo "Great for Neovim configuration!"
            '';
          };

          full = mkDevShell {
            name = "full-dev-shell";
            packages = toolsets.common ++ toolsets.ai ++ toolsets.cloud ++ toolsets.node ++ toolsets.python ++ toolsets.rust ++ toolsets.go ++ toolsets.devops ++ toolsets.lua ++ toolsets.java;
            welcome = ''
              echo "🌟 Full Development Environment"
              echo "All languages and tools available!"
              echo ""
              echo "Languages:"
              echo "  • Node.js: $(node --version)"
              echo "  • Python: $(python --version)"
              echo "  • Rust: $(rustc --version | cut -d' ' -f2)"
              echo "  • Go: $(go version | cut -d' ' -f3)"
              echo "  • Lua: $(lua -v 2>&1 | head -1)"
              echo "  • Java: $(java -version 2>&1 | head -1)"
              echo ""
              echo "AI Tools: claude-code, gemini-cli"
              echo "Cloud: gcloud, docker, colima"
              echo ""
            '';
          };
        };
      in {
        # Development shells
        devShells = shells;

        # Packages that can be installed with 'nix profile install'
        packages = {
          # Default package for 'nix shell'
          default = pkgs.buildEnv {
            name = "default-dev-env";
            paths = toolsets.common ++ toolsets.ai ++ toolsets.cloud;
          };

          # Development environments as packages
          dev-node = pkgs.buildEnv {
            name = "dev-node";
            paths = toolsets.common ++ toolsets.node;
          };

          dev-python = pkgs.buildEnv {
            name = "dev-python";
            paths = toolsets.common ++ toolsets.python;
          };

          dev-rust = pkgs.buildEnv {
            name = "dev-rust";
            paths = toolsets.common ++ toolsets.rust;
          };
        };

        # Apps that can be run with 'nix run'
        apps = {
          # Quick setup script
          setup = flake-utils.lib.mkApp {
            drv = pkgs.writeShellScriptBin "setup" ''
              echo "Setting up Nix development environment..."

              # Enable direnv integration
              if ! grep -q "nix-direnv" ~/.config/direnv/direnvrc 2>/dev/null; then
                mkdir -p ~/.config/direnv
                echo "source /etc/profiles/per-user/$USER/share/nix-direnv/direnvrc" >> ~/.config/direnv/direnvrc
                echo "✓ Configured direnv for Nix"
              fi

              # Create .envrc template
              if [ ! -f .envrc ]; then
                echo "use flake" > .envrc
                echo "✓ Created .envrc file"
                echo "Run 'direnv allow' to activate the environment"
              fi

              echo "🎉 Setup complete!"
            '';
          };
        };
      }
    );
}
