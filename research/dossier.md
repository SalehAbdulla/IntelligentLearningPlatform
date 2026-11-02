# Research dossier, StudyForge

> **What this file is.** The compiled evidence base for Design Document **section 2
> (Background research)** and **section 4 (Competitive analysis)**. It is the working
> dashboard: every claim the document makes, the source it rests on, and where the design
> uses it. The document carries the polished prose, this file carries the traceability.
>
> Roadmap task: [Phase 1, P1-10](../docs/01-ROADMAP-PHASES-TODOLIST.md). Rubric rows:
> `a1` (context, who is affected and why it matters), `a3` (supporting research and
> references) in [the rubric coverage matrix](../docs/08-RUBRIC-COVERAGE-MATRIX.md) section 2.

**Status summary, stated honestly up front.**

| Part | Status |
|---|---|
| Learning-science evidence (section 1) | ✅ assembled from stable, peer-reviewed sources |
| SDG mapping (section 4) | ✅ assembled, one source per claim |
| Competitor teardown (section 3) | ✅ analysis written, competitor screenshots still to be captured |
| Market / country statistics (section 2) | ⚠️ **not yet verified against primary sources**, see section 8 |
| Student interviews, 5 users (roadmap P1-05) | ⬜ not yet run |
| Tutor interview (document section 3) | ⬜ booked, not yet held, so sections 3.2 to 3.4 stay open |

Nothing in this file is a placeholder for work that was claimed and not done. Where a
figure is not yet verified it is listed as *to verify*, with the primary source named,
rather than approximated.

---

## 1. The problem, in evidence

The product claim is short: **students already have the material, and the missing piece is
the conversion of that material into active-recall practice.** Five findings support it,
and a further set of sources shapes the *design* rather than the *problem*.

### 1.1 Why the default behaviour fails

| # | Finding | Source | Strength | How StudyForge uses it |
|---|---|---|---|---|
| 1 | Of ten widely used study techniques, **rereading and highlighting were rated low utility**, while practice testing and distributed practice were rated high utility | Dunlosky et al. (2013) | Systematic review of the literature | The premise of the app: it does not store material, it converts material into testing and spacing |
| 2 | **Being tested produces better long-term retention than restudying** (the testing effect) | Roediger and Karpicke (2006) | Peer-reviewed experiments | F05 Quiz is a first-class feature, not an add-on to summaries |
| 3 | Retrieval practice produced more learning than elaborative concept mapping, on a delayed test | Karpicke and Blunt (2011) | Peer-reviewed experiment | Quizzes carry explanations and citations rather than being a score-only check |
| 4 | **Distributed practice beats massed practice** for verbal recall | Cepeda et al. (2006) | Meta-analysis, 254 studies | F06 Study Plan schedules review across days, not in one sitting |
| 5 | Retention decays in a predictable pattern | Ebbinghaus (1885) | Foundational, replicated since | Scheduling is treated as a solvable problem; review dates are computed, not guessed |

**The gap this establishes.** None of the above is unknown to students; the failure is one
of *effort*, not awareness. Converting one lecture PDF into cards, a quiz and a spaced plan
by hand takes hours, so it does not happen. The brief states the same opportunity:
*"This project asks students to design an AI-supported mobile learning platform that helps
students organize materials and turn them into useful study resources such as summaries,
notes, quizzes, and flashcards."*

### 1.2 Sources that shape the design rather than the problem

| # | Source | What it contributes | Where it shows |
|---|---|---|---|
| 6 | Bjork and Bjork (2011), desirable difficulties | Difficulty that feels productive is the point; the UI must not optimise for comfort | Rating a card Again is framed as progress, not failure (F04) |
| 7 | Sweller (1988), cognitive load | Extraneous load is removed: one primary action per screen | The 5-tab spine, one primary action per screen (document section 11) |
| 8 | Mayer (2009), multimedia learning | Visual and verbal output are genuinely different treatments | F03 output formats Visual / Verbal / Read-Write / Kinesthetic |
| 9 | Fleming and Mills (1992), VARK | The four output shapes are a **preference** setting, never a claim about ability | `12_ProfileSetup_LearningStyle`, output-format selector |
| 10 | Wozniak and Gorzelanczyk (1994), SM-2 | The scheduling algorithm for spaced repetition | `SpacedRepetition.swift`, F04 ratings Again / Hard / Good / Easy |
| 11 | Nielsen (1994), usability heuristics | Visibility of system status, user control, error prevention and recovery | Loading, empty, error and offline states; every error offers a next action |
| 12 | W3C (2023), WCAG 2.2 | The accessibility target the design is measured against | Contrast measured from rendered pixels, Dynamic Type to AX5, proof screens `138` and `139` |
| 13 | Kingdom of Bahrain (2018), Personal Data Protection Law No. 30 | The data-protection frame for a Bahraini student project | Document section 16.2, on-device-first processing, no training on student material |

