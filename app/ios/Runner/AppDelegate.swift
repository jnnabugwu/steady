import CloudKit
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SteadyAccountChannel") {
      SteadyAccountChannel.register(messenger: registrar.messenger())
    }
    SteadyHealthKitChannel.register(with: engineBridge.pluginRegistry)
  }
}

/// The `steady/account` platform channel (#53), iOS side. The Dart side is
/// `MethodChannelAccountStatusRepository` in `features/account/account_data`;
/// change both together. The macOS twin lives in
/// `macos/Runner/MainFlutterWindow.swift`.
///
/// Methods:
/// - `accountStatus` returns one of `available`, `noAccount`, `restricted`,
///   `temporarilyUnavailable`, `couldNotDetermine`, `notConfigured`.
/// - `openAccountSettings` opens Settings. iOS has no public URL for the Apple
///   Account screen, so this is `UIApplication.openSettingsURLString` (Steady's
///   own page in Settings); the sign-in screen's copy tells the user where to
///   go from there.
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
      // `.temporarilyUnavailable` is iOS 15+, newer than the deployment
      // target. Anything unknown is `couldNotDetermine`, which never blocks.
      if #available(iOS 15.0, *), status == .temporarilyUnavailable {
        return "temporarilyUnavailable"
      }
      return "couldNotDetermine"
    }
  }

  private static func openAccountSettings(_ result: @escaping FlutterResult) {
    guard let url = URL(string: UIApplication.openSettingsURLString) else {
      result(FlutterError(code: "openSettingsFailed", message: "No Settings URL", details: nil))
      return
    }
    UIApplication.shared.open(url) { opened in
      if opened {
        result(nil)
      } else {
        result(
          FlutterError(code: "openSettingsFailed", message: "Could not open Settings", details: nil))
      }
    }
  }
}
