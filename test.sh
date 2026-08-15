#!/bin/bash
# Gate checks: shell syntax, plist validity, AppleScript compilation, a full
# build, launcher table consistency, and the applet's launcher interface.
# Needs only tools that ship with macOS; shellcheck runs when installed.
# CI runs this via `make test`.

set -euo pipefail
cd "$(dirname "$0")" || exit 1

bash -n src/launcher.sh
bash -n build.sh
bash -n test.sh
echo "ok: shell syntax"

plutil -lint src/Info.plist >/dev/null
echo "ok: Info.plist lints"

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck src/launcher.sh build.sh test.sh
  echo "ok: shellcheck"
else
  echo "skip: shellcheck not installed"
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# The applet source tells no application, so unlike the snippets below it
# compiles on any macOS, CI runners included.
osacompile -o "$tmp/main.scpt" src/main.applescript
echo "ok: applet source compiles"

# The applet is only glue around launcher.sh; if either applet-facing mode
# stops being called, residency or quitting silently breaks.
grep -q -- '--launch-and-wait' src/main.applescript
grep -q -- '--herdr-running' src/main.applescript
echo "ok: applet wired to both launcher modes"

# Compile each AppleScript heredoc embedded in launcher.sh. Compilation
# resolves the target app's scripting dictionary, so a snippet can only be
# compiled where its app is present: Terminal.app always is, iTerm2 is not
# on CI runners.
awk -v dir="$tmp" '
  /<<'\''EOS'\''$/ { in_script = 1; n++; next }
  /^EOS$/          { in_script = 0; next }
  in_script        { print > (dir "/snippet_" n ".applescript") }
' src/launcher.sh

count=$(find "$tmp" -name 'snippet_*.applescript' | wc -l | tr -d ' ')
if [ "$count" -ne 4 ]; then
  echo "fail: expected 4 embedded AppleScript snippets, found $count"
  exit 1
fi

for f in "$tmp"/snippet_*.applescript; do
  app=$(sed -n 's/.*tell application "\([^"]*\)".*/\1/p' "$f" | head -n 1)
  if [ -d "/Applications/$app.app" ] || [ -d "/System/Applications/Utilities/$app.app" ] || [ -d "$HOME/Applications/$app.app" ]; then
    osacompile -o "${f%.applescript}.scpt" "$f"
    echo "ok: AppleScript for $app compiles"
  else
    echo "skip: $app not installed here, snippet not compiled"
  fi
done

# --herdr-running must answer from pgrep alone: before the herdr lookup,
# with no config reads and no UI, so the applet's poll works even where
# herdr is not installed (CI included).
shim="$tmp/shim"
mkdir -p "$shim"
printf '#!/bin/sh\nexit 0\n' > "$shim/pgrep"
chmod +x "$shim/pgrep"
if ! PATH="$shim:$PATH" bash src/launcher.sh --herdr-running; then
  echo "fail: --herdr-running should succeed while pgrep finds herdr"
  exit 1
fi
printf '#!/bin/sh\nexit 1\n' > "$shim/pgrep"
if PATH="$shim:$PATH" bash src/launcher.sh --herdr-running; then
  echo "fail: --herdr-running should fail when pgrep finds nothing"
  exit 1
fi
echo "ok: --herdr-running reflects the herdr process state"

# A Dock click with herdr already running must focus, not launch: with a
# fake process table describing herdr alive in an iTerm2 window,
# --launch-and-wait has to exit 0 after an osascript call carrying the
# session's tty, before any terminal-launching code runs.
printf '#!/bin/sh\necho 42\n' > "$shim/pgrep"
cat > "$shim/ps" <<'SH'
#!/bin/sh
case "$2:$4" in
  "tty=:42")  echo "ttys003" ;;
  "comm=:42") echo "herdr" ;;
  "ppid=:42") echo "41" ;;
  "comm=:41") echo "-zsh" ;;
  "ppid=:41") echo "40" ;;
  "comm=:40") echo "/Applications/iTerm.app/Contents/MacOS/iTerm2" ;;
  *) exit 1 ;;
esac
SH
cat > "$shim/osascript" <<SH
#!/bin/sh
printf '%s\n' "\$@" > "$tmp/osascript.args"
cat >/dev/null
SH
chmod +x "$shim/pgrep" "$shim/ps" "$shim/osascript"
if ! PATH="$shim:$PATH" bash src/launcher.sh --launch-and-wait; then
  echo "fail: --launch-and-wait should focus and exit 0 while herdr runs"
  exit 1
fi
if ! grep -q "ttys003" "$tmp/osascript.args"; then
  echo "fail: the focus call should receive the herdr session's tty"
  exit 1
fi
rm -f "$shim/ps" "$shim/osascript"
echo "ok: --launch-and-wait focuses the running session"

# The build must produce a complete, valid applet bundle.
./build.sh >/dev/null
test -x dist/Herdr.app/Contents/MacOS/herdr-launcher
test -f dist/Herdr.app/Contents/Resources/Scripts/main.scpt
test -x dist/Herdr.app/Contents/Resources/launcher.sh
test -f dist/Herdr.app/Contents/Resources/Herdr.icns
test ! -e dist/Herdr.app/Contents/Resources/applet.icns
test ! -e dist/Herdr.app/Contents/Resources/Assets.car
plutil -lint dist/Herdr.app/Contents/Info.plist >/dev/null
if [ "$(plutil -extract OSAAppletStayOpen raw dist/Herdr.app/Contents/Info.plist)" != "true" ]; then
  echo "fail: OSAAppletStayOpen must be true, or the applet exits at once"
  exit 1
