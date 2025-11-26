import 'package:async/async.dart';
import 'package:essential_dart/src/types.dart';

/// A class that memoizes the result of a computation.
///
/// The [Memoizer] runs a computation once and caches the result. Subsequent
/// calls returns the cached value.
///
/// It supports both lazy and non-lazy execution.
///
/// Example:
/// ```dart
/// final memoizer = Memoizer<int>(computation: () => 42);
/// final result = await memoizer.result; // 42
/// ```
final class Memoizer<T> {
  /// Creates a [Memoizer].
  ///
  /// If [lazy] is `true` (default), the [computation] is not executed until
  /// [run] or [runComputation] is called, or [result] is accessed (if [computation] was provided).
  ///
  /// If [lazy] is `false`, [computation] must be provided and will be executed immediately
  /// and value can be accessed via [result].
  ///
  /// Throws [MemoizerConfigurationException] if [lazy] is `false` and [computation] is `null`.
  Memoizer({
    bool lazy = true,
    Computation<T>? computation,
  }) : _computation = computation {
    if (!lazy) {
      if (_computation == null) {
        throw const MemoizerConfigurationException(
          'computation cannot be null if `lazy` is set to false',
        );
      }
      _run();
    }
  }

  /// The default computation to run.
  final Computation<T>? _computation;

  /// AsyncMemoizer used internally
  AsyncMemoizer<T> _asyncMemoizer = AsyncMemoizer<T>();

  /// Returns `true` if the computation has been run.
  bool get hasRun => _asyncMemoizer.hasRun;

  /// Returns a [Future] that completes with the cached result.
  ///
  /// If the computation has not been run yet and a default computation was provided,
  /// it will be executed automatically.
  ///
  /// If no default computation was provided and the memoizer has not been run,
  /// the returned future will not complete until [runComputation] or [reset] is called.
  Future<T> get result {
    if (!hasRun && _computation != null) {
      _run();
    }
    return _asyncMemoizer.future;
  }

  /// Executes the default computation if it hasn't been run yet.
  ///
  /// If the computation has already been executed, returns the cached result.
  ///
  /// Throws [MemoizerConfigurationException] if no default computation was provided.
  Future<T> run() {
    if (_computation == null) {
      throw const MemoizerConfigurationException(
        'No default computation provided. Use runComputation() instead.',
      );
    }
    return _run();
  }

  /// Executes the given [computation] if the memoizer hasn't been run yet.
  ///
  /// If the memoizer has already executed a computation (either the default
  /// or a previous call to this method), returns the existing cached result
  /// and ignores the new [computation].
  Future<T> runComputation(Computation<T> computation) {
    return _asyncMemoizer.runOnce(computation);
  }

  /// Resets the memoizer and runs the new [computation].
  ///
  /// This creates a new [AsyncMemoizer] instance, effectively clearing the
  /// previous result. The new [computation] is executed immediately.
  ///
  /// Returns the result of the new computation.
  Future<T> reset(Computation<T> computation) {
    _asyncMemoizer = AsyncMemoizer<T>();
    return _asyncMemoizer.runOnce(computation);
  }

  Future<T> _run() {
    return _asyncMemoizer.runOnce(_computation!);
  }
}

/// Base class for all exceptions thrown by [Memoizer].
sealed class MemoizerException implements Exception {
  const MemoizerException(this.message);

  final String message;

  @override
  String toString() => 'MemoizerException: $message';
}

/// Thrown when the [Memoizer] is configured incorrectly.
final class MemoizerConfigurationException extends MemoizerException {
  const MemoizerConfigurationException(super.message);
}
