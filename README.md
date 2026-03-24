# Dotfiles

Inspired by (nice word for copied ;) ) [Holmans doftiles](https://github.com/holman/dotfiles).

Main differences:

- topic/symlinks file for list of symlinks to create. Support other destination paths than `$HOME`.
- changed `$ZSH` to `$MY_ZSH` - collision with oh-my-zsh
- **configuration profiles** - separate repositories as git submodules for machine-specific overrides

## topical

Everything's built around topic areas. If you're adding a new area to your
forked dotfiles — say, "Java" — you can simply add a `java` directory and put
files in there. Anything with an extension of `.zsh` will get automatically
included into your shell.

## components

There's a few special files in the hierarchy.

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **topic/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **topic/completion.zsh**: Any file named `completion.zsh` is loaded
  last and is expected to setup autocomplete.
- **topic/install.sh**: Any file named `install.sh` is executed when you run `script/install`. To avoid being loaded automatically, its extension is `.sh`, not `.zsh`.
- **topic/symlinks**: each line should contain src to file/dir to link
and a dst to link to. They should be separated by white sign (i.e. space).
Src path should be relative to topic directory. For dst path `$HOME` will
be resolved to home directory.

## profiles

Profiles allow you to maintain machine-specific configurations in separate
git repositories. Profile repos are stored as git submodules in the `profiles/`
directory.

### How profiles work

- Profile files **override** base dotfiles on a file-by-file basis
- If a profile has `git/aliases.zsh`, it replaces only that file from base
- All other base files are still loaded
- Profiles can also add **new topics** that don't exist in base

### Adding a profile

```sh
# Add a profile as a git submodule
git submodule add git@github.com:youruser/dotfiles-work.git profiles/work

# Bootstrap with the profile
script/bootstrap.sh --profile work

# Or use environment variable
DOTFILES_PROFILE=work script/bootstrap.sh
```

### Profile repository structure

Your profile repo should mirror the dotfiles topic structure:

```
dotfiles-work/          # Your profile repository
├── git/
│   └── aliases.zsh     # Overrides base git/aliases.zsh
├── editor/
│   └── env.zsh         # Overrides base editor/env.zsh
├── work-tools/         # New topic (only in this profile)
│   ├── path.zsh
│   └── install.sh
└── symlinks            # Profile-level symlinks
```

### Profile selection priority

1. Command line argument: `--profile work`
2. Environment variable: `DOTFILES_PROFILE=work`
3. Saved profile file: `~/.dotfiles_profile`

The selected profile is automatically saved to `~/.dotfiles_profile` for
future shell sessions.

### Switching profiles

```sh
# Switch to a different profile
script/bootstrap.sh --profile personal

# Clear profile (use base config only)
rm ~/.dotfiles_profile
script/bootstrap.sh
```

## install

Run this:

```sh
git clone https://github.com/belskar/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

This will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.

`dot` is a simple script that installs some dependencies, sets sane macOS
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`.
