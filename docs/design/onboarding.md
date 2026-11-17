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
| 3 | Where did you hear about Steady? | A friend or family / Instagram / Reddit / App Store search / TikTok / something else. Reason line: helps a small app know what's working. Cal AI's attribution question. | PostHog event `onboarding_source` (`source`: a fixed code such as `tiktok`); never sent to the coach |
| 4 | Apple Health | A preview of the Today tiles first, then the system permission. | Health access |
| 5 | Your week | Activity chips (tennis, gym, walks, runs, yoga, other) and "my weekends are busier / quieter / all over the place". | `activities`, `weekends` |
| 6 | What gets in the way | Eating out, late nights, weekends, forgetting, travel, feeling judged. | `hardParts` |
| 7 | Your coach's voice | Gentle / Direct / Playful. The coach answers "I skipped logging Saturday" in the chosen voice, from text written in advance (no API call). | `voice` |
| 8 | Meet the coach | The existing consent screen, plus an optional line: "Anything else the coach should know?" (about 200 characters). | consent; `note` |
| 9 | Your first week | Two or three tiny suggestions built from the answers by templates in the app, e.g. "On tennis days, log lunch before you head out." | — |
| 10 | Your cairn | The stones placed so far. "Tonight's check-in adds the next." | — |

**Where screen 3's answer goes (decided 2026-11-17): PostHog.** One anonymous event,
`onboarding_source`, whose only property is a fixed code (`friend`, `instagram`, `reddit`,
`appStore`, `tiktok`, `other`). There's no free text, so "something else" is just `other`. A
skip sends nothing. This needs, in order:

1. **#156 merged.** Its hold ("until 1.0 is approved") is lifted: 1.0 is live.
2. **PostHog in App Store builds.** #156 sends from TestFlight builds only, which would count
   only testers. Sending from App Store builds is a change to its decision record ("Usage
   events from TestFlight builds only"), covering the events it already has, or only this
   one.
3. **The App Privacy label first.** Before a build that sends from the App Store goes to
   review, App Store Connect's answers change from "Data Not Collected" to usage data not
   linked to the person, used for analytics (what PostHog's privacy manifests declare).
   `docs/PRIVACY.md` says the same.

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

**Flutter only, no Rive (decided 2026-11-17).** Nothing in onboarding is worth a paid plan
yet.

- **The first stone (screen 1)** is drawn the way `CairnWeek` draws its stones: a
  `GestureDetector` for the tap or drag, then a spring (`SpringSimulation` on an
  `AnimationController`) for the wobble and settle.
- **Every other stone** reuses `CairnWeek`'s drawing, which is already shared with Today and
  the share card. `flutter_animate` (free, MIT) covers the screen transitions.
- **Rive, later.** If the first stone ever needs more than a spring can give, a Rive version
  can replace screen 1 alone, once paying for it is worth it.

## Open questions

- [ ] PostHog in App Store builds: every #156 event, or only `onboarding_source`?
- [ ] Ten screens and eight stones: merge 5 and 6 to get back to a seven-stone cairn, which would let the flow reuse `CairnWeek`?
- [ ] Should "Your first week" (screen 9) also seed the first weekly session?
