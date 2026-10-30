# App Store listing (#232)

Everything App Store Connect asks for, EN and ES, ready to paste. Updated 2026-10-30 for v1.0:
14 games, free, local-only. First draft: #35 (2026-09-20).

**Before pasting**, re-check three things in the current App Store Connect, because they change: the
screenshot sizes, the category list and the age-rating questions. And if Sliding Blocks (#222, #223)
doesn't ship in v1.0, change "14" to "13" everywhere below and drop it from the lists.

Claim ceiling everywhere (research §1, FTC/FDA): **"Fun mental exercise / Ejercicio mental
divertido"**. A game *exercises* memory or attention, and the copy promises no outcome
(decisions.md 2026-10-26). No treatment, no diagnosis, no outcomes. `tools/check_claims.sh` reads this
file on every PR.

## Who reads the page

Anyone who wants to keep their mind active, and the family member who installs it for someone they
love (decisions.md 2026-10-26: the audience is anyone, with no age asked). Speak plainly and warmly
to both; the player never sees a sales pitch inside the app.

## Metadata

| Field | EN | ES |
|---|---|---|
| Name | MenteViva | MenteViva |
| Subtitle (≤ 30) | Fun mental exercise | Ejercicio mental divertido |
| Primary category | Games › Puzzle | |
| Secondary category | Games › Family | |
| Price | Free, no in-app purchase (decisions.md 2026-10-27, #228) | |
| Age rating | 4+ (answers below) | |
| Languages | English (US), Spanish (Mexico and Spain) | |
| Copyright | 2026 Ismael Marin Cabrera | |
| Support URL | `https://menteviva-e4s.pages.dev/en/support` | `https://menteviva-e4s.pages.dev/es/support` |
| Privacy policy URL | `https://menteviva-e4s.pages.dev/en/privacy` | `https://menteviva-e4s.pages.dev/es/privacy` |
| Marketing URL (optional) | https://github.com/igmarin/menteviva | |

**Why Games › Puzzle:** every game is a puzzle or a card game, and a game category keeps the app out
of the medical review that Health & Fitness or Medical invite (App Store 1.4.1). Education was set
aside: it suggests learning outcomes, and it sits next to children's apps. **Family** as the second
category matches how the app is often installed: by someone in the family, for someone they love.

## Promotional text (≤ 170, can change without review)

- **EN:** Fourteen calm games for memory, attention, words, numbers and shapes. Free, offline, no
  account and no ads, in English and Spanish.
- **ES:** Catorce juegos tranquilos de memoria, atención, palabras, números y formas. Gratis, sin
  conexión, sin cuenta y sin anuncios, en español e inglés.

## Keywords (≤ 100, comma-separated, no spaces, no app name)

- **EN (93):** `memory,brain games,puzzle,sudoku,tangram,seniors,mind,attention,words,numbers,spanish,offline`
- **ES (91):** `memoria,juegos mentales,rompecabezas,sudoku,tangram,mayores,mente,atención,palabras,números`

## Description — English

Fun mental exercise, at your own pace.

MenteViva is fourteen calm games, each a different kind of thinking. Big buttons, clear colours, and
no countdown clock. When a move doesn't fit, it says "almost", never "wrong". Some games show
one example move the first time, so anyone can start on their own.

FOURTEEN GAMES
• Memory: Memory Lane, Names and Faces, Repeat the Sequence, Remember Together (with your own family photos)
• Attention: Quick Eyes, Color Clash, Tangram, Tile Pairs, Sliding Blocks
• Numbers: Number Trail, Sudoku, Up or Down
• Words: Name the Herd, Finish the Saying

AT YOUR PACE
• Ten levels in every game. The level moves gently with how you play, never in the middle of a game
• A few games picked for each day, or play any game you like
• Choose how many minutes a day and what you'd like to exercise, or skip the questions

MADE TO BE EASY
• English and Spanish, switch anytime
• Big text and buttons, VoiceOver throughout
• A family member can set levels, hide games and add photos

PRIVATE BY DESIGN
• Free, with no ads and no in-app purchases
• Works fully offline, no account
• Nothing leaves your device: no tracking, no analytics

MenteViva is entertainment and mental exercise. It is not a medical device and does not diagnose or
treat any condition. If you have a concern about memory, yours or a loved one's, talk to a doctor.

## Description — Spanish

Ejercicio mental divertido, a tu ritmo.

MenteViva son catorce juegos tranquilos, cada uno para un tipo distinto de pensamiento. Botones grandes,
colores claros y sin cuenta regresiva. Cuando una jugada no encaja, dice «casi», nunca «mal».
Algunos juegos muestran una jugada de ejemplo la primera vez, para que cualquiera empiece por
su cuenta.

CATORCE JUEGOS
• Memoria: Camino de Memoria, Nombres y Caras, Repite la secuencia, Recordar juntos (con tus propias fotos de familia)
• Atención: Ojos Ágiles, Choque de Colores, Tangram, Parejas de fichas, Bloques deslizantes
• Números: Sendero de Números, Sudoku, Sube o baja
• Palabras: Nombra la Manada, Termina el refrán

A TU RITMO
• Diez niveles en cada juego. El nivel se ajusta con calma según cómo juegas, nunca a mitad de partida
• Unos juegos elegidos para cada día, o juega el que quieras
• Elige cuántos minutos al día y qué te gustaría ejercitar, o salta las preguntas

PENSADO PARA SER FÁCIL
• Español e inglés, cambia cuando quieras
• Texto y botones grandes, VoiceOver en todo
• Alguien de la familia puede fijar niveles, ocultar juegos y añadir fotos

PRIVADO DESDE EL DISEÑO
• Gratis, sin anuncios y sin compras dentro de la app
• Funciona sin conexión, sin cuenta
• Nada sale de tu dispositivo: sin rastreo, sin analíticas

MenteViva es entretenimiento y ejercicio mental. No es un dispositivo médico y no diagnostica ni trata
ninguna enfermedad. Si te preocupa la memoria, la tuya o la de un ser querido, consulta a un médico.

## Screenshots

Sizes: 6.9" iPhone (1320 × 2868 portrait) and 13" iPad (2064 × 2752 portrait); App Store Connect
scales them for smaller devices. Capture in the simulator, **light mode**, with the text size one step
above default so the large text shows. Five per device and language. The overlay caption is
localized, not just the screen.

| # | Screen | EN caption | ES caption |
|---|---|---|---|
| 1 | Home: today's cards dealt | Today's games, ready | Los juegos de hoy, listos |
| 2 | Memory Lane, mid-round, a pair just found | Find the pairs, calmly | Encuentra las parejas, con calma |
| 3 | Tangram, a tile being placed | Shapes, at your pace | Figuras, a tu ritmo |
| 4 | Quick Eyes, answer beat showing the check | Every answer shows itself | Cada respuesta se muestra |
| 5 | Celebration, the card joining the week | Small wins, warmly | Pequeños logros, con cariño |

Avoid Color Clash in screenshots (lowest Jev scores, 008/010) and anything with a family photo.
Spanish screenshots use the Spanish UI.

## App Privacy

**Data Not Collected.** Checked against the code on 2026-10-27:

- **No network calls.** The app has no `URLSession` or networking code. The only URLs are the source
  links in "Why these games", which open in Safari.
- **Local storage only.** The default local-only build has no CloudKit; the entitlements file isn't
  used (AGENTS.md "Two build modes").
- **Photos never leave the device.** Memory photos come in through the system photo picker and are
  stored privately on the device.
- **Nothing third-party.** No accounts, analytics, ads or third-party SDKs.

If a CloudKit build ever ships (#11), revisit this answer.

## Age rating questionnaire

Every content question: **None** (violence, horror, profanity, sexual content, alcohol/tobacco/drugs,
gambling, contests). Every capability question: **No**:

- unrestricted web access (the source links open Safari outside the app);
- user-generated content shared with others (photos stay on the device);
- messaging or chat;
- advertising;
- parental controls;
- age assurance.

**Medical or treatment information:** None. "Why these games" is a short, sourced summary of
research with a clear "educational information, not medical advice" note (#210). The lawyer review
(#226) confirms this answer.

Result: **4+**.

## Notes for App Review

> MenteViva is a free set of calm puzzle and card games for adults, in English and Spanish. It has no
> account, no ads, no in-app purchases and no network requests: everything stays on the device. It is
> a general wellness game, "fun mental exercise". It makes no medical claims and does not diagnose
> or treat anything; Settings → Why these games explains this with sources. To review: open the app,
> skip or answer the four optional first-run questions, then play any game from Home. Language is in
> Settings; family options (levels, hidden games, photos) are under Set up. No login is needed.

## Before submitting

- [ ] Re-check screenshot sizes, categories and age-rating questions against App Store Connect
- [ ] Final ES pass by a native speaker (#12)
- [ ] Host the site (#34, #188) and paste the two URLs
- [ ] Capture and caption the screenshots above, both languages
- [ ] Family Sharing: on (free apps share automatically; nothing to set for in-app purchases)
- [ ] Lawyer review done (#226)
