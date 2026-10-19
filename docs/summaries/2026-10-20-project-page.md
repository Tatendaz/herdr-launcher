# Session: GitHub Pages project page

**Branch:** feat/project-page
**Date:** 2026-10-20

## Prompts

1. "Build GitHub Pages project pages for TWO public repos: Tatendaz/mission-control
   and Tatendaz/herdr-launcher, and turn Pages on for each." For this repo the
   brief added: "an unofficial macOS Dock launcher for the herdr TUI. Make clear
   it is unofficial and not affiliated with herdr. Small page is fine."

## Steps taken

- Read the claude-usage and yapui `docs/` pages and the live claude-usage page.
- Read this repo's README, `assets/README.md`, `src/Info.plist`,
  `herdr-plugin.toml`, `test.sh`, and the PR gate workflow.
- Wrote `docs/index.html`, `docs/index.md`, `docs/404.html`,
  `docs/.nojekyll`, and rendered `docs/social-preview.png` with headless
  Chrome.
- Checked the page in light and dark mode at desktop and 390 px widths.

## Decisions

- Left the herdr logo off the page because permission for it is recorded as
  requested, not granted.
- Put the "Unofficial" notice in the hero, not only in the footer.
- Reused claude-usage's tokens and structure so the project pages read as one
  family.
