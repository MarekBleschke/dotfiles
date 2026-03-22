#!/usr/bin/env bash
#
# Test script for dotfiles profile feature.
# Runs inside Docker container to test bootstrap and profile loading.

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
  echo -e "${GREEN}PASS${NC}: $1"
  ((TESTS_PASSED++)) || true
}

fail() {
  echo -e "${RED}FAIL${NC}: $1"
  ((TESTS_FAILED++)) || true
}

info() {
  echo -e "${YELLOW}INFO${NC}: $1"
}

# Setup function: prepares test environment
setup() {
  info "Setting up test environment..."

  # Copy dotfiles to home directory
  cp -r /dotfiles ~/.dotfiles

  # Copy mock profile to profiles directory
  mkdir -p ~/.dotfiles/profiles
  cp -r /mock-profile ~/.dotfiles/profiles/test

  # Create mock oh-my-zsh (required by zshrc)
  mkdir -p ~/.oh-my-zsh
  touch ~/.oh-my-zsh/oh-my-zsh.sh

  # Create mock ~/.local/bin/env (required by zshrc)
  mkdir -p ~/.local/bin
  touch ~/.local/bin/env

  # Create directories needed for symlinks
  mkdir -p ~/.config/opencode

  # Configure git for bootstrap script
  git config --global user.email "test@example.com"
  git config --global user.name "Test User"
}

# Cleanup function: removes test artifacts
cleanup() {
  info "Cleaning up..."
  cd ~  # Return to home before removing directories
  rm -rf ~/.dotfiles
  rm -rf ~/.zshrc
  rm -rf ~/.dotfiles_profile
  rm -rf ~/.oh-my-zsh
  rm -rf ~/.local
  rm -rf ~/.test_profile_symlink
  rm -f /tmp/profile_installer_ran
  unset DOTFILES_PROFILE 2>/dev/null || true
}

# Test: Bootstrap without profile uses base config only
test_bootstrap_no_profile() {
  info "Test: Bootstrap without profile"
  cleanup
  setup

  # Run bootstrap without profile, auto-answer "Overwrite all"
  cd ~/.dotfiles
  ./script/bootstrap.sh <<< "O" 2>/dev/null

  # Check that no profile file was created
  if [[ ! -f ~/.dotfiles_profile ]]; then
    pass "No profile file created when running without profile"
  else
    fail "Profile file should not exist when running without profile"
  fi
}

# Test: Bootstrap with --profile argument saves profile
test_bootstrap_with_profile_arg() {
  info "Test: Bootstrap with --profile argument"
  cleanup
  setup

  # Run bootstrap with profile argument
  cd ~/.dotfiles
  ./script/bootstrap.sh --profile test <<< "O" 2>/dev/null

  # Check that profile was saved
  if [[ -f ~/.dotfiles_profile ]]; then
    local saved_profile
    saved_profile=$(cat ~/.dotfiles_profile)
    if [[ "$saved_profile" == "test" ]]; then
      pass "Profile 'test' saved to ~/.dotfiles_profile via --profile argument"
    else
      fail "Profile file contains '$saved_profile' instead of 'test'"
    fi
  else
    fail "Profile file was not created"
  fi
}

# Test: Bootstrap with DOTFILES_PROFILE env var saves profile
test_bootstrap_with_env_var() {
  info "Test: Bootstrap with DOTFILES_PROFILE env var"
  cleanup
  setup

  # Run bootstrap with environment variable
  cd ~/.dotfiles
  DOTFILES_PROFILE=test ./script/bootstrap.sh <<< "O" 2>/dev/null

  # Check that profile was saved
  if [[ -f ~/.dotfiles_profile ]]; then
    local saved_profile
    saved_profile=$(cat ~/.dotfiles_profile)
    if [[ "$saved_profile" == "test" ]]; then
      pass "Profile 'test' saved to ~/.dotfiles_profile via env var"
    else
      fail "Profile file contains '$saved_profile' instead of 'test'"
    fi
  else
    fail "Profile file was not created"
  fi
}

# Test: Invalid profile shows error
test_invalid_profile() {
  info "Test: Invalid profile shows error"
  cleanup
  setup

  # Run bootstrap with invalid profile
  cd ~/.dotfiles
  local output
  output=$(./script/bootstrap.sh --profile nonexistent 2>&1 <<< "O" || true)

  # Check for "not found" in error message
  if echo "$output" | grep -qi "not found"; then
    pass "Invalid profile shows 'not found' error"
  else
    fail "Invalid profile should show 'not found' error, got: $output"
  fi
}

# Test: Profile symlinks are created
test_profile_symlinks() {
  info "Test: Profile symlinks are created"
  cleanup
  setup

  # Run bootstrap with profile
  cd ~/.dotfiles
  ./script/bootstrap.sh --profile test <<< "O" 2>/dev/null

  # Check that profile symlink was created
  if [[ -L ~/.test_profile_symlink ]]; then
    pass "Profile symlink ~/.test_profile_symlink was created"
  else
    fail "Profile symlink ~/.test_profile_symlink was not created"
  fi
}

# Test: Profile .zsh files are loaded
test_profile_zsh_loading() {
  info "Test: Profile .zsh files are loaded"
  cleanup
  setup

  # Run bootstrap with profile
  cd ~/.dotfiles
  ./script/bootstrap.sh --profile test <<< "O" 2>/dev/null

  # Source zshrc and check for TEST_TOPIC_LOADED
  # We need to source it in a way that catches the variable
  local test_result
  test_result=$(zsh -c 'source ~/.zshrc 2>/dev/null; echo $TEST_TOPIC_LOADED')

  if [[ "$test_result" == "true" ]]; then
    pass "Profile .zsh files are loaded (TEST_TOPIC_LOADED=true)"
  else
    fail "Profile .zsh files not loaded (TEST_TOPIC_LOADED='$test_result')"
  fi
}

# Main function
main() {
  echo ""
  echo "========================================"
  echo "  Dotfiles Profile Feature Tests"
  echo "========================================"
  echo ""

  test_bootstrap_no_profile
  test_bootstrap_with_profile_arg
  test_bootstrap_with_env_var
  test_invalid_profile
  test_profile_symlinks
  test_profile_zsh_loading

  echo ""
  echo "========================================"
  echo "  Test Summary"
  echo "========================================"
  echo -e "  ${GREEN}Passed${NC}: $TESTS_PASSED"
  echo -e "  ${RED}Failed${NC}: $TESTS_FAILED"
  echo "========================================"
  echo ""

  # Final cleanup
  cleanup

  # Exit with failure if any test failed
  if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
  fi

  exit 0
}

main
