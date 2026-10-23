#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif
import CoreData
import Foundation

/// Thin bridge from the `steady/daily_metrics` MethodChannel to
/// `DailyMetricsStore`. Translation only: argument parsing, row maps, and
/// `StoreError` to `FlutterError`. The contract is documented in
/// `lib/daily_metrics_store.dart`.
///
/// Also the stream handler for `steady/daily_metrics/changes`: while Dart
/// listens, it observes `NSPersistentStoreRemoteChange` for the open store,
/// debounces, and emits an event when the store changed through something
/// other than the channel itself (a CloudKit import), so screens re-read.
public final class DailyMetricsStorePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    /// Opened on first use, so registering the plugin can't fail.
    private var store: DailyMetricsStore?
    /// The test store selected by `useStore`, or nil for the real one.
    private var testStoreName: String?

    /// Set while Dart listens to the changes channel.
    private var eventSink: FlutterEventSink?
    private var remoteChangeObserver: NSObjectProtocol?
    private var pendingCheck: DispatchWorkItem?
    /// Counts emitted events; the payload, for logs.
    private var changeCount = 0
    /// CloudKit imports land as a burst of saves; one event per burst.
    private static let debounce: DispatchTimeInterval = .milliseconds(400)

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
            let messenger = registrar.messenger()
        #else
            let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(
            name: "steady/daily_metrics", binaryMessenger: messenger)
        let plugin = DailyMetricsStorePlugin()
        registrar.addMethodCallDelegate(plugin, channel: channel)
        FlutterEventChannel(name: "steady/daily_metrics/changes", binaryMessenger: messenger)
            .setStreamHandler(plugin)
    }

    // MARK: - Changes channel

    public func onListen(
        withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink
    ) -> FlutterError? {
        eventSink = events
        if remoteChangeObserver == nil {
            // Posted on a background queue; hop to the main (platform)
            // thread, where the store is used and events must be sent.
            remoteChangeObserver = NotificationCenter.default.addObserver(
                forName: .NSPersistentStoreRemoteChange, object: nil, queue: nil
            ) { [weak self] notification in
                let url = notification.userInfo?["storeURL"] as? URL
                DispatchQueue.main.async { self?.storeDidChange(url: url) }
            }
        }
        return nil
    }

    /// Idempotent: Dart sends `cancel` whenever its listener is torn down,
    /// even after the stream ended or a `listen` failed, so this must
    /// tolerate having no active sink or observer.
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        if let remoteChangeObserver {
            NotificationCenter.default.removeObserver(remoteChangeObserver)
        }
        remoteChangeObserver = nil
        pendingCheck?.cancel()
        pendingCheck = nil
        return nil
    }

    /// Main thread. Schedules one check per burst of notifications for the
    /// open store; other stores (another app's, a released test store) are
    /// ignored.
    private func storeDidChange(url: URL?) {
        guard let store, let url,
            url.standardizedFileURL.resolvingSymlinksInPath()
                == store.url.standardizedFileURL.resolvingSymlinksInPath()
        else { return }
        pendingCheck?.cancel()
        let check = DispatchWorkItem { [weak self] in self?.emitIfForeign() }
        pendingCheck = check
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.debounce, execute: check)
    }

    /// Main thread. Emits `changeCount` if the store changed through
    /// something other than this channel since the last check.
    private func emitIfForeign() {
        pendingCheck = nil
        guard let eventSink, let store, store.hasForeignChanges() else { return }
        changeCount += 1
        eventSink(changeCount)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            let args = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "get":
                let day = try dayString(args["date"], key: "date")
                result(try openStore().get(day: day)?.channelMap)
            case "range":
                let start = try dayString(args["start"], key: "start")
                let end = try dayString(args["end"], key: "end")
                result(try openStore().range(start: start, end: end).map(\.channelMap))
            case "put":
                let row = try MetricRow(channelMap: args, modifiedAt: Date())
                result(try openStore().put(row).channelMap)
            case "remove":
                try openStore().remove(day: try dayString(args["date"], key: "date"))
                result(nil)
            case "capabilities":
                // Doesn't open the store: safe to call before `useStore`.
                result(["historyFiltering": DailyMetricsStore.filtersOwnWrites])
            case "initializeCloudKitSchema":
                // Debug builds only; in release this falls through to
                // `FlutterMethodNotImplemented` below.
                #if DEBUG
                    initializeCloudKitSchema(result: result)
                #else
                    result(FlutterMethodNotImplemented)
                #endif
            case "useStore":
                try useStore(args["name"])
                result(nil)
            case "reset":
                try openStore(testOnly: true).reset()
                result(nil)
            case "insertRecordForTesting":
                guard let rowMap = args["row"] as? [String: Any],
                    let millis = args["modifiedAtMillis"] as? NSNumber
                else { throw StoreError.badArgs("Expected {row, modifiedAtMillis}") }
                let modifiedAt = Date(timeIntervalSince1970: millis.doubleValue / 1000)
                let row = try MetricRow(channelMap: rowMap, modifiedAt: modifiedAt)
                try openStore(testOnly: true).insertRecordForTesting(row)
                result(nil)
            case "simulateImportForTesting":
                guard let rowMap = args["row"] as? [String: Any],
                    let millis = args["modifiedAtMillis"] as? NSNumber
                else { throw StoreError.badArgs("Expected {row, modifiedAtMillis}") }
                let modifiedAt = Date(timeIntervalSince1970: millis.doubleValue / 1000)
                let row = try MetricRow(channelMap: rowMap, modifiedAt: modifiedAt)
                try openStore(testOnly: true).simulateImportForTesting(row)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let error as StoreError {
            result(FlutterError(code: error.code, message: error.message, details: nil))
        } catch {
            result(FlutterError(code: "unknown", message: "\(error)", details: nil))
        }
    }

    #if DEBUG
        /// Set while `initializeCloudKitSchema` runs, so a second tap can't
        /// start a second throwaway container.
        private var schemaInitRunning = false

        /// Debug builds only (#93): pushes the full model schema to the
        /// CloudKit development environment through a throwaway store (see
        /// `CloudKitSchemaInitializer`), off the main thread. Replies
        /// `{recordTypes: [{name, fields: [{name, type}]}]}`, or a
        /// `FlutterError` coded `cloudkit_disabled` (no CloudKit container
        /// in Info.plist), `schema_init_running` (already running), or
        /// `schema_init_failed`.
        private func initializeCloudKitSchema(result: @escaping FlutterResult) {
            guard
                let containerId = DailyMetricsStore.cloudKitContainer(
                    info: Bundle.main.infoDictionary)
            else {
                result(
                    FlutterError(
                        code: "cloudkit_disabled",
                        message: "CloudKit is off: set \(DailyMetricsStore.cloudKitEnabledKey) "
                            + "and \(DailyMetricsStore.cloudKitContainerKey) in Info.plist",
                        details: nil))
                return
            }
            guard !schemaInitRunning else {
                result(
                    FlutterError(
                        code: "schema_init_running",
                        message: "The CloudKit schema is already being initialized", details: nil))
                return
            }
            schemaInitRunning = true
            DispatchQueue.global(qos: .userInitiated).async {
                let reply: Any
                do {
                    reply = [
                        "containerIdentifier": containerId,
                        "recordTypes": try CloudKitSchemaInitializer.run(
                            containerIdentifier: containerId),
                    ]
                } catch let failure as CloudKitSchemaInitializer.Failure {
                    reply = FlutterError(
                        code: "schema_init_failed", message: failure.message, details: nil)
                } catch {
                    reply = FlutterError(
                        code: "schema_init_failed", message: "\(error)", details: nil)
                }
                DispatchQueue.main.async {
                    self.schemaInitRunning = false
                    result(reply)
                }
            }
        }
    #endif

    /// The current store, opened on first use. `testOnly` refuses with
    /// `not_test_store` unless a test store from `useStore(name)` is
    /// selected, before anything is opened, so a test-only call can never
    /// open (or create) the real store, let alone change it. The store
    /// methods check again.
    private func openStore(testOnly: Bool = false) throws -> DailyMetricsStore {
        if testOnly, testStoreName == nil { throw StoreError.notTestStore }
        if let store { return store }
        let opened = try DailyMetricsStore(testStoreName: testStoreName)
        store = opened
        return opened
    }

    /// Test only: switches to the local test store `name` (null for the
    /// real store). A test store is reopened right away, even for the same
    /// name, so a test can check what actually reached disk. The real store
    /// is left to open lazily on its next use, so a test's teardown never
    /// opens it.
    private func useStore(_ name: Any?) throws {
        var newName: String?
        if let name, !(name is NSNull) {
            guard let string = name as? String,
                string.range(of: #"^[A-Za-z0-9_-]+\z"#, options: .regularExpression) != nil
            else { throw StoreError.badArgs("\"name\" must match [A-Za-z0-9_-]+ or be null") }
            newName = string
        }
        store = nil  // Release the old container before opening the new one.
        pendingCheck?.cancel()  // A check for the old store has nothing to read.
        pendingCheck = nil
        testStoreName = newName
        if newName != nil { _ = try openStore() }
    }
}
