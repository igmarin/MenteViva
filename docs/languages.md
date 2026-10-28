# Next languages: shortlist and validators (#40)

MenteViva ships in English and Spanish. This is the shortlist for the next
language, measured on 2026-10-28.

**The rule (owner gate):** a language ships only when a named native speaker
has reviewed every string, the way Spanish was reviewed
([es-review-packet.md](es-review-packet.md), #12). A translation nobody can
check is a liability, so a row with an empty Validator column is not
started.

**Size of the job:** 614 strings, about 2,190 English words, 14 of them with
plural variants (`MenteViva/Localizable.xcstrings`, 2026-10-28). Each new
language also needs its own review packet.

## Shortlist, best first

Order: (people 65+ × iOS share) ÷ effort, with S = 1, M = 2, L = 4.

| # | Language | People 65+ (2025) | iOS share, mobile | Main stores | Effort | Validator |
|---|---|---|---|---|---|---|
| 1 | Japanese | 37.0M Japan [^wb-jpn] | 60.5% [^sc-jp] | Japan | **M**: CJK text sets wider per character, so it needs a line-break and font pass [^w3c]; 1 plural form [^cldr] | |
| 2 | Portuguese (Brazil) | 24.4M Brazil, 2.7M Portugal [^wb-pt] | 24.5% BR, 32.7% PT [^sc-br] [^sc-pt] | Brazil, Portugal | **S**: Latin script, same plural forms as Spanish [^cldr] | |
| 3 | French | 15.5M France [^wb-fra] | 35% [^sc-fr] | France, Belgium, Canada, Switzerland | **S**: same plural forms as Spanish [^cldr]; text grows about as much as Spanish | |
| 4 | Italian | 14.8M Italy [^wb-ita] | 35.0% [^sc-it] | Italy, Switzerland | **S**: same plural forms as Spanish [^cldr]; short labels can grow a lot [^w3c] | |
| 5 | German | 19.8M Germany, 1.9M Austria [^wb-de] | 27.6% [^sc-de] | Germany, Austria, Switzerland | **M**: long compound words break 100pt buttons at large text sizes [^w3c]; needs a layout pass | |
| 6 | Korean | 10.5M Korea [^wb-kor] | 37.8% [^sc-kr] | South Korea | **M**: Hangul font and line-break pass; 1 plural form [^cldr] | |
| 7 | Polish | 7.6M Poland [^wb-pol] | 36.2% [^sc-pl] | Poland | **M**: 4 plural forms, so all 14 plural strings need new variants [^cldr] | |

**Not on the list:**
- **Chinese (Simplified).** China has 209.7M people aged 65+ [^wb-chn], but games
  there need a government approval number before they can be listed [^apple-cn].
  That is a licence problem, not a translation one.
- **Dutch.** It would be easy (S), but the Netherlands has only 3.8M people aged
  65+ [^wb-nld].

## Decisions each language needs before translating

- **Formality:** Spanish uses *usted*. French needs *vous* or *tu*, Japanese a
  politeness level, German *Sie* or *du*. The validator decides.
- **Regional variant:** Brazil first, Portugal later; pt-BR and pt-PT differ.

## Caveats

- **Age measure:** population is 65+, because the source gives 65+ per
  country, not 60+. It comes from World Bank SP.POP.65UP.TO, which is built
  on UN World Population Prospects.
- **iOS share:** these are StatCounter figures for September 2026 web traffic
  across all ages (Brazil and Italy: August). No per-country source covers
  older adults only. Treat them as ±5 points, because monthly snapshots
  disagree (Poland showed 18.9% in September 2024).
- **Text growth:** general W3C guidance, not measured on our strings.
  [es-review-packet.md](es-review-packet.md) is the only measure from this
  app: Spanish runs about 20% longer than English.

[^wb-jpn]: https://api.worldbank.org/v2/country/JPN/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-pt]: https://api.worldbank.org/v2/country/BRA;PRT/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-fra]: https://api.worldbank.org/v2/country/FRA/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-ita]: https://api.worldbank.org/v2/country/ITA/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-de]: https://api.worldbank.org/v2/country/DEU;AUT/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-kor]: https://api.worldbank.org/v2/country/KOR/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-pol]: https://api.worldbank.org/v2/country/POL/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-chn]: https://api.worldbank.org/v2/country/CHN/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^wb-nld]: https://api.worldbank.org/v2/country/NLD/indicator/SP.POP.65UP.TO?format=json&mrnev=1
[^sc-jp]: https://gs.statcounter.com/os-market-share/mobile/japan
[^sc-br]: https://gs.statcounter.com/os-market-share/mobile/brazil
[^sc-pt]: https://gs.statcounter.com/os-market-share/mobile/portugal
[^sc-fr]: https://gs.statcounter.com/os-market-share/mobile/france
[^sc-it]: https://gs.statcounter.com/os-market-share/mobile/italy
[^sc-de]: https://gs.statcounter.com/os-market-share/mobile/germany
[^sc-kr]: https://gs.statcounter.com/os-market-share/mobile/south-korea
[^sc-pl]: https://gs.statcounter.com/os-market-share/mobile/poland
[^cldr]: https://www.unicode.org/cldr/charts/latest/supplemental/language_plural_rules.html
[^w3c]: https://www.w3.org/International/articles/article-text-size
[^apple-cn]: https://developer.apple.com/help/app-store-connect/reference/app-information/
