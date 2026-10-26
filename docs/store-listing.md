# App Store listing — draft (#35)

Written 2026-09-20. **Not for submission yet**: publishing needs the paid
Developer Program (#37). Before submitting, re-verify category names, keyword
rules and screenshot dimensions against the current App Store Connect — those
change, and this draft may sit for a while.

Claim ceiling everywhere (research §1, FTC/FDA): **"Fun mental exercise / Ejercicio mental divertido"**.
No treatment or diagnosis, and no outcome claims: games exercise memory and attention.

## Metadata

| Field | Value |
|---|---|
| Name | Mente Viva |
| Subtitle | Fun mental exercise |
| Category | **Games → Puzzle** (not Medical/Health — keeps it out of medical scrutiny) |
| Age rating | 4+ |
| Price | one-time $12.99 (decided-for-beta, #21) |
| Languages | English (US) + Spanish (ES) |

## Keywords (EN, ≤100 chars)

`brain games,memory game,seniors,senior,mind,spanish,cognitive,puzzle,attention,reaction,bilingual`

## Audience of the listing

The **adult child** reads this page (Jev 009: buyer = caregiver; the player
never sees a pitch). Speak to them about someone they love. In-app copy speaks
to the player. Every line must pass statistics-rationale §4 (exercise, never
outcomes). Screenshots avoid Color Clash (lowest Jev scores,
008/010).

## Description — English

Simple, warm games for someone you love — at their own pace, with no pressure.

Fun mental exercise.

Mente Viva has five gentle games, each a different kind of thinking: memory, attention, words, numbers and quick looks. Big buttons, calm colors, and no countdown clock. When an answer isn't right, it says "try again" — never "wrong". Set it up once, pick the language, and they can play on their own.

• Five games, five kinds of play
• English and Spanish — switch anytime
• Works fully offline — no account, no ads, no tracking
• Big text and buttons, easy on the eyes
• Progress stays on the device

Mente Viva is entertainment and mental exercise. It is not a medical device and does not diagnose or treat any condition. If you have concerns about a loved one's memory, talk to their doctor.

## Description — Spanish

Juegos sencillos y amables para alguien a quien quieres — a su ritmo y sin presión.

Ejercicio mental divertido.

Mente Viva tiene cinco juegos suaves, cada uno para un tipo distinto de pensamiento: memoria, atención, palabras, números y miradas rápidas. Botones grandes, colores tranquilos y sin cuenta regresiva. Si una respuesta no es correcta, dice «inténtalo otra vez», nunca «mal». Lo configuras una vez, eliges el idioma y puede jugar solo.

• Cinco juegos, cinco formas de jugar
• Español e inglés — cambia cuando quieras
• Funciona sin conexión — sin cuenta, sin anuncios, sin rastreo
• Texto y botones grandes, fáciles de leer
• El progreso se queda en el dispositivo

Mente Viva es entretenimiento y ejercicio mental. No es un dispositivo médico y no diagnostica ni trata ninguna enfermedad. Si te preocupa la memoria de un ser querido, consulta a su médico.

## Screenshots (5 per locale, captured from a simulator)

| Screen | EN overlay | ES overlay |
|---|---|---|
| Home (grid of tiles) | Five games, five kinds of play | Cinco juegos, cinco formas de jugar |
| Memory Lane, mid-round | Find the pairs, gently | Encuentra las parejas, con calma |
| Name the Herd, mid-round | Name them all, at your pace | Nómbralos todos, a tu ritmo |
| Celebration screen | Small wins, celebrated warmly | Pequeños logros, celebrados con cariño |
| My Week | See the week at a glance | La semana de un vistazo |

Capture at the sizes App Store Connect currently requires (historically 6.7"
iPhone and 12.9" iPad). Localize the overlay text, not just the screenshot.

## Privacy label

App Privacy in Connect will show **Data Not Collected** — the app is local-first,
no account, no ads, no analytics. Today's picks are computed on the device and
shipped builds make no network request (#101). The optional Jev backend would send only
anonymized aggregates and is **off** by default; if it is ever turned on in a shipped build,
re-audit the label (the proxy sees the device IP).

## Todo before submission (fast, last-minute)

- [ ] Re-check category/keyword/screenshot rules against Connect
- [ ] Final ES pass by a native speaker (#12)
- [ ] Regenerate icon/screenshots at the current required sizes
- [ ] Confirm price tier and Family Sharing flag
- [ ] Paste, attach screenshots, submit — the thinking is already done here
