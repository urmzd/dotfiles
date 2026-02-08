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
        toolsets = {
          common = with pkgs; [
            tldr
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
            tmux
            gnupg
            coreutils
            tree-sitter
          ];

          ai = with pkgs; [
            # claude-code, gemini-cli, and codex now managed via npm/npx
            # Packages: @anthropic-ai/claude-code, @openai/codex, @google/gemini-cli
            github-copilot-cli
          ];

          cloud = with pkgs; [
            colima
            docker
            docker-buildx
            docker-compose
            google-cloud-sdk
          ];

          javascript = with pkgs; [
            nodejs_22
            deno
            nodePackages.yarn
            nodePackages.pnpm
            nodePackages.typescript
          ];

          python = with pkgs; [
            python313
          ];

          rust = [
            # Entire Rust toolchain managed by rustup
          ];

          go = with pkgs; [
            go
            golangci-lint
            gotools
            go-migrate
            air
            goreleaser
          ];

          devops = with pkgs; [
            terraform
            kubectl
            kubernetes-helm
            k9s
            awscli2
          ];

          haskell = with pkgs; [ ghc cabal-install ];
          ruby = with pkgs; [ ruby bundler rubyPackages.rails ];
          scheme = with pkgs; [ guile ];
          perl = with pkgs; [ perl ];

          lua = with pkgs; [
            lua5_4
            ninja
            luajitPackages.luacheck
            stylua
            luarocks
          ];

          java = with pkgs; [
            openjdk21
            maven
            gradle
          ];
        };

        # Adds completions for every package in the shell that exposes zsh functions
        completionHook = packages:
          let
            # Auto-discovery for packages with standard zsh site-functions
            siteFunctionPkgs = pkgs.lib.filter (pkg: builtins.pathExists "${pkg}/share/zsh/site-functions") packages;
            addSiteFunctions = pkgs.lib.concatStringsSep "\n" (map
              (pkg: ''fpath=("${pkg}/share/zsh/site-functions" ''${fpath[@]})'')
              siteFunctionPkgs);

            # Google Cloud SDK completion
            gcloudCompletion = if pkgs.lib.elem pkgs.google-cloud-sdk packages then ''
              if [ -f "${pkgs.google-cloud-sdk}/share/google-cloud-sdk/completion.zsh.inc" ]; then
                source "${pkgs.google-cloud-sdk}/share/google-cloud-sdk/completion.zsh.inc"
              fi
            '' else "";

            # fzf key-bindings and completion
            fzfCompletion = if pkgs.lib.elem pkgs.fzf packages then ''
              if [ -f "${pkgs.fzf}/share/fzf/key-bindings.zsh" ]; then
                source "${pkgs.fzf}/share/fzf/key-bindings.zsh"
              fi
              if [ -f "${pkgs.fzf}/share/fzf/completion.zsh" ]; then
                source "${pkgs.fzf}/share/fzf/completion.zsh"
              fi
            '' else "";

            # Terraform uses bash-style completion
            terraformCompletion = if pkgs.lib.elem pkgs.terraform packages then ''
              autoload -U +X bashcompinit && bashcompinit
              complete -o nospace -C "${pkgs.terraform}/bin/terraform" terraform
            '' else "";

            # direnv hook
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

        # Configure npm to use writable user directory for global installs
        npmConfig = ''
          # Configure npm to use writable user directory for global installs
          export NPM_CONFIG_PREFIX="$HOME/.local/npm"
          export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
        '';

        # Auto-install AI CLI tools if not present
        ensureAiTools = ''
          # Auto-install AI CLI tools if not present
          _ensure_ai_tools() {
            # Install Claude Code via official installer
            if ! command -v claude &>/dev/null; then
              echo "📦 Installing Claude Code..."
              curl -fsSL https://claude.ai/install.sh | bash >/dev/null 2>&1
            fi

            # Install npm-based tools
            local packages=(
              "@openai/codex"
              "@google/gemini-cli"
            )

            for pkg in "''${packages[@]}"; do
              if ! npm list -g "$pkg" >/dev/null 2>&1; then
                echo "📦 Installing $pkg..."
                npm install -g "$pkg" 2>&1 | grep -v "npm WARN"
              fi
            done
          }

          # Run check in background to not block shell startup
          _ensure_ai_tools &
        '';

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
            packages = toolsets.common ++ toolsets.ai ++ toolsets.cloud ++ toolsets.devops ++ toolsets.go ++ toolsets.rust ++ toolsets.javascript ++ toolsets.lua ++ toolsets.java;
            welcome = ''
              if [[ -n "$NIX_DEVELOP_EXPLICIT" ]]; then
                echo "Welcome to Urmzd's development environment!"
                echo ""
                echo "Included tools:"
                echo "  AI: claude (curl), codex, gemini, copilot-cli"
                echo "  Cloud: gcloud, colima, docker"
                echo "  DevOps: terraform, kubectl, helm, k9s, awscli"
                echo "  JavaScript/TypeScript: node, npm, yarn, pnpm, deno, tsc"
                echo "  Go: go, golangci-lint, air"
                echo "  Java: java (JDK), mvn, gradle"
                echo "  Lua: lua, luarocks, stylua"
                echo "  Rust: rustup (toolchain manager)"
                echo "  CLI: git, gh, fzf, ripgrep, jq, yq, just"
                echo ""
                echo "Specialized environments:"
                echo "  nix develop .#node   - Node.js"
                echo "  nix develop .#python - Python"
                echo "  nix develop .#lua    - Lua"
                echo "  nix develop .#full   - Everything"
              fi
            '';
            extraHook = ''
              # npm configuration (must come before AI tools installation)
              ${npmConfig}

              # Go environment
              export GO111MODULE=on
              export GOPATH="$HOME/go"
              export PATH="$GOPATH/bin:$PATH"

              # Rust environment
              export RUST_BACKTRACE=1

              # AI tools installation
              ${ensureAiTools}
            '';
          };

          node = mkDevShell {
            name = "js-ts-dev-shell";
            packages = toolsets.common ++ toolsets.javascript;
            welcome = ''
              echo "📦 JavaScript/TypeScript Development Environment"
              echo "Node: $(node --version)"
              echo "Deno: $(deno --version | head -1)"
              echo "npm: $(npm --version)"
              echo ""
            '';
            extraHook = ''
              ${npmConfig}
              export NODE_ENV=development
            '';
          };

          python = mkDevShell {
            name = "python-dev-shell";
            packages = toolsets.common ++ toolsets.python;
            welcome = ''
              echo "🐍 Python Development Environment"
              echo "Python: $(python --version)"
              echo ""
            '';
            extraHook = ''
              unset PYTHONPATH
              if [ -f ".venv/bin/activate" ]; then
                source .venv/bin/activate
                echo "Activated project venv: .venv"
              fi
            '';
          };

          rust = mkDevShell {
            name = "rust-dev-shell";
            packages = toolsets.common ++ toolsets.rust;
            welcome = ''
              echo "🦀 Rust Development Environment"
              echo "Rust: $(rustc --version 2>/dev/null || echo 'not found - install rustup')"
              echo "Cargo: $(cargo --version 2>/dev/null || echo 'not found')"
              echo "Toolchain managed by rustup"
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

          haskell = mkDevShell {
            name = "haskell-dev-shell";
            packages = toolsets.common ++ toolsets.haskell;
            welcome = ''
              echo "λ Haskell Development Environment"
              echo "GHC: $(ghc --version)"
              echo ""
            '';
          };

          ruby = mkDevShell {
            name = "ruby-dev-shell";
            packages = toolsets.common ++ toolsets.ruby;
            welcome = ''
              echo "💎 Ruby Development Environment"
              echo "Ruby: $(ruby --version)"
              echo ""
            '';
          };

          scheme = mkDevShell {
            name = "scheme-dev-shell";
            packages = toolsets.common ++ toolsets.scheme;
            welcome = ''
              echo "🔧 Scheme Development Environment"
              echo "Guile: $(guile --version | head -1)"
              echo ""
            '';
          };

          perl = mkDevShell {
            name = "perl-dev-shell";
            packages = toolsets.common ++ toolsets.perl;
            welcome = ''
              echo "🐪 Perl Development Environment"
              echo "Perl: $(perl --version | head -2 | tail -1)"
              echo ""
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
            packages = toolsets.common ++ toolsets.ai ++ toolsets.cloud ++ toolsets.javascript ++ toolsets.python ++ toolsets.rust ++ toolsets.go ++ toolsets.devops ++ toolsets.lua ++ toolsets.java;
            welcome = ''
              echo "🌟 Full Development Environment"
              echo "All languages and tools available!"
              echo ""
              echo "Languages:"
              echo "  • JavaScript/TypeScript: $(node --version)"
              echo "  • Python: $(python --version)"
              echo "  • Rust: $(rustc --version 2>/dev/null | cut -d' ' -f2 || echo 'not found - install rustup')"
              echo "  • Go: $(go version | cut -d' ' -f3)"
              echo "  • Lua: $(lua -v 2>&1 | head -1)"
              echo "  • Java: $(java -version 2>&1 | head -1)"
              echo ""
              echo "AI Tools: claude (curl), codex, gemini, copilot-cli"
              echo "Cloud: gcloud, docker, colima"
              echo ""
            '';
            extraHook = ''
              # npm configuration (must come before AI tools installation)
              ${npmConfig}

              # AI tools installation
              ${ensureAiTools}
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
            paths = toolsets.common ++ toolsets.ai ++ toolsets.cloud ++ toolsets.devops ++ toolsets.go ++ toolsets.rust ++ toolsets.javascript ++ toolsets.lua ++ toolsets.java;
          };

          # Development environments as packages
          dev-node = pkgs.buildEnv {
            name = "dev-node";
            paths = toolsets.common ++ toolsets.javascript;
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
