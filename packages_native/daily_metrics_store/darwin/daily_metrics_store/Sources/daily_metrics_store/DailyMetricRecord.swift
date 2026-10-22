import Foundation
import SwiftData

/// One day's metrics, as stored by SwiftData (and, once enabled, synced by
/// CloudKit).
///
/// CloudKit-backed SwiftData rules (CLAUDE.md §7), followed even while
/// CloudKit is off so that turning it on needs no schema migration: every
/// attribute is optional or defaulted, nothing is `@Attribute(.unique)`,
/// and there are no relationships. Because uniqueness can't be enforced,
/// `day` can repeat across records; `DailyMetricsStore` merges duplicates
/// on read (see `mergeDuplicates`).
@Model
final class DailyMetricRecord {
    /// The day, as `yyyy-MM-dd`.
    var day: String = ""
    var caloriesEaten: Int?
    var caloriesBurnedActive: Int?
    var caloriesBurnedBasal: Int?
    var steps: Int?
    /// The Dart `LoggingStatus` enum name.
    var loggingStatus: String?
    /// When this record was last written. Decides which duplicate wins.
    var modifiedAt: Date = Date.distantPast

    init(day: String, modifiedAt: Date) {
        self.day = day
        self.modifiedAt = modifiedAt
    }

    var row: MetricRow {
        MetricRow(
            day: day,
            caloriesEaten: caloriesEaten,
            caloriesBurnedActive: caloriesBurnedActive,
            caloriesBurnedBasal: caloriesBurnedBasal,
            steps: steps,
            loggingStatus: loggingStatus,
            modifiedAt: modifiedAt
        )
    }

    /// Overwrites every stored value with `row`'s, nil included.
    func apply(_ row: MetricRow) {
        day = row.day
        caloriesEaten = row.caloriesEaten
        caloriesBurnedActive = row.caloriesBurnedActive
        caloriesBurnedBasal = row.caloriesBurnedBasal
        steps = row.steps
        loggingStatus = row.loggingStatus
        modifiedAt = row.modifiedAt
    }
}
