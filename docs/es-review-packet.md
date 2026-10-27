# ES review packet — for the native-speaker pass (#12)

Hand this whole file to the reviewer. Generated from `Localizable.xcstrings`
(361 user-facing strings; keys that are only format specifiers are omitted).
Rows already signed off on #12 are pre-marked ✅.
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
| `difficulty.level` | Level %lld | Nivel %lld | — |  |
| `family.auto` | set automatically | ajustado automáticamente | SetUpView |  |
| `family.caption.field` | A name or a few words | Un nombre o unas palabras | FamilyPhotoCaptionSheet |  |
| `family.caption.placeholder` | Mom's house | La casa de mamá | FamilyPhotoCaptionSheet |  |
| `family.caption.privacy` | Saved on this device. The app never shares or sends it. Your own backup, if you use one, may include it. | Se guarda en este dispositivo. La app nunca lo comparte ni lo envía. Tu propia copia de seguridad, si la usas, puede incluirlo. | FamilyPhotoCaptionSheet |  |
| `family.caption.save` | Save | Guardar | FamilyPhotoCaptionSheet |  |
| `family.caption.save.problem` | We couldn't save that name. Please try again. | No pudimos guardar ese nombre. Inténtalo de nuevo. | FamilyPhotoCaptionSheet |  |
| `family.caption.title` | Name this photo | Ponle nombre a esta foto | FamilyPhotoCaptionSheet |  |
| `family.difficulty` | Difficulty | Dificultad | SetUpView |  |
| `family.difficulty.auto` | Automatic (recommended) | Automática (recomendada) | SetUpView |  |
| `family.difficulty.footer` | Automatic moves at most one step a week, based on how the games go. A level you choose stays until you switch back to Automatic, which then continues from it. | La automática cambia como mucho un paso por semana, según cómo van los juegos. Un nivel que elijas se mantiene hasta que vuelvas a Automática, que sigue desde ese nivel. | SetUpView |  |
| `family.game.hint` | Opens this game's settings | Abre los ajustes de este juego | SetUpView |  |
| `family.game.nolevel` | Photos and names, no levels | Fotos y nombres, sin niveles | SetUpView |  |
| `family.games.footer` | Changes apply from the next game, on this device only. | Los cambios se aplican desde el próximo juego, solo en este dispositivo. | SetUpView |  |
| `family.games.header` | Games on this device | Juegos en este dispositivo | SetUpView |  |
| `family.hidden` | Hidden from home | Oculto en el inicio | SetUpView |  |
| `family.level %@ %@` | Next game: %1$@ (%2$@) | Próximo juego: %1$@ (%2$@) | SetUpView |  |
| `family.photos.add` | Add photos | Añadir fotos | MemoryMatchView, SetUpView |  |
| `family.photos.added %lld` | one: Added %lld photo. / other: Added %lld photos. | one: Se agregó %lld foto. / other: Se agregaron %lld fotos. | MemoryMatchView, SetUpView |  |
| `family.photos.caption.a11y %lld` | Photo %lld: add or change its name | Foto %lld: poner o cambiar su nombre | SetUpView |  |
| `family.photos.caption.add` | Add a name | Poner un nombre | SetUpView |  |
| `family.photos.footer` | Up to 8 photos from this device become Memory Lane cards. They stay on this device and are never uploaded. | Hasta 8 fotos de este dispositivo se convierten en cartas de Camino de Memoria. Se quedan en este dispositivo y nunca se suben a internet. | SetUpView |  |
| `family.photos.full %lld` | The album holds %lld photos. Remove one to add another. | El álbum guarda %lld fotos. Quita una para agregar otra. | SetUpView |  |
| `family.photos.header` | Memory Lane photos | Fotos para Camino de Memoria | SetUpView |  |
| `family.photos.remove` | Remove | Quitar | FamilyPhotoCaptionSheet |  |
| `family.photos.remove.a11y %lld` | Remove photo %lld | Quitar foto %lld | — |  |
| `family.photos.unreadable %lld` | one: %lld photo couldn't be used. Try another one. / other: %lld photos couldn't be used. Try other ones. | one: %lld foto no se pudo usar. Prueba con otra. / other: %lld fotos no se pudieron usar. Prueba con otras. | SetUpView |  |
| `family.pinned` | set by you | elegido por ti | SetUpView |  |
| `family.share` | Share with family | Compartir con la familia | MyProgressView |  |
| `family.share.hint` | Sends these numbers as a text message | Envía estos números como un mensaje de texto | MyProgressView |  |
| `family.share.title` | MenteViva — how each game went this week | MenteViva — cómo fue cada juego esta semana | MyProgressView |  |
| `family.show` | Show on home | Mostrar en el inicio | SetUpView |  |
| `family.show.last` | At least one game always stays on home. | Al menos un juego siempre queda en el inicio. | SetUpView |  |
| `game.category.a11y.picked` | Already picked | Ya elegido | CategoryFluencyView |  |
| `game.category.a11y.position %lld %lld` | Tile %lld of %lld | Ficha %lld de %lld | CategoryFluencyView |  |
| `game.category.animals` | Animals | Animales | CategoryFluencyView |  |
| `game.category.colors` | Colors | Colores | CategoryFluencyView |  |
| `game.category.complete %@` | All the %@ found! | ¡Encontraste todos: %@! | CategoryFluencyView |  |
| `game.category.found %lld %lld` | %1$lld of %2$lld found | %1$lld de %2$lld encontrados | CategoryFluencyView |  |
| `game.category.fruits` | Fruits | Frutas | CategoryFluencyView |  |
| `game.category.instruction` | Tap all that belong to | Toca todos los que sean | CategoryFluencyView |  |
| `game.category.title` | Name the Herd | Nombra la Manada | GameID |  |
| `game.category.vehicles` | Vehicles | Vehículos | CategoryFluencyView |  |
| `game.celebration.added` | Added to your week | Agregado a tu semana | CelebrationView | ✅ |
| `game.celebration.cards %lld` | You cleared %lld cards | Quitaste %lld cartas | UpOrDownView |  |
| `game.celebration.headline.1` | Well done! | ¡Muy bien! | CelebrationHeadline |  |
| `game.celebration.headline.2` | Lovely work! | ¡Qué buen trabajo! | — |  |
| `game.celebration.headline.3` | That was great! | ¡Estuvo genial! | — |  |
| `game.celebration.headline.4` | Beautifully done! | ¡Lo hiciste muy bien! | — |  |
| `game.celebration.headline.5` | Nicely played! | ¡Bien jugado! | — |  |
| `game.celebration.home` | Home | Inicio | CelebrationView |  |
| `game.celebration.items %lld` | You found %lld of them! | ¡Encontraste %lld! | CategoryFluencyView |  |
| `game.celebration.next %@` | Next: %@ | Siguiente: %@ | CelebrationView | ✅ |
| `game.celebration.pairs %lld` | You found all %lld pairs! | ¡Encontraste las %lld parejas! | MemoryMatchView |  |
| `game.celebration.playagain` | Play again | Jugar de nuevo | CelebrationView |  |
| `game.celebration.questions %lld` | You answered all %lld questions! | ¡Respondiste las %lld preguntas! | MathStreakView |  |
| `game.celebration.reminiscence %lld` | one: You looked at %lld picture today / other: You looked at %lld pictures today | one: Miraste %lld imagen hoy / other: Miraste %lld imágenes hoy | ReminiscenceView |  |
| `game.celebration.rounds %lld` | You finished all %lld rounds! | ¡Terminaste las %lld rondas! | ColorClashView |  |
| `game.celebration.sayings %lld` | You finished %lld sayings | Terminaste %lld refranes | SayingsView |  |
| `game.celebration.spotted %lld %lld` | You spotted %1$lld of %2$lld! | ¡Viste %1$lld de %2$lld! | QuickEyesView |  |
| `game.celebration.squares %lld` | You filled %lld squares | Llenaste %lld cuadros | SudokuView |  |
| `game.celebration.streak %lld` | Best streak: %lld in a row! | ¡Mejor racha: %lld seguidas! | MathStreakView |  |
| `game.celebration.table` | You cleared the table! | ¡Limpiaste la mesa! | UpOrDownView |  |
| `game.celebration.today %lld %lld` | %1$lld of %2$lld today | Hoy: %1$lld de %2$lld | CelebrationView | ✅ |
| `game.colorclash.a11y.stimulus %@ %@` | Ink colour: %1$@, shape: %2$@ | Color de la tinta: %1$@, forma: %2$@ | ColorClashView |  |
| `game.colorclash.a11y.stimulus.hint` | The written word is a decoy. Tap the button with the ink colour. | La palabra escrita es un señuelo. Toca el botón con el color de la tinta. | ColorClashView |  |
| `game.colorclash.color.blue` | Blue | Azul | ColorClashView |  |
| `game.colorclash.color.green` | Green | Verde | ColorClashView |  |
| `game.colorclash.color.orange` | Orange | Naranja | ColorClashView |  |
| `game.colorclash.color.red` | Red | Rojo | ColorClashView |  |
| `game.colorclash.instruction` | Tap the color of the ink, not the word | Toca el color de la tinta, no la palabra | ColorClashView |  |
| `game.colorclash.shape.circle` | Circle | Círculo | ColorClashView |  |
| `game.colorclash.shape.diamond` | Diamond | Rombo | ColorClashView |  |
| `game.colorclash.shape.square` | Square | Cuadrado | ColorClashView |  |
| `game.colorclash.shape.triangle` | Triangle | Triángulo | ColorClashView |  |
| `game.colorclash.title` | Color Clash | Choque de Colores | GameID |  |
| `game.colorclash.word.blue` | BLUE | AZUL | ColorClashView |  |
| `game.colorclash.word.green` | GREEN | VERDE | ColorClashView |  |
| `game.colorclash.word.orange` | ORANGE | NARANJA | ColorClashView |  |
| `game.colorclash.word.red` | RED | ROJO | ColorClashView |  |
| `game.math.instruction` | Tap the correct answer | Toca la respuesta correcta | MathStreakView |  |
| `game.math.operator.dividedBy` | divided by | entre | NumberTrailQuestion |  |
| `game.math.operator.minus` | minus | menos | NumberTrailQuestion |  |
| `game.math.operator.plus` | plus | más | NumberTrailQuestion |  |
| `game.math.operator.times` | times | por | NumberTrailQuestion |  |
| `game.math.title` | Number Trail | Sendero de Números | GameID |  |
| `game.memory.a11y.matched` | Pair found | Pareja encontrada | MemoryMatchView |  |
| `game.memory.a11y.position %lld %lld` | Card %lld of %lld | Carta %lld de %lld | MemoryMatchView |  |
| `game.memory.card.hidden` | Hidden card | Carta oculta | MemoryMatchView |  |
| `game.memory.instruction` | Find the matching pairs | Encuentra las parejas | MemoryMatchView |  |
| `game.memory.photo %lld` | Family photo %lld | Foto familiar %lld | MemoryMatchView |  |
| `game.memory.title` | Memory Lane | Camino de Memoria | GameID |  |
| `game.quickeyes.a11y.flash %@` | Picture shown: %@ | Imagen mostrada: %@ | QuickEyesView |  |
| `game.quickeyes.almost` | Almost — let's slow down a touch | Casi — vamos un poquito más despacio | QuickEyesView |  |
| `game.quickeyes.instruction` | A picture flashes on screen. Look closely, then tap the one you saw | Aparecerá una imagen por un instante. Mírala bien y luego tócala | QuickEyesView |  |
| `game.quickeyes.prompt` | Which one did you see? | ¿Cuál viste? | QuickEyesView |  |
| `game.quickeyes.title` | Quick Eyes | Ojos Ágiles | GameID |  |
| `game.readaloud` | Read aloud | Leer en voz alta | GameHeader | ✅ |
| `game.readaloud.hint` | Reads the instructions out loud | Lee las instrucciones en voz alta | GameHeader | ✅ |
| `game.reminiscence.a11y.object` | A familiar object | Un objeto conocido | ReminiscenceView |  |
| `game.reminiscence.a11y.photo` | Family photo, no name yet | Foto de familia, todavía sin nombre | ReminiscenceView |  |
| `game.reminiscence.hear` | Hear it again | Escucharlo otra vez | ReminiscenceView |  |
| `game.reminiscence.next` | Next | Siguiente | ReminiscenceView |  |
| `game.reminiscence.prompt.object` | What is this? | ¿Qué es esto? | ReminiscenceView |  |
| `game.reminiscence.prompt.photo` | Who is this? | ¿Quién es? | ReminiscenceView |  |
| `game.reminiscence.show` | Show me | Muéstrame | ReminiscenceView |  |
| `game.reminiscence.title` | Remember Together | Recordar juntos | GameID |  |
| `game.reminiscence.together` | Let's look together | Veámoslo juntos | ReminiscenceView |  |
| `game.round.a11y %lld %lld` | Round %1$lld of %2$lld | Ronda %1$lld de %2$lld | RoundCounter |  |
| `game.sayings.a11y.listen` | Hear the saying | Escuchar el refrán | SayingsView |  |
| `game.sayings.instruction` | How does this saying end? | ¿Cómo termina este refrán? | SayingsView |  |
| `game.sayings.miss` | Almost — try again. | Casi — inténtalo de nuevo. | SayingsView |  |
| `game.sayings.next` | Next | Siguiente | SayingsView |  |
| `game.sayings.title` | Finish the Saying | Termina el refrán | GameID |  |
| `game.sequence.title` | Repeat the Sequence | Repite la secuencia | GameID |  |
| `game.sliding.title` | Sliding Blocks | Bloques deslizantes | GameID |  |
| `game.sudoku.a11y.cell %lld %lld %lld` | Row %1$lld, column %2$lld, %3$lld | Fila %1$lld, columna %2$lld, %3$lld | SudokuView |  |
| `game.sudoku.a11y.empty %lld %lld` | Row %1$lld, column %2$lld, empty | Fila %1$lld, columna %2$lld, vacío | SudokuView |  |
| `game.sudoku.a11y.put %lld` | Put %lld | Poner %lld | SudokuView |  |
| `game.sudoku.a11y.selected` | Selected | Seleccionado | SudokuView |  |
| `game.sudoku.done.box %lld` | Box %lld done | Bloque %lld completo | SudokuView |  |
| `game.sudoku.done.column %lld` | Column %lld done | Columna %lld completa | SudokuView |  |
| `game.sudoku.done.row %lld` | Row %lld done | Fila %lld completa | SudokuView |  |
| `game.sudoku.instruction` | Tap a square, then a number. | Toca un cuadro y luego un número. | SudokuView |  |
| `game.sudoku.miss` | Almost — try another number. | Casi — prueba otro número. | SudokuView |  |
| `game.sudoku.showme` | Show me one | Muéstrame uno | SudokuView |  |
| `game.sudoku.title` | Sudoku | Sudoku | GameID |  |
| `game.tangram.title` | Tangram | Tangram | GameID |  |
| `game.tilepairs.title` | Tile Pairs | Parejas de fichas | GameID |  |
| `game.upordown.a11y.card %@ %@` | %1$@ of %2$@ | %1$@ de %2$@ | UpOrDownView |  |
| `game.upordown.a11y.deck %lld` | Turn a new card, %lld left | Voltear una carta nueva, quedan %lld | UpOrDownView |  |
| `game.upordown.a11y.empty` | Empty pile | Montón vacío | UpOrDownView |  |
| `game.upordown.a11y.fits` | fits | sirve | UpOrDownView |  |
| `game.upordown.a11y.open %@` | Open card: %@ | Carta abierta: %@ | UpOrDownView |  |
| `game.upordown.instruction` | Tap a card one higher or one lower. | Toca una carta con uno más o uno menos. | UpOrDownView |  |
| `game.upordown.miss %@` | Almost — it needs one more or one less than %@. | Casi — necesita uno más o uno menos que %@. | UpOrDownView |  |
| `game.upordown.rank.1` | Ace | As | — |  |
| `game.upordown.rank.10` | 10 | 10 | — |  |
| `game.upordown.rank.11` | Jack | Jota | — |  |
| `game.upordown.rank.12` | Queen | Reina | — |  |
| `game.upordown.rank.13` | King | Rey | — |  |
| `game.upordown.rank.2` | 2 | 2 | — |  |
| `game.upordown.rank.3` | 3 | 3 | — |  |
| `game.upordown.rank.4` | 4 | 4 | — |  |
| `game.upordown.rank.5` | 5 | 5 | — |  |
| `game.upordown.rank.6` | 6 | 6 | — |  |
| `game.upordown.rank.7` | 7 | 7 | — |  |
| `game.upordown.rank.8` | 8 | 8 | — |  |
| `game.upordown.rank.9` | 9 | 9 | — |  |
| `game.upordown.stuck` | No card fits — turn a new one. | Ninguna carta sirve — voltea una nueva. | UpOrDownView |  |
| `game.upordown.suit.clubs` | clubs | tréboles | — |  |
| `game.upordown.suit.diamonds` | diamonds | diamantes | — |  |
| `game.upordown.suit.hearts` | hearts | corazones | — |  |
| `game.upordown.suit.spades` | spades | picas | — |  |
| `game.upordown.title` | Up or Down | Sube o baja | GameID |  |
| `history.day.times %lld` | one: once / other: %lld times | one: una vez / other: %lld veces | HistoryView |  |
| `history.days.header` | Day by day | Día a día | HistoryView |  |
| `history.empty` | No games yet this week. Pick a game and have some fun! | Aún no hay juegos esta semana. ¡Elige un juego y diviértete! | HistoryView |  |
| `history.progress.header` | Your games this week | Tus juegos esta semana | HistoryView |  |
| `history.progress.steady %@` | %@: steady and strong this week. | %@: firme y constante esta semana. | HistoryView |  |
| `history.progress.up %@` | %@ got a little more challenging, and you're ready for it. | %@ ahora es un poco más desafiante, ¡y lo manejas muy bien! | HistoryView |  |
| `history.share` | Share with family | Compartir con la familia | HistoryView, WeeklySummary |  |
| `history.share.days %lld` | 📅 Days played: %lld | 📅 Días que jugué: %lld | WeeklySummary |  |
| `history.share.games %lld` | 🎮 Games played: %lld | 🎮 Juegos jugados: %lld | WeeklySummary |  |
| `history.share.hint` | Sends this week's games as a message | Envía los juegos de esta semana como mensaje | HistoryView |  |
| `history.share.title` | 🌻 My week with MenteViva | 🌻 Mi semana con MenteViva | WeeklySummary |  |
| `history.summary %lld` | one: You played %lld time this week! 🌟 / other: You played %lld times this week! 🌟 | one: ¡Jugaste %lld vez esta semana! 🌟 / other: ¡Jugaste %lld veces esta semana! 🌟 | HistoryView |  |
| `history.title` | My Week | Mi Semana | HistoryView, HomeView |  |
| `history.today` | Today | Hoy | HistoryView |  |
| `history.yesterday` | Yesterday | Ayer | HistoryView |  |
| `home.allgames` | All games | Todos los juegos | HomeView | ✅ |
| `home.greeting` | Shall we play a game? | ¿Jugamos un rato? | HomeView, TodayRun |  |
| `home.greeting.afternoon` | Good afternoon | Buenas tardes | TodayRun | ✅ |
| `home.greeting.evening` | Good evening | Buenas noches | TodayRun | ✅ |
| `home.greeting.morning` | Good morning | Buenos días | TodayRun | ✅ |
| `home.today.badge` | Today's pick | Sugerido de hoy | — |  |
| `home.today.continue %@` | Keep going: %@ | Seguimos con %@ | HomeView | ✅ |
| `home.today.done` | Today's games are done. See you tomorrow! | ¡Listos los juegos de hoy! Hasta mañana. | HomeView | ✅ |
| `home.today.label` | Today's games | Los juegos de hoy | HomeView | ✅ |
| `home.today.play` | Start today's games | Empezar los juegos de hoy | GameCard, HomeView | ✅ |
| `home.today.played` | Played today | Jugado hoy | GameCard | ✅ |
| `home.today.togo %lld` | one: Nice! %lld more to go. / other: Nice! %lld more to go. | one: ¡Bien! Falta %lld. / other: ¡Bien! Faltan %lld. | HomeView | ✅ |
| `home.week.hint` | See what you played this week | Mira lo que jugaste esta semana | HomeView |  |
| `home.week.title` | This week | Esta semana | HomeView | ✅ |
| `level.explain.eased` | We made it a little calmer, so you enjoy it more. | Lo pusimos más tranquilo para que lo disfrutes más. | LevelPolicy |  |
| `level.explain.raised1` | We made it a little harder: you've been doing great. | Lo subimos un poquito: te ha ido muy bien. | LevelPolicy |  |
| `level.explain.raised2` | Two steps up: you're flying! | Subimos dos pasos: ¡vas volando! | LevelPolicy |  |
| `level.offer.keep` | Keep it as it is | Así está bien | CelebrationView |  |
| `level.offer.prompt` | That was perfect. Shall we try the next level? | ¡Te salió perfecto! ¿Probamos el siguiente nivel? | CelebrationView |  |
| `level.offer.yes` | Yes, let's try | Sí, probemos | CelebrationView |  |
| `object.book` | Book | Libro | EverydayObjects |  |
| `object.chair` | Chair | Silla | EverydayObjects |  |
| `object.clock` | Clock | Reloj | EverydayObjects |  |
| `object.cup` | Cup | Taza | EverydayObjects |  |
| `object.house` | House | Casa | EverydayObjects |  |
| `object.key` | Key | Llave | EverydayObjects |  |
| `object.lamp` | Lamp | Lámpara | EverydayObjects |  |
| `object.umbrella` | Umbrella | Paraguas | EverydayObjects |  |
| `onboarding.disclaimer` | This is not a medical device. | No es un dispositivo médico. | OnboardingView |  |
| `onboarding.line1` | Fun mental exercise. | Ejercicio mental divertido. | OnboardingView |  |
| `onboarding.line2` | No rush, no pressure. | Sin prisa y sin presión. | OnboardingView |  |
| `onboarding.line3` | Pick a game and start. | Elige un juego y empieza. | OnboardingView |  |
| `onboarding.start` | Let's play | A jugar | OnboardingView |  |
| `onboarding.start.hint` | Opens the games | Abre los juegos | OnboardingView |  |
| `progress.accuracy %lld` | On average, %lld%% right each game | En promedio, %lld%% de aciertos por juego | MyProgressView |  |
| `progress.days %lld` | Played on %lld of the last 7 days | Jugaste %lld de los últimos 7 días | MyProgressView |  |
| `progress.empty` | No games in the last 7 days yet. Whenever you play, it shows up here. | Todavía no hay juegos en los últimos 7 días. Cuando juegues, aparecerá aquí. | MyProgressView |  |
| `progress.intro` | Your last 7 days on this device. Each game is compared only with your own earlier weeks. These numbers appear only here, unless you share them. | Tus últimos 7 días en este dispositivo. Cada juego se compara solo con tus propias semanas anteriores. Estos números solo aparecen aquí, a menos que tú los compartas. | MyProgressView |  |
| `progress.level %@` | Level reached: %@ | Nivel alcanzado: %@ | MyProgressView |  |
| `progress.open.hint` | How your games went this week, on this device | Cómo te fue en los juegos esta semana, en este dispositivo | SettingsView |  |
| `progress.plays %lld` | one: Played %lld time this week / other: Played %lld times this week | one: Jugaste %lld vez esta semana / other: Jugaste %lld veces esta semana | MyProgressView |  |
| `progress.share %lld` | %lld%% of this week's games | %lld%% de los juegos de esta semana | MyProgressView |  |
| `progress.share.header` | Played this week | Jugados esta semana | MyProgressView |  |
| `progress.title` | My progress | Mi progreso | MyProgressView, SettingsView |  |
| `progress.trend.accuracy.down` | A few fewer right answers than in your earlier weeks | Algunos aciertos menos que en tus semanas anteriores | MyProgressView |  |
| `progress.trend.accuracy.steady` | About the same as your earlier weeks | Más o menos igual que en tus semanas anteriores | MyProgressView |  |
| `progress.trend.accuracy.up` | More right answers than in your earlier weeks | Más aciertos que en tus semanas anteriores | MyProgressView |  |
| `progress.trend.first` | No earlier week of this game to compare with yet. | Todavía no hay una semana anterior de este juego para comparar. | MyProgressView |  |
| `progress.trend.level.down %@` | An easier level than your earlier weeks: now %@ | Un nivel más fácil que en tus semanas anteriores: ahora %@ | MyProgressView |  |
| `progress.trend.level.up %@` | A level up from your earlier weeks: now %@ | Un nivel más que en tus semanas anteriores: ahora %@ | MyProgressView |  |
| `progress.trend.wait %lld` | After %lld games this week, you'll see how it compares with your earlier weeks. | Después de %lld juegos esta semana, verás cómo se compara con tus semanas anteriores. | MyProgressView |  |
| `saying.01.end` | is worth two in the bush | que ciento volando | — |  |
| `saying.01.start` | A bird in the hand | Más vale pájaro en mano | — |  |
| `saying.02.end` | seldom bite | no muerde | — |  |
| `saying.02.start` | Barking dogs | Perro que ladra | — |  |
| `saying.03.end` | catches the worm | se lo lleva la corriente | — |  |
| `saying.03.start` | The early bird | Camarón que se duerme | — |  |
| `saying.04.end` | in the mouth | no se le mira el diente | — |  |
| `saying.04.start` | Don't look a gift horse | A caballo regalado | — |  |
| `saying.05.end` | the mice will play | los ratones bailan | — |  |
| `saying.05.start` | When the cat's away | Cuando el gato no está | — |  |
| `saying.06.end` | lie | no entran moscas | — |  |
| `saying.06.start` | Let sleeping dogs | En boca cerrada | — |  |
| `saying.07.end` | does not make a summer | no hace verano | — |  |
| `saying.07.start` | One swallow | Una golondrina | — |  |
| `saying.08.end` | flock together | del agua fría huye | — |  |
| `saying.08.start` | Birds of a feather | Gato escaldado | — |  |
| `saying.09.end` | is a penny earned | es don Dinero | — |  |
| `saying.09.start` | A penny saved | Poderoso caballero | — |  |
| `saying.10.end` | grow on trees | sino el que menos necesita | — |  |
| `saying.10.start` | Money doesn't | No es más rico el que más tiene | — |  |
| `saying.11.end` | in one basket | siempre tiene | — |  |
| `saying.11.start` | Don't put all your eggs | Quien guarda | — |  |
| `saying.12.end` | what you pay for | sale caro | — |  |
| `saying.12.start` | You get | Lo barato | — |  |
| `saying.13.end` | is not gold | la felicidad | — |  |
| `saying.13.start` | All that glitters | El dinero no da | — |  |
| `saying.14.end` | than sorry | que lamentar | — |  |
| `saying.14.start` | Better safe | Más vale prevenir | — |  |
| `saying.15.end` | nor a lender be | amistades largas | — |  |
| `saying.15.start` | Neither a borrower | Cuentas claras | — |  |
| `saying.16.end` | in a day | amanece más temprano | — |  |
| `saying.16.start` | Rome wasn't built | No por mucho madrugar | — |  |
| `saying.17.end` | than never | que nunca | — |  |
| `saying.17.start` | Better late | Más vale tarde | — |  |
| `saying.18.end` | what you can do today | lo que puedas hacer hoy | — |  |
| `saying.18.start` | Don't put off till tomorrow | No dejes para mañana | — |  |
| `saying.19.end` | is money | es oro | — |  |
| `saying.19.start` | Time | El tiempo | — |  |
| `saying.20.end` | wait for no man | Dios lo ayuda | — |  |
| `saying.20.start` | Time and tide | A quien madruga | — |  |
| `saying.21.end` | wins the race | se va lejos | — |  |
| `saying.21.start` | Slow and steady | Poco a poco | — |  |
| `saying.22.end` | like the present | a su tiempo | — |  |
| `saying.22.start` | There's no time | Cada cosa | — |  |
| `saying.23.end` | saves nine | que rondar un año | — |  |
| `saying.23.start` | A stitch in time | Más vale llegar a tiempo | — |  |
| `saying.24.end` | spoil the broth | y el chocolate espeso | — |  |
| `saying.24.start` | Too many cooks | Las cosas claras | — |  |
| `saying.25.end` | and eat it too | y al vino, vino | — |  |
| `saying.25.start` | You can't have your cake | Al pan, pan | — |  |
| `saying.26.end` | is in the eating | se anda el camino | — |  |
| `saying.26.start` | The proof of the pudding | Con pan y vino | — |  |
| `saying.27.end` | the best sauce | no hay pan duro | — |  |
| `saying.27.start` | Hunger is | A buen hambre | — |  |
| `saying.28.end` | is better than none | comen tres | — |  |
| `saying.28.start` | Half a loaf | Donde comen dos | — |  |
| `saying.29.end` | over spilled milk | corazón contento | — |  |
| `saying.29.start` | Don't cry | Panza llena | — |  |
| `saying.30.end` | is the spice of life | y cebolla | — |  |
| `saying.30.start` | Variety | Contigo pan | — |  |
| `saying.31.end` | is sauce for the gander | saben a beso | — |  |
| `saying.31.start` | What's sauce for the goose | Uvas con queso | — |  |
| `saying.32.end` | there's a way | algo le cuesta | — |  |
| `saying.32.start` | Where there's a will | El que algo quiere | — |  |
| `saying.33.end` | make light work | a la obra | — |  |
| `saying.33.start` | Many hands | Manos | — |  |
| `saying.34.end` | makes perfect | y no mires a quién | — |  |
| `saying.34.start` | Practice | Haz bien | — |  |
| `saying.35.end` | try, try again | la consigue | — |  |
| `saying.35.start` | If at first you don't succeed | El que la sigue | — |  |
| `saying.36.end` | makes Jack a dull boy | es poder | — |  |
| `saying.36.start` | All work and no play | Querer | — |  |
| `saying.37.end` | master of none | a tus zapatos | — |  |
| `saying.37.start` | Jack of all trades | Zapatero | — |  |
| `saying.38.end` | louder than words | que no buenas razones | — |  |
| `saying.38.start` | Actions speak | Obras son amores | — |  |
| `saying.39.end` | has a silver lining | buena cara | — |  |
| `saying.39.start` | Every cloud | Al mal tiempo | — |  |
| `saying.40.end` | comes the calm | llega la calma | — |  |
| `saying.40.start` | After the storm | Después de la tormenta | — |  |
| `saying.41.end` | bring May flowers | aguas mil | — |  |
| `saying.41.start` | April showers | En abril | — |  |
| `saying.42.end` | but it pours | a gusto de todos | — |  |
| `saying.42.start` | It never rains | Nunca llueve | — |  |
| `saying.43.end` | while the sun shines | no te quites el sayo | — |  |
| `saying.43.start` | Make hay | Hasta el cuarenta de mayo | — |  |
| `saying.44.end` | sailor's delight | suelo mojado | — |  |
| `saying.44.start` | Red sky at night | Cielo empedrado | — |  |
| `saying.45.end` | twice in the same place | déjala correr | — |  |
| `saying.45.start` | Lightning never strikes | Agua que no has de beber | — |  |
| `saying.46.end` | is a friend indeed | y te diré quién eres | — |  |
| `saying.46.start` | A friend in need | Dime con quién andas | — |  |
| `saying.47.end` | are better than one | tiene un tesoro | — |  |
| `saying.47.start` | Two heads | Quien tiene un amigo | — |  |
| `saying.48.end` | conquers all | se paga | — |  |
| `saying.48.start` | Love | Amor con amor | — |  |
| `saying.49.end` | than in bad company | que mal acompañado | — |  |
| `saying.49.start` | Better alone | Más vale solo | — |  |
| `saying.50.end` | grow fonder | hace el cariño | — |  |
| `saying.50.start` | Absence makes the heart | El roce | — |  |
| `saying.51.end` | as you'd like to be treated | es amigo de verdad | — |  |
| `saying.51.start` | Treat others | Amigo en la adversidad | — |  |
| `saying.52.end` | deserves another | mañana por mí | — |  |
| `saying.52.start` | One good turn | Hoy por ti | — |  |
| `saying.53.end` | the merrier | que cien parientes | — |  |
| `saying.53.start` | The more | Más vale un amigo | — |  |
| `saying.54.end` | is where the heart is | y Dios en la de todos | — |  |
| `saying.54.start` | Home | Cada uno en su casa | — |  |
| `saying.55.end` | like home | cuchillo de palo | — |  |
| `saying.55.start` | There's no place | En casa del herrero | — |  |
| `saying.56.end` | home | hogar | — |  |
| `saying.56.start` | Home sweet | Hogar, dulce | — |  |
| `saying.57.end` | far from the tree | tal astilla | — |  |
| `saying.57.start` | The apple doesn't fall | De tal palo | — |  |
| `saying.58.end` | begins at home | empieza por casa | — |  |
| `saying.58.start` | Charity | La caridad bien entendida | — |  |
| `saying.59.end` | is his castle | es un mundo | — |  |
| `saying.59.start` | A man's home | Cada casa | — |  |
| `saying.60.end` | shouldn't throw stones | casa quiere | — |  |
| `saying.60.start` | People who live in glass houses | Quien se casa | — |  |
| `settings.done` | Done | Listo | FamilyPhotoCaptionSheet, SettingsView |  |
| `settings.language` | Language | Idioma | AppLanguage, SettingsView |  |
| `settings.language.restart` | The language changes right away. | El idioma cambia al instante. | SettingsView |  |
| `settings.language.system` | Device | Sistema | AppLanguage |  |
| `settings.open.hint` | Language, bigger text and privacy | Idioma, texto más grande y privacidad | HomeView |  |
| `settings.privacy.backup %@` | If you back up this %@, the backup keeps them too. | Si haces copia de seguridad de este %@, la copia también los guarda. | SettingsView |  |
| `settings.privacy.device %@` | Your games stay on this %@. | Tus juegos se quedan en este %@. | SettingsView |  |
| `settings.privacy.noaccount` | No account, no ads, no tracking. | Sin cuenta, sin anuncios, sin rastreo. | SettingsView |  |
| `settings.privacy.photos` | Your photos and their names never leave it. | Tus fotos y sus nombres nunca salen de aquí. | SettingsView |  |
| `settings.privacy.title` | Your privacy | Tu privacidad | SettingsView |  |
| `settings.sound` | Sound & haptics | Sonido y vibración | SettingsView |  |
| `settings.sound.hint` | Gentle tones and taps | Tonos y toques suaves | SettingsView |  |
| `settings.speak` | Read names aloud | Leer los nombres en voz alta | SettingsView |  |
| `settings.speak.hint` | Says the name out loud when you tap Show me in Remember Together. Off by default. | Dice el nombre en voz alta cuando tocas Muéstrame en Recordar juntos. Desactivado de forma predeterminada. | SettingsView |  |
| `settings.textsize` | Bigger text | Texto más grande | SettingsView |  |
| `settings.title` | Settings | Ajustes | HomeView, SettingsView |  |
| `settings.version` | Version | Versión | SettingsView |  |
| `setup.open.hint` | Which games show, their difficulty, and Memory Lane photos | Qué juegos se muestran, su dificultad y las fotos de Camino de Memoria | SettingsView |  |
| `setup.title` | Set up | Ajustes de juego | SetUpView, SettingsView |  |
