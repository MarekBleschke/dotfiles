#!/usr/bin/env bash
#
# Profile detection and helper functions for dotfiles configuration profiles.
#
# Profiles allow overriding base dotfiles on a file-by-file basis.
# Profile repos are stored as git submodules in profiles/ directory.
#
# Usage:
#   source script/_profile.sh
#   profile=$(get_profile "$1")  # $1 = --profile argument value
#

PROFILE_FILE="$HOME/.dotfiles_profile"
PROFILES_DIR="$DOTFILES_ROOT/profiles"

# Get active profile name from: argument > env var > saved file
# Returns empty string if no profile is set
get_profile() {
  local arg_profile="${1:-}"

  # Priority: argument > env var > saved file
  if [ -n "$arg_profile" ]; then
    echo "$arg_profile"
  elif [ -n "${DOTFILES_PROFILE:-}" ]; then
    echo "$DOTFILES_PROFILE"
  elif [ -f "$PROFILE_FILE" ]; then
    cat "$PROFILE_FILE"
  else
    echo ""
  fi
}

# Validate that profile exists as a directory
# Returns 0 if valid or empty, 1 if invalid
validate_profile() {
  local profile="$1"

  if [ -z "$profile" ]; then
    return 0
  fi

  local profile_path="$PROFILES_DIR/$profile"
  if [ ! -d "$profile_path" ]; then
    fail "Profile '$profile' not found at $profile_path"
    return 1
  fi

  return 0
}

# Save profile name to persistent file
save_profile() {
  local profile="$1"

  if [ -n "$profile" ]; then
    echo "$profile" > "$PROFILE_FILE"
    success "Profile '$profile' saved to $PROFILE_FILE"
  elif [ -f "$PROFILE_FILE" ]; then
    rm "$PROFILE_FILE"
    info "Profile cleared (using base config only)"
  fi
}

# Get the profile directory path
# Returns empty if no profile
get_profile_path() {
  local profile="$1"

  if [ -n "$profile" ]; then
    echo "$PROFILES_DIR/$profile"
  else
    echo ""
  fi
}

# List all available profiles
list_profiles() {
  if [ -d "$PROFILES_DIR" ]; then
    find "$PROFILES_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; 2>/dev/null | sort
  fi
}

# Check if a file should be loaded from profile instead of base
# Returns the path to use (profile path if override exists, base path otherwise)
get_effective_file() {
  local profile="$1"
  local base_file="$2"

  if [ -z "$profile" ]; then
    echo "$base_file"
    return
  fi

  # Convert base path to relative path from DOTFILES_ROOT
  local relative_path="${base_file#$DOTFILES_ROOT/}"
  local profile_file="$PROFILES_DIR/$profile/$relative_path"

  if [ -f "$profile_file" ]; then
    echo "$profile_file"
  else
    echo "$base_file"
  fi
}

# Get all files from profile that don't exist in base (new files)
# These are additions, not overrides
get_profile_additions() {
  local profile="$1"
  local file_pattern="$2"  # e.g., "*.zsh" or "symlinks"

  if [ -z "$profile" ]; then
    return
  fi

  local profile_path="$PROFILES_DIR/$profile"
  if [ ! -d "$profile_path" ]; then
    return
  fi

  # Find all matching files in profile
  find "$profile_path" -name "$file_pattern" -type f 2>/dev/null | while read -r profile_file; do
    local relative_path="${profile_file#$profile_path/}"
    local base_file="$DOTFILES_ROOT/$relative_path"

    # Only output if base file doesn't exist
    if [ ! -f "$base_file" ]; then
      echo "$profile_file"
    fi
  done
}
