# Craving support: research for the iPhone craving flow

> Status: research input for a product decision (2026-10-23). Not a decision record. Product
> context is in `docs/steady_product_overview.md` (the coach does craving support and the weekly
> session, "coach, not therapist", no calorie prescriptions).
>
> **How to read the evidence labels.** **Strong** = replicated across several controlled studies
> or a meta-analysis. **Moderate** = at least one decent RCT or several consistent lab studies.
> **Weak** = small, uncontrolled, single-study, or lab-only work. **Expert opinion** = clinical
> or practitioner convention with little direct testing. Most food-craving research is small and
> run on undergraduates (often women, often chocolate). Treat effect sizes as directional.

---

## TL;DR

- A craving is best modelled as an **intrusive thought that you then elaborate into vivid
  imagery** (Elaborated Intrusion theory). This explains why visual tasks and "noticing without
  elaborating" can weaken it, and why suppressing it can backfire.
- Cravings **do fade on their own over minutes**, but there's no good food-specific study of how
  long they last. The "wave" is a useful clinical metaphor, not a measured curve.
- No in-the-moment technique has strong evidence for food. The best-supported pieces are
  **(a) a short visual task** (Tetris and similar, moderate lab evidence, small field
  studies), **(b) self-chosen postponement ("not now, maybe later")** instead of a flat "no"
  (one paper, four experiments), and **(c) mindfulness/defusion framing** (mixed: it changes
  behaviour more often than it lowers the craving itself).
- **Suppression and restriction make cravings worse**, and treating a lapse as failure makes
  eating worse (the "what-the-hell" effect). For Steady this is the main design constraint:
  the flow should never be about winning or losing.
- Steady's goal is *consistent tracking*, not fewer snacks. So the flow's best ending, if the
  person eats, is a gentle "log it in Cal AI when you're ready". Success metrics should be about
  use and logging consistency, **never about the share of cravings resisted**.
- **Data risk:** craving + mood logs are likely "health data" in App Review's eyes. Syncing them
  to the Mac through CloudKit hits the same open 5.1.3(ii) question Steady already has for
  calories and check-ins (`docs/technical_decisions.md`).

---

## 1. The science of food cravings

### What a craving is

