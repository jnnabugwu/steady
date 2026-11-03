# Steady Privacy Policy

Effective 3 November 2026.

Steady is an app for iPhone and Mac that shows your daily calories and a simple end-of-day
check-in. This policy describes what the app does with your data.

## The short version

- Steady has no accounts of its own. Your Apple ID and iCloud are the only account.
- Your data stays on your devices and in your own private iCloud storage. The developer
  can't see it.
- The one exception is the coach, and only if you turn it on. Then what a conversation needs
  goes through one small Steady server, which keeps none of it, to Anthropic, the company
  that makes the Claude model the coach uses, only to write the coach's replies. See
  "Coach" below.
- No analytics, no ads, no tracking. Nothing is ever used for advertising.

## What Steady stores

- **Calories eaten.** When you import a Cal AI PDF export, Steady reads each day's total
  calories eaten and saves those daily totals. The PDF itself isn't kept. On iPhone, calories
  eaten can also come from Apple Health (see below); those aren't saved.
- **Check-ins.** Your end-of-day status for each day (logged, partial or skipped).

This data is stored on your device and in your own private iCloud storage (the CloudKit
private database for your Apple ID), so your iPhone and Mac stay in sync. Only you can access
your private iCloud data; the developer can't. If your device isn't signed into iCloud, your
data stays only on that device until you sign in.

## Craving check-ins

On iPhone, when you use "Having a craving?", Steady records each finished check-in: when it
started and ended, how strong the craving was (1 to 5) at the start and, if you said, at the
end, what you said was behind it (for example bored or tired), whether you took the guided
minute, and how it ended (having it, it passed, not sure, or hungry). It doesn't record what
food it was, calories, your location or any notes.

- Craving check-ins are stored **on that iPhone**, in the app's own storage. Steady doesn't
  put them in iCloud storage or sync them to your other devices, and the Mac app doesn't
  have them. If your iPhone backs up to iCloud (Settings → [your name] → iCloud → iCloud
  Backup), iOS includes them in that device backup like any other app data, so they come
  back if you restore your phone from it.
- You can delete them at any time in Steady's Settings → Cravings → "Delete craving
  history". Deleting the app also removes them from the iPhone; an earlier iCloud Backup of
  the phone may still contain them until that backup is replaced or deleted.
- They aren't included in the data export.
- They're never shared with anyone, with one exception: if you turn on the coach, a coach
  conversation sends that week's craving check-ins to Anthropic, only to write the coach's
  replies (see "Coach"). They're never used for advertising.

## Coach

