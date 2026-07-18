# AGENTS.md

## Overview

Workstation bootstrapping and personal dotfiles managed by [mise](https://mise.jdx.dev/).

## Key commands

- `mise bootstrap` — re-apply symlink mappings and install packages defined in `mise.toml`

## Conventions
- `./bootstrap` installs Homebrew, oh-my-zsh, mise, then runs `mise bootstrap`
- System packages (brew formulae/casks) in `mise.toml` `[bootstrap.packages]`
- Global tool versions (i.e. node, python, go) in `mise/config.toml`
- Each tool has separate directory for its dotfiles
- When adding a new dotfile, add its symlink mapping to `mise.toml` `[dotfiles]`
- Use `shellcheck` for checking `./bootstrap` file
- Don't write any tests
