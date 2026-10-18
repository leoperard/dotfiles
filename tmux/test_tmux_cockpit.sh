#!/usr/bin/env bash
# tmux/test_tmux_cockpit.sh - Integration tests for tmux agentic cockpit (#4)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMUX_LOCAL="$REPO_DIR/tmux/.tmux.conf.local"

MOCK_BIN="$(mktemp -d)"
TMUX_LOG="$MOCK_BIN/tmux.log"
trap 'rm -rf "$MOCK_BIN"' EXIT

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

run_local_fn() {
  PATH="$MOCK_BIN:$PATH" cut -c3- "$TMUX_LOCAL" | PATH="$MOCK_BIN:$PATH" sh -s "$@"
}

mock_pgrep() {
  local match_line="$1"
  cat > "$MOCK_BIN/pgrep" << EOF
#!/usr/bin/env sh
if [ -n "$match_line" ]; then
  printf '%s\n' "$match_line"
  exit 0
fi
exit 1
EOF
  chmod +x "$MOCK_BIN/pgrep"
}

cat > "$MOCK_BIN/tmux" << EOF
#!/usr/bin/env sh
printf '%s\n' "\$*" >> "$TMUX_LOG"
EOF
chmod +x "$MOCK_BIN/tmux"

assert_popup_opens() {
  local session="$1"
  local pane_path="$2"
  local expected_agent="$3"
  local expected_popup_session="$4"
  : > "$TMUX_LOG"
  run_local_fn _toggle_agent_popup "$session" "$pane_path"
  local popup_cmd
  popup_cmd="$(cat "$TMUX_LOG")"
  assert_contains "$popup_cmd" "display-popup" "$session project must open display-popup"
  assert_contains "$popup_cmd" "-w 80% -h 80%" "popup must be ~80% size"
  assert_contains "$popup_cmd" "$pane_path" "popup must use current pane path"
  assert_contains "$popup_cmd" "$expected_popup_session" "popup attaches to $expected_popup_session"
  assert_contains "$popup_cmd" "'$expected_agent'" "popup must run $expected_agent"
}

# 1. Custom variable probe required by gpakosz/.tmux
probe_out="$(run_local_fn printf probe)"
assert_eq "probe" "$probe_out" "gpakosz/.tmux sh probe must output 'probe'"

# 2. agent_status outputs green active indicator when agy is running
mock_pgrep "12345 agy"
assert_eq "#[fg=green]🤖 active#[default]" "$(run_local_fn agent_status)" "agent_status shows green active when agy is running"

# 3. agent_status outputs green active indicator when claude is running
mock_pgrep "12346 claude"
assert_eq "#[fg=green]🤖 active#[default]" "$(run_local_fn agent_status)" "agent_status shows green active when claude is running"

# 4. agent_status outputs idle indicator when no agent is running
mock_pgrep ""
assert_eq "🤖 idle" "$(run_local_fn agent_status)" "agent_status shows idle when no agent is running"

# 4b. agent_status ignores background daemons (claude daemon/bg-spare/bg-pty-host and agy --hub)
cat > "$MOCK_BIN/pgrep" << 'EOF'
#!/usr/bin/env sh
cat << 'PROCS'
41995 claude bg-pty-host --bg-pty-host /tmp/cc-daemon/spare.pty.sock
42006 claude bg-spare --bg-spare /tmp/cc-daemon/spare.claim.sock
54255 /usr/local/bin/claude daemon run --json-path /tmp/daemon.json
81364 /Applications/Gemini.app/Contents/Helpers/agy --hub --hub-port=51542
PROCS
exit 0
EOF
chmod +x "$MOCK_BIN/pgrep"
assert_eq "🤖 idle" "$(run_local_fn agent_status)" "agent_status must ignore background claude/agy daemons"

# 5. tmux_conf_theme_status_right includes #{agent_status}
status_right_line="$(grep -E '^tmux_conf_theme_status_right=' "$TMUX_LOCAL")"
assert_contains "$status_right_line" '#{agent_status}' "tmux_conf_theme_status_right must include #{agent_status}"

# 6. _toggle_agent_popup opens ~80% display-popup running agy in personal workspace (per-project session)
assert_popup_opens "personal" "$HOME/workspace/personal/dotfiles" "agy" "agent-popup-agy-dotfiles"
assert_popup_opens "personal" "$HOME/workspace/personal/other" "agy" "agent-popup-agy-other"

# 7. _toggle_agent_popup opens ~80% display-popup running claude in work workspace
assert_popup_opens "work" "$HOME/workspace/work/service" "claude" "agent-popup-claude-service"

# 8. _toggle_agent_popup detaches cleanly when already inside an agent-popup session
: > "$TMUX_LOG"
run_local_fn _toggle_agent_popup "agent-popup-agy-dotfiles" "$HOME/workspace/personal/dotfiles"
assert_eq "detach-client" "$(cat "$TMUX_LOG")" "pressing C-Space a inside popup must detach-client cleanly"

# 9. Keybindings in tmux/.tmux.conf.local: C-Space a and Escape
bind_a_line="$(grep -E '^bind(-key)?\s+a\s+' "$TMUX_LOCAL")"
assert_contains "$bind_a_line" "_toggle_agent_popup" "bind a must invoke _toggle_agent_popup"
bind_a_count="$(grep -cE '^bind(-key)?\s+a\s+' "$TMUX_LOCAL")"
assert_eq "1" "$bind_a_count" "bind a must be mapped exactly once in .tmux.conf.local"

bind_esc_line="$(grep -E '^bind(-key)?\s+(-n\s+)?Escape\s+' "$TMUX_LOCAL")"
assert_contains "$bind_esc_line" "agent-popup" "Escape binding must check for agent-popup session"
assert_contains "$bind_esc_line" "detach-client" "Escape binding must detach-client when in popup"

# 10. gpakosz/.tmux custom variable parser expands #{agent_status}
replacements="$(perl -n -e 'print if s!^#\s+([a-zA-Z][a-zA-Z0-9_]*)\s*\(\)\s*{\s*(?:#.*)?\n!s%#\\\{\\Q\1\\E((?:\\s+(?:[^\{\}]+?|#\\{(?:[^\{\}]+?)\}))*)\\\}%#(cut -c3- '"'""$TMUX_LOCAL""'"' | sh -s \1\\1)%g; !p' "$TMUX_LOCAL")"
expanded_status_right="$(printf '%s\n' "$status_right_line" | perl -p -e "$replacements")"
assert_contains "$expanded_status_right" "sh -s agent_status)" "gpakosz/.tmux parser must expand #{agent_status}"

echo "PASS"
