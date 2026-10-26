# Why these games — words for review (#210)

Draft copy for the "Why these games" section, EN and ES side by side. **Not wired to any screen yet:**
the owner approves the text in the issue first, then the screen ticket starts. Keys are ready for
`Localizable.xcstrings` (`why.*`, EN + ES in the same commit, conventions §3).

Rules this text follows (`research-2026-09.md` §1, `statistics-rationale.md` §4): a game *exercises*,
it never promises; no percentages; no score or "age" of any kind; nothing about disease. Each part is
short enough for one phone screen. The "Source" column is for the doc and for a "Read more" link; the
app lines themselves stay plain.

Sources are the ones already in the repo's research docs. Nothing new was added.

- CCT = `https://pmc.ncbi.nlm.nih.gov/articles/PMC4236015/` (meta-analysis of 51 studies)
- Simons 2016 = `https://journals.sagepub.com/doi/10.1177/1529100616661983`
- Stanford 2014 = `https://longevity.stanford.edu/a-consensus-on-the-brain-training-industry-from-the-scientific-community/`

---

## 1. What the research says

| Key | English | Español | Source |
|---|---|---|---|
| `why.research.title` | What the research says | Lo que dice la investigación | n/a |
| `why.research.small` | In studies of older adults, computer games led to small gains, mostly on the very tasks people practised. | En estudios con personas mayores, los juegos de computadora dieron pequeños avances, sobre todo en las mismas tareas que se practicaron. | [CCT](https://pmc.ncbi.nlm.nih.gov/articles/PMC4236015/) |
| `why.research.transfer` | Whether that carries over to everyday life has not been shown. | Que eso se note después en la vida diaria no se ha demostrado. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) |
| `why.research.stanford` | In 2014, about 70 scientists wrote that there is "no compelling scientific evidence" for what brain games promise in daily life. | En 2014, unos 70 científicos escribieron que "no hay pruebas científicas convincentes" de lo que los juegos mentales prometen en la vida diaria. | [Stanford 2014](https://longevity.stanford.edu/a-consensus-on-the-brain-training-industry-from-the-scientific-community/) |
| `why.research.varied` | Another expert group, the Global Council on Brain Health, says that new, varied and shared activities matter too, and that games can be one part of a full day. | Otro grupo de expertos, el Global Council on Brain Health, dice que también cuentan las actividades nuevas, variadas y compartidas, y que los juegos pueden ser una parte de un día completo. | [Global Council on Brain Health](https://www.globalcouncilonbrainhealth.org/) |
| `why.research.bundle` | One large study of people aged 60 to 77 looked at games together with food, movement and a healthy routine, not games alone. | Un estudio grande con personas de 60 a 77 años miró los juegos junto con la comida, el movimiento y una rutina sana, no los juegos solos. | [FINGER](https://doi.org/10.1016/S0140-6736(15)60461-5) |
| `why.research.promise` | So we promise you nothing. We offer pleasant mental exercise, at your pace. | Por eso no te prometemos nada. Te ofrecemos un ejercicio mental agradable, a tu ritmo. | `statistics-rationale.md` §5 (our own policy, not a finding) |

## 2. What each game exercises

One line per game, 13 in all. "Exercises" is the only verb used.

| Key | English | Español | Source |
|---|---|---|---|
| `why.games.title` | What each game exercises | Qué ejercita cada juego | n/a |
| `why.game.memory` | **Memory Lane** exercises remembering where things are. | **Camino de Memoria** ejercita recordar dónde está cada cosa. | [CCT](https://pmc.ncbi.nlm.nih.gov/articles/PMC4236015/) (episodic memory) |
| `why.game.colorclash` | **Color Clash** exercises paying attention to what matters and ignoring the rest. | **Choque de Colores** ejercita fijarse en lo importante y dejar pasar lo demás. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) (attention, inhibition) |
| `why.game.category` | **Name the Herd** exercises finding words. | **Nombra la Manada** ejercita encontrar palabras. | [Fluency](https://pmc.ncbi.nlm.nih.gov/articles/PMC3394709/) |
| `why.game.math` | **Number Trail** exercises quick, easy sums. | **Sendero de Números** ejercita las cuentas sencillas y rápidas. | No source in the research docs, so this line only **describes the game** (see note A) |
| `why.game.quickeyes` | **Quick Eyes** exercises noticing things quickly. | **Ojos Ágiles** ejercita fijarse en las cosas con rapidez. | [Processing speed](https://pmc.ncbi.nlm.nih.gov/articles/PMC5700828/) |
| `why.game.reminiscence` | **Remember Together** is a chance to enjoy your own photos and talk about them with someone. There are no right or wrong answers. | **Recordar juntos** es una ocasión para disfrutar tus fotos y conversar sobre ellas con alguien. No hay respuestas buenas ni malas. | Describes the game; sharing as a good ingredient: [Global Council on Brain Health](https://www.globalcouncilonbrainhealth.org/) |
| `why.game.sudoku` | **Sudoku** exercises planning and thinking one step ahead. | **Sudoku** ejercita planear y pensar un paso adelante. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) (executive function) |
| `why.game.upordown` | **Up or Down** exercises planning your next card. | **Sube o baja** ejercita planear tu próxima carta. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) (executive function) |
| `why.game.sayings` | **Finish the Saying** exercises finding words you already know. | **Termina el refrán** ejercita encontrar palabras que ya conoces. | [Fluency](https://pmc.ncbi.nlm.nih.gov/articles/PMC3394709/) |
| `why.game.sequence` | **Repeat the Sequence** exercises holding a few things in mind at once. | **Repite la secuencia** ejercita tener varias cosas en mente a la vez. | [Working memory](https://pubmed.ncbi.nlm.nih.gov/22612437/) |
| `why.game.tangram` | **Tangram** exercises planning how shapes fit together. | **Tangram** ejercita planear cómo encajan las formas. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) (executive function) |
| `why.game.tilepairs` | **Tile Pairs** exercises looking closely and spotting matches. | **Pares de fichas** ejercita mirar con atención y encontrar parejas. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) (attention) |
| `why.game.sliding` | **Sliding Blocks** exercises planning your moves before you make them. | **Bloques deslizantes** ejercita planear los movimientos antes de hacerlos. | [Simons 2016](https://journals.sagepub.com/doi/10.1177/1529100616661983) (executive function) |

Notes for the reviewer:

- **A.** The research docs have no source for numeracy. Number Trail's line (`why.game.math`) is therefore
  kept to what you do: *"…exercises quick, easy sums."* If that still reads as a claim, the safe
  alternative is *"In Number Trail you follow a trail of easy sums."*
- **B.** The docs map executive function, attention and inhibition to one broad review (Simons 2016),
  not to these exact games. Placing Sudoku, Up or Down, Tangram, Tile Pairs and Sliding Blocks under those
  headings is a design judgement; the owner may prefer plain "what you do" lines for them.
- **C.** Spanish names of the four new games (Repite la secuencia, Tangram, Pares de fichas, Bloques
  deslizantes) are proposals; use the final names from each game's issue when they differ.
- **D.** The Global Council on Brain Health link is the organisation's home page. The docs mark a direct
  link to its 2019 report as unverified.

## 3. What MenteViva is not

| Key | English | Español | Source |
|---|---|---|---|
| `why.not.title` | What MenteViva is not | Lo que MenteViva no es | n/a |
| `why.not.device` | MenteViva is not a medical device. | MenteViva no es un dispositivo médico. | [FDA wellness policy](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices) |
| `why.not.test` | It is not a test. It never gives you a result about your mind, and it never gives a diagnosis. | No es una prueba. Nunca te da un resultado sobre tu mente ni un diagnóstico. | `research-2026-09.md` §5 item 2 (our own policy, not a finding) |
| `why.not.advice` | This is educational information, not medical advice. | Esta es información educativa, no consejo médico. | [FDA wellness policy](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices) |
| `why.not.doctor` | If something worries you about your memory, please talk to a doctor. | Si algo te preocupa de tu memoria, habla con un médico. | `research-2026-09.md` §5 item 1 (our own policy, not a finding) |
| `why.not.fun` | MenteViva is a fun mental exercise. We hope it gives you a good moment each day. | MenteViva es un ejercicio mental divertido. Esperamos que te dé un buen rato cada día. | `statistics-rationale.md` §4 (copy ceiling) |

---

## Checks

- The banned words (issue #210 acceptance grep) appear nowhere in this file, not even in quotes.
- Every row has a source link, or says it is our own policy, or says it only describes the game.
