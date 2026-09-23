# ES review packet — for the native-speaker pass (#12)

Hand this whole file to the reviewer. Generated from `Localizable.xcstrings`
(75 user-facing strings; 3 pure format-specifier keys omitted).
Regenerate after any string change: `python3 tools/generate_es_packet.py`.

## What to check, in order

1. **Tone.** Warm and kind, always. A missed answer must never read as
   failure — no «mal», «error», «fallaste». Ceiling is «inténtalo otra vez».
2. **Register.** Pick tú or usted and flag any mix — seniors often expect
   usted; consistency matters more than the choice.
3. **Claims.** Nothing medical. «Ejercicio mental divertido» is the ceiling;
   flag anything that sounds like treatment, prevention or improvement.
4. **Naturalness.** Would a Spanish-speaking abuelo say it this way?
   Mark anything that reads translated.
5. **Length.** ES runs ~20% longer than EN; flag strings that would crowd
   a big button (they show at very large text sizes).

Mark rows: ✅ fine / ✏️ suggestion (write the fix) / ❓ needs context (ask us).

## Strings

| Key | English | Español | Used in | ✓ |
|---|---|---|---|---|
| `app.title` | Mente Viva | Mente Viva | HomeView, OnboardingView |  |
| `game.category.a11y.picked` | Already picked | Ya elegido | CategoryFluencyView |  |
| `game.category.a11y.position %lld %lld` | Tile %lld of %lld | Ficha %lld de %lld | CategoryFluencyView |  |
| `game.category.animals` | Animals | Animales | CategoryFluencyView |  |
| `game.category.colors` | Colors | Colores | CategoryFluencyView |  |
| `game.category.fruits` | Fruits | Frutas | CategoryFluencyView |  |
| `game.category.instruction` | Tap all that belong to | Toca todos los que sean | CategoryFluencyView |  |
| `game.category.title` | Name the Herd | Nombra la Manada | CategoryFluencyView, JevService |  |
| `game.category.vehicles` | Vehicles | Vehículos | CategoryFluencyView |  |
| `game.celebration.home` | Home | Inicio | CelebrationView |  |
| `game.celebration.items %lld` | You found %lld of them! | ¡Encontraste %lld! | CategoryFluencyView |  |
| `game.celebration.pairs %lld` | You found all %lld pairs! | ¡Encontraste las %lld parejas! | MemoryMatchView |  |
| `game.celebration.playagain` | Play again | Jugar de nuevo | CelebrationView |  |
| `game.celebration.questions %lld` | You answered all %lld questions! | ¡Respondiste las %lld preguntas! | MathStreakView |  |
| `game.celebration.rounds %lld` | You finished all %lld rounds! | ¡Terminaste las %lld rondas! | ColorClashView |  |
| `game.celebration.spotted %lld %lld` | You spotted %1$lld of %2$lld! | ¡Viste %1$lld de %2$lld! | QuickEyesView |  |
| `game.celebration.streak %lld` | Best streak: %lld in a row! | ¡Mejor racha: %lld seguidas! | MathStreakView |  |
| `game.colorclash.color.blue` | Blue | Azul | ColorClashView |  |
| `game.colorclash.color.green` | Green | Verde | ColorClashView |  |
| `game.colorclash.color.orange` | Orange | Naranja | ColorClashView |  |
| `game.colorclash.color.red` | Red | Rojo | ColorClashView |  |
| `game.colorclash.instruction` | Tap the color of the ink, not the word | Toca el color de la tinta, no la palabra | ColorClashView |  |
| `game.colorclash.shape.circle` | Circle | Círculo | ColorClashView |  |
| `game.colorclash.shape.diamond` | Diamond | Rombo | ColorClashView |  |
| `game.colorclash.shape.square` | Square | Cuadrado | ColorClashView |  |
| `game.colorclash.shape.triangle` | Triangle | Triángulo | ColorClashView |  |
| `game.colorclash.title` | Color Clash | Choque de Colores | ColorClashView, JevService |  |
| `game.colorclash.word.blue` | BLUE | AZUL | ColorClashView |  |
| `game.colorclash.word.green` | GREEN | VERDE | ColorClashView |  |
| `game.colorclash.word.orange` | ORANGE | NARANJA | ColorClashView |  |
| `game.colorclash.word.red` | RED | ROJO | ColorClashView |  |
| `game.common.welldone` | Well done! 🎉 | ¡Muy bien! 🎉 | CelebrationView |  |
| `game.math.instruction` | Tap the correct answer | Toca la respuesta correcta | MathStreakView |  |
| `game.math.title` | Number Trail | Sendero de Números | JevService, MathStreakView |  |
| `game.memory.a11y.matched` | Pair found | Pareja encontrada | MemoryMatchView |  |
| `game.memory.a11y.position %lld %lld` | Card %lld of %lld | Carta %lld de %lld | MemoryMatchView |  |
| `game.memory.card.hidden` | Hidden card | Carta oculta | MemoryMatchView |  |
| `game.memory.instruction` | Find the matching pairs | Encuentra las parejas | MemoryMatchView |  |
| `game.memory.title` | Memory Lane | Camino de Memoria | JevService, MemoryMatchView |  |
| `game.quickeyes.a11y.showing` | A picture is being shown briefly | Se muestra una imagen por un instante | QuickEyesView |  |
| `game.quickeyes.almost` | Almost — let's slow down a touch | Casi — vamos un poquito más despacio | QuickEyesView |  |
| `game.quickeyes.instruction` | A picture flashes on screen. Look closely, then tap the one you saw | Aparecerá una imagen por un instante. Mírala bien y luego tócala | QuickEyesView |  |
| `game.quickeyes.prompt` | Which one did you see? | ¿Cuál viste? | QuickEyesView |  |
| `game.quickeyes.title` | Quick Eyes | Ojos Ágiles | JevService, QuickEyesView |  |
| `history.a11y.played %@` | Played %@ | Jugaste %@ | HistoryView |  |
| `history.empty` | No games yet this week. Pick a game and have some fun! | Aún no hay juegos esta semana. ¡Elige un juego y diviértete! | HistoryView |  |
| `history.game.unknown` | Game | Juego | HistoryView |  |
| `history.share` | Share with family | Compartir con la familia | HistoryView |  |
| `history.share.hint` | Sends this week's games as a message | Envía los juegos de esta semana como mensaje | HistoryView |  |
| `history.summary %lld` | You played %lld times this week! 🌟 | ¡Jugaste %lld veces esta semana! 🌟 | HistoryView |  |
| `history.title` | My Week | Mi Semana | HistoryView, HomeView |  |
| `history.today` | Today | Hoy | HistoryView |  |
| `history.yesterday` | Yesterday | Ayer | HistoryView |  |
| `home.greeting` | Shall we play a game? | ¿Jugamos un rato? | HomeView |  |
| `home.week.hint` | See what you played this week | Mira lo que jugaste esta semana | HomeView |  |
| `language.restart.notice` | Close and reopen the app to see the change. Cierra y vuelve a abrir la app para ver el cambio. | Close and reopen the app to see the change. Cierra y vuelve a abrir la app para ver el cambio. | — |  |
| `language.restart.title` | Language / Idioma | Idioma / Language | — |  |
| `onboarding.disclaimer` | This is not a medical device. | No es un dispositivo médico. | OnboardingView |  |
| `onboarding.line1` | Short games to keep your mind active. | Juegos cortos para mantener tu mente activa. | OnboardingView |  |
| `onboarding.line2` | No rush, no pressure. | Sin prisa y sin presión. | OnboardingView |  |
| `onboarding.line3` | Pick a game and start. | Elige un juego y empieza. | OnboardingView |  |
| `onboarding.start` | Let's play | A jugar | OnboardingView |  |
| `onboarding.start.hint` | Opens the games | Abre los juegos | OnboardingView |  |
| `settings.done` | Done | Listo | SettingsView |  |
| `settings.language` | Language | Idioma | SettingsView |  |
| `settings.language.restart` | The language changes right away. | El idioma cambia al instante. | SettingsView |  |
| `settings.language.system` | Device | Sistema | SettingsView |  |
| `settings.open.hint` | Language, bigger text and privacy | Idioma, texto más grande y privacidad | HomeView |  |
| `settings.privacy.body` | No ads. No tracking. No account. Your games stay on your device. If daily suggestions are on, only anonymous totals leave it — which games, how many, how well. Never your name. | Sin anuncios. Sin rastreo. Sin cuenta. Tus partidas se quedan en tu dispositivo. Si las sugerencias diarias están activas, solo salen totales anónimos: qué juegos, cuántos y qué tan bien. Nunca tu nombre. | SettingsView |  |
| `settings.privacy.title` | Your privacy | Tu privacidad | SettingsView |  |
| `settings.sound` | Sound & haptics | Sonido y vibración | SettingsView |  |
| `settings.sound.hint` | Gentle tones and taps | Tonos y toques suaves | SettingsView |  |
| `settings.textsize` | Bigger text | Texto más grande | SettingsView |  |
| `settings.title` | Settings | Ajustes | HomeView, SettingsView |  |
| `settings.version` | Version | Versión | SettingsView |  |
