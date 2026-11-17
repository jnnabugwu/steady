# Onboarding: design question and flow

Status: direction chosen 2026-11-17, not built. Tracking issue: #161. Prototype: branch
`prototype/onboarding` (throwaway, never merged).

## The design question

What should someone's first two minutes in Steady feel like, so that they enjoy it, the
coach learns enough to be personal, and nothing in it contradicts Steady's no-shame stance?

Today there is no onboarding: a first launch lands on Today, and the Apple Health
permission appears without any explanation in front of it.

## Constraints

- **No body or goal questions, ever:** no weight, goal weight, height, age, sex or
  calorie target. They invite the targets the coach refuses to give, and Steady's users
  have usually answered them already in their food tracker.
- **No streaks or streak commitments.** A missed day after committing to "14 days" is
  the shame Steady exists to avoid.
- **Every step can be skipped,** and every answer can be changed later in Settings →
  About me. Nothing gates the app (App Store 5.1.1, and the same reasoning as the iCloud
  banner).
- **Reduced motion:** animations reduce to appearing, as `CairnWeek` already does.
- **The answers become the coach's About me** (structured, below), stored only on the
  iPhone like the consent answer. Sending them with coach requests needs the consent
  version bump planned with session memory and patterns.

## What we looked at

Both flows were reviewed on Mobbin on 2026-11-17.

**Cal AI** (most Steady users come from it): one decision per screen with large rows and a
disabled Continue until answered; a one-line reason under each question ("This helps
personalize your experience"); a thin progress bar and a back arrow; a value screen
between the questions; "Where did you hear about us?" (kept, as screen 3). Its questions are all body and
goal questions (sex, workouts per week, birthday, height, weight, daily calorie and macro
goals), and its value screen is a weight chart framed as "without a plan". We take the
structure and leave out the questions and the fear framing.

**Finch** (self-care pet): a reward before any question (choose an egg, it hatches); the
pet asks in speech bubbles; a question with no wrong answer that teaches what the app is
for; a permission previewed before it's asked (a sample notification from the pet); a
starter plan built from the answers; a soft paywall after the person is invested ("free
forever, but try Plus for 7 days free"). We take all of that except its streak commitment
("How many days in a row…", up to "Unstoppable streak").

## The flow

Cal AI's structure, Finch's two best moments, and prototype variant B's coach voice. The
cairn is the progress bar: each step places a stone, and a skipped step still places a
dimmer one.

| # | Screen | What happens | Becomes |
|---|---|---|---|
| 1 | Place your first stone | The person taps (or drags) a stone onto the ground; it wobbles and settles. Steady's version of hatching the egg. "Log more days, without the guilt." | — |
| 2 | How you track food | Cal AI / another app that writes to Apple Health / I'm just starting. Reason line: so Today shows the right thing. | `tracking`; whether Today shows the import button |
| 3 | Where did you hear about Steady? | A friend or family / TikTok / Instagram / Reddit / App Store search / something else. Reason line: helps a small app know what's working. Cal AI's attribution question. | A count with no identifier; never sent to the coach |
| 4 | Apple Health | A preview of the Today tiles first, then the system permission. | Health access |
| 5 | Your week | Activity chips (tennis, gym, walks, runs, yoga, other) and "my weekends are busier / quieter / all over the place". | `activities`, `weekends` |
| 6 | What gets in the way | Eating out, late nights, weekends, forgetting, travel, feeling judged. | `hardParts` |
| 7 | Your coach's voice | Gentle / Direct / Playful. The coach answers "I skipped logging Saturday" in the chosen voice, from text written in advance (no API call). | `voice` |
| 8 | Meet the coach | The existing consent screen, plus an optional line: "Anything else the coach should know?" (about 200 characters). | consent; `note` |
| 9 | Your first week | Two or three tiny suggestions built from the answers by templates in the app, e.g. "On tennis days, log lunch before you head out." | — |
| 10 | Your cairn | The stones placed so far. "Tonight's check-in adds the next." | — |

**Later, with the paywall:** a soft Steady+ offer between screens 9 and 10, in Finch's tone
(the free app stays free; try the coach free for a week). It comes before the consent step
for anyone who hasn't subscribed, so nobody agrees to send data for a feature they
haven't chosen.

## About me, as the proxy will receive it

```json
"aboutMe": {
  "voice": "gentle",
  "tracking": "calAi",
  "activities": ["tennis", "walks"],
  "weekends": "busier",
  "hardParts": ["eatingOut", "lateNights"],
  "note": "I work nights twice a month"
}
```

Codes, not prose: the proxy turns them into sentences, so only `note` is free text, and
only `note` needs prompt-injection eval cases. Each voice gets a short tone rule on the
proxy and its own eval run, since a Direct coach still can't shame.

## Animation

- **The first stone (screen 1)** is the one moment worth Rive: an interactive wobble and
  settle, driven by data binding. Spike it on the prototype branch before paying for a
  plan; check the build size and Simulator performance.
- **Every other stone** stays in Flutter: `CairnWeek` is drawn from data in code and is
  shared with Today and the share card, so a second copy in Rive would drift.
  `flutter_animate` is enough for the remaining transitions.

## Open questions

- [ ] Rive or Flutter for the first stone, decided after the spike.
- [ ] Where-did-you-hear answers: counted how, and where? Steady has no analytics yet.
- [ ] Ten screens and eight stones: merge 5 and 6 to get back to a seven-stone cairn, which would let the flow reuse `CairnWeek`?
- [ ] Should "Your first week" (screen 9) also seed the first weekly session?
