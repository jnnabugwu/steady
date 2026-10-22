import CloudKit
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    SteadyAccountChannel.register(messenger: flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()
  }
}

/// The `steady/account` platform channel (#53), macOS side. The Dart side is
/// `MethodChannelAccountStatusRepository` in `features/account/account_data`;
/// change both together. The iOS twin lives in `ios/Runner/AppDelegate.swift`.
///
/// Methods:
/// - `accountStatus` returns one of `available`, `noAccount`, `restricted`,
///   `temporarilyUnavailable`, `couldNotDetermine`, `notConfigured`.
/// - `openAccountSettings` opens the Apple Account pane of System Settings.
///
/// **`SteadyCloudKitEnabled` (Info.plist, Bool).** `CKContainer.default()`
/// crashes the app when there's no iCloud/CloudKit entitlement and container,
/// and this build has neither yet. So unless `SteadyCloudKitEnabled` is `true`,
/// `accountStatus` answers `notConfigured` without touching CloudKit, and the
/// app never blocks on it. It's `false` in `Runner/Info.plist` today; #43 adds
/// the container and entitlement and flips it to `true` in the same change.
private enum SteadyAccountChannel {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "steady/account", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "accountStatus":
        readAccountStatus(result)
      case "openAccountSettings":
        openAccountSettings(result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static var cloudKitEnabled: Bool {
    Bundle.main.object(forInfoDictionaryKey: "SteadyCloudKitEnabled") as? Bool ?? false
  }

  private static func readAccountStatus(_ result: @escaping FlutterResult) {
    guard cloudKitEnabled else {
      result("notConfigured")
      return
    }
    CKContainer.default().accountStatus { status, error in
      DispatchQueue.main.async {
        if let error = error {
          result(
            FlutterError(
              code: "accountStatusFailed", message: error.localizedDescription, details: nil))
          return
        }
        result(wireString(status))
      }
    }
  }

  private static func wireString(_ status: CKAccountStatus) -> String {
    switch status {
    case .available: return "available"
    case .noAccount: return "noAccount"
    case .restricted: return "restricted"
    case .couldNotDetermine: return "couldNotDetermine"
    default:
      // `.temporarilyUnavailable` is macOS 12+, newer than the deployment
      // target. Anything unknown is `couldNotDetermine`, which never blocks.
      if #available(macOS 12.0, *), status == .temporarilyUnavailable {
        return "temporarilyUnavailable"
      }
      return "couldNotDetermine"
    }
  }

  /// Tries the Apple Account pane, newest name first, then System Settings
  /// itself. `com.apple.systempreferences.AppleIDSettings` is the pane's id on
  /// macOS 13+ (checked on macOS 26 Tahoe); `com.apple.preferences.AppleIDPrefPane`
  /// is the System Preferences pane on macOS 12 and earlier.
  private static func openAccountSettings(_ result: @escaping FlutterResult) {
    var candidates = [
      "x-apple.systempreferences:com.apple.preferences.AppleIDPrefPane",
      "x-apple.systempreferences:",
    ]
    if #available(macOS 13.0, *) {
      candidates.insert("x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings", at: 0)
    }
    for candidate in candidates {
      if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
        result(nil)
        return
      }
    }
    result(
      FlutterError(code: "openSettingsFailed", message: "Could not open System Settings", details: nil))
  }
}
