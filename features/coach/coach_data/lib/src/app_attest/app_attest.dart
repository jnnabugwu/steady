import 'dart:typed_data';

import 'package:failures/failures.dart';

/// Apple App Attest, as the hosted coach uses it (#150): every request to
/// Steady's coach proxy proves it comes from the genuine app on a real
/// iPhone. iOS only; the Mac has no coach (CLAUDE.md §11).
///
/// A thin wrapper over `DCAppAttestService` (the `steady/app_attest`
/// channel). The caller computes every `clientDataHash` and owns the
/// challenge/register/assert flow against the proxy (#151); this interface
/// only talks to the Secure Enclave. Every platform error comes back as an
/// [AppAttestFailure], never a `PlatformException` (CLAUDE.md §9).
abstract interface class AppAttest {
  /// Whether this device can attest. Always false in the Simulator.
  Future<bool> isSupported();

  /// Creates a new App Attest key and returns its key id (base64). The
  /// private key never leaves the Secure Enclave.
  ResultFuture<String> generateKey();

  /// Apple's attestation (base64 CBOR) that [keyId] belongs to this app on
  /// this device, over [clientDataHash] (SHA-256, 32 bytes). Once per key:
  /// Apple rate-limits attestation.
  ResultFuture<String> attestKey(String keyId, Uint8List clientDataHash);

  /// An assertion (base64 CBOR) signed by [keyId] over [clientDataHash]
  /// (SHA-256, 32 bytes). Once per request.
  ResultFuture<String> generateAssertion(
    String keyId,
    Uint8List clientDataHash,
  );
}

/// Where the attested key id is kept between launches. The key id isn't
/// secret, but it must survive a relaunch: attesting again on every launch
/// would hit Apple's rate limit.
abstract interface class AppAttestKeyStore {
  /// The stored key id, or `null` if this install hasn't attested yet.
  ResultFuture<String?> read();

  /// Stores [keyId] after a successful registration with the proxy.
  ResultFuture<Unit> write(String keyId);

  /// Forgets the key id, so the next request generates and attests a new
  /// key (after `invalidKey`, or the proxy's `attestation_failed`).
  ResultFuture<Unit> clear();
}

/// Why App Attest failed, as a stable wire code from the Swift side.
enum AppAttestFailureReason {
  /// This device can't attest (Simulator, or unsupported hardware).
  unsupported,

  /// The key is gone or invalid: generate a new one and attest again.
  invalidKey,

  /// Apple's attestation service is unavailable: retry later.
  serviceUnavailable,

  /// A malformed argument (for example a hash that isn't 32 bytes).
  invalidInput,

  /// Anything else.
  unknown,
}

/// A typed App Attest failure (CLAUDE.md §9).
class AppAttestFailure extends Failure {
  /// A failure for [reason], with a human-readable [message].
  const AppAttestFailure(this.reason, super.message, {super.cause});

  /// What went wrong, so the caller knows whether to re-attest or retry.
  final AppAttestFailureReason reason;

  @override
  List<Object?> get props => [reason, message];
}
