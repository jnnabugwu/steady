import 'dart:convert';
import 'dart:io';

import 'package:coach_data/src/app_attest/app_attest.dart';
import 'package:failures/failures.dart';

/// An [AppAttestKeyStore] kept in one small JSON file on this iPhone,
/// `{"keyId": "<base64 key id>"}`.
///
/// The key id isn't secret (the private key never leaves the Secure
/// Enclave), so a plain file is enough; it only has to survive a relaunch.
/// The app keeps it in the application support directory, next to
/// `coach_sessions.json`, the same way `FileCoachRepository` is given its
/// file. Like any local file it's in the person's own device backup; a key
/// id restored onto another iPhone names a key that iPhone doesn't have,
/// which App Attest reports as `invalidKey`, and the caller clears this
/// store and attests a new key.
///
/// - **Lazy.** The constructor does no I/O; the file is located on first
///   use. A missing file is no key (`Ok(null)`).
/// - **Serialized.** Operations run one at a time in call order.
/// - **Atomic writes.** [write] goes to `<file>.tmp` and is renamed over
///   the file, so a crash mid-write leaves the previous key id intact.
///   Parent directories are created if missing.
/// - **Unreadable contents are no key.** If the file isn't the JSON above
///   with a well-formed key id (corrupt, or a key id that isn't standard
///   base64 of 32 bytes, see [isAppAttestKeyId]), [read] returns
///   `Ok(null)`: losing a key id costs one new attestation, which is
///   exactly what the caller does for `null`, while an `Err` would stop the
///   coach until something cleared the file. The next [write] replaces it.
///   [write] only accepts a well-formed key id (`ValidationFailure`
///   otherwise), so it never stores one [read] would discard.
/// - **File-system errors** (the file can't be found, read, written or
///   deleted) are `Err(AppAttestKeyStoreFailure)`; the caller can still
///   attest, but shouldn't trust that the key id will be kept.
class FileAppAttestKeyStore implements AppAttestKeyStore {
  /// Creates a store backed by [file]. Does no I/O until first use.
  FileAppAttestKeyStore(File file) : this.locatedBy(() async => file);

  /// Creates a store whose file is found by [locate] on first use (e.g.
  /// under `getApplicationSupportDirectory()`). If [locate] throws, that
  /// call returns `Err(AppAttestKeyStoreFailure)` and the next call tries
  /// again.
  FileAppAttestKeyStore.locatedBy(Future<File> Function() locate)
    : _locate = locate;

  final Future<File> Function() _locate;

  File? _file;

  Future<void> _queue = Future<void>.value();

  static const _keyIdField = 'keyId';

  @override
  ResultFuture<String?> read() => _run((file) async {
    try {
      return Ok(_decode(await file.readAsBytes()));
    } on PathNotFoundException {
      return const Ok(null);
    } on FileSystemException catch (e) {
      return Err(
        AppAttestKeyStoreFailure(
          'Could not read the App Attest key file ${file.path}',
          cause: e,
        ),
      );
    }
  });

  @override
  ResultFuture<Unit> write(String keyId) => _run((file) async {
    if (!isAppAttestKeyId(keyId)) {
      return const Err(
        ValidationFailure('keyId must be standard base64 of 32 bytes'),
      );
    }
    final tmp = File('${file.path}.tmp');
    try {
      await file.parent.create(recursive: true);
      await tmp.writeAsString(jsonEncode({_keyIdField: keyId}), flush: true);
      await tmp.rename(file.path);
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        AppAttestKeyStoreFailure(
          'Could not write the App Attest key file ${file.path}',
          cause: e,
        ),
      );
    }
  });

  @override
  ResultFuture<Unit> clear() => _run((file) async {
    try {
      // The leftover `.tmp` first: a failure after it still leaves the
      // file of record, so [read] and disk agree.
      // Only "already gone" is ignored: anything else in the way (a
      // directory at the path, say) is an `Err`, since later writes would
      // fail on it too.
      for (final f in [File('${file.path}.tmp'), file]) {
        try {
          await f.delete();
        } on PathNotFoundException {
          // Already absent.
        }
      }
      return const Ok(unit);
    } on FileSystemException catch (e) {
      return Err(
        AppAttestKeyStoreFailure(
          'Could not delete the App Attest key file ${file.path}',
          cause: e,
        ),
      );
    }
  });

  /// The key id in [contents], or `null` if they aren't UTF-8
  /// `{"keyId": "<key id>"}` with a well-formed key id
  /// ([isAppAttestKeyId]).
  static String? _decode(List<int> contents) {
    try {
      final decoded = jsonDecode(utf8.decode(contents));
      if (decoded case {_keyIdField: final String keyId}
          when isAppAttestKeyId(keyId)) {
        return keyId;
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  /// Runs [op] with the located file, after every earlier operation.
  Future<Result<T>> _run<T>(Future<Result<T>> Function(File file) op) {
    final next = _queue.then((_) async {
      final File file;
      try {
        file = _file ??= await _locate();
      } on Object catch (e) {
        return Err<T>(
          AppAttestKeyStoreFailure(
            'Could not find the App Attest key file',
            cause: e,
          ),
        );
      }
      return await op(file);
    });
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }
}

/// Whether [keyId] has the shape of a `DCAppAttestService.generateKey` key
/// id: standard base64 (with padding) of a 32-byte SHA-256 of the public
/// key, as the proxy expects it (steady-backend `README.md`, "Encodings").
bool isAppAttestKeyId(String keyId) {
  if (keyId.length != 44 || keyId.contains(RegExp('[^A-Za-z0-9+/=]'))) {
    return false;
  }
  try {
    return base64.decode(keyId).length == 32;
  } on FormatException {
    return false;
  }
}

/// The App Attest key file couldn't be found, read, written or deleted
/// ([FileAppAttestKeyStore]).
class AppAttestKeyStoreFailure extends Failure {
  /// A failure with a human-readable [message].
  const AppAttestKeyStoreFailure(super.message, {super.cause});
}
