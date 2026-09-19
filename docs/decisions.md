# Decisions

Newest first. Format: date — decision — why — what would make us revisit.

## 2026-09-19 — Primary audience: healthy-to-mild older adults, preventive focus

Decided with the grill interview: dad is "mostly fine, we want to slow decline
and keep him sharp." We are **not** building for diagnosed cognitive impairment
in v1 — that raises the design bar (simplification, caregiver supervision) and
the regulatory bar (closer to medical claims) at the same time.

Revisit when: real users with MCI/early dementia show up, or a clinician
partner wants in.

## 2026-09-19 — Four games, one per cognitive domain

Memory (pair matching), attention/inhibition (Stroop), verbal fluency
(category recall), numeracy/processing (adaptive math). Small and polished
beats broad and shallow. Evidence basis: see research-2026-09.md §2.

Revisit when: playtest data shows one game dominates or gets abandoned.

## 2026-09-19 — Offline-first; Jev is seasoning

Games are 100% deterministic and playable without network. Jev ranks the
daily mix and nudges difficulty, once per day, with silent fallback to
deterministic rotation. Full design: jev-integration.md.

Revisit when: we have enough play data to evaluate whether Jev's rankings
beat the rotation.

## 2026-09-19 — Family visibility via CloudKit share, zero backend

Family circle sees progress and can send preset cheers. CloudKit `CKShare`
means no server to build or breach. Jev's API key still needs a tiny proxy
(jev-integration.md §proxy) — that's a config item, not a backend.

Revisit when: we outgrow per-record sharing or need cross-platform family
members (Android in the family → real backend).

## 2026-09-19 — Stack: SwiftUI + SwiftData, zero third-party dependencies

Native everything. No packages. Convention 1 in conventions.md.

Revisit when: a concrete need fails twice against stdlib/native.

## 2026-09-19 — Decision revisit with Jev (jev-revisit.md)

All five early decisions re-asked as real Jev judgments against an
evidence/constraints state; raw JSON archived in docs/jev-json/000–005.
Result: audience, monetization lean, and offline-first/once-daily architecture
confirmed (0.72–0.95). Two tensions became tickets: #18 (playtest-before-content
gate — Jev 005 at P=0.99 said polish-first; Quick Eyes had already shipped, so
the gate applies from game #6 onward) and #17 (numeracy scored 0.62, weakest
domain — Number Trail must justify itself via playtest).

Rule adopted: significant product decisions get a Jev judgment archived in
docs/jev-json/ before being logged here. Jev is evidence, not truth — the
human decides, and disagreements get recorded, not silently resolved.

## 2026-09-19 — Confirmed by owner (via discussion + Jev evidence)

- **Pricing:** one-time $12.99 + Family Sharing is *decided for beta* (#21);
  freemium-annual (Jev minority 0.28) revisited only with beta conversion data.
- **Audience:** v1 stays healthy preventive 60+ (Jev 001, P=0.95). Segment
  expansion becomes a Jev research study in v0.4.0 — not v1 scope.
- **Testing:** TDD for logic, BDD (Given/When/Then) for user flows, backfill
  for shipped code (#20). No tests for layout trivia or wire models.
- **MVP:** gates G0–G4 in docs/mvp.md adopted as the definition of done (#19).

## Open questions (not yet decided)

- Business model: research leans **one-time $12.99 + Family Sharing**
  (research-2026-09.md §4) — confirm after family beta.
- Age-rating and medical-disclaimer wording for App Store submission
  (research-2026-09.md §5 items 1–3).
- Whether "Name the Herd" needs voice input (motor-friendly) — needs playtest.
- Processing-speed game is the strongest-evidence domain we don't cover yet
  (research-2026-09.md §2) — candidate for the fifth game. Must be a generic
  speed task, NOT a UFOV® clone (licensed, §3).

