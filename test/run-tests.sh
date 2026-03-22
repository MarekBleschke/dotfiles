#!/usr/bin/env bash
#
# Host-side test runner for dotfiles profile feature.
# Builds Docker container and runs tests inside it.

set -e

cd "$(dirname "$0")"

# Check for Docker
if ! command -v docker &>/dev/null; then
  echo "Error: Docker is not installed or not in PATH"
  echo "Please install Docker to run tests locally."
  echo "Tests will run automatically in GitHub Actions CI."
  exit 1
fi

# Use docker compose v2 or fall back to docker-compose v1
compose_cmd() {
  if docker compose version &>/dev/null; then
    docker compose "$@"
  else
    docker-compose "$@"
  fi
}

echo "Building test container..."
compose_cmd build

echo "Running tests..."
compose_cmd run --rm dotfiles-test /dotfiles/test/test-profile-feature.sh
test_result=$?

echo "Cleaning up..."
compose_cmd down

exit $test_result
