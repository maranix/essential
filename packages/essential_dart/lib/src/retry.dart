import 'dart:async';

/// Exception thrown when a retry operation fails after all attempts.
class RetryException implements Exception {
  /// Creates a [RetryException].
  const RetryException({
    required this.lastError,
    required this.attempts,
    this.stackTrace,
  });

  /// The error from the last failed attempt.
  final Object lastError;

  /// The total number of attempts made.
  final int attempts;

  /// The stack trace from the last failed attempt.
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'RetryException: Failed after $attempts attempts. Last error: $lastError';
  }
}

/// Exception thrown when attempting to use a Retry instance that is already in progress.
class RetryConcurrentUseException implements Exception {
  /// Creates a [RetryConcurrentUseException].
  const RetryConcurrentUseException();

  @override
  String toString() {
    return 'RetryConcurrentUseException: Cannot call retry while another operation is in progress. '
        'Create a new Retry instance or wait for the current operation to complete.';
  }
}

/// Abstract base class for retry strategies.
///
/// A retry strategy provides a sequence of durations to wait between retry attempts.
abstract class RetryStrategy {
  /// Returns an iterable of durations to wait between retries.
  Iterable<Duration> get delays;
}

/// A retry strategy that waits for a constant duration between retries.
class ConstantBackoffStrategy implements RetryStrategy {
  const ConstantBackoffStrategy({this.duration = const Duration(seconds: 1)});
  final Duration duration;

  @override
  Iterable<Duration> get delays sync* {
    while (true) {
      yield duration;
    }
  }
}

/// A retry strategy that increases the delay linearly with each attempt.
class LinearBackoffStrategy implements RetryStrategy {
  const LinearBackoffStrategy({
    this.initialDuration = const Duration(seconds: 1),
    this.increment = const Duration(seconds: 1),
  });
  final Duration initialDuration;
  final Duration increment;

  @override
  Iterable<Duration> get delays sync* {
    var currentDelay = initialDuration;
    while (true) {
      yield currentDelay;
      currentDelay += increment;
    }
  }
}

/// A retry strategy that increases the delay exponentially with each attempt.
class ExponentialBackoffStrategy implements RetryStrategy {
  const ExponentialBackoffStrategy({
    this.initialDuration = const Duration(seconds: 1),
    this.multiplier = 2.0,
    this.maxDelay,
  });
  final Duration initialDuration;
  final double multiplier;
  final Duration? maxDelay;

  @override
  Iterable<Duration> get delays sync* {
    var currentDelay = initialDuration;
    while (true) {
      yield currentDelay;
      currentDelay *= multiplier;
      if (maxDelay != null && currentDelay > maxDelay!) {
        currentDelay = maxDelay!;
      }
    }
  }
}

/// Utility class for retrying asynchronous operations.
///
/// Use static methods for one-off operations:
/// ```dart
/// // Simple retry with defaults
/// final result = await Retry.run(() => fetchData());
///
/// // Exponential backoff
/// await Retry.withExponentialBackoff(
///   () => apiCall(),
///   maxAttempts: 5,
/// );
/// ```
///
/// Use instances for reusable configurations:
/// ```dart
/// final networkRetry = Retry(
///   maxAttempts: 5,
///   strategy: ExponentialBackoffStrategy(),
/// );
///
/// // Reuse across multiple operations
/// await networkRetry(() => fetchUser());
/// await networkRetry(() => fetchPosts());
/// ```
class Retry {
  /// Creates a [Retry] instance.
  ///
  /// [maxAttempts] defaults to 3.
  /// [strategy] defaults to [ConstantBackoffStrategy] with 1 second delay.
  Retry({
    this.maxAttempts = 3,
    this.strategy = const ConstantBackoffStrategy(),
  });

  /// The maximum number of times the task will be executed (initial attempt + retries).
  final int maxAttempts;

  /// The strategy to determine the delay between retries.
  final RetryStrategy strategy;

  /// The number of retry attempts made in the current or last operation.
  int get attempts => _attempts;
  int _attempts = 0;

  /// Whether a retry operation is currently in progress.
  bool get isRetrying => _isRetrying;
  bool _isRetrying = false;

  /// Runs a [computation] with default retry settings (3 attempts, 1s constant delay).
  ///
  /// Example:
  /// ```dart
  /// final data = await Retry.run(() => fetchData());
  /// ```
  static Future<T> run<T>(
    Future<T> Function() computation, {
    FutureOr<bool> Function(Object error, int attempt)? onRetry,
  }) {
    return Retry().call(computation, onRetry: onRetry);
  }

