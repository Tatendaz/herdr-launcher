# Feature: Least-privilege GITHUB_TOKEN in the PR gate workflow

**Branch:** fix/workflow-token-permissions
**Date:** 2026-07-30

## Summary
Adds an explicit workflow-level `permissions: contents: read` block to
`.github/workflows/pr-gate.yml`, restricting the `GITHUB_TOKEN` handed to
every job to read-only repository access.

## Motivation
CodeQL's workflow scanning (enabled 2026-07-28 with the repo security
baseline) raised three `actions/missing-workflow-permissions` alerts — one
per job. Without an explicit block, each job receives the repository's
default token permissions, which can include write scopes the jobs never
need. All three jobs only check out and read the tree.

## What changed
- Workflow-level `permissions: contents: read` in `pr-gate.yml`, covering
  the `docs-gate`, `tests`, and `coverage-for-new-code` jobs.

## Notes
Resolves code scanning alerts #1, #2, #3. No job behavior changes; if a
future job needs to write (comment, label, push), it must declare its own
job-level `permissions:` block.
