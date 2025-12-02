import 'dart:async';

import 'package:async/async.dart';
import 'package:essential_dart/essential_dart.dart' show Task;
import 'package:essential_dart/src/memoizer.dart';
import 'package:essential_dart/src/task.dart' show Task;

typedef SyncComputation<T> = T Function();

typedef AsyncComputation<T> = Future<T> Function();

typedef Computation<T> = FutureOr<T> Function();

/// Defines the caching strategy for a [Task].
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
