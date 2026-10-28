# Decisions

Every significant decision, with who made it, when and why. One file per month,
newest first inside each file. A reference like "decisions.md 2026-10-26" means
the entry with that date in the month file below.

| Month | Entries |
|---|---|
| [2026-10](decisions/2026-10.md) | Direction to v1.0, several agents, privacy stance, retro art, legacy migration… |
| [2026-09](decisions/2026-09.md) | Audience, the first four games, Jev, the decision-model spike… |
| [Open questions](decisions/open-questions.md) | Not decided yet |

## Adding a decision

Put it at the top of the current month's file; start a new file
(`decisions/YYYY-MM.md`) on the first decision of a month and add its row
above. Don't edit old entries: a reversal is a new entry that links the old
one. Use this shape for new entries (older ones keep theirs):

```markdown
## YYYY-MM-DD — <the decision, as a sentence> (#issue)

**Decision (<who>):** what was decided, and the context that forced it.

**Why:** the reasons, each one with its source or evidence link.

**Revisit when:** the event that would reopen it.
```