On iPhone, Steady's coach talks with you about your week: what you logged, your check-ins,
your steps and your craving check-ins. It's powered by Claude, an AI model made by
[Anthropic](https://www.anthropic.com). The coach is **off until you turn it on**: the first
time you open it, Steady shows what it sends and asks first, and nothing is sent unless you
tap "Allow and continue". You can turn it off any time in Settings → Coach, which stops it
sending anything at once, including a reply that's still coming in.

**What's sent, and only while the coach is on:**

- each day's check-in for the week the conversation is about (logged, partial or skipped);
- calories eaten (Apple Health's total, or the one from your Cal AI import), steps, active
  energy and resting energy from Apple Health;
- your craving check-ins for that week: how many, and the time of day, plus what you said
  was behind them in the weekly check-in;
- what you type to the coach, and its replies so far in the conversation.

Weight isn't sent. Nothing is sent from Steady's other screens, only from a coach
conversation.

**Where it goes:** each reply is a request from your iPhone to Steady's coach server, which
passes it on to Anthropic's API and streams the reply back. Steady's server doesn't keep
what's in the conversation: it doesn't store or log what you said or what the coach
replied. To stop misuse, each request carries an Apple App Attest signature proving it comes
from the genuine Steady app on a real iPhone, and the server counts requests per iPhone for a
daily limit; neither identifies you.

Anthropic receives this only to write the coach's replies. Under its API terms it deletes it
within 30 days and doesn't use it to train its models. It may keep a conversation longer
only if its automated safety systems flag it (up to two years) or the law requires it.
Sources: Anthropic's
[commercial data retention policy](https://privacy.claude.com/en/articles/7996866),
[API and data retention](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention)
("How Anthropic approaches data retention") and its
[privacy policy](https://www.anthropic.com/legal/privacy). Nothing sent to the coach is ever
used for advertising.

- Your conversations with the coach (the transcript and a short summary of each session)
  are saved **only on that iPhone**, like craving check-ins. Steady doesn't put them in
  iCloud storage or sync them to your other devices, and the Mac app has no coach. If your
  iPhone backs up to iCloud, iOS includes them in that device backup like any other app
  data.
- Whether you turned the coach on is also kept only on that iPhone (and in its device
  backup, the same way).
- You can delete your conversations at any time in Steady's Settings → Coach → "Delete coach
  history". Turning the coach off doesn't delete them. Deleting the app also removes them
  from the iPhone; an earlier iCloud Backup of the phone may still contain them until that
  backup is replaced or deleted.
- The data export (JSON) includes each coach session's date, kind (weekly check-in or chat)
  and summary, not the full transcript. A summary may mention numbers the coach talked
  about, such as your steps.
- The coach isn't medical advice and can't diagnose or treat anything. It won't set calorie
  targets, weight goals or diets. For questions about your health, talk to a doctor.

## Apple Health

On iPhone, with your permission, Steady reads your daily steps, active energy, resting
energy, weight and calories eaten (dietary energy, which apps like Cal AI can write to Apple
Health) from Apple Health and shows them in the app. Weight shows as a smoothed trend and
that day's reading. When Apple Health has calories eaten for a day, the iPhone shows that
total in place of one you imported from a Cal AI PDF; the imported total stays as it was, and
it's what your Mac shows. Steady:

- reads them fresh from Apple Health each time and doesn't save them, so Steady never puts
  them in its iCloud storage or in its own data on the iPhone (and so they aren't in Steady's
  part of an iCloud Backup or in the data export);
- never writes anything to Apple Health;
- never shares them with anyone, with one exception: if you turn on the coach, a coach
  conversation sends the week's daily totals (not weight) to Anthropic, only to write the
  coach's replies (see "Coach");
- never uses them for advertising. An export you make yourself (Settings → Export) includes
  a short summary of each coach session, and a summary may mention a number the coach
  discussed.

Apple Health keeps its own copy of this data, and syncs it through iCloud if you've turned
on Health in iCloud. That's Apple's storage, managed in the Health app and your iCloud
settings, not Steady's. You can turn off Steady's access at any time in the Health app or in
Settings → Privacy & Security → Health. The Mac app doesn't use Apple Health.

## What Steady doesn't do

- No Steady servers that keep your data, and nothing is sent to the developer. The coach,
  if you turn it on, is the one exception to "nothing leaves your devices": its conversations
  go through Steady's coach server, which keeps none of it, to Anthropic, only for the
  coach's replies (see "Coach").
- No analytics, advertising or tracking. Anthropic, for the coach's replies with your
  permission, is the only third party that receives your data.
- No selling of your data, and no sharing of it beyond the coach's replies.

Apple may pass crash reports to the developer if you've turned on sharing with app
developers in your device's analytics settings, and feedback you send through TestFlight goes
to the developer. Both are handled by Apple, not by Steady.

When you choose to share something, such as a week card image or an export file, it goes
where you send it through the system share sheet. Steady doesn't send it anywhere itself.

## Your data, your control

- **Export:** in Steady's Settings you can export your data as CSV or JSON.
- **Delete:** deleting the app removes its data from that device. Craving check-ins can also
  be deleted on their own in Settings → Cravings, and coach conversations in Settings →
  Coach.
- **Coach:** turn it on or off in Settings → Coach. Off, it sends nothing. To delete the copy in
  iCloud, go to Settings → [your name] → iCloud → Manage Storage (on Mac: System Settings →
  [your name] → iCloud → Manage) and delete Steady's data.

## Changes

If this policy changes, the updated version will be posted at this address with a new
effective date.

## Contact

Privacy questions or data requests: email **jordannnabugwu@gmail.com**. Please don't post personal
details in public GitHub issues. Other questions about the app: <https://github.com/jnnabugwu/steady/issues>.
