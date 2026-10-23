import Foundation
import SwiftData

/// A failure the channel reports back to Dart as a `FlutterError`.
enum StoreError: Error {
    case badArgs(String)
    case unavailable(Error)
    case fetchFailed(Error)
    case saveFailed(Error)
    case notTestStore

    var code: String {
        switch self {
        case .badArgs: return "bad_args"
        case .unavailable: return "store_unavailable"
        case .fetchFailed: return "fetch_failed"
        case .saveFailed: return "save_failed"
        case .notTestStore: return "not_test_store"
        }
    }

    var message: String {
        switch self {
        case .badArgs(let detail): return detail
        case .unavailable(let error): return "Could not open the store: \(error)"
        case .fetchFailed(let error): return "Fetch failed: \(error)"
        case .saveFailed(let error): return "Save failed: \(error)"
        case .notTestStore: return "Only allowed on a test store (call useStore first)"
        }
    }
}

/// The SwiftData store behind the channel. Every method is a plain storage
/// operation on `yyyy-MM-dd` keys; partial-field merging, clearing and
/// validation are the Dart repository's job.
///
/// Used from the platform thread only (the channel handler's thread), which
/// is also where its `ModelContext` is created.
final class DailyMetricsStore {
    /// Info.plist key: Bool. CloudKit sync is used only when this is true.
    static let cloudKitEnabledKey = "SteadyCloudKitEnabled"
    /// Info.plist key: String, the iCloud container, e.g.
    /// `iCloud.com.jmagic.steady`.
    static let cloudKitContainerKey = "SteadyCloudKitContainer"

    /// The test store in use, or nil for the real one.
    let testStoreName: String?
    /// The CloudKit container this store syncs through, or nil for local
    /// only.
    let cloudKitContainer: String?

    /// The store file, so remote-change notifications can be matched to
    /// it (`NSPersistentStoreRemoteChange` carries it as `storeURL`).
    let url: URL

    /// The author this store's own writes are tagged with in SwiftData's
    /// persistent history (iOS 18 / macOS 15+), so `hasForeignChanges` can
    /// tell them apart from CloudKit's imports.
    static let channelAuthor = "steady.daily_metrics_channel"

    /// Whether `hasForeignChanges` can tell this store's own writes apart
    /// (persistent history, iOS 18 / macOS 15+). When false, every save
    /// counts as foreign, own writes included.
    static var filtersOwnWrites: Bool {
        if #available(iOS 18, macOS 15, *) { return true }
        return false
    }

    private let container: ModelContainer
    private let context: ModelContext
    /// The last history transaction `hasForeignChanges` looked at, typed
    /// `Any` because `DefaultHistoryToken` needs iOS 18 / macOS 15.
    private var lastHistoryToken: Any?
    /// When this store was opened: the first history check only looks at
    /// transactions after it, rather than the whole history.
    private let openedAt = Date()

    /// Every SwiftData `@Model` in this store. The one list both the store's
    /// `Schema` and the debug CloudKit schema initializer use, so a model
    /// added here is always pushed by the initializer too.
    static let modelTypes: [any PersistentModel.Type] = [DailyMetricRecord.self]

    /// Opens the real store (nil) or a separate local test store.
    init(testStoreName: String?, info: [String: Any]? = Bundle.main.infoDictionary) throws {
        self.testStoreName = testStoreName
        // Test stores never sync, whatever the flag says.
        cloudKitContainer = testStoreName == nil ? Self.cloudKitContainer(info: info) : nil
        do {
            let schema = Schema(Self.modelTypes)
            url = try Self.storeDirectory().appendingPathComponent(
                testStoreName.map { "test-\($0).store" } ?? "steady.store")
            // `.none` is explicit on purpose: the default (`.automatic`)
            // turns CloudKit on by itself whenever the entitlement exists.
            let configuration = ModelConfiguration(
                schema: schema,
                url: url,
                cloudKitDatabase: cloudKitContainer.map { .private($0) } ?? .none
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            throw StoreError.unavailable(error)
        }
        context = ModelContext(container)
        context.autosaveEnabled = false
        if #available(iOS 18, macOS 15, *) {
            context.author = Self.channelAuthor
        }
    }

    /// The CloudKit container to sync through, or nil when CloudKit is off.
    /// On only when `SteadyCloudKitEnabled` is true and
    /// `SteadyCloudKitContainer` is a non-empty string. Without both, the
    /// store is plain local SwiftData and never touches CloudKit (which
    /// would crash without the iCloud entitlement).
    static func cloudKitContainer(info: [String: Any]?) -> String? {
        guard (info?[cloudKitEnabledKey] as? Bool) == true,
            let id = info?[cloudKitContainerKey] as? String,
            !id.trimmingCharacters(in: .whitespaces).isEmpty
        else { return nil }
        return id
    }

