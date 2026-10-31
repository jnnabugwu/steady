# Steady Privacy Policy

Effective 31 October 2026.

Steady is an app for iPhone and Mac that shows your daily calories and a simple end-of-day
check-in. This policy describes what the app does with your data.

## The short version

- Steady has no servers and no accounts of its own. Your Apple ID and iCloud are the only
  account.
- Your data stays on your devices and in your own private iCloud storage. The developer
  can't see it.
- No analytics, no ads, no tracking, no third-party services. The one exception is beta
  builds from TestFlight, which send anonymous usage events (see "TestFlight beta builds").
  Versions from the App Store send nothing.

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

## Coach

On iPhone, Steady's coach talks with you about your week: what you logged, your check-ins,
your steps and your craving check-ins. It uses Apple's on-device model (Apple Intelligence),
so it works only on an iPhone that supports Apple Intelligence, with it turned on.

- The coach runs **entirely on your iPhone**. What you type and what it replies are never
  sent to a server, to the developer or to Apple's cloud models.
- Your conversations with the coach (the transcript and a short summary of each session)
  stay **on that iPhone**, like craving check-ins. Steady doesn't put them in iCloud storage
  or sync them to your other devices, and the Mac app has no coach. If your iPhone backs up
  to iCloud, iOS includes them in that device backup like any other app data.
- You can delete them at any time in Steady's Settings → Coach → "Delete coach history".
  Deleting the app also removes them from the iPhone; an earlier iCloud Backup of the phone
  may still contain them until that backup is replaced or deleted.
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
- never shares them with anyone, and never uses them for advertising. An export you make
  yourself (Settings → Export) includes a short summary of each coach session, and a
  summary may mention a number the coach discussed.

Apple Health keeps its own copy of this data, and syncs it through iCloud if you've turned
on Health in iCloud. That's Apple's storage, managed in the Health app and your iCloud
settings, not Steady's. You can turn off Steady's access at any time in the Health app or in
Settings → Privacy & Security → Health. The Mac app doesn't use Apple Health.

## TestFlight beta builds

If you're testing Steady through Apple's TestFlight app, the beta sends anonymous usage
events to [PostHog](https://posthog.com/privacy), an analytics service, so the developer can
see which features get used and where things go wrong. Versions from the App Store never do.

- **What's sent:** that something happened, with a few yes/no answers, labels or counts and
  nothing more. The events are: the app was installed, opened or closed; a check-in was saved
  (and whether it was logged, partial or skipped); a Cal AI PDF import finished (how many days
  it had) or failed; the craving check-in reached its end; whether the coach can run on this
  iPhone (and if not, why, such as Apple Intelligence being off); and, once per launch,
  whether Apple Health returned any steps and any calories eaten in the last seven days (yes
  or no, not the amounts). Each event also carries the app version, the iPhone model, the iOS
  version, language and time zone, and a random ID made for this install.
- **What's never sent:** your calories, steps, weight or any other Health value, your
  check-in dates, anything about a craving beyond reaching the end, anything you or the coach
  wrote, your name, email or Apple ID. There's no screen recording and no tracking across
  other apps or websites.
- PostHog receives your IP address with each request, as any web service does; Steady's
  PostHog project is set to discard it.
- **Turning it off:** Settings → Usage sharing → "Share anonymous usage". Steady stops
  sending at once and remembers the choice on that iPhone.

## What Steady doesn't do

- No Steady servers: nothing is sent to the developer or to anyone else. That includes the
  coach, which runs on the iPhone itself.
- No analytics, advertising or tracking, and no third-party services that receive your data,
  apart from the anonymous usage events in TestFlight beta builds described above.
- No selling or sharing of your data.

Apple may pass crash reports to the developer if you've turned on sharing with app
developers in your device's analytics settings, and feedback you send through TestFlight goes
to the developer. Both are handled by Apple, not by Steady.

When you choose to share something, such as a week card image or an export file, it goes
where you send it through the system share sheet. Steady doesn't send it anywhere itself.

## Your data, your control

- **Export:** in Steady's Settings you can export your data as CSV or JSON.
- **Delete:** deleting the app removes its data from that device. Craving check-ins can also
  be deleted on their own in Settings → Cravings, and coach conversations in Settings →
  Coach. To delete the copy in
  iCloud, go to Settings → [your name] → iCloud → Manage Storage (on Mac: System Settings →
  [your name] → iCloud → Manage) and delete Steady's data.

## Changes

If this policy changes, the updated version will be posted at this address with a new
effective date.

## Contact

Privacy questions or data requests: email **jordannnabugwu@gmail.com**. Please don't post personal
details in public GitHub issues. Other questions about the app: <https://github.com/jnnabugwu/steady/issues>.
