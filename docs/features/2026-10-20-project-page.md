# Feature: GitHub Pages project page

**Branch:** feat/project-page
**Date:** 2026-10-20

## Summary
Adds a static project page under `docs/`, served by GitHub Pages at
https://tatendaz.github.io/herdr-launcher/.

## Motivation
The repo's homepage pointed at the owner's site root and there was no page for
the launcher itself. The other project pages on tatendaz.github.io
(claude-usage, yapui) serve from `main:/docs`; this one matches their layout,
theme tokens, and light/dark toggle.

## What changed
- `docs/index.html`: the page. A one-line summary, an "Unofficial" notice
  near the top, who it is for, what a click does, the six terminals, the
  README install blocks verbatim, how it works, an honest status list, and a
  "Built by" footer. System light/dark default plus a toggle that shares the
  `cu-theme` preference key with the other project pages on the same host.
- `docs/index.md`: Markdown twin, linked with `rel="alternate"`.
- `docs/404.html`: not-found page for paths under `/herdr-launcher/`.
- `docs/social-preview.png`: 1280x640 Open Graph image.
- `docs/.nojekyll`: serve files as they are, so `index.md` is not turned into
  a second `index.html`.

## Notes
- The page does not show the herdr ram logo. `assets/README.md` says
  permission to use it was requested, not that it was granted, so the page
  uses a terminal block as its visual and a plain geometric favicon.
- Content comes only from the README, `assets/README.md`, `src/Info.plist`,
  `herdr-plugin.toml`, and `test.sh`.
- The status list states that the only GitHub release is v0.1.0 while
  `main` is at 1.2.1.
- No source or test files change, so the test-coverage gate has nothing to
  check.
