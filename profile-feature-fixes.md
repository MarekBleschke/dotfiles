# Profile Feature Fixes

Code review fixes applied to the configuration profiles feature implementation.

## Fixes Applied

### 1. Quote `$0` in dirname calls (bootstrap.sh)

**Issue:** Unquoted `$0` in `dirname` calls can fail with paths containing spaces.

**Files:** `script/bootstrap.sh`

**Fix:** Changed `$(dirname $0)` to `$(dirname "$0")` in all occurrences.

---

### 2. Add validation for missing `--profile` argument value (bootstrap.sh)

**Issue:** Running `script/bootstrap.sh --profile` without a value causes unset variable error.

**Files:** `script/bootstrap.sh`

**Fix:** Added check for `${2:-}` before accessing `$2`, with user-friendly error message.

---

### 3. Remove dead code after `fail()` call (_profile.sh)

**Issue:** `return 1` after `fail()` is never reached because `fail()` calls `exit`.

**Files:** `script/_profile.sh`

**Fix:** Removed unreachable `return 1` and `return 0` statements from `validate_profile()`.

---

### 4. Remove unused functions (_profile.sh)

**Issue:** Three functions were defined but never used anywhere in the codebase.

**Files:** `script/_profile.sh`

**Removed functions:**
- `list_profiles()` - Lists available profiles
- `get_effective_file()` - Returns profile or base file path
- `get_profile_additions()` - Gets profile files not in base

**Note:** These can be re-added if needed in future. The logic they implemented is done inline in `zshrc.symlink` and `bootstrap.sh`.

---

### 5. Add `.git*` exclusion to profile symlinks find (bootstrap.sh)

**Issue:** Profile symlinks search didn't exclude `.git*` paths, unlike base symlinks search.

**Files:** `script/bootstrap.sh`

**Fix:** Added `-not -path '*.git*'` to the find command for profile symlinks.

---

### 6. Fix typo `dotfilesDirecotry` (bin/dot)

**Issue:** Variable name typo: `dotfilesDirecotry` instead of `dotfilesDirectory`.

**Files:** `bin/dot`

**Fix:** Renamed variable to `dotfilesDirectory` in declaration and usage.

---

### 7. Remove debug output (bootstrap.sh)

**Issue:** Debug line `echo "Current pwd: $(pwd)"` was left in the script.

**Files:** `script/bootstrap.sh`

**Fix:** Removed the debug echo statement.

---

### 8. Standardize on `[[ ]]` bash conditionals (_profile.sh)

**Issue:** Inconsistent use of `[ ]` (POSIX) vs `[[ ]]` (Bash) conditionals across files.

**Files:** `script/_profile.sh`

**Fix:** Changed all `[ ]` conditionals to `[[ ]]` for consistency with other bash scripts.

---

### 9. Add profile validation to `bin/dot`

**Issue:** No validation that saved profile directory exists before running operations.

**Files:** `bin/dot`

**Fix:** Added check for profile directory existence with error message and exit.

---

### 10. Add profile validation to `script/install.sh`

**Issue:** No validation that saved profile directory exists before running profile installers.

**Files:** `script/install.sh`

**Additional fix:** Also quoted `$0` in dirname call.

**Fix:** Added check for profile directory existence. If invalid, clears profile and continues with base installers only (graceful degradation).

---

## Commits

```
7789dbf AGENT FIX: Quote $0 in dirname calls to handle paths with spaces
40e16c2 AGENT FIX: Add validation for missing --profile argument value
cd211b9 AGENT FIX: Remove dead code after fail() call in validate_profile
012c18c AGENT FIX: Remove unused functions list_profiles, get_effective_file, get_profile_additions
708c5e9 AGENT FIX: Add .git* exclusion to profile symlinks find command
c816a78 AGENT FIX: Fix typo dotfilesDirecotry -> dotfilesDirectory
db182ff AGENT FIX: Remove debug output from bootstrap script
4a39668 AGENT FIX: Standardize on [[ ]] bash conditionals in _profile.sh
7811039 AGENT FIX: Add profile validation to bin/dot command
1cf7b4e AGENT FIX: Add profile validation to install.sh and quote $0
```

## Not Fixed (Intentionally Skipped)

### Add `set -e` to `_profile.sh`

**Reason:** `_profile.sh` is designed to be sourced by other scripts that already have error handling (`set -e` or `set -eu`). Adding it would be redundant and could cause issues if the sourcing script intentionally uses different error handling.
