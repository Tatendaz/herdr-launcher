# Session: Docs gate on PR author

**Branch:** ci/docs-gate-pr-author
**Date:** 2026-09-04

## Prompts

1. "can you review and merge this
   https://github.com/Tatendaz/langchain-fde-curriculum/pull/9"
2. "change it pr author and just merge it"
3. "same fix on the other repos too if they dont already have it use subagetns
   for each repo"

## Steps taken

- Branched `ci/docs-gate-pr-author` from `origin/main`.
- Swapped the `docs-gate` condition in `.github/workflows/pr-gate.yml` from
  `github.actor != 'dependabot[bot]'` to
  `github.event.pull_request.user.login != 'dependabot[bot]'`, keeping the
  existing comment and adding one explaining the actor-vs-author trap.
- Wrote this repo's docs entries (this repo's gate greps
  `docs/features/*<slug>.md` and does not strip the `ci/` prefix, so the slug
  is `ci-docs-gate-pr-author`).
- Opened the PR with the standard Summary / Motivation / What changed /
  Verification body.

## Decisions

- **Author, not actor.** The PR author is fixed for the life of the PR; the
  actor changes with every "Update branch" click or manual push (a re-run
  keeps the original actor and only sets `github.triggering_actor`).
- **No per-repo CodeRabbit review.** The identical diff was reviewed clean
  centrally on langchain-fde-curriculum #11, following the
  dependabot-auto-merge rollout precedent; the shared review budget stays
  untouched.
