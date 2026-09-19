# Product Brief — Mente Viva

## Who
Primary: dad, older adult, preventive/mild cognitive stage, motivated, ES/EN bilingual.
Secondary: family circle — wants visibility into his play + a way to cheer him on.

## Design pillars
1. **Easy above all** — one-tap start, huge touch targets (≥100pt), no timers pressuring him, no fail shame. Words: "try again", never "wrong".
2. **Bilingual from birth** — every string in `Localizable.xcstrings`, EN + ES. Emoji-first UI minimizes text dependence.
3. **Evidence-informed games** — one game per cognitive domain:
   | Game | Domain | Mechanic |
   |---|---|---|
   | 🧠 Memory Lane | Working memory | Emoji pair matching |
   | 🎨 Color Clash | Attention / inhibition | Stroop: tap the ink color |
   | 🐾 Name the Herd | Verbal fluency | "Name 7 animals" (category recall) |
   | 🔢 Number Trail | Processing + numeracy | Simple adaptive math streaks |
4. **Visually warm** — big cards, soft colors, celebration on completion.

## Where Jev fits (decided: seasoning, not the meal)
- Games are deterministic and fully offline. Code judges right/wrong, never the model.
- Jev (online only): (a) picks today's game mix from recent play history, (b) nudges difficulty up/down.
- API key stays server-side / never ships in the app binary in production. For private family beta, a local key file excluded from git is acceptable.
- Fallback: offline heuristic (rotate games, 3-strikes difficulty rule) when Jev is unreachable. **The app must never degrade without network.**

## Non-goals for v1
- No accounts, no leaderboards, no clinical scores, no medical claims.
- No caregiver remote management (revisit post-launch).

## Sharing
CloudKit `CKShare` on the progress record → family members get a read-only view + can send pre-set cheers. Zero backend.
