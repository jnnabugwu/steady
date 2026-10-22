import Foundation

/// One record's stored values, detached from SwiftData so that merging and
/// channel (de)serialization are plain functions over plain values.
struct MetricRow: Equatable {
    /// The day, as `yyyy-MM-dd`. A string key rather than a `Date`, so the
    /// same calendar day can't drift between devices in different time
    /// zones.
    var day: String
    var caloriesEaten: Int?
    var caloriesBurnedActive: Int?
    var caloriesBurnedBasal: Int?
    var steps: Int?
    /// The Dart `LoggingStatus` enum name. Stored as given; Dart validates.
    var loggingStatus: String?
    var modifiedAt: Date
}

/// Collapses several records for the same day into one.
///
/// CloudKit can't enforce uniqueness, so two devices can each create a
/// record for the same day before either has synced the other's. For each
/// field this takes the non-nil value from the highest-ranked record that
/// has one (see `outranks`: newest `modifiedAt`, ties broken by the values).
/// The result keeps the top record's `modifiedAt` (it isn't bumped), so two
/// devices merging the same set reach the same row, whatever order their
/// stores return the records in.
///
/// Returns nil only for an empty input.
func mergeDuplicates(_ rows: [MetricRow]) -> MetricRow? {
    let highestFirst = rows.sorted { $0.outranks($1) }
    guard var merged = highestFirst.first else { return nil }
    for lower in highestFirst.dropFirst() {
        merged.caloriesEaten = merged.caloriesEaten ?? lower.caloriesEaten
        merged.caloriesBurnedActive =
            merged.caloriesBurnedActive ?? lower.caloriesBurnedActive
        merged.caloriesBurnedBasal =
            merged.caloriesBurnedBasal ?? lower.caloriesBurnedBasal
        merged.steps = merged.steps ?? lower.steps
        merged.loggingStatus = merged.loggingStatus ?? lower.loggingStatus
    }
    return merged
}

extension MetricRow {
    /// Whether this row takes precedence over `other` among same-day
    /// duplicates: the later `modifiedAt` wins. Equal timestamps (two
    /// devices writing in the same instant, or a clock that only ticks
    /// coarsely) are broken by the stored values themselves, compared
    /// field by field in a fixed order (`day`, `caloriesEaten`,
    /// `caloriesBurnedActive`, `caloriesBurnedBasal`, `steps`,
    /// `loggingStatus`; nil lowest, strings by UTF-8 bytes), and the greater
    /// row wins. Every device holds the same values, so every device picks
    /// the same winner. Only rows with identical values still tie, and
    /// then either one gives the same result.
    func outranks(_ other: MetricRow) -> Bool {
        if modifiedAt != other.modifiedAt { return modifiedAt > other.modifiedAt }
        let order = [
            compareBytes(day, other.day),
            compareOptional(caloriesEaten, other.caloriesEaten),
            compareOptional(caloriesBurnedActive, other.caloriesBurnedActive),
            compareOptional(caloriesBurnedBasal, other.caloriesBurnedBasal),
            compareOptional(steps, other.steps),
            compareBytes(loggingStatus, other.loggingStatus),
        ]
        return (order.first { $0 != 0 } ?? 0) > 0
    }
}

/// -1, 0 or 1; nil sorts lowest.
private func compareOptional(_ a: Int?, _ b: Int?) -> Int {
    switch (a, b) {
    case (nil, nil): return 0
    case (nil, _): return -1
    case (_, nil): return 1
    case let (a?, b?): return a < b ? -1 : (a == b ? 0 : 1)
    }
}

/// -1, 0 or 1 by UTF-8 bytes (not locale or Unicode collation, so it's the
/// same everywhere); nil sorts lowest.
private func compareBytes(_ a: String?, _ b: String?) -> Int {
    switch (a, b) {
    case (nil, nil): return 0
    case (nil, _): return -1
    case (_, nil): return 1
    case let (a?, b?):
        let (x, y) = (Array(a.utf8), Array(b.utf8))
        return x == y ? 0 : (x.lexicographicallyPrecedes(y) ? -1 : 1)
    }
}

// MARK: - Channel wire format

/// Keys of a row map on the `steady/daily_metrics` channel. Same names as
/// the Dart side's `daily_metric_json.dart`.
enum RowKey {
    static let date = "date"
    static let caloriesEaten = "caloriesEaten"
    static let caloriesBurnedActive = "caloriesBurnedActive"
    static let caloriesBurnedBasal = "caloriesBurnedBasal"
    static let steps = "steps"
    static let loggingStatus = "loggingStatus"

    static let fields = [
        caloriesEaten, caloriesBurnedActive, caloriesBurnedBasal, steps,
        loggingStatus,
    ]
}

extension MetricRow {
    /// The row as a channel map. Nil fields are sent as `NSNull`, so the
    /// Dart side always sees every key.
    var channelMap: [String: Any] {
        [
            RowKey.date: day,
            RowKey.caloriesEaten: caloriesEaten ?? NSNull(),
            RowKey.caloriesBurnedActive: caloriesBurnedActive ?? NSNull(),
            RowKey.caloriesBurnedBasal: caloriesBurnedBasal ?? NSNull(),
            RowKey.steps: steps ?? NSNull(),
            RowKey.loggingStatus: loggingStatus ?? NSNull(),
        ]
    }

    /// Parses a row map sent by Dart. Every key must be present (a full-row
    /// replace with a missing key is a client bug, not an implicit nil).
    init(channelMap map: [String: Any], modifiedAt: Date) throws {
        for key in [RowKey.date] + RowKey.fields where map[key] == nil {
            throw StoreError.badArgs("Row is missing \"\(key)\"")
        }
        self.init(
            day: try dayString(map[RowKey.date], key: RowKey.date),
            caloriesEaten: try optionalInt(map, RowKey.caloriesEaten),
            caloriesBurnedActive: try optionalInt(map, RowKey.caloriesBurnedActive),
            caloriesBurnedBasal: try optionalInt(map, RowKey.caloriesBurnedBasal),
            steps: try optionalInt(map, RowKey.steps),
            loggingStatus: try optionalString(map, RowKey.loggingStatus),
            modifiedAt: modifiedAt
        )
    }
}

/// Validates a `yyyy-MM-dd` day key: exactly ten ASCII characters, digits
/// and dashes (`\z`, unlike `$`, doesn't accept a trailing newline). Shape
/// only; Dart owns calendar rules.
func dayString(_ value: Any?, key: String) throws -> String {
    guard let day = value as? String,
        day.range(of: #"^[0-9]{4}-[0-9]{2}-[0-9]{2}\z"#, options: .regularExpression) != nil
    else {
        throw StoreError.badArgs("\"\(key)\" must be a yyyy-MM-dd string")
    }
    return day
}

/// An integer field. A Bool or floating-point NSNumber is rejected rather
/// than converted (`intValue` would silently truncate 1.5 to 1).
private func optionalInt(_ map: [String: Any], _ key: String) throws -> Int? {
    guard let value = map[key], !(value is NSNull) else { return nil }
    guard let number = value as? NSNumber,
        CFGetTypeID(number) != CFBooleanGetTypeID(),
        !CFNumberIsFloatType(number)
    else {
        throw StoreError.badArgs("\"\(key)\" must be an int or null")
    }
    return number.intValue
}

private func optionalString(_ map: [String: Any], _ key: String) throws -> String? {
    guard let value = map[key], !(value is NSNull) else { return nil }
    guard let string = value as? String else {
        throw StoreError.badArgs("\"\(key)\" must be a string or null")
    }
    return string
}
