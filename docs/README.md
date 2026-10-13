# Docs — Mente Viva

Read in this order. Each doc is short on purpose. If a doc grows past one
screen of real content, split it — long docs don't get read.

| Doc | Question it answers | Status |
|---|---|---|
| [product-brief.md](product-brief.md) | What are we building, for whom, and why | Current |
| [conventions.md](conventions.md) | Rules every commit must follow | Current |
| [jev-integration.md](jev-integration.md) | The on-device daily policy, and how optional Jev/TypeSafe fits | Policy is the default; Jev optional, verified live (2026-09-30) |
| [decision-model-spike-2026-09-30.md](decision-model-spike-2026-09-30.md) | Nimble and Laya tested as Jev replacements, with numbers | Snapshot |
| [jev-revisit.md](jev-revisit.md) | Jev judgments 001–010: early decisions, corrected audience, games, segments, utility matrix | Living, to 2026-09-22 |
| [jev-json/](jev-json/) | Raw Jev request/response archive (audit trail); 011 is the app's real daily request | Growing |
| [mvp.md](mvp.md) | MVP definition of done + phase gates | Living |
| [playtest.md](playtest.md) | How to run a playtest and record it (#6, #33) | Living |
| [profiling.md](profiling.md) | Signposts + Instruments: how to time the hot paths | Living |
| [playtest-session-1.md](playtest-session-1.md) | Printable session sheet for dad's playtest (#6) — findings map to #44/#46/#47 | Current |
| [install-runbook.md](install-runbook.md) | Installing on a device with a free Apple ID (7-day expiry) | Current |
| [device-support.md](device-support.md) | What hardware/OS we claim and what we verified | Living |
| [decisions.md](decisions.md) | Every significant decision, with date and reason | Living log |
| [design/](design/) | Card Table redesign: review of the current app and the round 2 spec (HTML, open in a browser) | Draft, 2026-10-12 |
| [research-2026-09.md](research-2026-09.md) | Evidence + market scan behind the decisions | Snapshot |
| [research-2026-09-22.md](research-2026-09-22.md) | Market and segment numbers (60+, caregivers, iOS floor) | Snapshot |
| [statistics-rationale.md](statistics-rationale.md) | What our numbers support, and what copy may say | Current |
| [jev-sounds.md](jev-sounds.md) | Sound and haptics design choices | Current |
| [a11y-audit-2026-09.md](a11y-audit-2026-09.md) | Accessibility audit vs conventions §4, with addendum | Snapshot + addendum |
| [es-review-packet.md](es-review-packet.md) | Spanish strings for the native-speaker review (#12) | Current |
| [question-audit.md](question-audit.md) | The real questions, checked (against wrong questions) | Living |
| [roadmap.md](roadmap.md) | What happens next, in order | Living |
| [store-listing.md](store-listing.md) | App Store copy + screenshots (EN/ES), drafted early | Draft |
| [privacy-policy.md](privacy-policy.md) | Privacy policy draft — local-first, what leaves the device (#34) | Draft — needs hosting + contact |
| [support.md](support.md) | Support page draft — 7-day expiry, language, progress (#34) | Draft — needs hosting + contact |

## Writing rules for these docs

1. One idea per sentence. No filler ("It's important to note that…").
2. Every claim that isn't our own decision gets a source URL.
3. Decisions say **who decided, when, and why** — so future-us can reverse them.
4. No boilerplate sections. A section with nothing to say gets deleted.
5. Spanish summaries land when the product copy stabilizes — YAGNI for now.
