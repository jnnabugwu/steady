import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Retry policy for this package's repository-backed Notifiers.
///
/// A [Failure] has already been mapped at the `_data` boundary (CLAUDE.md
/// §9), so it is surfaced immediately as `AsyncError` instead of being
/// retried. Riverpod 3's default retry would otherwise keep the provider in
/// `AsyncLoading` for up to 10 attempts before the UI saw the error. Any
/// other error falls back to Riverpod's default retry.
Duration? retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);