**Honesty note on item 9.** Citing VARK invites the objection that learning styles do not
predict learning outcomes. The position is stated explicitly: StudyForge uses the inventory
as a *preference and accessibility* control and makes no claim that a "visual" learner
learns better from a diagram. Recorded because the rubric rewards defensible reasoning and
penalises marketing claims dressed as research.

---

## 2. Who is affected, and why it matters

The primary population is **undergraduates**, and the design is shaped by the Gulf context
in four concrete ways rather than by a generic "students struggle" framing:

| # | Contextual fact | Design consequence | Screen or feature |
|---|---|---|---|
| 1 | Many students study in a **second language** on English-medium programmes | Output carries a language choice; the UI is fully bilingual with true RTL | F03 language selector, `139_RTL_Arabic_Example` |
| 2 | Many study **alongside part-time work**, so time is scarce | The plan is deliberately realistic and re-plans itself after a missed session instead of silently failing | F06 wizard intensity step, AI re-plan |
| 3 | Many pay for **mobile data by the gigabyte** | Generation happens on the device where possible, so the core loop costs nothing to run | The 3-tier AI router, on-device extraction |
| 4 | Commercial AI study tools are largely **Western-market, subscription-gated, English-only and cloud-only** | A genuinely useful free tier, offline operation and true RTL are inclusion decisions, not extras | F13 free tier, offline states, SDG 10 mapping below |

This is what turns the module's **SDG 10 (Reduced Inequalities)** alignment into a design
position rather than a slogan: a student on a mid-range iPhone with metered data is the
same first-class user as a student on a new device with unlimited data.

### 2.1 Figures that must be verified before submission

`DESIGN-DOCUMENT.md` section 2 carries an export note requiring every market figure to be
re-checked against its primary source, and any figure that cannot be verified to be removed
rather than approximated. **This is the open list.** No number is asserted here until it is
checked, which is why the cells name the source to check instead of quoting a figure.

| # | Claim the document would like to make | Primary source to check | Owner | Status |
|---|---|---|---|---|
| V1 | Size of the tertiary-education population in Bahrain | Bahrain Ministry of Education / Information and eGovernment Authority open data | M1 | ✅ **VERIFIED — 60,723 enrolled students, academic year 2025/2026** (public 41,824 + private 18,899). Source: **iGA Bahrain Open Data Portal**, dataset `23-hec_students-in-higher-education-institutions-by-academic-programme-sex0`, summing all 16 records for `academic_year = 2025/2026`; dataset last processed 27 Sep 2026, retrieved 15 Oct 2026 |
| V2 | Smartphone and mobile-internet penetration in Bahrain | Bahrain Telecommunications Regulatory Authority (TRA) quarterly market report | M1 | ✅ **VERIFIED — 144.5 mobile lines per 100 inhabitants, 2025.** **2,316,986 mobile phone lines** (TRA, annual series 2016–2025, via the iGA open-data portal) against a **population of 1,603,260** (iGA, June 2025). ⚠️ This is *mobile-line* penetration, the closest primary-source proxy; the TRA's own smartphone/mobile-broadband split lives in its quarterly report, which blocks scripted requests (see the note below) |
| V3 | Growth of digital learning in the GCC | A named industry report (for example a regional e-learning market study) with a publication year, not a blog | M4 | ✅ **VERIFIED — the GCC e-learning market reached USD 7.7 billion in 2025, and is forecast to grow at a 13.46% CAGR over 2026–2034.** Source: **IMARC Group**, *GCC E-Learning Market Size, Share, Trends and Forecast by Learning Type, Sector, Product Type, Technology, and Country, 2026–2034* — a named industry report with a stated publication year (**press release dated 25 May 2026**), retrieved 23 Oct 2026. Corroborating named report, same direction: **Technavio**, *E-Learning Market in GCC — Size and Forecast 2025–2029* |
| V4 | Bahrain digital-payments context, cited as local context | **Resolution No. 43** as published in the official gazette, plus the Central Bank of Bahrain rulebook for the payment rails named in F13 | M3 | ✅ **VERIFIED — Ministerial Resolution No. (43) of 2024**, issued by the **Minister of Industry and Commerce**, published in the **Official Gazette, Issue No. 3753, Thursday 13 June 2024**: every commercial entity registered with the MOIC must hold a **dedicated business bank account** and process its payments **through licensed financial institutions**, and the resolution directs establishments to **adopt electronic payment systems**. The rails F13 names (Tap card acquiring, BenefitPay) sit under the **Central Bank of Bahrain Rulebook, Volume 5 (Specialised Licensees) — Payment Service Provider module**, version **5 February 2026**. Sources retrieved 23 Oct 2026; see the note below for the exact references |
| V5 | Cost of the cloud AI tiers the router falls back to | The providers' published price lists, checked on the day of export | M2 | ✅ **VERIFIED — the free tier is genuinely $0, and the paid rate is quantified. Gemini 2.5 Flash-Lite: free of charge on the free tier; paid $0.10 / 1M input tokens and $0.40 / 1M output tokens.** At the project's own task sizes that is **≈ $0.0008 per generation**, so even the *paid* rate at the stated ceiling of <100 calls/day is **≈ $0.08/day (≈ $2.40/month)**. Source: Google's published Gemini Developer API price list, retrieved 15 Oct 2026 |

