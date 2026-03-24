# Dotfiles Test Framework

Docker-based testing framework for the dotfiles profile feature.

## Purpose

This test framework provides isolated testing for the dotfiles profile feature using Docker containers. Tests run in a clean Ubuntu environment to ensure profile functionality works correctly without affecting your local setup.

## Running Tests Locally

```bash
./test/run-tests.sh
```

This will:
1. Build the Docker test container
2. Run all profile feature tests
3. Clean up containers after completion
4. Exit with appropriate status code (0 = pass, 1 = fail)

## Debugging Inside Container

To enter the container for manual debugging:

```bash
cd test
docker-compose run --rm dotfiles-test /bin/zsh
```

Inside the container, you can:
- Manually run the test script: `/dotfiles/test/test-profile-feature.sh`
- Copy dotfiles: `cp -r /dotfiles ~/.dotfiles`
- Run bootstrap: `cd ~/.dotfiles && ./script/bootstrap.sh --profile test`

## What Is Tested

- Bootstrap without profile uses base config only
- Bootstrap with `--profile` argument loads profile overrides
- Bootstrap with `DOTFILES_PROFILE` env var works
- Profile is saved to `~/.dotfiles_profile`
- Profile .zsh files are loaded and can set environment variables
- Profile symlinks are created
- Invalid profile name shows error message

## What Is NOT Tested

These features require macOS and cannot be tested in Docker:

- Homebrew installation and updates
- macOS defaults via `macos/set-defaults.sh`
- Full `bin/dot` flow (calls Homebrew)
- Karabiner, Aerospace, and other macOS-specific tools

## Adding New Tests

1. Add a new test function in `test-profile-feature.sh`:
   ```bash
   test_my_new_feature() {
     info "Test: My new feature"
     cleanup
     setup

     # Test logic here

     if [[ condition ]]; then
       pass "Feature works correctly"
     else
       fail "Feature did not work"
     fi
   }
   ```

2. Call the function from `main()`:
   ```bash
   test_my_new_feature
   ```

## Mock Profile Structure

The `mock-profile/` directory contains test fixtures:

```
mock-profile/
├── git/
│   └── aliases.zsh      # Tests file override behavior
├── test-topic/
│   ├── config.zsh       # Tests new topic from profile
│   └── install.sh       # Tests profile installer execution
└── symlinks             # Tests profile symlink creation
```

## CI Integration

Tests run automatically via GitHub Actions on:
- Pull requests to `main`
- Push/merge to `main`

See `.github/workflows/test.yml` for CI configuration.
