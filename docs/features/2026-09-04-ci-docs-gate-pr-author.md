# Feature: Docs gate binds to the PR author, not the run actor

**Branch:** ci/docs-gate-pr-author
**Date:** 2026-09-04

## Summary
The `docs-gate` job in `.github/workflows/pr-gate.yml` now stands down when the
pull request *author* is `dependabot[bot]` (`github.event.pull_request.user.login`),
instead of when the run *actor* is (`github.actor`). Dependabot bumps keep
skipping the docs requirement no matter who last touched the branch.

## Motivation
`github.actor` is whoever triggered the current run. Pressing "Update branch" on
a Dependabot PR starts a new `pull_request: synchronize` run whose actor is the
human who clicked, the skip stops firing, and the gate demands a
`docs/features/<date>-<slug>.md` entry a bump PR will never have. (A plain
re-run keeps the original actor; the person re-running only shows up as
`github.triggering_actor`.) This failure mode was seen live on
langchain-fde-curriculum #9 (cryptography 49 → 50), where the red docs gate
blocked the merge until Dependabot recreated the branch. The PR author is fixed
for the life of the PR, so it is the right handle — and it is the check GitHub's
Dependabot automation guidance recommends.

## What changed
- `.github/workflows/pr-gate.yml`: the `docs-gate` condition is now
  `github.event.pull_request.user.login != 'dependabot[bot]'`, with a comment
  explaining why the author, not the actor, is the right handle.
- Nothing else. The tests job, the coverage job, and the check names are
  untouched.

## Notes
- Rolled out from langchain-fde-curriculum #11, where the identical diff was
  reviewed clean.
- Human and agent PRs are unaffected — their author is never `dependabot[bot]`,
  so the docs gate still runs and still requires the features entry.