Kavanagh, Andrade and May's **Elaborated Intrusion (EI) theory** treats desire as conscious,
emotionally charged thinking in two stages ([Kavanagh et al., 2005, *Psychological
Review*](https://doi.org/10.1037/0033-295X.112.2.446)):

1. **Intrusion.** An unbidden thought about the target, set off automatically by external cues
   (seeing or smelling food), bodily states, or associated thoughts.
2. **Elaboration.** If the thought promises pleasure or relief, you start elaborating it,
   especially as **sensory imagery** (imagining the taste, the texture). Elaboration uses
   working memory, so it competes with other mental tasks. The imagery is briefly rewarding but
   makes you more aware of what you lack, which feeds the craving.

The theory was built for substance craving and treats craving as the extreme end of ordinary
desire. A 10-year retrospective by the same authors reviews the supporting work and its
implications for treatment ([May, Kavanagh & Andrade, 2015, *Addictive
Behaviors*](https://doi.org/10.1016/j.addbeh.2014.09.016)). Evidence: **Moderate-to-strong** as a
descriptive model (many supporting lab studies); it's the theory behind most of the visual-task
work in §2.

A food craving is not hunger. Reviews define it as an intense desire for a **specific** food,
closely tied to liking but not the same as eating more, and note that the old "cravings signal a
nutrient need" idea has given way to cue, mood and cognitive explanations ([Hill, 2007,
*Proceedings of the Nutrition Society*](https://doi.org/10.1017/S0029665107005502)).

### How common, and what follows

In a 2-week EMA study of 100 adults, a specific craving was present at about **39–41% of eating
events** and **about 14% of random non-eating moments**, and when a craving was present at an
eating event, people ate the craved food about **9 times in 10**
([Roefs et al., 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC6899849/)). That study didn't
measure hunger. Practical read: cravings are an everyday event, not a crisis, and the flow
should feel that way.

### Time course: do cravings peak and pass?

- **No good food-specific measurement exists.** EMA authors describe food cravings as having a
  "relatively short duration" as the reason to use phone sampling, but don't time them
  ([Roefs et al., 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC6899849/)).
- The cleanest timed data is from smoking. After a smoking cue, smokers rated craving every 5
  minutes for 35 minutes; **craving fell in both the nicotine-gum and placebo arms**, with the
  active gum pulling ahead only after ~15 minutes
  ([Shiffman et al., 2003, *Psychopharmacology*](https://ctri.wiscweb.wisc.edu/wp-content/uploads/sites/240/2017/06/Shiffman...Jorenby-Psychopharmacol-Efficacy-of-acute-administration-of-nicotine-gum-03.pdf)).
  So a cue-triggered craving does decline over minutes without doing anything.
- Public-health quit guidance puts single nicotine cravings at **3–5 minutes**
  ([HSE Ireland](https://www.hse.ie/living-well/quit-smoking/get-help-to-quit/cravings-withdrawal/)).
  This is guidance, not a cited measurement. Reframe (alcohol) designs around a "typical
  20-minute craving" ([Georgia Tech ChBE magazine,
  2021](https://issuu.com/gtchbe/docs/chbe_magazine_2021final/s/14302526)), also unsourced.

**Bottom line (Weak):** "It will rise and fall" is honest to say. A specific number of minutes is
not. A wait of a few minutes is plausible; "10 minutes" is a reasonable round number, not an
evidence-derived one.

### Triggers

- **Cues** (sight, smell, places, times of day) and **conditioned cue reactivity** are among the
  most prominent mechanisms ([Hill, 2007](https://doi.org/10.1017/S0029665107005502)).
- **Restriction and dieting.** Prospective and experimental work shows dietary restraint makes
  craving more likely, and trying to restrict a particular food is linked to more craving for
  that food ([Hill, 2007](https://doi.org/10.1017/S0029665107005502)). **Moderate.**
- **Stress and mood.** In an EMA study of 123 adults (3 prompts/day for 10 days), reporting a
  stressor was linked to higher craving in that same moment
  ([Dicker-Oren et al., 2024, *Stress and Health*](https://pubmed.ncbi.nlm.nih.gov/38635310/)).
  Hill lists dysphoric mood as a main mechanism. **Moderate** (observational).
- **Tiredness.** One night of sleep deprivation increased desire for high-calorie foods and
  changed reward-related brain activity in a small lab study
  ([Greer, Goldstein & Walker, 2013, *Nature Communications*](https://doi.org/10.1038/ncomms3259)).
  **Weak-to-moderate** (small, lab).
- **HALT** (Hungry, Angry, Lonely, Tired) comes from mutual-aid recovery culture. A 2026
  discussion paper says peer-reviewed research on HALT itself is limited, though its four states
  are each studied ([Kretchman, *Advances in Drug and Alcohol
  Research*](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12827198/)). **Expert opinion** as a
  tool; the underlying factors have better evidence. Steady's proposed reasons list
  (hungry/bored/stressed/tired/habit) is essentially HALT adapted for food, which is fine as a
  labelling prompt.

### What makes cravings worse

- **Thought suppression.** Restrained eaters told to suppress chocolate thoughts later ate
  significantly more chocolate than those told to express them or a control group (n=116); people
  who habitually suppress reported stronger cravings
  ([Erskine & Georgiou, 2010, *Appetite*](https://uhra.herts.ac.uk/id/eprint/2423/)). The same
  team found a similar rebound in smokers. **Moderate** (several lab studies).
- **The "what-the-hell" effect.** Dieters who were led to *believe* they'd overeaten (a bigger
  pizza slice than someone else's) ate more cookies afterwards; non-dieters ate less
  ([University of Toronto Magazine on Polivy & Herman's study](https://magazine.utoronto.ca/?p=16585)).
  The lesson repeated across this literature: the *belief that you've failed* is what breaks
  self-regulation, not the food. Addiction research calls the same pattern the abstinence
  violation effect. **Moderate.**

These two findings are the strongest reason the flow must not frame cravings as something to
beat.

---

## 2. In-the-moment techniques and their evidence

| Technique | Best evidence | Effect | Strength |
| --- | --- | --- | --- |
| Visual task (Tetris, visual noise, imagining a non-food scene) | Lab RCTs + 2 small field studies | Lowers craving strength/vividness by modest amounts | **Moderate** (lab) / **Weak** (real world) |
| Self-chosen postponement ("later") | 4 experiments, one paper | Less desire and consumption than restraint | **Weak-to-moderate** |
| Mindfulness: urge surfing | Small RCTs | Often no change in the urge; sometimes less consumption later | **Mixed** |
| Mindfulness: defusion ("notice the thought") | One RCT for chocolate | Ate less chocolate | **Weak** |
| ACT-style acceptance vs control strategies | Analog RCT; large smoking RCT | Depends on person; strong for smoking quit | **Mixed** for food, **Moderate-strong** for smoking |
| App-based mindful-eating program (Eat Right Now) | Uncontrolled feasibility studies | ~40% less craving-related eating | **Weak** |
| Implementation intentions (if-then plans) | Meta-analyses | Medium overall; smaller for *reducing* unhealthy eating | **Strong** (planning), **Moderate** (for snacking) |
| HALT check | None as an intervention | n/a | **Expert opinion** |
| Drink water | Hunger/intake studies, none on cravings | Inconsistent | **Weak** |
| Logging cravings | 1 EMA reactivity study | Craving and snacking fell over time while monitored | **Weak** |

### Visual / visuospatial tasks

EI theory predicts that tasks loading visual working memory starve the craving image. Three
minutes of Tetris reduced naturally occurring food cravings versus a control that waited for a
game that "failed to load" (~119 students) ([Skorka-Brown, Andrade & May, 2014,
*Appetite*](https://doi.org/10.1016/j.appet.2014.01.073)). In a 1-week field study (n=31),
3 minutes of Tetris cut craving strength across food, drink, drugs and activities by about
**14 percentage points** (f² = 0.11, a small effect), consistently across the week
([Skorka-Brown et al., 2015, *Addictive Behaviors*](https://pearl.plymouth.ac.uk/handle/10026.1/3458)).
Kemps and Tiggemann's work found eye-movement, visual-noise and spatial-tapping tasks reduce
food-image vividness and craving; imagining a non-food scene (e.g., a rainbow) reduced chocolate
craving; and dynamic visual noise on a handheld device over 2 weeks reduced craving strength,
eating in response to cravings, and calories eaten
([Kemps & Tiggemann, 2015, *Frontiers in Psychiatry*](https://pmc.ncbi.nlm.nih.gov/articles/PMC4284995/)).

Caveats: small samples, mostly students, self-reported craving, no test of whether Tetris beats
any other mildly absorbing game. **Moderate for "reduces craving in the moment", Weak for "changes
eating".** It's also the cheapest thing to build: 60–90 seconds of a visual task fits in the time
budget.

### Delay / "wait 10 minutes"

There's no trial of a "wait 10 minutes" timer for food. The closest evidence:

- Cravings decline over minutes without intervention (§1, smoking data).
- **Unspecific postponement** ("I'll have it later", no time named) reduced desire for and
  consumption of a temptation **more than restraint** ("I won't have it"), in the moment and over
  the following week. Two details matter for design: it only worked when the person **chose** to
  postpone (not when it was imposed), and only when the "later" was **vague**, not a specific
  time ([Mead & Patrick, 2016, *JPSP*](https://repub.eur.nl/pub/78955)). **Weak-to-moderate**
  (one paper, four experiments, lab).

Design implication: frame the wait as the person's own choice ("Want to give it a few minutes?"),
and avoid "You can have it at 4:15" countdown framing.

### Urge surfing and mindfulness

- **Urge surfing** (Marlatt's technique: notice the urge as a wave and ride it out). In 123
  student smokers given a cue-exposure task, brief urge-surfing instruction **did not reduce
  urges** but the group **smoked fewer cigarettes over the next 7 days**
  ([Bowen & Marlatt, 2009](https://pubmed.ncbi.nlm.nih.gov/20025372/)).
- For chocolate (n=137, 5 days carrying chocolate), **cognitive defusion** (treating chocolate
  thoughts as passengers on a bus you're driving) led to eating less chocolate than relaxation;
  **acceptance/urge surfing did not differ from control**
  ([Jenkins & Tapper, 2014, *Br J Health Psychol*](https://pubmed.ncbi.nlm.nih.gov/23678870/)).
  The difference was modest.
- **Acceptance vs control strategies** (n=98, 48 hours with a box of chocolates): acceptance
  helped people who were *most* sensitive to food cues and was linked to *more* craving in the
  least sensitive ([Forman et al., 2007, *Behaviour Research and
  Therapy*](https://contextualscience.org/publications/forman_hoffman_mcgrath_herbert_brandsma_lowe_2007)).
- **Smoking, at scale:** the ACT-based app iCanQuit beat the guideline-based QuitGuide app on
  12-month quit rates (n=2,415; OR 1.49). iCanQuit teaches accepting urges and letting them pass;
  QuitGuide teaches avoiding triggers
  ([Bricker et al., 2020, *JAMA Internal Medicine*](https://pmc.ncbi.nlm.nih.gov/articles/PMC7506605)).
  **Strong for smoking**, not tested for food.
- **Eat Right Now (Brewer).** A 28-day app program (n=104 women with overweight/obesity) showed a
  **40% reduction in craving-related eating** with no control group
  ([Mason et al., 2018, *J Behav Med*](https://doi.org/10.1007/s10865-017-9884-5);
  [NCT02694731](https://clinicaltrials.gov/study/NCT02694731)). A follow-up found that using the
  app's craving tool lowered the expected reward of eating and that reward changes predicted
  eating changes; less binge eating appeared in people who used the tool 5+ times. Again no
  control group ([Taylor et al., 2021, *J Behav
  Addict*](https://pmc.ncbi.nlm.nih.gov/articles/PMC8997232)). Brewer's smoking app, Craving to
  Quit, did **not** beat experience sampling alone on 6-month quit rates (n=505), though
  cigarettes per day fell
  ([Garrison et al., *Nicotine & Tobacco Research*, via NAQC](https://www.naquitline.org/news/409678/Craving-to-Quit-A-Randomized-Controlled-Trial-of-Smartphone-app-based-Mindfulness-Training-for-Smok.htm)).
  The marketing line "clinically proven 40%" overstates a single uncontrolled feasibility study.

**Read across:** mindfulness approaches tend to change *what you do* with a craving more than
*how strong* it feels. That's a good fit for Steady, since the goal isn't to kill the craving,
it's to keep the person in a calm, observing stance (and logging). **Mixed / Weak** for food.

### Implementation intentions (if-then plans)

Across 94 tests, forming "if situation X, then I'll do Y" plans had a medium-to-large effect on
goal attainment (d ≈ 0.65) ([Gollwitzer & Sheeran, 2006, *Advances in Experimental Social
Psychology*](https://doi.org/10.1016/S0065-2601(06)38002-1)). **Strong.** For eating
specifically, a meta-analysis of 23 studies found effects were larger for **adding** healthy
foods (d ≈ 0.51) than for **cutting** unhealthy eating (d ≈ 0.29)
([Adriaanse et al., 2011, *Appetite*, summary via
Aprifel](https://www.aprifel.com/fr/resume-scientifique/do-implementation-intentions-help-to-eat-a-healthy-diet-a-systematic/)).
**Moderate.**

Design implication: if-then plans belong in the **weekly review**, not the in-the-moment flow,
and should be phrased as something to *do* ("If it's 4pm and I'm wiped, then I'll have the snack
I brought"), not something to avoid.

### HALT check, water, planned snack

- **HALT check.** Untested as an intervention (§1). Its value in the flow is as a labelling step:
  naming the state is cheap and feeds the weekly review. **Expert opinion.**
- **Water.** A water preload reduced hunger and intake at a meal in a 14-person crossover study,
  but a larger look at increased water intake found it "influences hunger and food preference, but
  does not reliably suppress energy intake" ([McKay et al.,
  2018](https://pubmed.ncbi.nlm.nih.gov/29678599/)). No study found on water and cravings.
  **Weak.** Don't present water as a craving fix. It also edges toward "fill up on water instead
  of eating", which is a recognised disordered-eating behaviour.
- **Eating a planned snack when actually hungry** is not a craving technique, it's eating.
  Because restriction increases craving (§1), the flow should treat "hungry" as a reason to eat,
  not a craving to ride out. **Moderate** (inferred from the restraint literature).

### Does logging cravings reduce them?

Possibly, a little. Women randomised to 3, 6 or 9 phone prompts a day for 3 weeks (n=136) all
showed falling craving and snacking over time, with no extra benefit from more frequent prompts;
3/day was least burdensome ([Pimpini et al., 2026, *Eating
Behaviors*](https://cris.maastrichtuniversity.nl/en/publications/less-is-more-a-smartphone-ema-study-manipulating-frequency-of-ass)).
There was no unmonitored control group, so this can't separate reactivity from regression to the
mean. Eat Right Now's own findings (above) are consistent with awareness itself doing work.
**Weak.** For Steady: logging is user-initiated (event-based), so this mostly supports "noticing
is not nothing", not prompts.

---

## 3. Apps with craving support

Patterns only; no copy text or screen designs. Where a flow detail couldn't be confirmed from a
primary or official source, the table says so.

| App (domain) | In-the-moment pattern | What it tracks | Published evidence | Tone notes |
| --- | --- | --- | --- | --- |
| **Eat Right Now** (food; Brewer, Sharecare) | User-initiated guided craving exercise built on **RAIN** (Recognize, Allow, Investigate, Note/Non-identify). Doesn't tell you not to eat; asks you to pay attention while eating and notice how you feel after ([Point32Health course material](https://point32health.org/documents/hunger-habit-session-3); [App Store](https://apps.apple.com/us/app/-/id1052785076)) | Craving tool uses; post-eating contentment ratings used to model reward value ([Taylor et al., 2021](https://pmc.ncbi.nlm.nih.gov/articles/PMC8997232)) | Uncontrolled feasibility studies (40% less craving-related eating) | Curious, non-restrictive; "notice" over "resist". Closest to Steady's intent |
| **Craving to Quit** (smoking; Brewer) | App-based mindfulness training plus experience sampling (same lab and approach; exact in-app steps not confirmed) | Craving and smoking check-ins | RCT, n=505: no quit-rate benefit over experience sampling alone ([NAQC](https://www.naquitline.org/news/409678/Craving-to-Quit-A-Randomized-Controlled-Trial-of-Smartphone-app-based-Mindfulness-Training-for-Smok.htm)) | Mindfulness-based, like Eat Right Now |
| **iCanQuit** (smoking; Fred Hutch) | ACT: accept urges and let them pass, values-based | Urges, smoking | Large RCT, beat QuitGuide (OR 1.49) ([Bricker 2020](https://pmc.ncbi.nlm.nih.gov/articles/PMC7506605)) | Acceptance, non-avoidant |
| **QuitGuide** (smoking; NCI) | "Track my craving": rate strength 1–10, pick trigger, get coping tips/distractions; on a slip, name the trigger ([smokefree.gov](https://smokefree.gov/apps-quitguide); [HCPLive review](https://hcplive.com/view/app-review-month-quitguide)) | Cravings, mood, slips, triggers, time/place | Not tested on its own; was the *comparator* that lost to iCanQuit | Practical, guideline-based, avoidance-oriented |
| **Smoke Free** (smoking; UCL-linked) | Log each craving as it happens, with location and notes on what helped; daily "missions" (behaviour-change techniques) ([developer site](https://smokefreeapp.com/?p=3590); [Crane et al., 2018](https://f1000research.com/articles/7-1524/v1)) | Craving log with map, triggers, progress, money saved | Pragmatic RCT (n=3,143): **no detectable benefit** of offering the app; benefit only in the non-randomised subgroup who downloaded it ([Jackson et al., 2024, *JMIR*](https://jmir.org/2024/1/e50963)) | Gamified (badges, streak-like progress); fine for smoking, risky for food |
| **Quit Genius** (smoking; now Pelago) | CBT program with craving tools plus 1:1 coaching ([Webb et al., 2020](https://mental.jmir.org/2020/10/e22833)) | Cravings, smoking | RCT vs very brief advice: 44.5% vs 28.7% 7-day abstinence at 4 weeks; craving-tool contribution not isolated; coaching confounds it | Clinical/CBT |
| **Reframe** (alcohol) | "Craving check-in" with before/after intensity rating; games, breathing, meditations, journaling to get through a craving ([company release, 2026](https://www.businesswire.com/news/home/20260806272643/en/); [Georgia Tech magazine](https://issuu.com/gtchbe/docs/chbe_magazine_2021final/s/14302526)) | Intensity before/after, time of day (company reports cravings peak around 5pm) | No independent controlled trial found; company self-report data only | Reduction-friendly, not abstinence-only |
| **Headspace** (general) | "Coping With Cravings" course, guided audio about seeing your patterns ([Headspace](https://www.headspace.com/content/course/coping-with-cravings/292)) | Not a craving log | None specific to the course | Gentle, non-clinical |
| **Noom** (weight loss) | Psychology lessons; a specific in-the-moment craving flow could **not** be confirmed from a primary source | Food, weight, calorie budget | Weight-loss evidence exists; a separate clinical product (Noom Monitor) was trialled for eating-disorder care ([MobiHealthNews](https://mobihealthnews.com/node/120491)) | Criticised by clinicians for low calorie targets and for not screening for eating-disorder history ([Eat This, Not That](https://www.eatthis.com/experts-question-noom-weight-loss-app/)) |
| **Calm** | No craving-specific content found | n/a | n/a | n/a |

**Patterns worth noting:**

1. **Before/after intensity** (Reframe, Tetris studies, QuitGuide's strength rating) is the most
   common measure, and the cheapest proof to the user that the moment changed.
2. **Trigger labelling** is universal (QuitGuide, Smoke Free, Reframe). It's what makes the weekly
   review possible.
3. **Craving tools alone don't show strong outcome effects.** The two big smoking trials of
   tool-heavy apps (Smoke Free, Craving to Quit) found no randomised benefit. The app that won
   (iCanQuit) won on its *stance* (acceptance) more than its tools. That argues for getting the
   tone right before adding more tools.
4. **Smoking/alcohol apps can count "resisted" and use streaks** because abstinence is the goal.
   **Food is different:** abstinence isn't the goal and counting resisted cravings mirrors
   restriction. Don't import that pattern.

---

## 4. Safety: eating-disorder risk

### What the evidence says

- Among 105 people with a diagnosed eating disorder, about 75% had used MyFitnessPal, and **73% of
  those users said it contributed to their disorder**, with perceived contribution tracking
  symptom levels ([Levinson, Fewell & Brosof, 2017, *Eating
  Behaviors*](https://pmc.ncbi.nlm.nih.gov/articles/PMC5700836/)).
- A 2025 systematic review of 38 studies found diet and fitness app users (and heavier users)
  report more disordered-eating symptoms; qualitative studies describe pressure to hit goals and
  guilt. The evidence is cross-sectional, so causation isn't shown
  ([Prichard, Kemps & Anderberg, *Body
  Image*](https://researchnow.flinders.edu.au/en/publications/the-link-between-the-use-of-diet-and-fitness-monitoring-apps-body/)).
  Calorie tracking in students has been linked to disordered eating, with authors suggesting
  tracking can intensify rigidity ([Simpson & Mazzeo 2017, summarised by Duke
  Psychiatry](https://psychiatry.duke.edu/blog/trouble-tracking)).
- UK charity Beat has warned fitness trackers can be dangerous for people with eating disorders
  and asked tech companies to turn push notifications off by default
  ([secondary report, 2019](https://gadgetsandwearables.com/2019/05/22/fitness-tracker-eating-disorder/)),
  and pushed the NHS to add safeguards to a calorie-counting app
  ([Beat](https://beateatingdisorders.org.uk/news/beat-campaigners-celebrate-improvement-in-nhs-app)).
- **Cautionary tale for Steady's on-device coach:** in 2023 NEDA replaced its human helpline with
  a chatbot ("Tessa"), which was taken down after it gave people with eating disorders advice
  like a 500–1,000 calorie daily deficit and weekly weigh-ins
  ([NPR](https://www.npr.org/sections/health-shots/2023/05/31/1179244569/national-eating-disorders-association-phases-out-human-helpline-pivots-to-chatbo);
  [CBS News](https://cbsnews.com/amp/news/eating-disorder-helpline-chatbot-disabled)). Steady's
  coach reads craving data on the Mac; it needs the same "never prescribe calories or weight"
  guardrail in its prompt and tests.

Steady already tracks calories (via Cal AI), so it sits in the at-risk category by default. A
craving feature adds risk if it frames eating as failure; it can reduce risk if it models a
non-restrictive stance.

### What to avoid (all **Moderate** unless noted, from the restraint/what-the-hell and app research above)

- **Framing cravings as failures or tests.** No "you gave in", "slip", "cheat", "stay strong",
  "good/bad food".
- **Praising resisting.** No celebration when the craving passes that isn't also there when the
  person eats. Equal, neutral endings.
- **Counting or streaks of resisted cravings**, "cravings beaten this week", success rates, or any
  red/green colouring of outcomes.
- **Treating hunger as a craving to wait out.** If the person is hungry, the flow should say
  eating is a good idea.
- **Calorie or weight content** anywhere in the flow ("that would be 300 calories"). Steady
  already doesn't prescribe targets; the craving flow shouldn't even show numbers.
- **Push notifications that nag about cravings.** Only a notification the person asked for (the
  "check back" after a wait), off by default (Beat's guidance; **Expert opinion**).
- **Water-as-substitute, "just have gum", or other fill-up tricks** (they mirror ED behaviours).

### When and how to point to help

- Keep a **static, always-available "If food feels out of control" link** in settings and at the
  bottom of the flow, not as a pop-up. Point to national organisations (ANAD in the US, Beat in
  the UK) and verify current helpline details at build time: NEDA's own helpline was shut in
  2023 ([NPR](https://www.npr.org/sections/health-shots/2023/05/31/1179244569/national-eating-disorders-association-phases-out-human-helpline-pivots-to-chatbo)).
  **Expert opinion.**
- A soft contextual pointer is reasonable if the person, over a week, logs very frequent
  high-intensity cravings. But Steady isn't a screening tool and shouldn't diagnose; the "coach,
  not therapist" line applies. Phrase it as an offer, not a flag.
- App Store 1.4.1 asks medical apps to remind users to check with a doctor; Steady avoids medical
  claims, and the existing "not medical advice" coach note (`docs/BUILD_CHECKLIST.md`) should
  cover craving content too
  ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)).

---

## 5. Data sensitivity (risk summary, not legal advice)

- **5.1.3(ii)** says apps "may not store personal health information in iCloud", and 5.1.3
  opens by grouping "health, fitness, and medical data" as especially sensitive
  ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)). Apple
  doesn't define "personal health information", and developers asking on Apple's forums whether a
  CloudKit private container counts have been pointed to an App Review consultation rather than
  given an answer ([Apple Developer Forums](https://developer.apple.com/forums/thread/844159)).
- **Craving events with an intensity and a reason like "stressed" or "tired" read like mood and
  eating-behaviour data.** That's at least as health-like as calories eaten, which Steady already
  flags as an open 5.1.3 risk (`docs/technical_decisions.md`, "Health data stays on the iPhone").
- **The weekly reflection is planned for the Mac,** which means syncing craving events through
  CloudKit. That puts them in iCloud. This is the main risk, and it's the same question as the
  existing open risk, so it should be decided alongside it rather than separately.
- **5.1.1** requires the privacy policy to list what's collected and how it's used, consent for
  collection, and **data minimisation**: collect only what the feature needs
  ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)).
  `docs/PRIVACY.md` will need a craving-data line.

**Options, cheapest first:**

1. Sync craving events like other data and treat it as part of the existing open 5.1.3 risk
   (check at the external TestFlight review and full App Review; record exact reviewer wording).
2. Keep craving events in a **local-only store on the iPhone** (a separate SwiftData
   configuration without CloudKit), and give the Mac review only what the iPhone hands it via the
   deferred iPhone→Mac local handoff (#97).
3. Do the weekly craving reflection on the iPhone for v1.

Whatever is picked, putting craving events in their own model/store from the start keeps option
2 open without a schema migration (CloudKit production schema is additive-only,
`docs/cloudkit_schema.md`).

---

## 6. Recommendations for Steady's v1 flow

### The flow (target: 60–120 seconds of active time)

1. **Open it in one tap.** Home-screen button on iPhone (later: a widget or App Intent). No
   onboarding inside the flow. *(Expert opinion: speed matters in the moment.)*
2. **"How strong is it?"** 1–5, one tap. *(Common to every app and study above; gives the
   before/after.)*
3. **"What's going on?"** Pick any: hungry · bored · stressed · tired · habit/saw it · not sure.
   Multi-select, optional. *(HALT-style labelling: Expert opinion; feeds the review.)*
   - **If "hungry" is picked:** say plainly that being hungry is a good reason to eat, and offer
     "I'll eat something" as the next step, with no timer. *(Moderate: restriction increases
     craving; don't teach waiting out hunger.)*
4. **Offer, don't impose, a few minutes.** "Want to give it a few minutes?" with
   **Yes** / **No, I'm going to have it**. Both are fine. If yes:
   - **60–90 seconds of something in the app:** a simple visual task (a tile/shape puzzle, or a
     guided "picture somewhere specific, in detail" prompt), *or* a short "notice it" guide
     (where you feel it, that it's a thought, that it changes). *(Visual task: Moderate lab /
     Weak field. Defusion/noticing: Weak/Mixed.)* The visual task is the better-evidenced
     default; offering both lets the person pick.
   - Then: **"Check back in a bit?"** sets an optional local notification (default ~10 minutes,
     adjustable). The person can close the app. *(Weak: cravings fade over minutes; Mead &
     Patrick: self-chosen, vague postponement beats restraint.)* Keep "later" vague in the copy
     even if the timer is concrete.
5. **"Still want it?"** Re-rate 1–5, then: **Having it** · **It passed** · **Not sure**. Each
   gets an equally neutral one-liner. If "having it": "Enjoy it. Log it in Cal AI when you're
   ready." *(Ties the flow to Steady's actual goal, consistent tracking. Expert opinion; consistent
   with Eat Right Now's "eat with attention" stance.)*
6. **Done.** No score, no tally, no confetti.

### What to record per craving event (minimal)

| Field | Type | Why |
| --- | --- | --- |
| `id` | UUID | Identity |
| `startedAt` | timestamp | Time-of-day patterns in the review |
| `intensityBefore` | 1–5 | Before/after |
| `reasons` | set of enum (hungry, bored, stressed, tired, habit, unsure) | Patterns |
| `waited` | bool | Did they choose the few minutes |
| `toolUsed` | enum? (visual, notice, none) | Which tool people pick (not which "works") |
| `intensityAfter` | 1–5? | Before/after; optional |
| `outcome` | enum? (hadIt, passed, unsure, notAnswered) | Neutral; only for reflection, never scored |
| `endedAt` | timestamp? | Flow duration (is it under 2 min?) |

**Don't record in v1:** the specific food, calories, location, free-text notes, photos. Each adds
sensitivity (5.1.1 minimisation) and the first two pull toward calorie framing. A free-text
note could come later if the weekly review needs it. All fields optional or defaulted per
CloudKit rules (CLAUDE.md §7).

### Wording principles

- **Curious, not corrective:** "What's going on?" not "Why do you want to eat?"
- **The person decides:** offers and questions, never instructions ("Want to…?", not "Wait 10
  minutes").
- **Cravings are normal and temporary:** "Cravings rise and fall" is fine; a specific duration
  promise isn't (the evidence doesn't support one).
- **Symmetric endings:** whatever copy follows "It passed" has the same warmth as "Having it".
- **No moral food words** (good/bad/junk/cheat/treat/earned), no "willpower", "give in", "slip",
  "resist", "win".
- **No clinical claims:** don't say the flow "reduces cravings" or "treats" anything. "Some people
  find a short puzzle takes the edge off" is about as far as the evidence goes.

### What not to do (summary)

- No resisted-craving counts, streaks, badges, success rates, or red/green outcomes.
- No calories, weight, or targets in the flow or the review's craving section.
- No making people wait out hunger.
- No unrequested craving notifications.
- No water/gum substitution tips.
- The coach (Foundation Models, macOS) must never turn craving data into calorie advice. Add
  this to its system prompt and to tests (the NEDA "Tessa" failure).

### What the weekly review (Mac) could reflect on

Descriptive patterns, offered as observations with a question, never a grade:

- **When:** "Most came between 4 and 6pm on weekdays."
- **What was behind them:** "Mostly tagged 'tired'."
- **Before/after:** "On average they were a bit lower when you checked back." (Only if there's
  enough data; skip otherwise.)
- **Craving days and logging:** "On days you used the craving check, you still logged in Cal AI
  most days." This is the link to Steady's real goal.
- **One optional if-then plan** for next week, phrased as something to add ("If it's 4pm and I'm
  wiped, then I'll have the snack I brought"). *(Implementation intentions: Strong in general,
  Moderate for eating, stronger when adding than avoiding.)*

Avoid week-over-week comparisons of craving counts. More logged cravings can mean more noticing,
which is good; a falling count invites the person to under-log.

### Signals that the feature works (2–3)

1. **Repeat, voluntary use.** Share of active weeks with at least one craving flow after the
   first two weeks, and the share of started flows that reach step 5. Tells you it's useful
   enough to reach for. Target to set after a baseline, not up front.
2. **Logging consistency holds on craving days.** End-of-day check-in status ("logged fully")
   on days with a craving event vs days without, per person. Steady's goal is tracking; a craving
   moment that ends in not logging is the failure mode this flow exists to prevent. Success = the
   gap closes or stays small.
3. **The moment feels different.** Median drop from `intensityBefore` to `intensityAfter`, plus an
   occasional one-tap "Was that useful?" after the flow. A modest drop is the realistic
   expectation (the Tetris field study saw ~14 points on a 100-point scale).

**Guardrail (not a success metric):** watch for weeks where intensity is consistently 5 and
frequency is unusually high for that person; that's when the soft help pointer (§4) is shown.
**Never** use "share of cravings that passed" as a success metric. It rewards restriction and
would push the design toward the patterns §4 rules out.

### Evidence strength per recommendation (at a glance)

| Recommendation | Strength |
| --- | --- |
| Non-judgmental, symmetric framing; no failure language | Moderate (suppression, what-the-hell, ED app research) |
| Treat "hungry" as a reason to eat | Moderate (restraint literature) |
| Before/after intensity rating | Expert opinion / common practice |
| Reason labels (HALT-style) | Expert opinion |
| Short visual task as default tool | Moderate (lab), Weak (real world) |
| "Notice it" / defusion option | Weak / Mixed |
| Self-chosen, vague "few minutes" | Weak-to-moderate |
| ~10-minute check-back | Weak (cravings fade over minutes; no food-specific timing) |
| Nudge to log in Cal AI if they eat | Expert opinion (fits Steady's goal) |
| If-then plan in weekly review, phrased as adding | Strong (planning) / Moderate (eating) |
| No counts/streaks of resisted cravings | Moderate (ED app research), Expert opinion (Beat) |
| Minimal fields; consider local-only store | App Review 5.1.1/5.1.3 risk (no legal advice) |

---

## Open questions for Jordan

- Does the weekly craving reflection need to be on the Mac in v1, given 5.1.3? (Options in §5.)
- Visual task: build a tiny puzzle, or start with a guided imagery prompt (no game to build)?
- Should "habit/saw it" be split into "habit" and "saw/smelled it"? Cue-triggered cravings are a
  distinct mechanism, but more chips slow the flow.

---

## Sources

**Theory and mechanisms**

- Kavanagh, Andrade & May (2005). Imaginary relish and exquisite torture: the elaborated intrusion theory of desire. *Psychological Review*. https://doi.org/10.1037/0033-295X.112.2.446
- May, Kavanagh & Andrade (2015). The Elaborated Intrusion Theory of desire: a 10-year retrospective and implications for addiction treatments. *Addictive Behaviors*. https://doi.org/10.1016/j.addbeh.2014.09.016
- Hill (2007). The psychology of food craving. *Proceedings of the Nutrition Society*. https://doi.org/10.1017/S0029665107005502
- Roefs et al. (2019). Food craving in daily life: comparison of overweight and normal-weight participants with EMA. *J Hum Nutr Diet*. https://pmc.ncbi.nlm.nih.gov/articles/PMC6899849/
- Dicker-Oren, Gelkopf & Greene (2024). Momentary stress-induced food craving: an EMA study. *Stress and Health*. https://pubmed.ncbi.nlm.nih.gov/38635310/
- Greer, Goldstein & Walker (2013). The impact of sleep deprivation on food desire in the human brain. *Nature Communications*. https://doi.org/10.1038/ncomms3259
- Erskine & Georgiou (2010). Effects of thought suppression on eating behaviour in restrained and non-restrained eaters. *Appetite*. https://uhra.herts.ac.uk/id/eprint/2423/
- University of Toronto Magazine on Polivy & Herman's "what-the-hell effect" study. https://magazine.utoronto.ca/?p=16585
- Shiffman et al. (2003). Efficacy of acute administration of nicotine gum in relief of cue-provoked cigarette craving. *Psychopharmacology*. https://ctri.wiscweb.wisc.edu/wp-content/uploads/sites/240/2017/06/Shiffman...Jorenby-Psychopharmacol-Efficacy-of-acute-administration-of-nicotine-gum-03.pdf
- HSE Ireland, cravings and withdrawal. https://www.hse.ie/living-well/quit-smoking/get-help-to-quit/cravings-withdrawal/
- Kretchman (2026). HALT: relapse prevention to resilience. *Advances in Drug and Alcohol Research*. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12827198/

**Techniques**

- Skorka-Brown, Andrade & May (2014). Playing "Tetris" reduces the strength, frequency and vividness of naturally occurring cravings. *Appetite*. https://doi.org/10.1016/j.appet.2014.01.073
- Skorka-Brown et al. (2015). Playing Tetris decreases drug and other cravings in real world settings. *Addictive Behaviors*. https://pearl.plymouth.ac.uk/handle/10026.1/3458
- Kemps & Tiggemann (2015). A role for mental imagery in the experience and reduction of food cravings. *Frontiers in Psychiatry*. https://pmc.ncbi.nlm.nih.gov/articles/PMC4284995/
- Mead & Patrick (2016). The taming of desire: unspecific postponement reduces desire for and consumption of postponed temptations. *JPSP*. https://repub.eur.nl/pub/78955
- Bowen & Marlatt (2009). Surfing the urge: brief mindfulness-based intervention for college student smokers. *Psychology of Addictive Behaviors*. https://pubmed.ncbi.nlm.nih.gov/20025372/
- Jenkins & Tapper (2014). Resisting chocolate temptation using a brief mindfulness strategy. *British Journal of Health Psychology*. https://pubmed.ncbi.nlm.nih.gov/23678870/
- Forman et al. (2007). A comparison of acceptance- and control-based strategies for coping with food cravings. *Behaviour Research and Therapy*. https://contextualscience.org/publications/forman_hoffman_mcgrath_herbert_brandsma_lowe_2007
- Mason, Jhaveri, Cohn & Brewer (2018). Testing a mobile mindful eating intervention targeting craving-related eating. *Journal of Behavioral Medicine*. https://doi.org/10.1007/s10865-017-9884-5 (registration: https://clinicaltrials.gov/study/NCT02694731)
- Taylor et al. (2021). Awareness drives changes in reward value which predict eating behavior change. *Journal of Behavioral Addictions*. https://pmc.ncbi.nlm.nih.gov/articles/PMC8997232
- Gollwitzer & Sheeran (2006). Implementation intentions and goal achievement: a meta-analysis. *Advances in Experimental Social Psychology*. https://doi.org/10.1016/S0065-2601(06)38002-1
- Adriaanse et al. (2011). Do implementation intentions help to eat a healthy diet? *Appetite* (summary). https://www.aprifel.com/fr/resume-scientifique/do-implementation-intentions-help-to-eat-a-healthy-diet-a-systematic/
- McKay et al. (2018). Increasing water intake influences hunger and food preference, but does not reliably suppress energy intake in adults. https://pubmed.ncbi.nlm.nih.gov/29678599/
- Pimpini et al. (2026). Less is more: a smartphone EMA study manipulating frequency of assessment. *Eating Behaviors*. https://cris.maastrichtuniversity.nl/en/publications/less-is-more-a-smartphone-ema-study-manipulating-frequency-of-ass

**Apps**

- Eat Right Now, App Store listing. https://apps.apple.com/us/app/-/id1052785076
- Point32Health "Hunger Habit" course material (RAIN, craving tool). https://point32health.org/documents/hunger-habit-session-3
- Garrison et al., Craving to Quit RCT (NAQC summary). https://www.naquitline.org/news/409678/Craving-to-Quit-A-Randomized-Controlled-Trial-of-Smartphone-app-based-Mindfulness-Training-for-Smok.htm
- Bricker et al. (2020). Efficacy of smartphone applications for smoking cessation (iCanQuit vs QuitGuide). *JAMA Internal Medicine*. https://pmc.ncbi.nlm.nih.gov/articles/PMC7506605
- QuitGuide, smokefree.gov. https://smokefree.gov/apps-quitguide
- QuitGuide review, HCPLive. https://hcplive.com/view/app-review-month-quitguide
- Smoke Free, developer site. https://smokefreeapp.com/?p=3590
- Crane et al. (2018). Smoke Free full vs reduced version. *F1000Research*. https://f1000research.com/articles/7-1524/v1
- Jackson et al. (2024). Effectiveness of the offer of the Smoke Free app. *JMIR*. https://jmir.org/2024/1/e50963
- Webb et al. (2020). Quit Genius RCT. *JMIR Mental Health*. https://mental.jmir.org/2020/10/e22833
- Reframe company release (2026). https://www.businesswire.com/news/home/20260806272643/en/
- Georgia Tech ChBE magazine (2021) on Reframe. https://issuu.com/gtchbe/docs/chbe_magazine_2021final/s/14302526
- Headspace, Coping With Cravings. https://www.headspace.com/content/course/coping-with-cravings/292
- MobiHealthNews on Noom Monitor eating-disorder trial. https://mobihealthnews.com/node/120491
- Eat This, Not That: experts question Noom. https://www.eatthis.com/experts-question-noom-weight-loss-app/

**Safety**

- Levinson, Fewell & Brosof (2017). My Fitness Pal calorie tracker usage in the eating disorders. *Eating Behaviors*. https://pmc.ncbi.nlm.nih.gov/articles/PMC5700836/
- Prichard, Kemps & Anderberg (2025). Diet and fitness monitoring apps, body image and disordered eating: a systematic review. *Body Image*. https://researchnow.flinders.edu.au/en/publications/the-link-between-the-use-of-diet-and-fitness-monitoring-apps-body/
- Duke Psychiatry, "The Trouble with Tracking" (summarises Simpson & Mazzeo 2017). https://psychiatry.duke.edu/blog/trouble-tracking
- Beat on NHS weight-loss app safeguards. https://beateatingdisorders.org.uk/news/beat-campaigners-celebrate-improvement-in-nhs-app
- Report on Beat's fitness-tracker warning (secondary). https://gadgetsandwearables.com/2019/05/22/fitness-tracker-eating-disorder/
- NPR (2023) on NEDA's helpline and chatbot. https://www.npr.org/sections/health-shots/2023/05/31/1179244569/national-eating-disorders-association-phases-out-human-helpline-pivots-to-chatbo
- CBS News (2023) on Tessa being taken down. https://cbsnews.com/amp/news/eating-disorder-helpline-chatbot-disabled

**App Store**

- Apple App Review Guidelines (1.4.1, 5.1.1, 5.1.3). https://developer.apple.com/app-store/review/guidelines/
- Apple Developer Forums, "Guideline 5.1.3(ii) — what counts as personal health information for CloudKit?". https://developer.apple.com/forums/thread/844159
