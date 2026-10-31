# Agent setup: one toolbox for every coding agent

AGENTS.md is the only rulebook. Each agent gets the thinnest pointer its tool needs, and
shared skills live in one folder. Nothing here holds a key or token.

## What the repo provides

| File | Who reads it | What it is |
|---|---|---|
| `AGENTS.md` | Claude Code (verified), and others (see table) | The rules: conventions, definition of done, workflow |
| `.clinerules` | Cline | Pointer: "Read AGENTS.md and follow it" |
| `.mcp.json` | Claude Code (verified), OMP (verified as fallback) | Project MCP servers. GitHub only, token from `GITHUB_TOKEN` |
| `.agents/skills/` | Muse Code, Codex, OMP (see table) | The one shared skills folder. Holds `menteviva-checks` |
| `.claude/skills` | Claude Code (verified) | Symlink to `../.agents/skills`, so Claude sees the same skills |

No `CLAUDE.md` is needed: Claude Code reads `AGENTS.md` by default when there is no `CLAUDE.md`.

## Agent by agent

"Verified" means read from the agent's official doc or source in this session. "Search only"
means a third-party or search summary that the official page could not confirm. "Not verified"
means nothing could be confirmed.

| Agent | Rules: where it reads | Project MCP | Skills | Status |
|---|---|---|---|---|
| Claude Code | `AGENTS.md` natively when no `CLAUDE.md` exists (code.claude.com/docs/en/memory) | `.mcp.json` at repo root (code.claude.com/docs/en/mcp) | `.claude/skills/<name>/SKILL.md` (code.claude.com/docs/en/skills), symlinked to `.agents/skills` | Verified |
| OMP (oh-my-pi) | `AGENTS.md` (README: reads Codex AGENTS.md and Cline `.clinerules`) | `.mcp.json` root fallback, read after `.omp/mcp.json` (docs/mcp-config.md in can1357/oh-my-pi) | Not verified for project path; user skills read from `~/.agents/skills` (search only) | MCP verified; skills not |
| Codex (OpenAI) | `AGENTS.md` (standard; `project_doc_fallback_filenames` in codex-rs config schema) | User `~/.codex/config.toml` with `[mcp_servers.<name>]`: key verified in schema; project `.codex/config.toml` search only | `.agents/skills` (search only) | Partly verified |
| Cline | `.clinerules` (search only; docs.cline.bot not reachable) | Not verified. Owner adds in Cline's MCP settings UI | Not verified | Search only |
| Devin (Cognition) | `AGENTS.md` (search only) | `.devin/config.json` (search only) | `.devin` skills (search only) | Not verified; docs.devin.ai not reachable |
| Muse Code (Meta) | `AGENTS.md` (search only); falls back to `CLAUDE.md` | User `~/.config/muse/settings.json` `mcp_servers` (search only; sources disagree that MCP works in the public beta) | `.agents/skills/<id>/SKILL.md` (search only) | Not verified |

Where a row says "search only", treat it as a hypothesis until the owner confirms it on the
machine.

## Owner: once per machine

Do the steps for the agents you use. Nothing here is committed.

1. **Clone and hooks.** `git config core.hooksPath .githooks` (enables pre-commit and pre-push).
2. **GitHub token for MCP.** Create a token with repo scope for `igmarin/menteviva`. Export it in the
   shell the agent starts from, never in a committed file:
   `export GITHUB_TOKEN=<token>`. Claude Code and OMP expand `${GITHUB_TOKEN}` from `.mcp.json`.
   Without it, the GitHub server fails to connect and the agent reports a warning.
3. **Claude Code.** Open the repo and approve the project server when prompted
   (`claude mcp reset-project-choices` resets the choice). Nothing else.
4. **OMP.** Start `omp` in the repo; it loads `.mcp.json` and `.agents/skills` if it reads them (check).
5. **Codex.** Add the GitHub server to `~/.codex/config.toml` under `[mcp_servers.github]`
   (the `codex mcp add` command writes this for you; check its help first).
6. **Cline.** Open the MCP Servers panel, add a GitHub server with the token from step 2, and
   confirm `.clinerules` is active in the project's rules list.
7. **Devin.** Not verified. Read its CLI extensibility doc, then decide whether a `.devin/` config is needed.
8. **Muse Code.** Not verified. Run `muse init` in the repo if its docs say so, then add the GitHub
   server to `~/.config/muse/settings.json`. The file needs `"schema_version": 1` at the top, or every
   command fails at startup. Merge into the file; do not replace it.

Owner-only tooling the repo cannot provide (keep it on your machine, not in the repo): the skills
named in AGENTS.md (ponytail, task-complexity-classifier, codegraph, graphify, xerj) and the
`ocr` review tool used by the pre-commit hook.

## How to check it worked

Ask the agent, in the repo:

- "List the MCP tools you can call. Is there one for GitHub?" Expect a GitHub tool list.
- "What does AGENTS.md say about the definition of done? Quote the first rule." Expect the rule.
- "List the skills you can use. Is `menteviva-checks` among them?" Expect it, or the agent says
  where it looked.

If an agent answers from memory and names nothing from AGENTS.md, it did not load the rules.

## Local setup notes

- `.mcp.json` needs `GITHUB_TOKEN` in your environment. Set it, or ignore `.mcp.json`.
- Run graphify from the repo root only, so `graphify-out/` does not appear inside `MenteViva/`.

## Open decisions for the owner

- Whether Devin and Muse Code get a project config file, or stay user-level. Blocked until their
  official docs are checked from a machine that can reach them.
- Whether `.clinerules` should also carry the GitHub MCP keyword triggers Cline's docs describe.
- Whether to add `${GITHUB_TOKEN}` to the environment for cloud sessions (the token then sits in
  the environment settings, not the repo).
