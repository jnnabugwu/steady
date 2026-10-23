import Flutter
import HealthKit

/// The `steady/healthkit` platform channel (#74), iOS only. The Dart side is
/// `MethodChannelHealthKitRepository` in `features/health_sync/health_sync_data`
/// (contract: `HealthKitChannel` in `health_kit_wire.dart`); change both
/// together. There is no macOS twin on purpose: the iPhone is the only
/// HealthKit reader, and the Mac has no Health data. The Dart side shows
/// these values live and never stores them in the iCloud-synced store (App
/// Store guideline 5.1.3(ii)).
///
/// Read-only. Steady asks to read step count, active energy and basal energy,
/// and never asks to write anything to Health.
///
/// Methods:
/// - `isAvailable` returns `HKHealthStore.isHealthDataAvailable()`.
/// - `authorizationStatus` returns `unavailable`, `notDetermined` (the
///   permission sheet hasn't been shown for every type yet) or `requested`
///   (it has). HealthKit never tells an app whether *read* access was granted,
///   so there is no "allowed" or "denied" answer to give.
/// - `requestAuthorization` shows the read-permission sheet if needed and
///   returns `nil` once it's dismissed (or at once, if it was shown before).
/// - `dailyTotals({start, end})`, both `yyyy-MM-dd`, inclusive, returns one
///   `{date, steps, activeKcal, basalKcal}` map per **local calendar day**.
///   Sums come from an `HKStatisticsCollectionQuery` (`.cumulativeSum`,
///   anchored at local midnight, one-day interval), so Health's own
///   de-duplication across iPhone and Watch applies, the same numbers the
///   Health app shows. A type with no samples that day is `nil`, never 0.
///   kcal and steps are rounded to whole numbers.
///
/// Errors are `FlutterError`s: code `unavailable` when Health isn't
/// available on this device, `authorizationNotDetermined` when `dailyTotals`
/// runs before the permission sheet was ever shown.
enum SteadyHealthKitChannel {
  /// Registers the channel. Called once from `AppDelegate`, next to the
  /// other runner-adjacent channels.
  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "SteadyHealthKitChannel") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "steady/healthkit", binaryMessenger: registrar.messenger())
    let handler = HealthKitHandler()
    channel.setMethodCallHandler { call, result in
      handler.handle(call, result: result)
    }
  }
}

private final class HealthKitHandler {
  private lazy var store = HKHealthStore()

  private static let stepCount = HKQuantityType(.stepCount)
  private static let activeEnergy = HKQuantityType(.activeEnergyBurned)
  private static let basalEnergy = HKQuantityType(.basalEnergyBurned)

  private static let readTypes: Set<HKObjectType> = [stepCount, activeEnergy, basalEnergy]

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(HKHealthStore.isHealthDataAvailable())
    case "authorizationStatus":
      authorizationStatus(result)
    case "requestAuthorization":
      requestAuthorization(result)
    case "dailyTotals":
      dailyTotals(call.arguments, result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static var unavailableError: FlutterError {
    FlutterError(
      code: "unavailable", message: "Apple Health is not available on this device", details: nil)
  }

  private func authorizationStatus(_ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result("unavailable")
      return
    }
    store.getRequestStatusForAuthorization(toShare: [], read: Self.readTypes) { status, error in
      DispatchQueue.main.async {
        if let error = error {
          result(
            FlutterError(
              code: "authorizationStatusFailed", message: error.localizedDescription,
              details: nil))
          return
        }
        switch status {
        case .unnecessary: result("requested")
        // `.shouldRequest`, `.unknown` and anything newer: asking again is
        // harmless, iOS shows the sheet at most once per type.
        default: result("notDetermined")
        }
      }
    }
  }