#### How V1 was verified, reproducibly

The Bahrain Open Data Portal renders its tables in JavaScript, so the dataset cannot be read
from the page's HTML. It does expose the standard Opendatasoft API, which **is** the primary
source and returns the same records the portal shows. Two calls reproduce the figure exactly:

```bash
# 1. which academic years exist (the latest is 2025/2026)
curl -s 'https://www.data.gov.bh/api/records/1.0/search/?dataset=23-hec_students-in-higher-education-institutions-by-academic-programme-sex0&rows=0&facet=academic_year'

# 2. the 16 records for the latest year; sum the "value" field
curl -s 'https://www.data.gov.bh/api/records/1.0/search/?dataset=23-hec_students-in-higher-education-institutions-by-academic-programme-sex0&rows=16&refine.academic_year=2025%2F2026'
```

The 16 records are 2 sectors × 4 education levels × 2 sexes, and they sum to **60,723**:
public 41,824 (diploma 3,345 · bachelor 36,825 · master 1,347 · doctorate 307) and private
18,899 (diploma 233 · bachelor 15,095 · master 3,278 · doctorate 293).

> **A note for whoever verifies V2.** The TRA's own site (`tra.org.bh`) returns **HTTP 403** to
> a scripted request, so the quarterly market report cannot be fetched the same way. It needs
> either a browser or a request with a normal user agent, or the figure should be taken from the
> iGA's *Bahrain in Figures* instead, which is also a government primary source and is on the
> same open-data portal.

#### How V2 was verified, reproducibly

**The 403 was worked around, not bypassed.** The TRA publishes its series to the **iGA open-data
portal** as well as to its own site, and the portal's API answers scripted requests. So the figure
below is still **TRA-published** — only the delivery route changed.

```bash
# 1. mobile phone lines, TRA, annual (2016-2025)
curl -s 'https://www.data.gov.bh/api/records/1.0/search/?dataset=01-number-of-mobile-phone-lines&rows=10&sort=-year'

# 2. population, iGA, June 2025 (16 records: 4 governorates x 2 nationalities x 2 sexes)
curl -s 'https://www.data.gov.bh/api/records/1.0/search/?dataset=02-population-by-governorate-nationality-sex&rows=16&refine.year=2025'
```

| Year | Mobile phone lines (TRA) |
|---|---|
| 2020 | 1,770,966 |
| 2021 | 1,923,443 |
| 2022 | 2,128,304 |
| 2023 | 2,250,359 |
| 2024 | 2,316,110 |
| **2025** | **2,316,986** |

Population, June 2025: **1,603,260** total — of whom **746,097 Bahraini** and 857,163 non-Bahraini.

