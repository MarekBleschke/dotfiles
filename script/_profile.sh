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
# Exits with error if profile is invalid
validate_profile() {
  local profile="$1"

  if [ -z "$profile" ]; then
    return 0
  fi

  local profile_path="$PROFILES_DIR/$profile"
  if [ ! -d "$profile_path" ]; then
    fail "Profile '$profile' not found at $profile_path"
  fi
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