  private func requestAuthorization(_ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(Self.unavailableError)
      return
    }
    store.requestAuthorization(toShare: [], read: Self.readTypes) { _, error in
      DispatchQueue.main.async {
        if let error = error {
          result(
            FlutterError(
              code: "authorizationFailed", message: error.localizedDescription, details: nil))
          return
        }
        // `success` only says the request completed, not what the user
        // chose, so there's nothing more to report.
        result(nil)
      }
    }
  }

  // MARK: - dailyTotals

  private static func dayFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }

  private func dailyTotals(_ arguments: Any?, _ result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(Self.unavailableError)
      return
    }
    let formatter = Self.dayFormatter()
    guard
      let args = arguments as? [String: Any],
      let startString = args["start"] as? String,
      let endString = args["end"] as? String,
      let startDay = formatter.date(from: startString),
      let endDay = formatter.date(from: endString)
    else {
      result(
        FlutterError(
          code: "invalidArguments", message: "Expected {start, end} as yyyy-MM-dd", details: nil))
      return
    }

    var calendar = Calendar.current
    calendar.timeZone = TimeZone.current
    let start = calendar.startOfDay(for: startDay)
    let lastDay = calendar.startOfDay(for: endDay)
    guard start <= lastDay, let endExclusive = calendar.date(byAdding: .day, value: 1, to: lastDay)
    else {
      result(
        FlutterError(code: "invalidArguments", message: "start is after end", details: nil))
      return
    }

    let group = DispatchGroup()
    let lock = NSLock()
    var sums: [HKQuantityType: [String: Double]] = [:]
    var firstError: Error?

    let units: [(HKQuantityType, HKUnit)] = [
      (Self.stepCount, .count()),
      (Self.activeEnergy, .kilocalorie()),
      (Self.basalEnergy, .kilocalorie()),
    ]
    for (type, unit) in units {
      group.enter()
      querySums(
        type: type, unit: unit, start: start, endExclusive: endExclusive, formatter: formatter
      ) { byDay, error in
        lock.lock()
        if let error = error, firstError == nil { firstError = error }
        sums[type] = byDay
        lock.unlock()
        group.leave()
      }
    }

    group.notify(queue: .main) {
      if let error = firstError {
        // Querying before the permission sheet was ever shown fails with
        // `errorAuthorizationNotDetermined`; after the sheet, a type the
        // user didn't allow just has no samples.
        let notDetermined =
          (error as? HKError)?.code == .errorAuthorizationNotDetermined
        result(
          FlutterError(
            code: notDetermined ? "authorizationNotDetermined" : "queryFailed",
            message: error.localizedDescription, details: nil))
        return
      }
      var rows: [[String: Any]] = []
      var day = start
      while day < endExclusive {
        let key = formatter.string(from: day)
        rows.append([
          "date": key,
          "steps": Self.rounded(sums[Self.stepCount]?[key]),
          "activeKcal": Self.rounded(sums[Self.activeEnergy]?[key]),
          "basalKcal": Self.rounded(sums[Self.basalEnergy]?[key]),
        ])
        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
        day = next
      }
      result(rows)
    }
  }

  /// `NSNull` for a day without samples, so the Dart side reads `null`.
  private static func rounded(_ value: Double?) -> Any {
    guard let value = value else { return NSNull() }
    return Int(value.rounded())
  }

  /// Per-day sums of [type] in [unit], keyed by `yyyy-MM-dd`. Days without
  /// samples are absent from the dictionary.
  private func querySums(
    type: HKQuantityType, unit: HKUnit, start: Date, endExclusive: Date,
    formatter: DateFormatter,
    completion: @escaping ([String: Double], Error?) -> Void
  ) {
    let predicate = HKQuery.predicateForSamples(
      withStart: start, end: endExclusive, options: .strictStartDate)
    let query = HKStatisticsCollectionQuery(
      quantityType: type,
      quantitySamplePredicate: predicate,
      options: .cumulativeSum,
      anchorDate: start,
      intervalComponents: DateComponents(day: 1))
    query.initialResultsHandler = { _, collection, error in
      if let error = error {
        // No data (including read access the user didn't allow) is not an
        // error to Steady: those days are just `nil`.
        if let hkError = error as? HKError, hkError.code == .errorNoData {
          completion([:], nil)
        } else {
          completion([:], error)
        }
        return
      }
      var byDay: [String: Double] = [:]
      for statistics in collection?.statistics() ?? [] {
        guard let sum = statistics.sumQuantity() else { continue }
        // Each interval starts at a local midnight (the anchor), so its
        // start date names the calendar day.
        byDay[formatter.string(from: statistics.startDate)] = sum.doubleValue(for: unit)
      }
      completion(byDay, nil)
    }
    store.execute(query)
  }
}
