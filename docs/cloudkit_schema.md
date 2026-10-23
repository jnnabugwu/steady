# CloudKit schema: expected fields and the pre-deploy check

Container: `iCloud.com.jmagic.steady` (private database). SwiftData's CloudKit mirroring
(Core Data's `NSPersistentCloudKitContainer` underneath) names every record type and field
`CD_<name>`.

## Why there's a check at all

CloudKit's **Development** environment adds a field to a record type only the first time a
record is saved with a value in that field. Production is deployed from Development, can't
add fields at runtime, and is additive-only (a field can never be removed or renamed once
deployed). So a Development schema built up by normal use can be missing fields (the first
eight imported days only ever had `caloriesEaten`), and deploying it would ship a layout
that friends' devices then fail to sync into.

The fix (#93) is a debug-only initializer that pushes every attribute of every SwiftData
model, value or not, with `NSPersistentCloudKitContainer.initializeCloudKitSchema`.

## Expected record types

### `CD_DailyMetricRecord` (`DailyMetricRecord`, `packages_native/daily_metrics_store`)

| Field | Type |
| --- | --- |
| `CD_day` | String |
| `CD_caloriesEaten` | Int(64) |
| `CD_caloriesBurnedActive` | Int(64) |
| `CD_caloriesBurnedBasal` | Int(64) |
| `CD_steps` | Int(64) |
| `CD_loggingStatus` | String |
| `CD_modifiedAt` | Date/Time |
| `CD_entityName` | String (added by Core Data's mirroring) |

The initializer reports this same list back from the model it pushed, and
`app/integration_test/cloudkit_schema_init_test.dart` asserts it.

**Health fields stay in the schema.** `steps`, `caloriesBurnedActive` and
`caloriesBurnedBasal` are in the model, but per the App Store 5.1.3 decision (#98) Apple
Health values are no longer written to the synced store. They stay anyway: production is
additive-only, so they couldn't be removed later, and they may hold non-HealthKit values in
future. Expect them to be empty in every record for now.

Add the coach (#78) and notes (#83) record types here when they land, and add their models
to `CloudKitSchemaInitializer.modelTypes` (or their own store's equivalent).

## Before every production deploy

1. On the Mac signed into the iCloud account you develop with, run a **debug** build:
   `cd app && flutter run -d macos`. (The Developer section and the native method exist only
   in debug builds.)
2. Settings (gear on the home screen) → **Developer (debug builds only)** → **Initialize
   CloudKit schema**. Wait for the spinner (a few seconds to tens of seconds). It shows the
   record types and fields it pushed, or the error code (`cloudkit_disabled`,
   `schema_init_running`, `schema_init_failed`) and message.
   - Headless alternative: `flutter test integration_test/cloudkit_schema_init_test.dart -d
     macos --dart-define=RUN_CLOUDKIT_SCHEMA_INIT=true`.
3. Open [CloudKit Console](https://icloud.developer.apple.com/) →
   `iCloud.com.jmagic.steady` → **Development** → Schema → Record Types →
   `CD_DailyMetricRecord`. Confirm every field in the table above exists with that type.
4. Only then: Deploy Schema Changes (to Production).

It's safe to run repeatedly. It never touches the real store: it builds a Core Data model
from the SwiftData `@Model`s (`NSManagedObjectModel.makeManagedObjectModel(for:)`), opens it
on a throwaway store in the temp directory, pushes the schema, then removes the store and
deletes its files. Core Data saves one placeholder record per type to create the fields and
deletes it again, so no data is left behind in Development.

## Caveats

- **SwiftData compatibility.** This is Apple's documented pattern for SwiftData ("Syncing
  model data across a person's devices"): SwiftData has no `initializeCloudKitSchema` of its
  own, so a Core Data container is built from the same model. The record type and field
  names match SwiftData's own mirroring because both come from the same generated Core Data
  model. Apple's sample runs it on the real store's URL before the `ModelContainer` opens;
  Steady uses a throwaway URL instead, so it can run while the real store is open (verified
  on macOS: real store open, initializer succeeded).
- Removing the throwaway store cancels the import its mirroring had started, so the
  console logs `Told to tear down with reason: Store Removed` and an import error
  (`NSCocoaErrorDomain` 134407). That's expected and harmless.
- Debug builds talk to the **Development** environment (`environment=Sandbox` in the logs);
  TestFlight and App Store builds use Production. Never ship this to release: in release
  builds the native method doesn't exist and the Dart helper returns `not_available`.
