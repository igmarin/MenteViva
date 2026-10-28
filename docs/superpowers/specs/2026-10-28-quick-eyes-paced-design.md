# Quick Eyes, player-paced (#46)

Decision: [../../decisions/2026-10.md](../../decisions/2026-10.md), 2026-10-28.

## Behaviour

| Level | Reveal | Choices |
|---|---|---|
| 1–2 | Picture stays until "Got it" | 2 |
| 3–5 | Picture stays until "Got it" | 3, then 4 at level 5 |
| 6–10 | Quick mode: today's flash (`displayTimeTable`) | 4 |

1. **Reveal (levels 1–5):** the picture shows with one "Got it" button, at least 100pt tall (AGENTS.md
   floor for game controls). Tapping it hides the picture and shows the choices.
2. **Miss:** the picture comes back above the choices, the wrong tapped option fades, and the player
   picks again. The round is never replaced and no copy says wrong; use "Almost — look again". Only a
   first-try right answer counts as correct.
3. **Right:** the existing answer beat (#235), then the next round.
4. **Quick mode (levels 6–10):** unchanged flash and shrink curve.
5. **Quiet speed measure:** the look time per round (reveal to "Got it") is kept in the session. Saving
   it for the caregiver screen needs a `GameSession` change and is a follow-up; it never shows to the
   player (#45).
6. **Faster-round invite:** after three first-try right rounds in a row, each looked at for under 1.0s,
   offer once per game "Want a faster one?". Yes flashes the picture for the rest of that game, at the
   level's own flash times; no changes nothing. The stored level is never changed by the invite.

## Touches

`QuickEyesView.swift`, `QuickEyesDeal.swift` (options per round by level), `Difficulty` values,
`Localizable.xcstrings` (EN and ES: "Got it", "Almost — look again", the invite), `docs/how-it-works.md`.

## Checks

- Unit: options per level, a miss keeps the same target, look time is recorded.
- Level 5 → 6 boundary: the mode switches, nothing else changes.
- VoiceOver: the picture's name is read on reveal and again after a miss; "Got it" is labelled.
- Dynamic Type at the largest size on an iPhone and an iPad simulator.
- Claims: `./tools/check_claims.sh` passes; no copy says the paced version trains speed.
