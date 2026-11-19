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
| 1 | Place your first stone | The person taps (or drags) a stone onto the tortoise's back (the mascot, #176); it wobbles and settles. Steady's version of hatching the egg. "Log more days, without the guilt." | — |
| 2 | How you track food | Cal AI / another app that writes to Apple Health / I'm just starting. Reason line: so Today shows the right thing. | `tracking`; whether Today shows the import button |
| 3 | Where did you hear about Steady? | A friend or family / Instagram / Reddit / App Store search / TikTok / something else. Reason line: helps a small app know what's working. Cal AI's attribution question. | PostHog event `onboarding_source` (`source`: a fixed code such as `tiktok`); never sent to the coach |
| 4 | Apple Health | A preview of the Today tiles first, then the system permission. | Health access |
| 5 | Your week | Activity chips (tennis, gym, walks, runs, yoga, other) and "my weekends are busier / quieter / all over the place". | `activities`, `weekends` |
| 6 | What gets in the way | Eating out, late nights, weekends, forgetting, travel, feeling judged. | `hardParts` |
| 7 | Your coach's voice | Gentle / Direct / Playful. The coach answers "I skipped logging Saturday" in the chosen voice, from text written in advance (no API call). | `voice` |
| 8 | Meet the coach | The existing consent screen, plus an optional line: "Anything else the coach should know?" (about 200 characters). | consent; `note` |
| 9 | Your first week | Two or three tiny suggestions built from the answers by templates in the app, e.g. "On tennis days, log lunch before you head out." | — |
| 10 | Your cairn | The stones placed so far, with the tortoise beside them. "Tonight's check-in adds the next." | — |

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

**Who sees it (decided 2026-11-17): everyone, once.** A new install sees it on first launch,
and someone updating from 1.0 sees it on their first launch after the update. Finishing or
skipping to the end marks it done; it never comes back on its own.

**Leaving early (decided 2026-11-17).** Nothing ever traps someone in the flow.

- **"Not now"**, in the corner of every screen, goes straight to Today: one tap, no "are you
  sure?". It marks onboarding done. The answers given so far are kept, and Settings → About me
  has every question for later.
- **Closing the app mid-flow** (swiped away, or iOS ends it in the background) isn't leaving.
  Each answer is saved as it's given, with the screen the person was on, and the next launch
  opens on that screen with the earlier answers filled in.
- **Apple Health is never asked for without screen 4 in front of it.** Steady no longer asks
  at launch. Someone who leaves before screen 4 reaches the same screen from Settings → Apple
  Health or Today's empty Health tiles.
- **Leaving before screen 8** means no consent, and every way into the coach already asks for
  it first.
- **Screen 3's answer** is sent only when it's chosen. Leaving or skipping sends nothing, and
  nothing is stored.
- **A first launch from a link** (`/checkin/<date>`) opens the link. Onboarding shows on the
  next ordinary launch.
- **An unreadable `onboarding.json` counts as done**, so a damaged file never puts the flow in
  front of someone, and the next save replaces it with a record that says done.
- **`onboarding_exited`** (PostHog, with the screen's fixed code only) records where people
  leave, so the screens that lose people can be fixed.

**The coach steps are marked paid (decided 2026-11-17).** The coach, including the weekly
check-in, is what Steady will charge for. Until the paywall exists, screens 7 and 8 carry a
small "paid" badge, so nobody is surprised later. The coach is the main thing Steady does,
not an add-on, so the copy never calls it "Plus" or an upgrade. What exactly is free and what
is paid is being decided separately.

**Later, with the paywall:** the offer sits before the consent step (screen 8) for anyone who
hasn't subscribed, so nobody agrees to send data for a feature they haven't chosen. Finch's
tone: try the coach free for a week, without pressure.

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

- **The first stone (screen 1)** is the mascot's bottom stone (`TortoiseStone`, #176), and
  it lands on the tortoise's back (`SteadyTortoise.stoneRect`): a `GestureDetector` for
  the tap or drag, then a spring (`SpringSimulation` on an `AnimationController`) for the
  wobble and settle. The tortoise doesn't move.
- **Every other stone** reuses `CairnWeek`'s drawing, which is already shared with Today and
  the share card. `flutter_animate` (free, MIT) covers the screen transitions.
- **Rive, later.** If the first stone ever needs more than a spring can give, a Rive version
  can replace screen 1 alone, once paying for it is worth it.

## Open questions

- [ ] PostHog in App Store builds: every #156 event, or only `onboarding_source`?
- [x] Ten screens and nine stones (screens 1–9 each place one): the onboarding cairn is its
  own widget built from `CairnWeek`'s stone drawing, and `CairnWeek` keeps its seven days.
- [ ] The paid badge's wording, once free and paid are decided.
- [ ] Should "Your first week" (screen 9) also seed the first weekly session?