**Penetration = 2,316,986 ÷ 1,603,260 = 144.5 mobile lines per 100 inhabitants.**

> **Two honest caveats, stated rather than buried.**
> 1. **Mobile *lines*, not smartphones.** A lines-per-head figure counts SIMs, and one person can
>    hold two. It is the strongest primary-source proxy for "almost everyone has a phone", which
>    is the claim the document actually needs — but it is not a smartphone-specific statistic, and
>    the document must not describe it as one.
> 2. **The population denominator is a mid-year estimate** (June 2025), and the mobile-lines figure
>    is an annual one, so the ratio mixes two reference periods. The ratio is stable enough for the
>    argument; the *sources* are what a marker should check, and both are cited above.

#### How V3 and V4 were verified, reproducibly

**Both were verified on 23 Oct 2026 by M1 (Saleh Abdulla, `202300540`) — not by the members the
table names as owners.** The submission deadline moved to Saturday 24 Oct and both rows were still
open, so the verification was done rather than left standing. **M4 and M3 own the claims; the
sources below are what a marker should check.**

**V3 — the GCC e-learning figure.** §2.3 needs a *named industry report with a publication year*,
not a blog. It is cited from one, with a second named report agreeing on the direction:

| | |
|---|---|
| **Publisher and report** | **IMARC Group**, *GCC E-Learning Market Size, Share, Trends and Forecast by Learning Type, Sector, Product Type, Technology, and Country, 2026–2034* |
| **Publication** | press release dated **25 May 2026** |
| **Figure** | **USD 7.7 billion** in **2025**, forecast at a **13.46% CAGR over 2026–2034** |
| **Corroborating** | **Technavio**, *E-Learning Market in GCC — Size and Forecast 2025–2029* — a named report with a stated forecast period. Its headline rate could not be read from the page in this pass, so **no figure is asserted from it** |
| **Retrieved** | 23 Oct 2026 |

> **Honest framing of what this is.** Both are **commercial market-research vendors**, not
> statistical agencies — which is what the row asked for, but it is *not* the same class of source
> as V1 and V2, which are government open data. The document therefore uses the figure as **market
> direction with a citation**, not as a precise claim about Bahrain, and it states the GCC-wide
> scope rather than blurring it into a local one.

**V4 — Resolution No. 43 and the payment rails.** Two separate references were required, and both
are now pinned:

| | |
|---|---|
| **The resolution** | **Ministerial Resolution No. (43) of 2024**, Minister of Industry and Commerce |
| **Published in** | **Official Gazette, Issue No. 3753 — Thursday 13 June 2024** |
| **What it requires** | every commercial entity registered with the MOIC holds a **dedicated business bank account**; payments are processed **through licensed financial institutions**; establishments are directed to **adopt electronic payment systems** |
| **Implementation** | recorded in the **CBB Rulebook** as **24 July 2025** |
| **The rails F13 names** | card acquiring through **Tap** and **BenefitPay** sit under the **CBB Rulebook, Volume 5 (Specialised Licensees) — Payment Service Provider (PSP) module**, version **5 February 2026** |
| **Retrieved** | 23 Oct 2026 |

```bash
# the rulebook module that governs the rails F13 uses — the citation, not just a claim
curl -sI 'https://www.cbb.gov.bh/wp-content/uploads/2026/02/Volume-5_PSP-Module_5-Feb-26.pdf'
#   → HTTP 200 · application/pdf · 1,376,295 bytes

# the resolution itself is published by the ministry under the gazette issue in its filename:
#   moic.gov.bh → "قرار وزير الصناعة والتجارة رقم (43) لسنة 2024" · العدد 3753 · الخميس 13 يونيو 2024
```

