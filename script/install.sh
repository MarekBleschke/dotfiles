#!/usr/bin/env bash
#
# Run all dotfiles installers.
# With profile support: runs base installers first, then profile installers.

set -e

cd "$(dirname $0)"/..
DOTFILES_ROOT=$(pwd -P)

# Load saved profile
DOTFILES_PROFILE_FILE="$HOME/.dotfiles_profile"
if [[ -f "$DOTFILES_PROFILE_FILE" ]]; then
  DOTFILES_PROFILE=$(cat "$DOTFILES_PROFILE_FILE")
  echo "› Using profile: $DOTFILES_PROFILE"
else
  DOTFILES_PROFILE=""
fi

echo "› brew bundle"
brew bundle

# Run base installers (excluding script/ and profiles/)
echo "› Running base installers"
find . -name install.sh -not -path './script/*' -not -path './profiles/*' | while read installer; do
  sh -c "${installer}"
done

# Run profile installers if profile is set
if [[ -n "$DOTFILES_PROFILE" && -d "$DOTFILES_ROOT/profiles/$DOTFILES_PROFILE" ]]; then
  echo "› Running profile installers"
  find "./profiles/$DOTFILES_PROFILE" -name install.sh 2>/dev/null | while read installer; do
    sh -c "${installer}"
  done
fi
