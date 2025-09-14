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

        # Common development tools used across environments
        commonTools = with pkgs; [
          git
          fzf
          ripgrep
          tree
          curl
          wget
          jq
          yq
          direnv
          nix-direnv
          chezmoi
          age
          neovim
          tmux
          just  # Task runner
          gh    # GitHub CLI
          gnupg # GPG for signing
        ];

        # Node.js development environment
        nodeEnv = with pkgs; [
          nodejs_20
          nodePackages.npm
          nodePackages.yarn
          nodePackages.pnpm
          nodePackages.typescript
          nodePackages.typescript-language-server
          nodePackages.vscode-langservers-extracted
        ];

        # Python development environment
        pythonEnv = with pkgs; [
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

        # Rust development environment
        rustEnv = with pkgs; [
          rustc
          cargo
          rustfmt
          clippy
          rust-analyzer
          cargo-watch
          cargo-edit
          cargo-outdated
        ];

        # Go development environment
        goEnv = with pkgs; [
          go
          gopls
          golangci-lint
          gotools
          go-migrate
          air
        ];

        # DevOps/Infrastructure tools
        devopsEnv = with pkgs; [
          terraform
          ansible
          docker
          docker-compose
          kubectl
          kubernetes-helm
          k9s
          awscli2
          google-cloud-sdk
        ];

        # Data/ML environment
        dataEnv = with pkgs; [
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

        # Lua development environment (for Neovim configuration)
        luaEnv = with pkgs; [
          lua5_4
          luajitPackages.luacheck
          stylua
          lua-language-server
          luarocks
        ];

      in {
        # Development shells
        devShells = {
          # Default shell with basic tools
          default = pkgs.mkShell {
            name = "default-dev-shell";
            buildInputs = commonTools;

            shellHook = ''
              echo "🚀 Welcome to Urmzd's development environment!"
              echo "Available environments:"
              echo "  • nix develop .#node     - Node.js development"
              echo "  • nix develop .#python   - Python development"
              echo "  • nix develop .#rust     - Rust development"
              echo "  • nix develop .#go       - Go development"
              echo "  • nix develop .#devops   - DevOps/Infrastructure"
              echo "  • nix develop .#data     - Data science & ML"
              echo "  • nix develop .#lua      - Lua development"
              echo "  • nix develop .#full     - All tools combined"
              echo ""
              echo "Current environment: Default (basic tools)"
            '';
          };

          # Node.js development shell
          node = pkgs.mkShell {
            name = "nodejs-dev-shell";
            buildInputs = commonTools ++ nodeEnv;

            shellHook = ''
              echo "📦 Node.js Development Environment"
              echo "Node: $(node --version)"
              echo "npm: $(npm --version)"
              echo ""
              export NODE_ENV=development
            '';
          };

          # Python development shell
          python = pkgs.mkShell {
            name = "python-dev-shell";
            buildInputs = commonTools ++ pythonEnv;

            shellHook = ''
              echo "🐍 Python Development Environment"
              echo "Python: $(python --version)"
              echo "pip: $(pip --version)"
              echo ""
              export PYTHONPATH="./src:$PYTHONPATH"
            '';
          };

          # Rust development shell
          rust = pkgs.mkShell {
            name = "rust-dev-shell";
            buildInputs = commonTools ++ rustEnv;

            shellHook = ''
              echo "🦀 Rust Development Environment"
              echo "Rust: $(rustc --version)"
              echo "Cargo: $(cargo --version)"
              echo ""
              export RUST_BACKTRACE=1
            '';
          };

          # Go development shell
          go = pkgs.mkShell {
            name = "go-dev-shell";
            buildInputs = commonTools ++ goEnv;

            shellHook = ''
              echo "🐹 Go Development Environment"
              echo "Go: $(go version)"
              echo ""
              export GO111MODULE=on
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"
            '';
          };

          # DevOps/Infrastructure shell
          devops = pkgs.mkShell {
            name = "devops-dev-shell";
            buildInputs = commonTools ++ devopsEnv;

            shellHook = ''
              echo "⚙️  DevOps/Infrastructure Environment"
              echo "Terraform: $(terraform version | head -1)"
              echo "Docker: $(docker --version)"
              echo "kubectl: $(kubectl version --client --short 2>/dev/null || echo 'kubectl available')"
              echo ""
            '';
          };

          # Data science shell
          data = pkgs.mkShell {
            name = "data-science-shell";
            buildInputs = commonTools ++ dataEnv;

            shellHook = ''
              echo "📊 Data Science Environment"
              echo "Python: $(python --version)"
              echo "R: $(R --version | head -1)"
              echo ""
              echo "Jupyter notebook: jupyter notebook"
              echo "R console: R"
            '';
          };

          # Lua development shell
          lua = pkgs.mkShell {
            name = "lua-dev-shell";
            buildInputs = commonTools ++ luaEnv;

            shellHook = ''
              echo "🌙 Lua Development Environment"
              echo "Lua: $(lua -v)"
              echo ""
              echo "Great for Neovim configuration!"
            '';
          };

          # Full environment with everything
          full = pkgs.mkShell {
            name = "full-dev-shell";
            buildInputs = commonTools ++ nodeEnv ++ pythonEnv ++ rustEnv ++ goEnv ++ devopsEnv ++ luaEnv;

            shellHook = ''
              echo "🌟 Full Development Environment"
              echo "All languages and tools available!"
              echo ""
              echo "Languages:"
              echo "  • Node.js: $(node --version)"
              echo "  • Python: $(python --version)"
              echo "  • Rust: $(rustc --version | cut -d' ' -f2)"
              echo "  • Go: $(go version | cut -d' ' -f3)"
              echo "  • Lua: $(lua -v 2>&1 | head -1)"
              echo ""
            '';
          };
        };

        # Packages that can be installed with 'nix profile install'
        packages = {
          # Default package for 'nix shell'
          default = pkgs.buildEnv {
            name = "default-dev-env";
            paths = commonTools;
          };

          # Development environments as packages
          dev-node = pkgs.buildEnv {
            name = "dev-node";
            paths = commonTools ++ nodeEnv;
          };

          dev-python = pkgs.buildEnv {
            name = "dev-python";
            paths = commonTools ++ pythonEnv;
          };

          dev-rust = pkgs.buildEnv {
            name = "dev-rust";
            paths = commonTools ++ rustEnv;
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