> **One caveat, stated rather than buried.** The ministry serves that PDF with an anti-bot response
> to scripted requests (**HTTP 403** — the same behaviour V2 hit on the TRA's site), so the
> resolution's **obligations** were read from a law firm's analysis of it (**Raees + Co**, *Legal
> Update: New Financial Obligations For Commercial Entities In Bahrain*, Legal 500, 29 Nov 2024),
> while the **citation** — number, issuer, gazette issue and date — comes from the ministry's own
> published filename. The PDF is the primary source and opens normally in a browser.

#### How V5 was verified, reproducibly

**One price list covers both cloud tiers.** The app's `AITier` names tier 1 as *Firebase AI Logic
(Gemini)* and tier 2 as *Gemini via a Cloud Function proxy* — both are the same provider, so a
single published price list answers V5 for both. Source:
**`https://ai.google.dev/gemini-api/docs/pricing`**, retrieved **15 Oct 2026**.

**Rate card, Gemini 2.5 Flash-Lite** (`gemini-2.5-flash-lite`) — the model the high-volume text
tasks (summarise, make flashcards, make quiz) would use:

| | Free tier | Paid (per 1M tokens) |
|---|---|---|
| **Input** (text / image / video) | **free of charge** | **$0.10** |
| Input (audio) | free of charge | $0.30 |
| **Output** (including thinking tokens) | **free of charge** | **$0.40** |
| Batch / Flex | not available | $0.05 in / $0.20 out (the documented 50% reduction) |

**Worked example, using the app's own task sizes** (`AITask.typicalContextTokens`, plus a
~1,000-token generated answer):

| Task | Context | Cost at the paid rate |
|---|---|---|
| `summarize` | 4,000 tokens | 4,000 × $0.10/1M + 1,000 × $0.40/1M = **$0.0008** |
| `coachAnswer` | 8,000 tokens | 8,000 × $0.10/1M + 1,000 × $0.40/1M = **$0.0012** |
| 100 generations/day (the stated ceiling) | — | **$0.08 / day ≈ $2.40 / month** |

**What this proves, and what it does not.** It does **not** prove the project is free — it proves
the *rate* is negligible and that the **$0 claim rests on the free-tier quota, not on the price**.
That is the honest framing and the more useful one, because it puts a number on the worst case: if
the free tier were exhausted and nothing else changed, the guardrails in `docs/04 §5`
(on-device-first routing, the content-hash cache, the per-user daily budget) would be containing a
cost of roughly **$2.40 a month**, not an unbounded one.

> ⚠️ **Three caveats, stated rather than buried.**
> 1. **The router does not pin a model** — that is deliberate (`AIProvider` is a seam), so the rate
>    depends on what an admin configures. Flash-Lite is the model the volume tasks would use; the
>    larger Flash and Pro models cost more, and **their Standard rates could not be read directly**
>    from the page in this pass (it is long and truncates), so no figure is asserted for them.
> 2. **Prices change.** The dossier's own rule is "checked on the day of export", and this was
>    checked on **15 Oct 2026**. Re-check before submitting.
> 3. **The free tier's *limits*, not just its price, are what the $0 claim rests on** — per-model
>    RPM / RPD / TPM quotas, documented on the same page. The design stays inside them through
>    caching and tier-0 routing, which is why `docs/04 §5` lists "<100 generation calls / day" as
>    the expected load.

**Rule for the two that remain:** the document states the *structural* argument (second-language
instruction, part-time work, metered data, Western-market tooling) which the team can evidence from
its own programme, and **does not quote a statistic whose primary source has not been checked** —
an unverifiable figure is **removed rather than approximated**. V1, V2 and V5 have now cleared that
bar; **V3 and V4 have not**, and no number from either may appear in the document until they do.
---

## 3. Competitor teardown

Roadmap `P1-03` requires a teardown of Quizlet, Anki, Google NotebookLM, Notion, ChatGPT
and Studocu **with screenshots**. The analysis below is the written half; the screenshot
capture is still open and is listed in section 8.

### 3.1 The teardown table

| Competitor | Strength | The gap StudyForge exploits |
|---|---|---|
| **Quizlet** | Huge card library, polished UX | Cloud-only, freemium with aggressive paywalls, English-first, weak on *your own* uploaded material |
| **Anki** | Best-in-class spaced repetition | Hostile onboarding, no AI generation, no collaboration, desktop-centric |
| **Notion / Obsidian** | Powerful organisation | The student must build the system themselves; no generation, no scheduling intelligence |
| **Google NotebookLM** | Excellent grounded summarisation | Desktop and web-first, no mobile revision loop, no flashcards, quizzes or spaced repetition, no group spaces |
| **ChatGPT / Gemini apps** | Broad general capability | Not grounded in *your* course material, no structure, no provenance, no revision scheduling |
| **Studocu / Course Hero** | Shared notes at scale | Paywalled, legal grey areas, no personal generation |

