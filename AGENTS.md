# AGENTS.md

## Overview

Topical dotfiles for macOS (inspired by Holman's dotfiles). Each topic directory contains config files; `*.zsh` files are auto-sourced by `zsh/zshrc.symlink`.

## Structure

```
bin/            # Executables added to $PATH
functions/      # Zsh autoloaded functions + completions (_<name>)
local/*.zsh     # Machine-specific config (gitignored, not tracked)
script/         # Bootstrap and install orchestration
system/         # System PATH setup (system/_path.zsh)
<topic>/        # One dir per tool: zsh, git, editor, fzf, ghostty, homebrew, keyboard, macos, node, opencode
```

Special files per topic: `path.zsh` (loaded first), `completion.zsh` (loaded last), `install.sh` (run by `script/install.sh`), `symlinks` (link definitions for bootstrap).

## Commands

```bash
script/bootstrap.sh   # Symlink all topics + run bin/dot
script/install.sh     # brew bundle + run all topic install.sh scripts
bin/dot               # git pull → macos defaults → homebrew install/update/upgrade → script/install
bin/e                 # Open $EDITOR in current dir (or dotfiles with -d)
```

No automated tests. **Shellcheck CI** runs on `bin/` and `script/` at warning severity — always verify with `shellcheck` before committing shell scripts.

## Symlinks Format

Each line in a `symlinks` file: `<source> <destination>`
- Source is relative to the topic directory
- `$HOME` in destination expands to home directory
- Escaped spaces (`\ `) in destination are supported (see `ghostty/symlinks`)

## Neovim

- Config at `editor/nvim/`, symlinked to `~/.config/nvim`
- Uses LazyVim as base; plugins in `lua/plugins/`, config in `lua/config/`
- Format Lua with stylua (config: `editor/nvim/stylua.toml` — 2-space indent, 120 col width)

## Conventions

- **`$MY_ZSH`** = dotfiles root (`~/.dotfiles`). Used instead of `$ZSH` to avoid oh-my-zsh collision.
- **`~/.localrc`** = secrets/tokens (sourced by zshrc, never committed)
- **`local/*.zsh`** = per-machine config (gitignored except `.gitkeep`)
- **Bash 3.2 compat required** in `.sh` scripts (macOS default bash): no associative arrays, no `readarray`/`mapmap`, no `${var,,}`/`${var^^}`, no negative array indices.
- Shell scripts: 2-space indent, quote variables, use `$(command)` not backticks.
- Helper functions from `script/_functions.sh`: `info`, `user`, `success`, `fail`.

## Git Commits

- Prefix with `AGENT:` (or `AGENT FIX:` for bug fixes)
- **Never push** — let the user decide
- Only `git add` files you explicitly modified
