# MenteViva Research — 2026-09

Internal research, not marketing: nothing here may reach a user as a claim (copy ceiling: "fun mental exercise"; see statistics-rationale.md §4). Terse, cited, decision-oriented. Every claim has a URL; unverifiable items are marked [UNVERIFIED]. App Store data scanned 2026-09 (US storefront).

## 1. AUDIENCE

**Who benefits (per current evidence):**

| Population | Verdict | Source |
|---|---|---|
| Healthy older adults | Small near-transfer gains on trained tasks; far transfer to daily life weak/unproven. Overall CCT effect small (g≈0.22) in meta-analysis of 51 studies. | https://pmc.ncbi.nlm.nih.gov/articles/PMC4236015/ |
| MCI | Small–moderate improvements across domains; best-supported target population for CCT. | https://pubmed.ncbi.nlm.nih.gov/27838936/ |
| Established dementia | No reliable benefit shown in the same meta-analysis; evidence base is thin. | https://pubmed.ncbi.nlm.nih.gov/27838936/ |
| Early-stage (mild) dementia | Unclear: the evidence sits between the MCI and dementia rows and is not established for computer games. We design for this player (errorless, familiar, calm) as a kindness, not on an efficacy claim, and the product stays "fun mental exercise". | (no direct source; see rows above) |
| General public (younger) | Not MenteViva's market; evidence is for 60+. | https://journals.sagepub.com/doi/10.1177/1529100616661983 |

**Transfer to daily life — the big studies:**

