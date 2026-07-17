#!/bin/bash
# Gate checks: shell syntax, plist validity, AppleScript compilation, a full
# build, and launcher table consistency. Needs only tools that ship with
# macOS; shellcheck runs when installed. CI runs this via `make test`.

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

# Compile each AppleScript heredoc embedded in launcher.sh. Compilation
# resolves the target app's scripting dictionary, so a snippet can only be
# compiled where its app is present: Terminal.app always is, iTerm2 is not
# on CI runners.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

awk -v dir="$tmp" '
  /<<'\''EOS'\''$/ { in_script = 1; n++; next }
  /^EOS$/          { in_script = 0; next }
  in_script        { print > (dir "/snippet_" n ".applescript") }
' src/launcher.sh

count=$(find "$tmp" -name 'snippet_*.applescript' | wc -l | tr -d ' ')
if [ "$count" -ne 2 ]; then
  echo "fail: expected 2 embedded AppleScript snippets, found $count"
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

# The build must produce a complete, valid bundle.
./build.sh >/dev/null
test -x dist/Herdr.app/Contents/MacOS/herdr-launcher
test -f dist/Herdr.app/Contents/Resources/Herdr.icns
plutil -lint dist/Herdr.app/Contents/Info.plist >/dev/null
codesign --verify --strict dist/Herdr.app
echo "ok: build.sh produces a complete, signed bundle"

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

echo "all checks passed"
