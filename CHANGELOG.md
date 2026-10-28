# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Newest first.

## [Unreleased]

### Added
- **Sliding Blocks — slide the blocks to free the big one (#222/#223):** a new game with levels 1–10 (3×4 boards of 1–3 slides up to 4×5 boards of 60+, generated offline and checked solvable). Tap a block and only the 100pt arrows it can follow appear, or drag it where it fits; VoiceOver names each block by size and place ("big block, top middle") and offers "move left/right/up/down" only where it can go, so the puzzle can be solved by ear. Undo, "Start over" and "Show me a move" (100pt each); Reduce Motion moves blocks instantly. The big block is amber and striped, never colour alone, and the exit is a gap in the board's edge with a chevron. It ends with "It's out!" and the usual celebration, and the session is saved with its level.
- **Our own pictures for travels, music and home (#328):** Memory Lane's travels and music-and-home themes show original illustrations (map, suitcase, mountain, beach, tent, lighthouse, helicopter, violin, trumpet, piano, radio, yarn, accordion, picture frame, telephone, sofa) instead of emoji.
- **New pictures for Memory Lane's kitchen table and garden (#327):** 18 original retro illustrations (teapot, bread, cheese, wine glass, croissant, lemon, olives, honey, cake, chocolate, egg, rose, tulip, potted plant, pear, tree, pine, ladybug), checked side by side with their themes at 100pt and 52pt on light and dark tiles and in grayscale.
- **New pictures in Name the Herd (#325):** 21 original retro illustrations (dog, cat, lion, frog, turtle, butterfly, elephant; apple, banana, grapes, orange, strawberry, watermelon, peach; car, bus, airplane, rocket, bicycle, train, sailboat) replace the emoji, checked at 52pt on light and dark tiles and in grayscale.
- **Our own pictures in Quick Eyes and Remember Together (#326):** fourteen original retro illustrations (sunflower, guitar, moon, coffee, star, bee, cactus; clock, key, house, chair, umbrella, book, lamp) ready for the games to show in place of emoji, checked at 100pt and 52pt on light and dark tiles and in grayscale.
- **Art direction samples for our own game pictures (#323):** eight original retro illustrations (dog, apple, teapot, sunflower, key, sailboat, violin, moon) with a contact sheet checked at real game sizes on light and dark tiles and in grayscale, so the four picture batches (#325–#328) can replace emoji with our own art in the same style.
- **Pictures say their name in the app's language (#324):** in Memory Lane, Name the Herd, Quick Eyes and Remember Together, VoiceOver now reads each picture's own English or Spanish name instead of the phone's emoji name. Memory Lane's themes swap four pictures that looked too alike or showed a landmark: honey and an egg join the kitchen table, a lighthouse joins the travels, and an accordion joins music and home. The games are ready for MenteViva's own illustrations (#322), which replace the emoji one batch at a time.
- **A warm-up that finds your pace (#213):** at the end of the first run, "Shall we play three games to find your pace?" ("Let's play" / "Not now"), and always in Settings → My plan; not offered when the app is set up for a family member. It deals three games from three different focus areas at the starting level. While a game is in its first three sessions its level may move two up or two down after each one, more than once a day; after that the normal staircase returns. Nothing is shown at the end but the usual warm celebration: no score, no result, no level screen.
- **Tile Pairs — a mahjong-solitaire pairs game (#220/#221):** find two free tiles that match; layers offset with a shadow, free vs covered never colour alone (covered tiles are dimmed and hatched). Ten levels (8 to 72 tiles, 1–3 layers, look-alike tiles from level 5); every deal clears and a warm reshuffle mixes the tiles when stuck. Warm hints: "That one's covered — try a tile on the edge" and "Almost — those two are different"; "Show me a pair" highlights a free match. Tiles drawn in code with 18 symbols, 80–100pt targets where the board allows (≥60pt always), title2 instructions, VoiceOver only on free tiles with symbol names. Celebration records the session with its level.
- **"Why these games" in Settings (#214):** a new screen that says plainly what the research found,
  what each game exercises, and what MenteViva is not. Every line that rests on a source carries
  that source as a link whose label names where it goes, each part is a heading the VoiceOver rotor
  lists, and the screen closes on "Educational information, not medical advice." EN + ES, readable
  offline.
- **The first run asks four short questions, and "My plan" asks them again (#212):** after the
  welcome screen, one question per screen — who will play, what to exercise (any number of
  answers), how long a day and how to start — each with 100pt answer tiles, a visible "Skip",
  Back, and a "2 of 5" dot row. Nothing is required, nothing is preselected, and with "a family
  member" the calmest pace is offered first. The same four answers live in Settings → My plan,
  where tapping a chosen answer again leaves that question unanswered. Minutes a day decide how
  many games the daily plan deals (5 → 2, 10 → 3, 15 → 5); a change made today shapes tomorrow's
  plan, not today's.
- **Repeat the Sequence — watch and repeat the lit tiles (#216/#217):** a new game with levels 1–10 (grid 2×2 to 3×3, sequence 2–8, light 1.0s→0.55s; on a narrow screen a 3×3 falls back to 2×3). Five sequences per game; miss once and it says "Almost — watch again" and replays, then moves on warmly.
- **Levels 1–10 for four games (#203–#206):** Name the Herd (2–11 decoys), Finish the Saying (2–5 choices, same-theme from level 6), Number Trail (ops and caps per level, cap 120 at 10), Color Clash (matching chance 0.85→0 and 6 colours/shapes at levels 9–10).

### Changed
- **One retro look across the app (#336):** cards, buttons, game screens and the celebration now use the approved cream, espresso, jade and mustard palette (a dark surround in dark mode) with espresso outlines and a hard print shadow, so the app matches the new pictures. Layout, games, copy and every control size are unchanged; each game keeps its own colour.
- **Warmer tones an iPhone speaker can play (#240):** the sounds now fade in over 10 ms and die away gently instead of stopping after a fraction of the note, with a soft second harmonic for warmth. The "not quite" tone moves up from 180 Hz to 280 Hz, still the lowest and softest, so a phone speaker actually plays it. The tone maker is now a pure `ToneSynth`, tested for headroom and pitch.

### Fixed
- **Tile Pairs opens from Home again (#221 follow-up):** since its screen shipped, the card (and a daily plan that deals it) led to a blank screen; it now opens the game.
- **One migration at launch, reads stay pure (#264):** pre-level pins and plan levels used to migrate inside every `pinned()` / `storedDifficulty()` read (Home renders, the plan, Set up). Now `LevelMigration.runOnce` batches both at launch behind one `level.migration.done` flag and reads do not write.

### Changed
- **Up or Down, ten levels (#202):** tables now grow from 3 piles to 7, King–Ace stops wrapping from level 6, and only the first three levels always clear. Levels 2, 4 and 6 deal exactly the old easy, medium and hard games.
- **Sudoku, ten levels (#201):** boards now grow from 4×4 to 6×6 to a classic 9×9 with more blanks at every step. Levels 2, 4 and 6 deal exactly the old easy, medium and hard boards; where the wanted board doesn't fit, a fuller smaller board steps in.
- **Memory Lane, ten levels (#199):** the board now grows one pair at a time from 3 pairs (level 1) to 12 (level 10). Levels 2, 4 and 6 deal exactly the old easy, medium and hard boards; on a small screen the board caps itself so every card stays big enough to tap.

### Added
- **Tangram (#218, #219):** a new game. Fill the silhouette with seven tiles:
  tap a tile, then tap where it goes, or drag it there. Near enough is enough,
  and up to level 6 the tile turns itself into place; from level 7 you turn it,
  and from level 9 you flip the parallelogram too. Four tiles start in place at
  level 1. A tile that doesn't fit goes back with a hint ("Almost — try another
  spot"). "Show me one" places a tile when you're stuck, and VoiceOver places
  tiles through custom actions naming each free slot. Thirty figures, ten levels,
  no repeats until all have been seen.
- **"Let me show you" first-play guide (#243):** the first time you open Sudoku, Up or Down or Color Clash, a calm card says the one-line instruction (in big type, read aloud), highlights one example move with a soft pulse and an arrow (just the highlight with Reduce Motion), and offers two 100pt buttons, "Got it" and "Show me again". VoiceOver treats it as a modal with the example described in words. Settings has a new row, "Show the game guides again".
- **Set up: pin a game at any level 1–10 (#208):** each game with levels now has an "Automatic" switch and, when it is off, two big 100pt buttons (− / +) around "Level 4". At level 1 and 10 the button is dimmed and a line says it is the lowest or highest level. VoiceOver reads it as one adjustable control: swipe up or down to change the level.
- **A gentle nudge after a strong game and a one-line level note (#207):** when the rules move a game up by one, by two, or ease it, the first time you open it that day you see one warm line under the header ("We made it a little harder: you've been doing great.", "Two steps up: you're flying!", "We made it a little calmer, so you enjoy it more.") in `.title2`, read by VoiceOver, gone once the first round starts and only once per day; never mentions misses or accuracy. When you finish a strong game below level 10 and the game isn't pinned, the celebration asks once that day "That was perfect. Shall we try the next level?" with two 100pt buttons "Yes, let's try" / "Keep it as it is" (equally prominent, neither default) — Yes lifts the level by one now with reason `.chosen` so the staircase counts from there.
- **Finish the Saying (#181):** a ninth game. The start of a familiar saying; pick the
  ending from big buttons and hear the whole saying read aloud. Sixty sayings in each
  language, English sayings and Spanish refranes chosen separately, none repeated until
  all have been seen.
- **Up or Down (#180):** an eighth game, a solitaire with big cards. Tap a card one higher
  or one lower than the open card; turn the deck when none fits. A new deal every time; the
  easy level lifts the cards that fit and always clears. It ends on the cards you cleared.
- **Sudoku (#179):** a seventh game. A 4×4 or 6×6 number square, new every time.
  A number that doesn't fit gets a gentle "try another number"; "Show me one" fills a
  square when you're stuck. Hard is 6×6, or a fuller 4×4 on small iPhones.
- **Remember Together (#139):** a sixth game. Your family's photos appear one at a
  time with "Who is this?"; "Show me" reveals the name you gave the photo. Nothing
  can be answered wrongly, and with no photos it shows everyday objects. Names are
  typed per photo in For family and stay on this device. A new setting, "Read names
  aloud", speaks the name on its own (off by default); the speaker button always works.
- **Weekly progression (#107):** My Week now has a "Your games this week" line
  per game, warm words and an icon only (moved up a level, or steady), never a
  number or a down arrow. Settings → **For family** shows the numbers: games and
  % right this week vs the week before, the level each game is set to, level
  and accuracy trends (declines included, worded kindly), and a share button
  that sends them as text. Each session now records the difficulty it was
  played at. EN + ES.

- **Family settings (#108):** For family → Games on this device: per game,
  show or hide it on Home (hidden games are never in the daily picks; the last
  game can't be hidden) and choose Automatic or a fixed Easy/Medium/Hard. A
  fixed level stays until switched back to Automatic, which continues from it.
  Per device. Resolves #47: Color Clash and Number Trail can be hidden, code
  kept. EN + ES.
- **Memory Lane with his own photos (#110):** For family → Memory Lane photos:
  add up to 8 photos with Apple's photo picker (no library permission), each
  with its own Remove button. Photos become Memory Lane cards first; the
  theme's pictures fill the rest. Kept small, on this device only, never
  uploaded. VoiceOver reads photo cards as "Family photo 1, 2…". EN + ES.
- **Jev config via xcconfig (#91):** `JEV_PROXY_URL` / `JEV_PROXY_SECRET` now
  come from a git-ignored `MenteViva/Config/Local.xcconfig` (template:
  `Local.xcconfig.example`) through `Base.xcconfig`; empty = Jev off. URLs need
  `https:/$()/host` because `//` starts an xcconfig comment.
- **Weekly summary card (#71):** "My Week" shows days played, games played and
  day streak (no scores), and the existing share button sends that same warm
  text. Built locally from saved sessions; EN + ES.
- Sound & haptics (#26): synthesized tones (no audio files, no fees) with a
  matching haptic — soft low-frequency success, a gentle three-note completion,
  a quiet low "miss", all behind one "Sound & haptics" Settings toggle, on by
  default. Design decisions (incl. overriding Jev on cue redundancy) recorded in
  `docs/jev-sounds.md`; Jev call archived as `jev-json/006-sounds`.
- First-run onboarding (#31): one screen — what this is, language choice,
  one big "Let's play" button. Written for a stranger, not for family.
- Settings (#32): language (Device/English/Español), bigger text, plain-language
  privacy summary, version. Reachable from home in one tap. The sound
  toggle followed with sound & haptics (#26).
- Home screen personality (#27): warm greeting, large emoji game tiles in a
  grid (>=140pt tall), and the My Week card. Replaces the bare list.
- App icon + launch screen: warm gradient with two memory cards, generated
  reproducibly by `tools/generate_icon.swift` (no design tools, no assets to
  lose). Deliberately not a brain glyph — research §1 caps our positioning at
  "fun mental exercise".
- Accessibility audit fixes (#5, docs/a11y-audit-2026-09.md): Color Clash
  buttons now carry a distinct shape (circle/triangle/square/diamond) so
  color never carries the answer alone; Name the Herd picked tiles get a
  visible checkmark; VoiceOver position/state hints in Memory Lane and Name
  the Herd ("Card 3 of 16", "Pair found", "Already picked") — all ES/EN.
  "My Week" now shows Quick Eyes sessions instead of "Unknown game".
- Quick Eyes: processing-speed game — a picture flashes for a shrinking
  display time (1.2 s → 0.35 s floor, relaxes after a miss), then the player
  picks it among four big buttons. 12 rounds, no countdown timer. ES/EN copy.
- Shared end-of-game celebration screen (#8): gentle pure-SwiftUI confetti,
  warm "Well done! 🎉" headline, a progress line (the score was replaced by
  progress in #45), and ≥100pt "Play again / Home" buttons. All games present it on finish
  (fullScreenCover); Reduced Motion shows static confetti.
- "My Week" session history (#9): last 7 days grouped by day, big rows with
  game emoji + score, warm weekly summary line, gentle empty state.

### Changed
- **Every answer shows itself (#235):** in Quick Eyes, Color Clash and Number Trail the answer you tapped gets a check, or a soft amber outline with the right answer checked beside it, for a moment before the next round; taps wait meanwhile. It shows with sound off too, and VoiceOver says "That's it!" after a right answer and "The answer was …" after a miss.
- **Every game comes round at least once a week (#279):** a game left out of today's games for a week takes the last place, whatever the minutes or focus chosen; the first places stay as they were.
- **Color Clash and Number Trail come round too (#277):** they used to be left out of today's three every day; now each is dealt about two days in fourteen, and Memory Lane still comes up most.
- **Quick Eyes has ten levels (#200):** the picture flashes from 2 seconds at level 1 down to a 0.16-second floor at level 10. Levels 2, 4 and 6 play exactly as easy, medium and hard did.
- **A gentler staircase, still in one day's plan (#198):** levels 1–10 climb one after a strong game, two after two strong in a row, and ease one when the latest game was hard going; once a day, never mid-game, clamped to 1...10. Memory Lane's strong/weak thresholds (0.65/0.45) are lowered because its accuracy counts moves (pairs / moves) so even good play sits near 0.6. The old 7-day hold is gone — the window since the last change is the hold now.
- **Sudoku and Finish the Saying are easier to tap (#236):** every answer button
  and Sudoku's "Show me one" are back to at least 100pt tall, so they're
  comfortable at the largest text sizes. The board still keeps 60pt squares;
  overflow scrolls.
- **Warm celebrations (#242):** the end of a game says one of five warm headlines ("Well done!",
  "Lovely work!", "That was great!", "Beautifully done!", "Nicely played!"), never the same one
  twice in a row. Nothing in them mentions a score or speed.
- **Name the Herd enjoys each finished category (#238):** every check stays visible for a
  moment with a warm completion note before the next category arrives, and VoiceOver hears
  the new category's name.
- **Memory Lane turns its cards (#237):** a card turns over like a real card, and a
  missed pair turns back the moment you pick the next card, so the board never holds
  more than it should. With Reduce Motion the cards cross-fade instead of turning.
- **Sudoku celebrates finished rows (#239):** finishing a row, column or box washes it
  in the game's ink and names it aloud, and each placed number pops gently onto its
  square. The finished board keeps its usual celebration and nothing else.
- **A clear, honest introduction (#227):** onboarding and store copy now use
  "Fun mental exercise" / "Ejercicio mental divertido" and describe games as
  exercising memory and attention, without promising cognitive outcomes.
- MenteViva no longer connects to the internet; today's games are always chosen on your device (#195).
- **Privacy you can read (Settings):** the long paragraph is now three short lines with
  icons: your games stay on this iPad, no account or ads or tracking, and your photos and
  their names never leave it. The backup note follows in smaller text. The line about daily
  suggestions appears only in builds where they're on.
- **A new app icon:** one of the app's own framed game cards, with Memory Lane's emblem, on
  the table colours, so the icon matches the cards inside the app.
- **My Week agrees with itself:** "this week" now means Sunday to Saturday everywhere on
  the screen, the same week as the board at the top, so the counts, the game lines and
  the day-by-day rows match the cards shown. The "Days in a row" line is gone from the
  summary and the shared text (no streaks). My progress and Set up show each game's
  drawn emblem instead of an emoji.
- **"For family" is now "My progress" and "Set up" (#141):** Settings has two rows.
  My progress shows whoever holds this device how each game went in the last 7 days:
  days played out of 7, the average right answers per game, the level reached, and each
  game's share of the week ("Played this week"). A trend appears only after 3 games that
  week, compared only with your own earlier weeks, in words with an arrow that never
  points down. Remember Together shows plays and days only. Sharing stays your choice.
  Hiding games, fixing a difficulty and Memory Lane photos moved to Set up.
- **Number Trail steps up with difficulty (#143):** Easy still asks only sums. Medium
  adds take-aways that never go below zero (the bigger number comes first). Hard adds
  times and exact division with small numbers (up to 10). The signs are the usual
  + − × ÷, and VoiceOver and the speaker button say them in words ("7 minus 3",
  "7 menos 3").
- **My Week reads by day (#140):** instead of one line per game played, each day is
  one row with a chip for every game and how many times it was played ("Memory Lane
  ×2"), so the week is about seven rows, not a long log. VoiceOver reads each day as
  one sentence ("Today: Memory Lane, 2 times; Quick Eyes, once").
- **Spanish wording (#12):** the end-of-game stamp now says "Agregado a tu semana"
  (neutral Latin American), Home's button reads "Seguimos con …" without a colon, and
  the end-of-game pill reads "Hoy: 1 de 3".
- **A warmer look, taken from the app icon (Card Table, step 1):** each game has its
  own colour on Home and inside the game, and buttons and switches are icon teal
  instead of system blue. The welcome title and "Well done!" use a serif. Memory
  Lane's card backs are teal. Layouts, sizes and words are unchanged.
- **Games on Home are cards (Card Table, step 2):** each game is a framed card in
  its colour, with its own drawn emblem instead of an emoji and its name on a band
  of that colour. "Today's pick" stays on the card with its star. Cards sink a
  little when pressed (they dim instead with Reduce Motion).
- **One header for every game (Card Table, step 3):** the big title is gone; the
  game's name sits small at the top, and a speaker button next to it reads the
  instructions aloud (in English or Spanish). Progress is a row of small cards in
  the game's colour with "Round 4 of 10" in full-contrast text, instead of grey
  "4 / 10". Quick Eyes' "Almost" line is a soft amber note instead of grey.
- **Home deals today's games on a table (Card Table, step 4):** a greeting for the
  time of day, then today's three games as cards on the icon's teal-to-amber table
  with one big button that always names the next one ("Start today's games", then
  "Keep going: Name the Herd"). Played games get an amber tick; when all are done
  the cards stack up and the week shows instead. A week board (seven days, small
  cards for the games played) opens My Week. All games stay below. On iPad, today
  is on the left and everything else on the right; at the largest text sizes the
  cards become full-width rows. The "Today's pick" stars are gone from the grid.
- **The end of a game adds a card to the week (Card Table, step 5):** the game's
  card arrives on the table stamped "Added to your week", above "Well done!", the
  progress line and the week board with today's new card. During today's games the
  big button reads "Next: Quick Eyes" and opens it straight away, with "2 of 3
  today" at the top; otherwise it stays "Play again". My Week opens with the same
  week board. The confetti is gone; the card is the celebration.
- **Memory Lane looks grown-up (#109):** boards of 4 / 6 / 8 pairs (was 6 / 8 /
  10) laid out to fit the screen on iPad and iPhone, with no scrolling and full
  rows; grown-up themes (kitchen table, garden, travels, music and home);
  paper-like cards with a calm slate back instead of the flower emoji. Found
  pairs keep the checkmark.
- **Daily picks decided on the device (#101):** "Today's pick" and each game's
  difficulty now come from a small built-in policy (most worthwhile games first,
  nudged toward ones you haven't played lately; difficulty eases after low
  accuracy, rises only after steady success, one level at a time, then holds a
  week). No network, no account, no cost. Jev remains an optional override when
  a proxy is configured.
- **Difficulty applied in games (#60):** Memory Lane (6/8/10 pairs), Number Trail
  (sum range), Quick Eyes (flash time), Color Clash (how often the word matches)
  and Name the Herd (decoys) follow the daily difficulty. New players and Jev-less
  installs stay on medium, which is the game as it was.
- **Today's picks on Home (#59):** three games carry a "Today's pick" star, chosen
  once a day from recent play (Jev when a proxy is configured, a fixed rotation
  otherwise). Home never waits for it and the tile order stays put.
- **Session accuracy (#58):** every game now records how many answers were right
  (`correct`/`attempts`), and `rounds` means the same thing everywhere (Memory Lane
  stores pairs, not moves). Existing history is untouched.
- **Memory Lane warmth pass (#43):** boards now draw from four themed emoji
  sets (garden, animals, fruit, vehicles) so repeat visits feel fresh; cards
  are larger with a softer warm palette, found pairs bloom gently and keep a
  visible checkmark instead of relying on color alone.
- **Scoring → progress (#45):** points no longer appear anywhere in the UI.
  Every game now ends with the shared celebration showing a warm progress line
  (pairs found, rounds finished, best streak, items spotted — EN + ES). Quick
  Eyes gains the celebration screen it never had. "My Week" rows and the family
  share text show the games played, without point totals. Scores are still
  stored on `GameSession` as anonymous telemetry for Jev; they are just never
  displayed.
- Review pass: game IDs now share one typed source of truth across Jev, Home,
  history, and saved sessions; delayed game tasks cancel when their round ends;
  interactive settings and language controls now use the app's 100pt target
  floor.
- Language selection now updates the visible app immediately, including settings
  labels and game names.
- Round bookkeeping extracted into a tested `RoundProgress` type (#30), used by
  Name the Herd, Color Clash and Quick Eyes. A counter can no longer run past the
  end of a game: advancing is idempotent, the displayed round is clamped, and 8
  boundary tests pin the behaviour (zero rounds, single round, over-advance,
  replay).

### Fixed
- **Pinning a game at Level 2 keeps it at Level 2:** Set up saved the pin correctly, but reading it treated
  1 and 2 as old easy/medium values, so "Level 2" became Level 6, the hardest. Old pins from before levels
  1–10 still move over once as 2/4/6.
- **Higher levels never get easier (#267):** at levels 7–10, Up or Down dealt the easier King–Ace
  wrap again and Finish the Saying dropped its closer endings; at levels 1 and 3 Up or Down no longer
  promised a deal you can clear. Each game now reads its level as a band (1–3, 4–5, 6–10) until it gets
  its own ten steps.
- **Up or Down deck pulses only when stuck (#241):** the deck used to jump to 1.06 and stay there because the pulse was set once on appear; it now repeats 1.0↔1.06 at 0.8s while stuck, stops when a card fits or the deck empties, stays still under Reduce Motion (amber ring only), and VoiceOver says the stuck note once.
- **Finish the Saying speaks the solution (#245):** completing a saying now reads it aloud when
  automatic speech is on, or announces it once to VoiceOver when automatic speech is off.
- **My progress froze on iOS 17 (#169):** opening it from Settings on an iPad with
  iOS 17 locked the app. It now reads every play and keeps the days it needs in code,
  the way the old For family screen did. Checked on the iPad (iOS 17.7).
- **Daily picks use Jev again when it is set up (#146):** adding Remember Together
  left the key-holding proxy expecting five games, so it turned every request away
  and the app quietly fell back to its own on-device plan. Installs without the
  proxy were never affected.
- **Language switch applies everywhere at once (#134):** game text and spoken
  labels now follow the chosen language right away, not after a relaunch.
- **Memory Lane photos say what happened (#120):** after picking photos, one
  line says how many were added and, if some weren't, that a photo couldn't
  be used or that the album holds 8. VoiceOver reads it too. EN + ES.
- **The app always opens (#124):** if the saved game history can't be opened
  (for example after a failed update), the app now starts with a temporary
  history instead of crashing on every launch; the problem is logged.
- **For family shows the level you just set (#124):** after changing a game's
  level and going back, its progress lines show the new level right away.
- **Counts read naturally (#124):** "1 game" / "1 juego" and "You played 1
  time this week" / "Jugaste 1 vez", instead of "1 games" / "1 times".
- **Finished games missing from My Week (#106):** every game now saves its
  session the moment it ends instead of waiting for SwiftData's autosave, so an
  Xcode renewal or iOS closing the app right after a game no longer loses it.
  Docs warn that deleting the app erases My Week.
- **Jev proxy hardening (#63):** worker now requires a shared-secret header, rate-limits,
  caps body size, validates model/question keys, and returns a warm 502 on upstream failure.
- **Jev client (#61):** one unreadable answer no longer discards the rest, the
  fallback plan is remembered for the day (no retry storm while offline), and
  simultaneous requests share one call. Optional `JEV_PROXY_SECRET` is sent as
  `X-MenteViva-Key` when set.
- **Round-end bugs (#53, #54, #55):** an extra tap after the last round no longer
  records a second session (Color Clash, Quick Eyes, Number Trail); Color Clash
  now records whole-session time; Number Trail uses the shared round counter.
- **VoiceOver position hints (#56):** Memory Lane and Name the Herd position
  hints now resolve through the string catalog; orphan strings removed.
- **Launch crash on device (local-only builds):** the CloudKit on/off flag was
  passed as `INFOPLIST_KEY_CloudKitEnabled`, which Xcode does not inject (it
  only handles a known allowlist), so the app read `nil`, assumed CloudKit was
  on, and trapped inside CloudKit's mirroring setup with no iCloud entitlement —
  `EXC_BREAKPOINT` in `PFCloudKitContainerProvider`, uncatchable. The simulator
  tolerates the missing entitlement, which is why local testing missed it. Now a
  compile-time `LOCAL_ONLY` flag drives the choice.

### Accessibility
- **"Today's pick" is readable (#118):** the badge was light orange on a light
  blue tile (1.8:1); it is now a deep orange in light mode (over 4.5:1) and
  stays system orange in dark mode. A test checks both.
- **Follows the device text size (#117):** the app used to lock text at the
  default size, ignoring the iPad/iPhone setting. Now it follows it, and Bigger
  text raises the minimum instead of fixing one size. Number Trail's numbers
  and Color Clash's word grow with it. At the largest sizes Home tiles widen
  (one column on iPhone, two on iPad) so names never break mid-word, a game
  screen scrolls only if it can't fit (no instruction is cut short), and Quick
  Eyes shows only its short prompt while choosing so the four pictures stay on
  screen.
- **VoiceOver playability (#64):** Quick Eyes announces the flashed picture (and
  holds it 2.5s while VoiceOver is on); Color Clash reads the ink colour and
  shape, and draws the shape beside the word for colour-blind players; wrong
  picks in Name the Herd, Number Trail and Color Clash show a gentle amber
  outline (no text); gear, share and Done buttons have 100pt hit areas; the
  language-row hint is on each button. EN + ES.

### Docs
- **IP clearance for all names (#225):** `docs/ip-clearance.md` now lists the 2026-10-27 search for MenteViva and the 13 game names in EN and ES (USPTO + EUIPO + IMPI + App Store, classes 9/41), with per-name risk (none/low) and sources, plus the asset check (system fonts only, emoji as Apple glyphs, synthesized tones, no third-party images/sounds/code). No rename needed; two alternatives are recorded for each name. Still needs the one-hour lawyer review before the paid release.

## [0.1.0] — 2026-09-19

First playable. Built in one session with agent teammates.

### Added
- Four games: Memory Lane (pairs), Color Clash (Stroop), Name the Herd
  (category fluency), Number Trail (adaptive math).
- ES/EN localization for every user-facing string (25 keys).
- Jev/TypeSafe client: daily game-mix ranking + difficulty nudge policy,
  once per day, silent deterministic fallback when offline. Not yet wired
  into the app's screens (tracked in #59). Key never on device — proxy
  contract documented.
- Docs system: product brief, conventions, decision log, cited research
  (audience evidence, domain ranking, licensing table, App Store pricing),
  roadmap.
- VoiceOver labels on all game elements; ≥100pt touch targets.

### Fixed
- JevService brace nesting (caught by first real build; parse ≠ compile).
- Missing ES translations for math format strings auto-extracted by Xcode.

[0.1.0]: https://github.com/nebulaideas/MenteViva/releases/tag/v0.1.0
