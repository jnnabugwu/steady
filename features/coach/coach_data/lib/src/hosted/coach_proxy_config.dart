import 'package:flutter/foundation.dart';

/// Where Steady's coach proxy is (`jnnabugwu/steady-backend`), and, in
/// debug builds only, how a request gets past a Preview deployment's
/// protections.
///
/// Built from `--dart-define`s ([CoachProxyConfig.fromEnvironment]):
///
/// - `COACH_PROXY_URL`: the proxy's base URL, one per build type (a debug
///   build points at a Preview deployment, TestFlight and the App Store at
///   Production). There's no default: unset, the coach reports itself off
///   (`CoachTurnedOffFailure`) instead of reaching for a URL.
/// - `COACH_DEV_BYPASS_TOKEN` (**debug builds only**): sent as
///   `x-steady-dev-bypass` instead of App Attest where App Attest isn't
///   supported (the Simulator). The proxy honours it only outside
///   Production.
/// - `VERCEL_PROTECTION_BYPASS` (**debug builds only**): sent as
///   `x-vercel-protection-bypass`, for a Preview deployment behind Vercel
///   Authentication.
///
/// **Release builds never carry the bypass.** [kDebugMode] is a
/// compile-time constant (`false` in profile and release), so in those
/// builds [CoachProxyConfig.fromEnvironment] reads neither bypass define:
/// the conditional folds to the empty string, and the define's value never
/// reaches the compiled app. `HostedCoachModel` guards its use of both with
/// [kDebugMode] again, so the code that would send them is dead in release
/// too. [coachProxyConfigFor] with `debugBuild: false` is what a release
/// build gets, and its tests check it drops both.
@immutable
class CoachProxyConfig {
  /// Creates a config. Prefer [CoachProxyConfig.fromEnvironment] outside
  /// tests.
  const CoachProxyConfig({
    this.baseUrl,
    this.devBypassToken,
    this.vercelProtectionBypass,
  });

  /// The config from this build's `--dart-define`s (see the class doc).
  factory CoachProxyConfig.fromEnvironment() => coachProxyConfigFor(
    debugBuild: kDebugMode,
    baseUrl: const String.fromEnvironment('COACH_PROXY_URL'),
    // Constant-folded to '' outside debug builds: see the class doc.
    devBypassToken: kDebugMode
        ? const String.fromEnvironment('COACH_DEV_BYPASS_TOKEN')
        : '',
    vercelProtectionBypass: kDebugMode
        ? const String.fromEnvironment('VERCEL_PROTECTION_BYPASS')
        : '',
  );

  /// The proxy's base URL, without a trailing slash, or `null` when this
  /// build has none (the coach is then off).
  final Uri? baseUrl;

  /// The dev bypass token, or `null`. Debug builds only.
  final String? devBypassToken;

  /// The Vercel Deployment Protection bypass secret, or `null`. Debug builds
  /// only.
  final String? vercelProtectionBypass;
}

/// The config for raw define values, as a [debugBuild] or a profile or
/// release build sees them.
///
/// [baseUrl] must be an absolute `https` URL (or, in a debug build, `http`,
/// for `vercel dev` on this Mac); anything else counts as none. Outside a
/// debug build both bypass values are dropped, whatever they are. Empty
/// values count as unset; pass `''` for a define that isn't set.
CoachProxyConfig coachProxyConfigFor({
  required bool debugBuild,
  required String baseUrl,
  required String devBypassToken,
  required String vercelProtectionBypass,
}) {
  String? debugOnly(String value) =>
      debugBuild && value.trim().isNotEmpty ? value.trim() : null;
  return CoachProxyConfig(
    baseUrl: _proxyUrl(baseUrl, debugBuild: debugBuild),
    devBypassToken: debugOnly(devBypassToken),
    vercelProtectionBypass: debugOnly(vercelProtectionBypass),
  );
}

Uri? _proxyUrl(String value, {required bool debugBuild}) {
  final url = Uri.tryParse(value.trim());
  if (url == null || !url.hasAuthority || url.host.isEmpty) return null;
  final schemeOk =
      url.scheme == 'https' || (debugBuild && url.scheme == 'http');
  if (!schemeOk || url.hasQuery || url.hasFragment) return null;
  final path = url.path.endsWith('/')
      ? url.path.substring(0, url.path.length - 1)
      : url.path;
  return url.replace(path: path);
}
