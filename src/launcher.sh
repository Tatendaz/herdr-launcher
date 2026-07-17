#!/bin/bash
# Herdr.app — opens the herdr TUI in the user's terminal. macOS only.
#
# Terminal selection, in order:
#   1. ~/.config/herdr-launcher/terminal (one word: iterm | ghostty | wezterm |
#      kitty | alacritty | terminal), when it names an installed terminal.
#      Stale or unrecognized values are ignored.
#   2. Otherwise: a picker dialog listing the installed terminals; the choice
#      is saved to the file above.
#   3. Picker cancelled or unavailable: first installed of iTerm2, Ghostty,
#      WezTerm, kitty, Alacritty, then Terminal.app.

set -u

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/herdr-launcher/terminal"

find_herdr() {
  local p
  for p in /opt/homebrew/bin/herdr /usr/local/bin/herdr "$HOME/.local/bin/herdr" "$HOME/.cargo/bin/herdr"; do
    if [ -x "$p" ]; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  command -v herdr 2>/dev/null
}

app_installed() {
  local name="$1" dir
  for dir in "/Applications" "$HOME/Applications" "/Applications/Utilities" "/System/Applications/Utilities"; do
    if [ -d "$dir/$name.app" ]; then
      return 0
    fi
  done
  return 1
}

# Config values in auto-detect priority order. Terminal.app ships with macOS,
# so the list is never empty.
installed_terminals() {
  app_installed "iTerm"     && echo "iterm"
  app_installed "Ghostty"   && echo "ghostty"
  app_installed "WezTerm"   && echo "wezterm"
  app_installed "kitty"     && echo "kitty"
  app_installed "Alacritty" && echo "alacritty"
  echo "terminal"
}

display_name() {
  case "$1" in
    iterm)     echo "iTerm2" ;;
    ghostty)   echo "Ghostty" ;;
    wezterm)   echo "WezTerm" ;;
    kitty)     echo "kitty" ;;
    alacritty) echo "Alacritty" ;;
    terminal)  echo "Terminal" ;;
  esac
}

config_value() {
  case "$1" in
    iTerm2)    echo "iterm" ;;
    Ghostty)   echo "ghostty" ;;
    WezTerm)   echo "wezterm" ;;
    kitty)     echo "kitty" ;;
    Alacritty) echo "alacritty" ;;
    Terminal)  echo "terminal" ;;
  esac
}

show_alert() {
  osascript -e 'on run argv' \
            -e 'display alert (item 1 of argv) message (item 2 of argv) as critical' \
            -e 'end run' -- "$1" "$2" >/dev/null 2>&1
}

launch_failed() {
  show_alert "Herdr could not open $1" "$2

If this mentions Apple events or permissions, allow Herdr to control your terminal under System Settings > Privacy & Security > Automation."
  exit 1
}

# Shows a picker of installed terminals; prints the chosen config value.
# Returns 1 if the user cancels.
choose_terminal() {
  local names=() v list choice
  for v in "$@"; do
    names+=("$(display_name "$v")")
  done
  list=$(printf '"%s", ' "${names[@]}")
  list="{${list%, }}"
  choice=$(osascript -e "choose from list $list with title \"Herdr\" with prompt \"Open herdr in which terminal? Your choice is saved; the README explains how to change it later.\" default items {\"${names[0]}\"}" 2>/dev/null)
  if [ -z "$choice" ] || [ "$choice" = "false" ]; then
    return 1
  fi
  config_value "$choice"
}

# A new iTerm2 window running the login shell; the resolved herdr path is
# typed into it (in shell quoting), so rc files load and the binary the
# launcher verified is the one that runs.
run_iterm() {
  osascript - "$1" <<'EOS'
on run argv
  set herdrCmd to quoted form of (item 1 of argv)
  tell application "iTerm"
    activate
    set newWindow to (create window with default profile)
    tell current session of newWindow
      write text herdrCmd
    end tell
  end tell
end run
EOS
}

# Terminal.app. When it is not running, the tell block launches it and that
# launch creates window 1; reuse it instead of opening a second window.
run_terminal_app() {
  osascript - "$1" <<'EOS'
on run argv
  set herdrCmd to quoted form of (item 1 of argv)
  tell application "Terminal"
    if it is running then
      do script herdrCmd
    else
      do script herdrCmd in window 1
    end if
    activate
  end tell
end run
EOS
}

# When sourced for tests, stop here: definitions only, no side effects.
# The exit runs only when the script is executed, where return is invalid.
# shellcheck disable=SC2317
if [ "${HERDR_LAUNCHER_LIB:-0}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

HERDR_BIN="$(find_herdr || true)"
if [ -z "$HERDR_BIN" ]; then
  show_alert "herdr is not installed" "Install it first:

brew install herdr"
  exit 1
fi

installed=()
while IFS= read -r t; do
  installed+=("$t")
done < <(installed_terminals)

is_installed_value() {
  local t
  for t in "${installed[@]}"; do
    if [ "$t" = "$1" ]; then
      return 0
    fi
  done
  return 1
}

TERMINAL=""
if [ -f "$CONFIG_FILE" ]; then
  TERMINAL="$(head -n 1 "$CONFIG_FILE" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
  # A saved value that no longer names an installed terminal would make the
  # launch below fail, so ignore it and let the picker run again.
  if [ -n "$TERMINAL" ] && ! is_installed_value "$TERMINAL"; then
    TERMINAL=""
  fi
fi

if [ -z "$TERMINAL" ]; then
  if [ "${#installed[@]}" -gt 1 ] && TERMINAL="$(choose_terminal "${installed[@]}")" && [ -n "$TERMINAL" ]; then
    mkdir -p "$(dirname "$CONFIG_FILE")"
    printf '%s\n' "$TERMINAL" > "$CONFIG_FILE"
  else
    TERMINAL="${installed[0]}"
  fi
fi

case "$TERMINAL" in
  iterm)
    if ! err=$(run_iterm "$HERDR_BIN" 2>&1 >/dev/null); then
      launch_failed "iTerm2" "$err"
    fi
    ;;
  ghostty)
    if ! err=$(open -na Ghostty --args -e "$HERDR_BIN" 2>&1); then
      launch_failed "Ghostty" "$err"
    fi
    ;;
  wezterm)
    if ! err=$(open -na WezTerm --args start -- "$HERDR_BIN" 2>&1); then
      launch_failed "WezTerm" "$err"
    fi
    ;;
  kitty)
    if ! err=$(open -na kitty --args "$HERDR_BIN" 2>&1); then
      launch_failed "kitty" "$err"
    fi
    ;;
  alacritty)
    if ! err=$(open -na Alacritty --args -e "$HERDR_BIN" 2>&1); then
      launch_failed "Alacritty" "$err"
    fi
    ;;
  *)
    if ! err=$(run_terminal_app "$HERDR_BIN" 2>&1 >/dev/null); then
      launch_failed "Terminal" "$err"
    fi
    ;;
esac
