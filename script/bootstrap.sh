#!/usr/bin/env bash
# Bootstrap script for installing dotfiles and dependencies.
# Usage: Run this script from the dotfiles repository root.
#        script/bootstrap.sh [--profile <name>]

source "$(dirname "$0")/_functions.sh" # Load helper functions

cd "$(dirname "$0")/.."   # Change to repository root
DOTFILES_ROOT=$(pwd -P) # Store absolute path to dotfiles root
export DOTFILES_ROOT

source "$(dirname "$0")/_profile.sh" # Load profile functions

set -eu # Exit on error or unset variable

# Parse command line arguments
PROFILE_ARG=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --profile)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --profile requires a value"
        echo "Usage: script/bootstrap.sh [--profile <name>]"
        exit 1
      fi
      PROFILE_ARG="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: script/bootstrap.sh [--profile <name>]"
      exit 1
      ;;
  esac
done

# Get and validate profile
PROFILE=$(get_profile "$PROFILE_ARG")
validate_profile "$PROFILE"

if [ -n "$PROFILE" ]; then
  info "Using profile: $PROFILE"
else
  info "Using base configuration (no profile)"
fi

echo ''

# link_file <src> <dst>
# Creates a symlink from <src> to <dst>, handling existing files:
# - Prompts user to skip, overwrite, or backup if destination exists.
# - Supports "all" actions for batch operations.
link_file() {
  local src=$1 dst=$2

  local overwrite= backup= skip=
  local action=

  if [ -f "$dst" -o -d "$dst" -o -L "$dst" ]; then

    if [ "$overwrite_all" == "false" ] && [ "$backup_all" == "false" ] && [ "$skip_all" == "false" ]; then

      local currentSrc="$(readlink $dst)"

      if [ "$currentSrc" == "$src" ]; then

        echo "skipping"
        skip=true

      else

        user "File already exists: $dst ($(basename "$src")), what do you want to do?\n\
        [s]kip, [S]kip all, [o]verwrite, [O]verwrite all, [b]ackup, [B]ackup all?"
        read -n 1 action </dev/tty

        case "$action" in
        o)
          overwrite=true
          ;;
        O)
          overwrite_all=true
          ;;
        b)
          backup=true
          ;;
        B)
          backup_all=true
          ;;
        s)
          skip=true
          ;;
        S)
          skip_all=true
          ;;
        *) ;;
        esac

      fi

    fi

    overwrite=${overwrite:-$overwrite_all}
    backup=${backup:-$backup_all}
    skip=${skip:-$skip_all}

    if [ "$overwrite" == "true" ]; then
      rm -rf "$dst"
      success "removed $dst"
    fi

    if [ "$backup" == "true" ]; then
      mv "$dst" "${dst}.backup"
      success "moved $dst to ${dst}.backup"
    fi

    if [ "$skip" == "true" ]; then
      success "skipped $src"
    fi
  fi

  if [ "$skip" != "true" ]; then # "false" or empty
    ln -s "$1" "$2"
    success "linked $1 to $2"
  fi
}

# install_dotfiles
# Finds all 'symlinks' files in the dotfiles repo and creates symlinks as specified.
# With profile support: profile symlinks override base symlinks (file-by-file).
install_dotfiles() {
  info 'installing dotfiles'

  local overwrite_all=false backup_all=false skip_all=false

  # Associative array to track destination -> source mapping
  # Profile entries will override base entries
  declare -A symlink_map

  # First, collect all base symlinks
  for symlinks in $(find -H "$DOTFILES_ROOT" -maxdepth 2 -name 'symlinks' -not -path '*.git*' -not -path '*profiles*'); do
    srcDir="$(dirname "$symlinks")"
    while read -r src dst _; do
      # skip empty lines and comments
      [[ -z "$src" || "$src" =~ ^# ]] && continue
      local expanded_dst="${dst/#\$HOME/$HOME}"
      symlink_map["$expanded_dst"]="$srcDir/$src"
    done <"$symlinks"
  done

  # Then, collect profile symlinks (these override base)
  if [ -n "$PROFILE" ]; then
    local profile_path
    profile_path=$(get_profile_path "$PROFILE")
    if [ -d "$profile_path" ]; then
      for symlinks in $(find -H "$profile_path" -maxdepth 2 -name 'symlinks' -not -path '*.git*' 2>/dev/null); do
        srcDir="$(dirname "$symlinks")"
        while read -r src dst _; do
          # skip empty lines and comments
          [[ -z "$src" || "$src" =~ ^# ]] && continue
          local expanded_dst="${dst/#\$HOME/$HOME}"
          symlink_map["$expanded_dst"]="$srcDir/$src"
          info "Profile override: $dst"
        done <"$symlinks"
      done
    fi
  fi

  # Create all symlinks
  for dst in "${!symlink_map[@]}"; do
    link_file "${symlink_map[$dst]}" "$dst"
  done
}

install_dotfiles

# Save profile for future shell sessions
save_profile "$PROFILE"

# Install dependencies using bin/dot script.
info "installing dependencies"
if source bin/dot | while read -r data; do info "$data"; done; then
  success "dependencies installed"
else
  fail "error installing dependencies"
fi

echo ''
echo '  All installed!'
