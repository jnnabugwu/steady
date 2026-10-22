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
/// field this takes the non-nil value from the most recently modified
/// record that has one. The result keeps the newest record's `modifiedAt`
/// (it isn't bumped), so two devices merging the same set reach the same
/// row.
///
/// Returns nil only for an empty input.
func mergeDuplicates(_ rows: [MetricRow]) -> MetricRow? {
    let newestFirst = rows.sorted { $0.modifiedAt > $1.modifiedAt }
    guard var merged = newestFirst.first else { return nil }
    for older in newestFirst.dropFirst() {
        merged.caloriesEaten = merged.caloriesEaten ?? older.caloriesEaten
        merged.caloriesBurnedActive =
            merged.caloriesBurnedActive ?? older.caloriesBurnedActive
        merged.caloriesBurnedBasal =
            merged.caloriesBurnedBasal ?? older.caloriesBurnedBasal
        merged.steps = merged.steps ?? older.steps
        merged.loggingStatus = merged.loggingStatus ?? older.loggingStatus
    }
    return merged
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

/// Validates a `yyyy-MM-dd` day key. Shape only; Dart owns calendar rules.
func dayString(_ value: Any?, key: String) throws -> String {
    guard let day = value as? String,
        day.range(of: #"^\d{4}-\d{2}-\d{2}$"#, options: .regularExpression) != nil
    else {
        throw StoreError.badArgs("\"\(key)\" must be a yyyy-MM-dd string")
    }
    return day
}

private func optionalInt(_ map: [String: Any], _ key: String) throws -> Int? {
    guard let value = map[key], !(value is NSNull) else { return nil }
    guard let number = value as? NSNumber,
        CFGetTypeID(number) != CFBooleanGetTypeID()
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
