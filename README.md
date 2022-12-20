# Dotfiles

A collection of configurations meant to speed up my workflow,
in addition to reducing the complexity of migrations.

## Usage (WIP)

Create a configuration file and run `./pm apply`

```toml
[[configuration]]
repo = ""

[[links]
source = "~/dotfiles/nvim"
target = "~/.config/"

[[packages]
repo = "" 
tag = "latest"
install_instructions = "./install.sh"
```