fi
# The Dock only draws its running indicator for regular apps, which is the
# point of the applet: LSUIElement has to stay out of the plist.
if plutil -extract LSUIElement raw dist/Herdr.app/Contents/Info.plist >/dev/null 2>&1; then
  echo "fail: LSUIElement is set; it would hide the Dock running indicator"
  exit 1
fi
codesign --verify --strict dist/Herdr.app
echo "ok: build.sh produces a complete, signed applet bundle"

# Launcher tables, exercised as functions: every supported terminal needs a
# display name, a config mapping that round-trips, and a launch branch.
# HERDR_LAUNCHER_LIB=1 makes launcher.sh stop after its definitions.
HERDR_LAUNCHER_LIB=1
export HERDR_LAUNCHER_LIB
# shellcheck source=src/launcher.sh
. src/launcher.sh
for value in iterm ghostty wezterm kitty alacritty terminal; do
  name="$(display_name "$value")"
  if [ -z "$name" ]; then
    echo "fail: no display name for $value"
    exit 1
  fi
  back="$(config_value "$name")"
  if [ "$back" != "$value" ]; then
    echo "fail: mapping for $value round-trips to '$back'"
    exit 1
  fi
  if ! grep -qE "^  ($value|\*)\)" src/launcher.sh; then
    echo "fail: no launch branch for $value"
    exit 1
  fi
done

# installed_terminals must emit only known values and always end with the
# Terminal.app fallback.
last=""
while IFS= read -r t; do
  case "$t" in
    iterm|ghostty|wezterm|kitty|alacritty|terminal) ;;
    *)
      echo "fail: installed_terminals emitted unknown value '$t'"
      exit 1
      ;;
  esac
  last="$t"
done < <(installed_terminals)
if [ "$last" != "terminal" ]; then
  echo "fail: installed_terminals does not end with the Terminal.app fallback"
  exit 1
fi
echo "ok: terminal tables consistent"

# wait_for_herdr backs the applet's --launch-and-wait grace period.
# Subshells keep the fake pgrep from leaking into anything else; the fakes
# are invoked through herdr_running, which shellcheck cannot see.
# shellcheck disable=SC2329
if (pgrep() { return 1; }; HERDR_LAUNCH_WAIT_SECS=1; wait_for_herdr); then
  echo "fail: wait_for_herdr should time out when herdr never appears"
  exit 1
fi
# shellcheck disable=SC2329
if ! (pgrep() { return 0; }; wait_for_herdr); then
  echo "fail: wait_for_herdr should return once herdr is running"
  exit 1
fi
echo "ok: wait_for_herdr waits, then gives up"

# terminal_of_pid and focus_herdr back the focus-instead-of-relaunch
# behavior; fake ps/pgrep/focus functions stand in for the live system.
# shellcheck disable=SC2329
if ! (
  ps() {
    case "$2:$4" in
      "comm=:42") echo "herdr" ;;
      "ppid=:42") echo "41" ;;
      "comm=:41") echo "/Applications/Ghostty.app/Contents/MacOS/ghostty" ;;
      *) return 1 ;;
    esac
  }
  [ "$(terminal_of_pid 42)" = "ghostty" ]
); then
  echo "fail: terminal_of_pid should name the terminal in the ancestry"
  exit 1
fi
# shellcheck disable=SC2329
if (
  ps() {
    case "$2:$4" in
      "comm=:42") echo "herdr" ;;
      "ppid=:42") echo "1" ;;
      *) return 1 ;;
    esac
  }
  terminal_of_pid 42
); then
  echo "fail: terminal_of_pid should fail with no terminal ancestor"
  exit 1
fi
# shellcheck disable=SC2329
if ! (
  pgrep() { echo 42; }
  ps() { echo "ttys009"; }
  terminal_of_pid() { echo "iterm"; }
  focus_iterm() { [ "$1" = "ttys009" ]; }
  focus_herdr
); then
  echo "fail: focus_herdr should focus iTerm2 with the session's tty"
  exit 1
fi
# shellcheck disable=SC2329
if ! (
  pgrep() { echo 42; }
  ps() { echo "ttys009"; }
  terminal_of_pid() { echo "ghostty"; }
  open() { [ "$1" = "-a" ] && [ "$2" = "Ghostty" ]; }
  focus_herdr
); then
  echo "fail: focus_herdr should activate unscriptable terminals via open -a"
  exit 1
fi
# shellcheck disable=SC2329
if (pgrep() { return 1; }; focus_herdr); then
  echo "fail: focus_herdr should fail with no herdr process"
  exit 1
fi
# shellcheck disable=SC2329
if (
  pgrep() { echo 42; }
  ps() { echo "??"; }
  focus_herdr
); then
  echo "fail: focus_herdr should fail when herdr has no controlling tty"
  exit 1
fi
echo "ok: focus helpers pick the right window mechanism"

echo "all checks passed"