### 3.2 Stage coverage: where each product stops

The columns are the six stages of the loop the design claims. The table is the team's own
reading of publicly documented product behaviour, and it is the evidence behind the
"one closed loop" claim. It is a qualitative assessment, not measured data.

| Product | Upload own material | Generate artefacts | Schedule review | Practise (test) | Measure mastery | Adapt the plan |
|---|---|---|---|---|---|---|
| Quizlet | Partial, manual card entry | Cards only | Partial, paid | ✅ | Partial | ⬜ |
| Anki | Manual import | ⬜ | ✅ | ✅ | Partial | Partial, by hand |
| NotebookLM | ✅ (documents) | Summaries, audio | ⬜ | ⬜ | ⬜ | ⬜ |
| Notion / Obsidian | ✅ (as files) | ⬜ | ⬜ | ⬜ | ⬜ | ⬜ |
| ChatGPT / Gemini apps | ✅ (attachments) | ✅ | ⬜ | ⬜ | ⬜ | ⬜ |
| Studocu / Course Hero | ⬜ (others' notes) | ⬜ | ⬜ | Partial | ⬜ | ⬜ |
| **StudyForge (designed)** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**The competitive edge, one sentence:** incumbents solve *one stage* of the study workflow,
whereas StudyForge is designed so that **upload, generate, schedule, practise, measure and
adapt** are a single closed loop grounded in the student's own course material.

### 3.3 The three supporting differentiators

1. **Grounded by default, with visible provenance.** Every summary line and every quiz
   answer traces back to the page it came from, so a generated quiz answer is never an
   unsourced assertion. Evidence: provenance chip and confidence band (`Figure 13.1`),
   `38_Citation_Source_Sheet`, F15 answer citations.
2. **Works without a network.** On-device extraction and on-device generation mean the core
   loop runs on a bus with no data. Evidence: offline state `133`, cached quiz, SwiftData
   plus Firebase offline persistence.
3. **Bilingual English and Arabic with true right-to-left layout.** Designed for the GCC
   market that every listed competitor treats as an afterthought. Evidence: proof screen
   `139_RTL_Arabic_Example`, mirroring built into the layout rather than overlaid.

**What we deliberately do not claim.** StudyForge is not the best spaced-repetition tool in
existence; Anki is, and the design says so. StudyForge is not a better general chatbot than
ChatGPT. The claim is narrower and defensible: it is the only one of these products that
closes the loop from a student's *own* material to a *scheduled, measured and adapted*
---

## 4. SDG mapping, one source per claim

Roadmap `P1-04`. Each row states the contribution, the evidence inside the design, and the
source class that must be cited for it in the document.

| SDG | How StudyForge contributes | Evidence in the design | Source to cite |
|---|---|---|---|
| **SDG 4, Quality Education** | Turns passive material into active-recall resources with measurable mastery | Flashcard and quiz generation with SM-2 scheduling; `topicMastery` written by quiz attempts; weakness radar | Dunlosky et al. (2013), Roediger and Karpicke (2006), Cepeda et al. (2006) |
| **SDG 9, Industry, Innovation & Infrastructure** | Quality learning tools that work on low-quality or intermittent connectivity | On-device generation, offline-first core loop, 3-tier AI router, graceful degradation screen `80` | W3C (2023) for the accessibility bar; the on-device capability claim is the platform's own documentation (Apple Foundation Models, iOS 26) to be cited at export |
| **SDG 10, Reduced Inequalities** | Bilingual English and Arabic with true RTL, dyslexia-friendly typography, a free tier that is genuinely useful, offline mode, accessibility-first design | Proof screens `138` and `139`; `Layout.minTouchTarget` 44 pt; Dynamic Type to AX5; recorded contrast ratios in the design system | Kingdom of Bahrain (2018) for the data-protection frame; WCAG 2.2 for the accessibility target |

**Why this is not decoration.** Each SDG row names a design artefact that would have to be
removed for the claim to become false. That is the test the rubric's "why it matters"
bullet is really applying.

---

## 5. Interviews: what exists, what does not

| Interview | Roadmap task | Status | Where it lands |
|---|---|---|---|
| **Tutor interview** (10 questions on risk, innovation, F15 approval, tester expectations) | `P1-06`, `P1-07` | ⬜ booked, **not yet held** | Document section 3.1 to 3.4. The question bank is already finalised, so only the answers are missing |
| **5 student interviews** (semi-structured, 10 minutes, verbatim quotes) | `P1-05` | ⬜ not yet run | To be filed as anonymised notes beside this dossier, and quoted in document section 2.2 |

**This is a known, unavoidable gap and it is stated rather than dressed up.** The document
must not be submitted with section 3 as a promise: the rubric explicitly asks for the
questions *and* the responses, and the responses only exist after a real interview with the
tutor. The dossier records the dependency so nobody has to rediscover it at 23:00 before
the deadline.

**What the student interviews would test** (so the protocol is ready to run): whether a
student currently converts material into practice, how long that takes them, what they use
---

## 6. From evidence to design: the change log

This is the section that proves the research was *used* rather than cited. Each row is a
finding from section 1 or 2, the decision it forced, and where a marker can see the result.

| Finding | Design decision it forced | Visible in |
|---|---|---|
| Practice testing beats restudy (2, 3) | Quizzes are a first-class feature with explanations and citations, not a score-only check | F05, screens `51` to `59` |
| Distributed practice beats massed practice (4) | The plan schedules review across days and re-plans after a missed session | F06 wizard and calendar, screens `60` to `68` |
| Retention decays predictably (5) | Ratings map to a computed next-due date (SM-2), so the student never chooses a date | F04 review, `SpacedRepetition.swift` |
| Rereading is low-yield (1) | Upload does not just *store* material, it immediately offers summarise, cards and quiz | Upload success `29`, generate action sheet `34` |
| Cognitive load (7) | One primary action per screen; five-tab spine; no nested navigation beyond two levels | Navigation map, document section 11 |
| Multimedia learning (8) | Output formats are genuinely different renderings, and the choice is stored in the profile | `12_ProfileSetup_LearningStyle`, F03 format step |
| Desirable difficulties (6) | "Again" on a card is presented as normal progress, with no failure language | `55`/`56` feedback, F04 rating row |
| Usability heuristics (11) | Every error state offers a next action; every list has an empty state with a primary action | States set `128` to `141` |
| WCAG 2.2 (12) | Contrast measured from rendered pixels; fill-only hues never used as text | Design system, proof screens `138`, `139` |
| Data protection (13) | On-device-first processing; no student material used for training; consent before the usability test | Document section 16.2, AI router |
| Gulf context (section 2) | Bilingual with true RTL; a free tier that is genuinely usable; offline mode | `139`, F13 free tier, state `133` |

**Cross-check.** Every row above names a screen number or a named class, so the claim is
falsifiable by opening the artefact. Rows that could not be evidenced this way were not
written.

---

## 7. References (Harvard)

The submitted document carries the same list in section 18. Duplicated here so the dossier
stands alone as the evidence base.

- Bjork, R.A. and Bjork, E.L. (2011) 'Making things hard on yourself, but in a good way: creating desirable difficulties to enhance learning', in Gernsbacher, M.A., Pew, R.W., Hough, L.M. and Pomerantz, J.R. (eds.) *Psychology and the real world: essays illustrating fundamental contributions to society*. New York: Worth Publishers, pp. 56-64.
- Cepeda, N.J., Pashler, H., Vul, E., Wixted, J.T. and Rohrer, D. (2006) 'Distributed practice in verbal recall tasks: a review and quantitative synthesis', *Psychological Bulletin*, 132(3), pp. 354-380.
- Dunlosky, J., Rawson, K.A., Marsh, E.J., Nathan, M.J. and Willingham, D.T. (2013) 'Improving students' learning with effective learning techniques: promising directions from cognitive and educational psychology', *Psychological Science in the Public Interest*, 14(1), pp. 4-58.
- Ebbinghaus, H. (1885) *Über das Gedächtnis: Untersuchungen zur experimentellen Psychologie*. Leipzig: Duncker und Humblot.
- Fleming, N.D. and Mills, C. (1992) 'Not another inventory, rather a catalyst for reflection', *To Improve the Academy*, 11(1), pp. 137-155.
- Karpicke, J.D. and Blunt, J.R. (2011) 'Retrieval practice produces more learning than elaborative studying with concept mapping', *Science*, 331(6018), pp. 772-775.
- Kingdom of Bahrain (2018) *Law No. 30 of 2018 with respect to Personal Data Protection*. Manama: Government of the Kingdom of Bahrain.
- Mayer, R.E. (2009) *Multimedia learning*. 2nd edn. New York: Cambridge University Press.
- Nielsen, J. (1994) *Usability engineering*. San Francisco: Morgan Kaufmann.
- Roediger, H.L. and Karpicke, J.D. (2006) 'Test-enhanced learning: taking memory tests improves long-term retention', *Psychological Science*, 17(3), pp. 249-255.
- Sweller, J. (1988) 'Cognitive load during problem solving: effects on learning', *Cognitive Science*, 12(2), pp. 257-285.
- W3C (2023) *Web Content Accessibility Guidelines (WCAG) 2.2*. Available at: https://www.w3.org/TR/WCAG22/ (Accessed: 1 October 2026).
- Wozniak, P.A. and Gorzelanczyk, E.J. (1994) 'Optimization of repetition schedules in SuperMemo', *Acta Neurobiologiae Experimentalis*, 54(1), pp. 59-62.

---


## 8. Verification log and roadmap coverage

### 8.1 What is verified, and what is not

| Item | Verified how | Date |
|---|---|---|
| Learning-science findings (1 to 5) | Stable peer-reviewed sources, cited for their established findings. No number is quoted beyond what the sources state | 7 Oct 2026 |
| Design-shaping sources (6 to 13) | Read for the principle they contribute; each mapped to a screen or class in section 6 | 7 Oct 2026 |
| Competitor teardown | Written from publicly documented product behaviour; **screenshots not yet captured** | 7 Oct 2026 |
| SDG mapping | Each row names an artefact in the design, so the claim is checkable | 7 Oct 2026 |
| Market and country statistics | **Not verified.** Five open items in section 2.1 | open |
| Tutor interview | **Not held.** Document section 3 must not ship without it | open |
| Student interviews | **Not run.** Five participants planned | open |
| Usability test and SUS score | **Not run.** Document section 17.3, roadmap `P9-03/04` | open |

### 8.2 Roadmap Phase 1 coverage

| Task | Requirement | Where it is satisfied |
|---|---|---|
| `P1-01` | 8+ credible sources on retrieval practice, spaced repetition and the testing effect, each with a Harvard reference | Section 1 (13 sources, 12 of them peer-reviewed or primary), section 7 |
| `P1-02` | Digital-learning adoption in Bahrain / the GCC, with Resolution No. 43 as local context | Section 2, and the open item V4 in section 2.1 until the gazette reference is confirmed |
| `P1-03` | Competitor teardown with screenshots and the gap table | Section 3 (written); screenshots still to capture |
| `P1-04` | SDG mapping with a source per claim | Section 4 |
| `P1-05` | Interview 5 real students | Section 5, not yet run |
| `P1-06` | Tutor interview, verbatim answers, what changed | Document section 3; question bank finalised, answers pending |
| `P1-07` | Written approval for F15 | Document section 3.4, pending |
| `P1-08` | Problem statement: who is affected, why it matters, scale | Sections 1 and 2 |
| `P1-09` | Purpose, goals, measurable success metrics | Document section 5.3, which this dossier feeds |
| `P1-10` | Compile everything into `research/dossier.md` with a Harvard reference list | **This file** |

### 8.3 How this file relates to the submitted document

| Dossier | Document |
|---|---|
| Section 1, 2 | `DESIGN-DOCUMENT.md` section 2 (Background research) |
| Section 3 | `DESIGN-DOCUMENT.md` section 4 (Competitive analysis) |
| Section 4 | `DESIGN-DOCUMENT.md` sections 2.2 and 5 |
| Section 6 | `DESIGN-DOCUMENT.md` sections 5, 7 to 15 |
| Section 7 | `DESIGN-DOCUMENT.md` section 18 (References) |
| Section 8 | The export-readiness checks in `docs/TODOLIST.md` section 4 |

**One deliberate difference.** This file is allowed to say "not verified" and "not run".
The submitted document states what is known, and opens each unfinished item with its
status, exactly as section 3 and 17.3 already do. Nothing is upgraded on the way from the
dossier into the document.






and a further set of sources shapes the *design* rather than the *problem*.
