# Feature: Dock launcher app for herdr

**Branch:** main (initial commit)
**Date:** 2026-07-18

## Summary
Herdr.app, a macOS Dock launcher that opens the herdr TUI in the user's terminal. A shell script wrapped in an `.app` bundle with the herdr ram as its icon.

## Motivation
herdr installs as a Homebrew formula, so there is no app bundle to pin to the Dock. This gives it one: click the ram, get herdr in a new terminal window, in whichever terminal the user prefers.

## What changed
- `src/launcher.sh`: finds the herdr binary, picks a terminal, opens herdr in it. Selection order: saved config (`~/.config/herdr-launcher/terminal`, ignored when stale) > first-run picker dialog (choice saved) > auto-detect (iTerm2, Ghostty, WezTerm, kitty, Alacritty, then Terminal.app). iTerm2 and Terminal.app are driven over AppleScript, typing the resolved herdr path into the login shell; the rest are launched via `open -na <App> --args` with the same path. Launch failures surface in an alert.
- `src/Info.plist`: bundle metadata; `LSUIElement` keeps the running script out of the Dock, `NSAppleEventsUsageDescription` covers the Automation prompt.
- `build.sh` + `Makefile`: assemble `dist/Herdr.app` with stock macOS tools (sips, iconutil, codesign ad-hoc); `--install` copies to `/Applications`.
- `assets/`: ram icon rebuilt from herdr.dev's SVG in the site header's colors, exported at 1024 px.
- `test.sh`: shell syntax, shellcheck when present, plist lint, compilation of the embedded AppleScript snippets, a full build, and launcher-table consistency.
- `README.md`: install and configuration docs, plus an explicit statement that this is not the official herdr launcher.

## Notes
- macOS only (12+). The launch mechanisms have no equivalent elsewhere.
- The ram logo belongs to the upstream herdr project; permission request to hey@herdr.dev drafted 2026-07-18. If declined, `assets/` gets a replacement icon.
- CI test job runs on `macos-latest`; the build tooling does not exist on Linux runners.
