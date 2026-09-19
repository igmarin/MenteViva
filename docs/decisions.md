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

## Open questions (not yet decided)

- Business model: research leans **one-time $12.99 + Family Sharing**
  (research-2026-09.md §4) — confirm after family beta.
- Age-rating and medical-disclaimer wording for App Store submission
  (research-2026-09.md §5 items 1–3).
- Whether "Name the Herd" needs voice input (motor-friendly) — needs playtest.
- Processing-speed game is the strongest-evidence domain we don't cover yet
  (research-2026-09.md §2) — candidate for the fifth game. Must be a generic
  speed task, NOT a UFOV® clone (licensed, §3).