  /// Runs a [computation] with constant backoff strategy.
  ///
  /// Example:
  /// ```dart
  /// await Retry.withConstantBackoff(
  ///   () => uploadFile(),
  ///   duration: Duration(seconds: 2),
  ///   maxAttempts: 5,
  /// );
  /// ```
  static Future<T> withConstantBackoff<T>(
    Future<T> Function() computation, {
    Duration duration = const Duration(seconds: 1),
    int maxAttempts = 3,
    FutureOr<bool> Function(Object error, int attempt)? onRetry,
  }) {
    return Retry(
      maxAttempts: maxAttempts,
      strategy: ConstantBackoffStrategy(duration: duration),
    ).call(computation, onRetry: onRetry);
  }

  /// Runs a [computation] with linear backoff strategy.
  ///
  /// Example:
  /// ```dart
  /// await Retry.withLinearBackoff(
  ///   () => processData(),
  ///   initialDuration: Duration(seconds: 1),
  ///   increment: Duration(seconds: 2),
  ///   maxAttempts: 4,
  /// );
  /// ```
  static Future<T> withLinearBackoff<T>(
    Future<T> Function() computation, {
    Duration initialDuration = const Duration(seconds: 1),
    Duration increment = const Duration(seconds: 1),
    int maxAttempts = 3,
    FutureOr<bool> Function(Object error, int attempt)? onRetry,
  }) {
    return Retry(
      maxAttempts: maxAttempts,
      strategy: LinearBackoffStrategy(
        initialDuration: initialDuration,
        increment: increment,
      ),
    ).call(computation, onRetry: onRetry);
  }

  /// Runs a [computation] with exponential backoff strategy.
  ///
  /// Example:
  /// ```dart
  /// await Retry.withExponentialBackoff(
  ///   () => apiCall(),
  ///   initialDuration: Duration(milliseconds: 500),
  ///   multiplier: 2.0,
  ///   maxDelay: Duration(seconds: 10),
  ///   maxAttempts: 5,
  /// );
  /// ```
  static Future<T> withExponentialBackoff<T>(
    Future<T> Function() computation, {
    Duration initialDuration = const Duration(seconds: 1),
    double multiplier = 2.0,
    Duration? maxDelay,
    int maxAttempts = 3,
    FutureOr<bool> Function(Object error, int attempt)? onRetry,
  }) {
    return Retry(
      maxAttempts: maxAttempts,
      strategy: ExponentialBackoffStrategy(
        initialDuration: initialDuration,
        multiplier: multiplier,
        maxDelay: maxDelay,
      ),
    ).call(computation, onRetry: onRetry);
  }

  /// Executes a [task] and retries it if it fails.
  ///
  /// This method can be called directly on a [Retry] instance, allowing
  /// the instance to be reused across multiple operations.
  ///
  /// [onRetry] is an optional callback that is called before each retry.
  /// It receives the error that caused the failure and the current attempt number.
  /// If it returns `false` (or a Future resolving to `false`), the retry is aborted and the error is rethrown.
  ///
  /// Example:
  /// ```dart
  /// final retry = Retry(maxAttempts: 5);
  /// await retry(() => fetchUser());
  /// await retry(() => fetchPosts());
  /// ```
  Future<T> call<T>(
    Future<T> Function() task, {
    FutureOr<bool> Function(Object error, int attempt)? onRetry,
  }) async {
    if (_isRetrying) {
      throw const RetryConcurrentUseException();
    }

    _isRetrying = true;
    _attempts = 0;
    final delayIterator = strategy.delays.iterator;

    try {
      while (true) {
        _attempts++;
        try {
          final result = await task();
          return result;
        } catch (e, stackTrace) {
          if (_attempts >= maxAttempts) {
            throw RetryException(
              lastError: e,
              attempts: _attempts,
              stackTrace: stackTrace,
            );
          }

          if (onRetry != null) {
            final shouldRetry = await onRetry(e, _attempts);
            if (!shouldRetry) {
              throw RetryException(
                lastError: e,
                attempts: _attempts,
                stackTrace: stackTrace,
              );
            }
          }

          if (delayIterator.moveNext()) {
            final delay = delayIterator.current;
            await Future<void>.delayed(delay);
          } else {
            throw RetryException(
              lastError: e,
              attempts: _attempts,
              stackTrace: stackTrace,
            );
          }
        }
      }
    } finally {
      _isRetrying = false;
    }
  }
}
