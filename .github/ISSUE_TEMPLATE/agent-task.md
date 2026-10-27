---
name: Agent task
about: A self-contained brief any agent (Muse Code, Cline, Claude) can pick up cold
labels: ready
---

## Goal

<!-- One or two sentences: what the player or the codebase gains. -->

## Context

<!-- Files to read first, related issues and decisions. -->

## Spec

<!-- Exactly what to build. Numbers, copy keys, level tables. -->

## Acceptance (Given/When/Then)

- Given …, when …, then …

## Tests to write first

- `test…`

## Out of scope

-

## Depends on

- none

## How to work it (AGENTS.md "Several agents at once")

- Own worktree and branch: `git worktree add ../mv-<issue> -b agent/<issue>-<slug> origin/main`.
- A "(2/2)" ticket stacks on its "(1/2)" branch with `gh stack`; its PR targets that branch.
- Tests first; lint and tests green locally (pre-push hook, your own simulator) before every push.

## Done when

AGENTS.md "Definition of done" holds, and the PR says `Closes #<this issue>`.
