#!/usr/bin/env bash
# scripts/test_maintenance.sh - Unit & contract tests for make update & make skills (#2)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $msg" >&2
    echo "  expected: $expected" >&2
    echo "  actual:   $actual" >&2
    exit 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="$3"
  case "$haystack" in
    *"$needle"*) ;;
    *)
      echo "FAIL: $msg" >&2
      echo "  expected to contain: $needle" >&2
      echo "  actual:              $haystack" >&2
      exit 1
      ;;
  esac
}

echo "Testing Makefile targets and contracts..."

# 1. make help lists update and skills
help_out="$(make -C "$REPO_DIR" help)"
assert_contains "$help_out" "make update" "make help must describe make update"
assert_contains "$help_out" "make skills" "make help must describe make skills"

# 2. make -n update dry run includes all expected update steps
update_dry_run="$(make -C "$REPO_DIR" -n update)"
assert_contains "$update_dry_run" "brew update && brew upgrade && brew cleanup" "make update must update and clean homebrew"
assert_contains "$update_dry_run" ".oh-my-zsh" "make update must update Oh-My-Zsh"
assert_contains "$update_dry_run" "zsh-syntax-highlighting" "make update must update zsh-syntax-highlighting"
assert_contains "$update_dry_run" "zsh-autosuggestions" "make update must update zsh-autosuggestions"
assert_contains "$update_dry_run" "powerlevel10k" "make update must update powerlevel10k"
assert_contains "$update_dry_run" ".tmux" "make update must update gpakosz/.tmux"
assert_contains "$update_dry_run" "nvim" "make update must update kickstart.nvim"
assert_contains "$update_dry_run" "check" "make update must run health check"

# 3. make -n skills dry run includes npx skills installation/update
skills_dry_run="$(make -C "$REPO_DIR" -n skills)"
assert_contains "$skills_dry_run" "skills" "make skills must invoke skills CLI"
assert_contains "$skills_dry_run" "mattpocock/skills" "make skills must install/update mattpocock/skills"
assert_contains "$skills_dry_run" "-g" "make skills must install globally to ~/.agents/skills"

# 4. Verify no agent skills or work/EA skills are tracked in git repository
tracked_skills="$(git -C "$REPO_DIR" ls-files | grep -iE '(\.agents/|skills/|ea-artifactory)' || true)"
assert_eq "" "$tracked_skills" "Zero skill files or work/EA skills must be tracked in git"

echo "PASS: All maintenance tests passed."
