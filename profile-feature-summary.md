# Profile Feature Implementation Summary

This document describes the configuration profiles feature added to the dotfiles repository.

## Feature Overview

Configuration profiles allow machine-specific overrides stored as separate git submodules.
Profiles use file-by-file merge: profile files override matching base files, other base files remain loaded.

## Requirements Implemented

- [x] Default configs shared between profiles
- [x] Profile has higher precedence than default config
- [x] Profile selected via environment variable or command parameter
- [x] Profile overrides selected files (no merging within files)
- [x] Profiles stored as git submodules in `profiles/`
- [x] README updated with profile documentation

## Files Changed

### New Files

| File | Purpose |
|------|---------|
| `profiles/.gitkeep` | Directory for profile submodules |
| `script/_profile.sh` | Profile detection and helper functions |

### Modified Files

| File | Changes |
|------|---------|
| `script/bootstrap.sh` | Added `--profile` arg, profile symlink merging, saves profile to `~/.dotfiles_profile` |
| `zsh/zshrc.symlink` | Profile-aware .zsh loading with file-by-file merge logic |
| `bin/dot` | Reads saved profile, runs `git submodule update` for profiles |
| `script/install.sh` | Runs profile `install.sh` scripts after base installers |
| `README.md` | Added profiles documentation section |

## Key Implementation Details

### Profile Selection Priority

1. Command line: `--profile <name>`
2. Environment variable: `DOTFILES_PROFILE`
3. Saved file: `~/.dotfiles_profile`

### File Override Logic

```
For each file in base dotfiles:
  If profile has same relative path → use profile version
  Else → use base version

For each file in profile not in base:
  → Load as addition (new file)
```

### Symlink Handling (`script/bootstrap.sh`)

- Collects base symlinks first (excludes `profiles/` directory)
- Collects profile symlinks second (these override by destination path)
- Creates merged symlink set

### Zsh Loading (`zsh/zshrc.symlink`)

- Uses associative array `file_map[relative_path] = absolute_path`
- Base files added first, profile files override by key
- Maintains load order: `path.zsh` first, `completion.zsh` last

### Profile Persistence

- Bootstrap saves profile to `~/.dotfiles_profile`
- Zshrc reads this file on shell startup
- `bin/dot` reads for update operations

## Commits

```
423ed6b AGENT: Add profiles documentation to README
d487ffd AGENT: Add profile support to install script
a14fbb3 AGENT: Add profile support to dot command
aa022d8 AGENT: Add profile-aware zsh file loading
bb331de AGENT: Add profile support to bootstrap script
df1ecab AGENT: Add profile helper functions script
c584e3a AGENT: Add profiles directory for configuration submodules
```

## Usage Examples

```bash
# Add a profile as git submodule
git submodule add git@github.com:user/dotfiles-work.git profiles/work

# Bootstrap with profile (command arg)
script/bootstrap.sh --profile work

# Bootstrap with profile (env var)
DOTFILES_PROFILE=work script/bootstrap.sh

# Switch profiles
script/bootstrap.sh --profile personal

# Clear profile (use base only)
rm ~/.dotfiles_profile
script/bootstrap.sh
```

## Profile Repository Structure

Profile repos should mirror dotfiles topic structure:

```
dotfiles-work/              # Separate git repository
├── git/
│   └── aliases.zsh         # Overrides base git/aliases.zsh
├── editor/
│   └── env.zsh             # Overrides base editor/env.zsh
├── work-tools/             # New topic (addition)
│   ├── path.zsh
│   └── install.sh
└── symlinks                # Profile-level symlinks
```

## Testing Checklist

- [ ] Bootstrap without profile uses base config only
- [ ] Bootstrap with `--profile` loads profile overrides
- [ ] Bootstrap with `DOTFILES_PROFILE` env var works
- [ ] Profile is saved to `~/.dotfiles_profile`
- [ ] New shell sessions load saved profile
- [ ] Profile .zsh files override base files
- [ ] Profile symlinks override base symlinks
- [ ] Profile install.sh scripts run after base
- [ ] `bin/dot` updates submodules when profile is set
- [ ] Invalid profile name shows error