- **ACTIVE (N=2,802, 10-yr follow-up):** speed-of-processing arm was followed by lower dementia incidence (22.7% vs 28.8% control, a 29% relative difference), dose-dependent; memory and reasoning arms showed no dementia benefit. Strongest single result in the field. https://pmc.ncbi.nlm.nih.gov/articles/PMC5700828/
- **2014 Stanford/Max Planck consensus (70 scientists):** "no compelling scientific evidence" brain games improve everyday cognition or prevent decline; ads exploiting seniors' anxieties called out. This is the scientific mainstream. https://longevity.stanford.edu/a-consensus-on-the-brain-training-industry-from-the-scientific-community/
- **2019 GCBH/AARP "Engage Your Brain" report:** novel, challenging, socially embedded activities > repetitive brain games; games fine as one ingredient. [UNVERIFIED direct report URL; org: https://www.globalcouncilonbrainhealth.org/]
- **FINGER (n=1,260, ages 60–77, 2 yr):** multidomain (diet+exercise+cognitive training+vascular) improved cognition vs control (NTB z-score +0.022/yr, p=0.030) — supports bundling games with lifestyle framing, not games-alone claims. https://doi.org/10.1016/S0140-6736(15)60461-5

**Regulatory landmines:**

- **FDA:** "General wellness" = low-risk, enforcement-discretion safe ONLY if claims stay lifestyle-level. Any claim to diagnose, treat, mitigate, or *prevent* dementia/Alzheimer's/MCI = medical device, triggers regulation. 21st Century Cures Act §520(o)(1)(B) explicitly excludes only software "unrelated to the diagnosis, cure, mitigation, prevention, or treatment of a disease." https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices
- **FTC precedent:** Lumosity paid $2M (suspended $50M judgment) in 2016 for unsubstantiated claims about real-world performance and age-related decline. Health claims need "competent and reliable scientific evidence." https://www.ftc.gov/news-events/news/press-releases/2016/01/lumosity-pay-2-million-settle-ftc-deceptive-advertising-charges-its-brain-training-program
- **App Store 1.4.1 (Medical apps):** "Medical apps that could provide inaccurate data or information, or that could be used for diagnosing or treating patients may be reviewed with greater scrutiny." Keep MenteViva out of "diagnosis" territory: no screening scores, no cutoffs, no "cognitive age" medical framing. https://developer.apple.com/app-store/review/guidelines/
- **DECISION:** Marketing copy ceiling = "fun mental exercise / stay engaged." Never: memory-loss reversal, dementia prevention, MCI treatment, clinical screening.


## 2. GAME DOMAINS

Ranked by evidence strength in older adults:

1. **Processing speed** — strongest: ACTIVE 10-yr dementia signal + broad transfer (IADL, driving, quality of life). Mechanic: time-limited visual discrimination w/ shrinking display time (build your own; UFOV® is licensed). https://pmc.ncbi.nlm.nih.gov/articles/PMC5700828/
2. **Working memory** — near transfer reliable, far transfer unproven (Melby-Lervåg & Hulme 2013, 23 studies). Mechanic: N-back, adaptive sequence recall. https://pubmed.ncbi.nlm.nih.gov/22612437/
3. **Episodic memory** — trains in healthy older adults; strategy-based training (method of loci) persists but rarely transfers beyond memory tasks. https://pmc.ncbi.nlm.nih.gov/articles/PMC4236015/
4. **Executive function / inhibition** — improves on trained tasks; far transfer inconsistent. Mechanic: Stroop, task-switching, go/no-go. https://journals.sagepub.com/doi/10.1177/1529100616661983
5. **Verbal fluency** — least studied as training target; more a language/social exercise. Mechanic: category naming under time pressure (ES-friendly: "cosas de la cocina"). https://pmc.ncbi.nlm.nih.gov/articles/PMC3394709/

**Design implication:** anchor on speed + WM + episodic; treat fluency/executive as variety, not claims.

## 3. LICENSING

Paradigms are public-domain *science*; specific commercial implementations and clinical tests are protected. You can build your own versions of everything below except the last rows.

| Paradigm | Status | Can we build? | Source |
|---|---|---|---|
| Stroop task | Published 1935 (J. Exp. Psychol.); the method itself is not protected IP. | ✅ Yes | https://en.wikipedia.org/wiki/Stroop_effect |
| N-back | Published 1958 (Kirchner); paradigm free. CogMed's *product* is trademarked, not the paradigm. | ✅ Yes | https://en.wikipedia.org/wiki/N-back |
| Dual-task paradigms | Generic experimental method; no single owner. | ✅ Yes | https://journals.sagepub.com/doi/10.1177/1529100616661983 |
| Corsi blocks | Published 1970s (Corsi/Milner); free paradigm. | ✅ Yes | https://en.wikipedia.org/wiki/Corsi_block-tapping_test |
| Trail-Making Test (A/B) | Reitan's original (1944/1958) is public domain as a method; do NOT copy the exact paper form layout (some printed versions copyrighted). Implement your own layout. | ⚠️ Yes, w/ own layout | https://en.wikipedia.org/wiki/Trail_Making_Test |
| UFOV® speed-of-processing | Trademarked/licensed (U. of Alabama/Posit Science). ACTIVE's specific task is licensed to BrainHQ. | ❌ No (build generic speed tasks instead) | https://www.brainhq.com/ |
| MoCA | Copyrighted; mandatory training/certification since 2019; development of any electronic version prohibited; commercial use requires written license. | ❌ No | https://mocacognition.com/permission/ |
| Lumosity/BrainHQ/CogMed games | Copyrighted expressions + trademarks; never clone art, names, or game flow. | ❌ No | https://www.lumosity.com/legal/terms_of_service |

**Rule:** paradigm = free; name, exact stimuli, scoring norms, and branding = protected.

## 4. PRICING (App Store US, scanned 2026-09)

| App | Model | Price points | Rating | Source |
|---|---|---|---|---|
| Lumosity | Freemium sub | $11.99/mo, $89/yr (also $54.99 tiers, $14.99 legacy mo) | 4.7 / 130K | https://apps.apple.com/us/app/lumosity-brain-training/id577232024 |
| Elevate | Freemium sub | $39.99/yr (7–14 day trial), $4.99–9.99/mo tiers | 4.8 / 542K | https://apps.apple.com/us/app/elevate-brain-training/id875063456 |
| Peak | Freemium sub + free edu modules | $34.99/yr, $4.99/mo (promo $19.99/yr, $2.99/mo) | 4.7 / 146K | https://apps.apple.com/us/app/peak-brain-training/id806223188 |
| Impulse | Freemium sub, aggressive promos | $9.99/wk, $6.99/mo, $39.99–49.99/yr (promo $29.49/yr) | 4.7 / 849K | https://apps.apple.com/us/app/impulse-brain-training/id1451295827 |
| CogniFit | Freemium sub | $9.99/mo, $59.99/yr | 4.5 / 1.7K | https://itunes.apple.com/search?term=CogniFit&entity=software&country=US |
| BrainHQ | Freemium sub | $13.99/mo, $94.99/yr | 4.6 / 22K | https://itunes.apple.com/search?term=BrainHQ&entity=software&country=US |
| Senior-focused (e.g. NeuroNation "seniors" mode) | Freemium sub, ~$40–70/yr | [UNVERIFIED exact tiers] | — | https://apps.apple.com/us/app/neuronation-brain-training/id610456643 |

**Market norms:** $35–95/yr subscription, 4.5+ rating, free tier with 3–5 games, aggressive trials. No mainstream brain-training app succeeds at one-time pricing. Reviewer complaints cluster on: (a) subscription cost / paywall after a few games; (b) repetitive content; (c) trials that auto-convert (see Lumosity review corpus: https://apps.apple.com/us/app/lumosity-brain-training/id577232024?see-all=reviews).

**One-time vs subscription for MenteViva (indie, seniors, Family Sharing):**

- One-time (we chose $12.99): seniors/caregivers distrust subscriptions (FTC-vintage wariness), Family Sharing makes one purchase cover the whole family — strong fit for the "adult child buys for parent" channel. Zero churn revenue though; updates must be funded by new sales.
- Subscription funds ongoing content, but seniors have lowest subscription tolerance of any demographic and care facilities avoid auto-renewing app purchases entirely. [UNVERIFIED — no public survey found]
- Alternative not chosen, used by adjacent indie apps: cheap annual ($19.99–29.99) + generous free tier (daily 3 games free forever). Converts the engaged, doesn't alienate the casual.
- One-time also dodges Guideline 3.1.1 subscription fatigue risk in review and simplifies refunds/disputes.
- **DECIDED for beta (decisions.md 2026-09-19, #21):** one-time $12.99 with Family Sharing; revisit annual sub only with beta conversion data.

## 5. PRE-RELEASE CONSIDERATIONS CHECKLIST

1. **Medical disclaimer wording** — "Entertainment and mental exercise only; not a medical device, not for diagnosis, treatment, or prevention of any condition. Consult a physician for memory concerns." Enforce in-app + App Store description. Rationale: FDA general-wellness line (https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices) + FTC/Lumosity precedent (https://www.ftc.gov/news-events/news/press-releases/2016/01/lumosity-pay-2-million-settle-ftc-deceptive-advertising-charges-its-brain-training-program).
2. **App Store 1.4.1 positioning** — no screening scores, cutoffs, "cognitive age vs population norms presented clinically," or disease references anywhere (name, keywords, screenshots). https://developer.apple.com/app-store/review/guidelines/
3. **Age rating & COPPA/GDPR-K** — rate 4+ only if zero child-directed content/data collection; if under-13 use is plausible, COPPA verifiable parental consent and GDPR Art. 8 (member-state 13–16 consent age) apply. Seniors-only design keeps this simple. https://www.ftc.gov/legal-library/browse/rules/childrens-online-privacy-protection-rule-coppa
4. **Privacy / HIPAA-adjacency** — HIPAA does NOT apply (MenteViva is not a covered entity or business associate; consumer app, no covered provider data flows). Still: minimize PII, local-first storage, no ad SDKs — seniors + health-adjacent data attracts FTC §5 unfairness scrutiny. https://www.hhs.gov/hipaa/for-professionals/covered-entities/index.html
5. **Caregiver data-sharing consent** — if family members view a senior's progress: explicit opt-in consent from the player (not just the purchaser), revoke controls, plain-language ES/EN consent screen. No silent sharing.
6. **Accessibility audit** — WCAG 2.2 AA + Apple HIG: Dynamic Type to AX5, VoiceOver labels on all game elements, min 44×44pt targets, no color-only cues (Stroop!), adjustable animation speed. https://developer.apple.com/accessibility/
7. **Offline-first** — senior facilities have poor/restricted wifi; all gameplay, progress, and Family Sharing validation must work offline, sync opportunistically. App Store review requires no forced login for core function.
8. **ES/EN cultural localization** — not just translation: category-fluency word lists differ culturally (e.g., "animales" categories), calendar/number formats, neutral Latin-American Spanish, avoid US-centric references. Test with native ES speakers 65+.

---
*Method note: FDA guidance page dated Jan 2026, App Store pages fetched 2026-09; pricing is US storefront and changes frequently.*