    /// `<Application Support>[/<bundle id> on macOS]/DailyMetrics/`, next to
    /// where `path_provider` puts the app's other support files.
    private static func storeDirectory() throws -> URL {
        var dir = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask,
            appropriateFor: nil, create: true)
        #if os(macOS)
            if let bundleId = Bundle.main.bundleIdentifier {
                dir.appendPathComponent(bundleId, isDirectory: true)
            }
        #endif
        dir.appendPathComponent("DailyMetrics", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Channel operations

    /// The row for `day`, merging duplicates first.
    func get(day: String) throws -> MetricRow? {
        try collapse(try records(matching: #Predicate { $0.day == day }))?.row
    }

    /// Every row from `start` to `end` inclusive, sorted by day, merging
    /// duplicates first. `yyyy-MM-dd` strings sort the same as the dates.
    func range(start: String, end: String) throws -> [MetricRow] {
        let all = try records(matching: #Predicate { $0.day >= start && $0.day <= end })
        let byDay = Dictionary(grouping: all, by: \.day)
        return try byDay.keys.sorted().compactMap { try collapse(byDay[$0]!)?.row }
    }

    /// Replaces the whole row for `row.day` (nil fields stored as nil),
    /// creating it if absent. Duplicates for that day are dropped, since
    /// the new row replaces all of them.
    func put(_ row: MetricRow) throws -> MetricRow {
        let day = row.day
        let existing = try records(matching: #Predicate { $0.day == day })
        let survivor = newest(existing) ?? {
            let record = DailyMetricRecord(day: day, modifiedAt: row.modifiedAt)
            context.insert(record)
            return record
        }()
        for record in existing where record !== survivor {
            context.delete(record)
        }
        survivor.apply(row)
        try save()
        return survivor.row
    }

    /// Deletes every record for `day`.
    func remove(day: String) throws {
        for record in try records(matching: #Predicate { $0.day == day }) {
            context.delete(record)
        }
        try save()
    }

    /// Test only: deletes every record in this store. Refused on the real
    /// store.
    func reset() throws {
        guard testStoreName != nil else { throw StoreError.notTestStore }
        for record in try records(matching: nil) {
            context.delete(record)
        }
        try save()
    }

    /// Test only: inserts `row` as a new record without merging, to
    /// simulate two devices each creating the same day.
    func insertRecordForTesting(_ row: MetricRow) throws {
        guard testStoreName != nil else { throw StoreError.notTestStore }
        let record = DailyMetricRecord(day: row.day, modifiedAt: row.modifiedAt)
        record.apply(row)
        context.insert(record)
        try save()
    }

    /// Test only: inserts `row` through a second `ModelContext` on the same
    /// container, under another author. That is the path a CloudKit import
    /// takes (the mirroring delegate saves through its own context), so a
    /// test can check the remote-change event without CloudKit.
    func simulateImportForTesting(_ row: MetricRow) throws {
        guard testStoreName != nil else { throw StoreError.notTestStore }
        let importer = ModelContext(container)
        if #available(iOS 18, macOS 15, *) {
            importer.author = "steady.test_import"
        }
        let record = DailyMetricRecord(day: row.day, modifiedAt: row.modifiedAt)
        record.apply(row)
        importer.insert(record)
        do {
            try importer.save()
        } catch {
            throw StoreError.saveFailed(error)
        }
    }

    // MARK: - Remote changes

    /// Whether the store changed, since the last call, through anything
    /// other than this store's own context: in practice, a CloudKit import.
    ///
    /// `NSPersistentStoreRemoteChange` fires for every save, this app's
    /// own channel writes included, so on iOS 18 / macOS 15+ this reads
    /// SwiftData's persistent history and ignores transactions authored by
    /// `channelAuthor`, and ones that changed no record (e.g. CloudKit
    /// bookkeeping). Older systems have no history API, so every change
    /// counts (the Dart side then re-reads after its own writes too, which
    /// is harmless). A failed history read also counts, for the same
    /// reason: a needless re-read is cheaper than a missed one.
    func hasForeignChanges() -> Bool {
        guard #available(iOS 18, macOS 15, *) else { return true }
        var descriptor = HistoryDescriptor<DefaultHistoryTransaction>()
        if let token = lastHistoryToken as? DefaultHistoryToken {
            descriptor.predicate = #Predicate { $0.token > token }
        } else {
            let since = openedAt
            descriptor.predicate = #Predicate { $0.timestamp > since }
        }
        let transactions: [DefaultHistoryTransaction]
        do {
            transactions = try context.fetchHistory(descriptor)
        } catch {
            return true
        }
        if let last = transactions.max(by: { $0.transactionIdentifier < $1.transactionIdentifier }) {
            lastHistoryToken = last.token
        }
        return transactions.contains { $0.author != Self.channelAuthor && !$0.changes.isEmpty }
    }

    // MARK: - Helpers

    private func records(
        matching predicate: Predicate<DailyMetricRecord>?
    ) throws -> [DailyMetricRecord] {
        do {
            return try context.fetch(FetchDescriptor(predicate: predicate))
        } catch {
            throw StoreError.fetchFailed(error)
        }
    }

    /// The highest-ranked record (see `MetricRow.outranks`), the same one
    /// on every device.
    private func newest(_ records: [DailyMetricRecord]) -> DailyMetricRecord? {
        records.max { $1.row.outranks($0.row) }
    }

    /// Merges same-day `records` into the highest-ranked one and deletes the rest,
    /// saving if anything changed. Returns the survivor.
    private func collapse(_ records: [DailyMetricRecord]) throws -> DailyMetricRecord? {
        guard records.count > 1 else { return records.first }
        guard let survivor = newest(records),
            let merged = mergeDuplicates(records.map(\.row))
        else { return nil }
        survivor.apply(merged)
        for record in records where record !== survivor {
            context.delete(record)
        }
        try save()
        return survivor
    }

    private func save() throws {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            context.rollback()
            throw StoreError.saveFailed(error)
        }
    }
}
