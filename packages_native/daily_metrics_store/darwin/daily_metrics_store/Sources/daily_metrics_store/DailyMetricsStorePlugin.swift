#if os(iOS)
    import Flutter
#elseif os(macOS)
    import FlutterMacOS
#endif
import Foundation

/// Thin bridge from the `steady/daily_metrics` MethodChannel to
/// `DailyMetricsStore`. Translation only: argument parsing, row maps, and
/// `StoreError` to `FlutterError`. The contract is documented in
/// `lib/daily_metrics_store.dart`.
public final class DailyMetricsStorePlugin: NSObject, FlutterPlugin {
    /// Opened on first use, so registering the plugin can't fail.
    private var store: DailyMetricsStore?
    /// The test store selected by `useStore`, or nil for the real one.
    private var testStoreName: String?

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
            let messenger = registrar.messenger()
        #else
            let messenger = registrar.messenger
        #endif
        let channel = FlutterMethodChannel(
            name: "steady/daily_metrics", binaryMessenger: messenger)
        registrar.addMethodCallDelegate(DailyMetricsStorePlugin(), channel: channel)
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
            case "useStore":
                try useStore(args["name"])
                result(nil)
            case "reset":
                try openStore().reset()
                result(nil)
            case "insertRecordForTesting":
                guard let rowMap = args["row"] as? [String: Any],
                    let millis = args["modifiedAtMillis"] as? NSNumber
                else { throw StoreError.badArgs("Expected {row, modifiedAtMillis}") }
                let modifiedAt = Date(timeIntervalSince1970: millis.doubleValue / 1000)
                let row = try MetricRow(channelMap: rowMap, modifiedAt: modifiedAt)
                try openStore().insertRecordForTesting(row)
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

    private func openStore() throws -> DailyMetricsStore {
        if let store { return store }
        let opened = try DailyMetricsStore(testStoreName: testStoreName)
        store = opened
        return opened
    }

    /// Test only: switches to the local test store `name` (null for the
    /// real store). Always reopens the container, even for the same name,
    /// so a test can check what actually reached disk.
    private func useStore(_ name: Any?) throws {
        var newName: String?
        if let name, !(name is NSNull) {
            guard let string = name as? String,
                string.range(of: #"^[A-Za-z0-9_-]+$"#, options: .regularExpression) != nil
            else { throw StoreError.badArgs("\"name\" must match [A-Za-z0-9_-]+ or be null") }
            newName = string
        }
        store = nil  // Release the old container before opening the new one.
        testStoreName = newName
        _ = try openStore()
    }
}
