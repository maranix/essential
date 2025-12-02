/// @docImport 'package:async/async.dart';
/// @docImport 'package:essential_dart/src/memoizer.dart';
library;

/// Defines the caching strategy
enum CachingStrategy {
  /// No caching. Every execution runs the computation.
  none,

  /// Memoizes the result indefinitely until manually reset.
  /// Uses [Memoizer].
  memoize,

  /// Caches the result for a specific duration.
  /// Uses [AsyncCache].
  temporal,
}
