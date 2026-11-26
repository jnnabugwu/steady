# Feedback: a designer's first look at Steady (2026-11-25)

> Status: notes from one conversation, an input to product decisions, not a decision record.
> The person is a designer with about 30 years in print and digital work, seeing Steady for the
> first time over a screen share. Names are left out on purpose (the repo is public). Most of
> the call was about other work; this file keeps only the Steady parts.

---

## What was shown

- **Today:** no check-in logged yet that day, calories burned and steps from Apple Health,
  the last 30 days and the recent averages.
- **Where Steady came from:** a weekly meeting with friends where each person presents goals
  for the week that tie to goals for the month, on Fridays. Cal AI's week didn't line up with
  that meeting, which is why Steady's week runs Friday to Thursday.
- **The coach:** described as moving from the on-device model to a hosted one, and as the paid
  feature. (Out of date when it was said: 1.0 has been on the App Store since 2026-11-17, and
  the hosted coach was then in TestFlight testing.)
- **Cravings (free):** how strong, and hunger, stress or both. Hunger gets "eating something
  might be a good call"; stress gets the one-minute urge-surfing cooldown.
- **Traction at the time:** 23 downloads, from word of mouth plus one Instagram post and story.
- **The palette:** green because it's calm, and nothing loud or plain black and white.

## What they said

1. **Show people their progress.** Seeing where you've been keeps people going, the same pull
   as likes and hearts on social media. Their example was Pillo, a medication reminder app.
   Early on it donated to a nonprofit when users kept their log up to date, and the person they
   knew who used it liked feeling it did some good beyond themselves.
2. **Accountability with other people.** Their main idea. They asked whether people can link
   accounts to keep each other accountable, and compared it to working out with a trainer,
   Orangetheory's leaderboard and fantasy-football teasing between friends. Their example:
   "I slacked off, but I see [a friend] logging more consistently, so I need to do it."
3. **Get it into communities.** CrossFit gyms, Camp Gladiator, Orangetheory, or trainers who'd
   use it with their clients (steps, calories eaten, logging). It would then spread through
   groups instead of one person at a time.
4. **The palette works.** Green reads as health, and the palette is subtle and works well
   together. The only thing they praised outright.
5. **It's an MVP.** Get the core right, then improve it from feedback and new ideas.
6. **Polish (said about another app shown on the same call, not Steady).** It looked
   utilitarian and needed more visuals and engagement, to make a boring task feel fun.
   It still applies here: getting better at design is a stated goal for Steady.

## How this fits existing decisions

- **Linked accounts are live sharing,** which is deferred:
  [`live_sharing_research.md`](../live_sharing_research.md). SwiftData has no shared database,
  so it means Core Data or hand-written CloudKit sync, and sharing data with a second person is
  what brings back the need for accounts (CLAUDE.md §1). That doc's trigger to revisit is real
  users asking to see each other's data in the app. One suggestion on a call isn't that yet.
  Share cards (`technical_decisions.md`, "Sharing is share cards, not live data") are the
  cheaper version that exists today.
- **What gets compared matters.** Their example was logging consistency, which is closer to
  Steady's check-in statuses than calories or steps are. Even so, the product rules out streaks,
  scores and shame-coded visuals for missed days (`steady_product_overview.md`), and a
  leaderboard is a score: whoever logged less is behind. A leaderboard on calories or steps would
  also conflict with the coach's guardrails on calorie targets and with the eating-disorder risks
  in [`craving_support.md`](craving_support.md).
- **Trainers seeing their clients' data** would put Health values in front of another person:
  the same sharing and accounts problem, with App Store 5.1.3 on top.
- **Showing progress needs no sharing, and Steady already does it without streaks:** the cairn
  week (each day's check-in as a stone), the 30-day view and the weekly look back. The tortoise
  mascot carrying its stones fits the same single-person design. Gamification beyond that
  (streaks, badges, scores) is out by the product's own rules.
