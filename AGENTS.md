# AGENTS.md

Guidelines for AI coding agents operating in this dotfiles repository.

## Repository Overview

This is a topical dotfiles repository for macOS, organized around "topics" (directories).
Each topic contains configuration files for a specific tool or area (e.g., `zsh/`, `git/`, `tmux/`).

The repository is inspired by [Holman's dotfiles](https://github.com/holman/dotfiles).

## Project Structure

```
dotfiles/
├── aerospace/     # Window manager configuration
├── ai_tools/      # AI tool configurations (OpenCode, etc.)
├── bin/           # Executable scripts (added to $PATH)
├── editor/        # Editor configs (Neovim, markdownlint)
├── functions/     # Zsh functions (autoloaded)
├── fzf/           # Fuzzy finder configuration
├── git/           # Git aliases and completions
├── homebrew/      # Homebrew installation and path
├── keyboard/      # Karabiner-Elements config
├── macos/         # macOS system defaults
├── node/          # Node.js/NVM configuration
├── script/        # Bootstrap and installation scripts
├── system/        # System path configuration
├── tmux/          # Tmux configuration
├── zk/            # Zettelkasten note-taking config
└── zsh/           # Zsh shell configuration
```

## Installation & Setup Commands

```bash
# Initial setup (clones and symlinks everything)
git clone https://github.com/belskar/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap.sh

# Update environment and dependencies
bin/dot

# Run all topic installers
script/install.sh

# Reload zsh configuration
source ~/.zshrc
# or use alias:
reload!
```

## Testing Changes

### Automated Tests (Docker)

Run the profile feature tests in an isolated Docker container:

```bash
# Run all tests
test/run-tests.sh

# Or manually with docker-compose
cd test && docker-compose run --rm dotfiles-test /dotfiles/test/test-profile-feature.sh
```

Tests also run automatically via GitHub Actions on push/PR to main.

### Manual Verification

1. **Shell config**: Run `source ~/.zshrc` or `reload!` to test zsh changes
2. **Symlinks**: Run `script/bootstrap.sh` to recreate symlinks
3. **Installers**: Run individual `<topic>/install.sh` scripts
4. **Neovim**: Open nvim and check for errors with `:checkhealth`

## File Naming Conventions

### Special File Names (Auto-loaded by zshrc)

| Pattern              | Purpose                                    | Load Order |
|----------------------|--------------------------------------------|------------|
| `topic/*.zsh`        | Loaded into shell environment              | Middle     |
| `topic/path.zsh`     | PATH setup (loaded first)                  | First      |
| `topic/completion.zsh` | Autocomplete setup (loaded last)         | Last       |
| `topic/install.sh`   | Installer script (run by `script/install`) | Manual     |
| `topic/symlinks`     | Symlink definitions                        | Bootstrap  |

### Symlinks File Format

Each line: `<source> <destination>`
- Source path is relative to the topic directory
- Destination supports `$HOME` variable

```
# Example: editor/symlinks
nvim $HOME/.config/nvim
markdownlint-cli2.yaml $HOME/.markdownlint-cli2.yaml
```

## Code Style Guidelines

### Shell Scripts (Bash/Zsh)

**Shebang lines:**
```bash
#!/usr/bin/env bash    # For bash scripts
#!/bin/zsh             # For zsh-specific scripts
#!/bin/sh              # For POSIX-compatible scripts
```

**Error handling:**
```bash
set -eu                # Exit on error, exit on unset variable
set -e                 # Exit on error only (for less strict scripts)
```

**Formatting:**
- Use 2-space indentation
- Use lowercase for local variables
- Use UPPERCASE for exported/environment variables
- Quote variables: `"$var"` not `$var`
- Use `$(command)` instead of backticks

**Helper functions (from script/_functions.sh):**
```bash
info "message"         # Blue info message
user "message"         # Yellow prompt message
success "message"      # Green success message
fail "message"         # Red error message (exits)
```

**Conditional checks:**
```bash
# Check if command exists
if ! command -v brew &>/dev/null; then
  # install it
fi

# Check if directory exists
if [ ! -d ~/.some/dir ]; then
  mkdir -p ~/.some/dir
fi

# Check if file/link exists
if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then
  # handle existing file
fi
```

### Lua (Neovim Config)

**Formatting (stylua.toml):**
- Indent: 2 spaces
- Column width: 120
- Use spaces, not tabs

**Structure:**
- Main entry: `init.lua`
- Config files: `lua/config/*.lua`
- Plugin specs: `lua/plugins/*.lua`
- Uses LazyVim as base configuration

### Configuration Files

**TOML files:** Use for aerospace, zk, stylua configs
**JSON files:** Use for AI tools (opencode.json), neovim lazy-lock
**YAML files:** Use for markdownlint configuration

## Naming Conventions

| Type                | Convention              | Example                    |
|---------------------|-------------------------|----------------------------|
| Topic directories   | lowercase, singular     | `git/`, `zsh/`, `editor/`  |
| Zsh files           | lowercase, `.zsh` ext   | `aliases.zsh`, `config.zsh`|
| Shell scripts       | lowercase, `.sh` ext    | `install.sh`, `bootstrap.sh`|
| Bin executables     | lowercase, no extension | `dot`, `e`, `tmux-sessionizer`|
| Zsh functions       | lowercase, no extension | `c`, `_c` (completion)     |
| Environment vars    | UPPERCASE, underscore   | `$MY_ZSH`, `$PROJECTS`     |
| Local variables     | lowercase               | `$src`, `$dst`, `$selected`|

## Key Environment Variables

```bash
$MY_ZSH       # Path to dotfiles root (~/.dotfiles)
$PROJECTS     # Projects directory (~/workspace)
$EDITOR       # Default editor (nvim)
$HOME         # User home directory
```

## Error Handling Patterns

```bash
# Simple exit on any error
set -e

# Strict mode (recommended for scripts)
set -eu

# Redirect stderr to /dev/null for optional commands
git ls-files --deleted 2> /dev/null

# Conditional with fallback
if [[ -a ~/.localrc ]]; then
  source ~/.localrc
fi
```

## Adding New Topics

1. Create topic directory: `mkdir -p newtopic/`
2. Add configuration files with `.zsh` extension for auto-loading
3. Create `symlinks` file if files need to be linked elsewhere
4. Create `install.sh` if dependencies need installation
5. Use `path.zsh` for PATH modifications (loaded first)
6. Use `completion.zsh` for autocompletions (loaded last)

## Common Modifications

**Add alias:** Edit `<topic>/aliases.zsh` or create new one
**Add PATH:** Create/edit `<topic>/path.zsh`
**Add zsh function:** Add file to `functions/` directory
**Add completion:** Create `functions/_<funcname>` file
**Add executable:** Add script to `bin/` directory
**Add macOS default:** Edit `macos/set-defaults.sh`
**Add brew package:** Edit `Brewfile`

## Dependencies (Brewfile)

Core tools installed via Homebrew:
- Shell: zsh (via oh-my-zsh)
- Editor: neovim, vim
- Search: fzf, fd, ripgrep
- Git: git, gh, lazygit
- Languages: go, node (via nvm), uv (python)
- Utils: bat, jq, tree, wget, tmux, zk

## Git Commit Guidelines

When committing changes made by AI agents:

**Commit message format:**
- Prefix all commits with `AGENT:` for general changes
- Use `AGENT FIX:` prefix for bug fixes
- Write meaningful commit messages that explain what and why
- Include details of changes in the commit body when helpful

**Committing process:**
```bash
# Only add files explicitly modified by you
git add file1.sh file2.zsh

# Use meaningful commit messages with AGENT prefix
git commit -m "AGENT: add new feature X

- Detail 1
- Detail 2"

# For bug fixes, use AGENT FIX prefix
git commit -m "AGENT FIX: resolve shellcheck warnings

- Fixed issue 1
- Fixed issue 2"
```

**Important rules:**
- **NEVER push commits** - let the user decide when to push
- **Only add files you explicitly modified** - avoid `git add .` or `git commit -a`
- **Do not commit** untracked files that were created as byproducts (temp files, logs, etc.)
- **Always check `git status`** before committing to see what will be included

## Important Notes

- `$MY_ZSH` is used instead of `$ZSH` to avoid collision with oh-my-zsh
- The `bin/` directory is added to `$PATH` automatically
- All `*.zsh` files are sourced automatically by zshrc
- Symlinks support non-$HOME destinations (unlike original holman dotfiles)
- Environment-specific settings go in `~/.localrc` (not tracked)
- **Bash 3.2 compatibility required**: macOS ships with Bash 3.2; avoid Bash 4+ features:
  - No `declare -A` (associative arrays)
  - No `readarray`/`mapfile`
  - No `${var,,}` or `${var^^}` (case conversion)
  - No negative array indices `${array[-1]}`
  - No `;;&` case fall-through
