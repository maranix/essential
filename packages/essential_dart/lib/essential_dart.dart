/// Reusable building blocks, patterns, and utilities for Dart.
///
/// This library provides essential utilities to improve code efficiency and quality:
///
/// ## Memoizer
///
/// Cache results of expensive computations with support for lazy/eager execution
/// and reset functionality.
///
/// Example:
/// ```dart
/// final memoizer = Memoizer<int>(
///   computation: () => expensiveCalculation(),
/// );
/// final result = await memoizer.result; // Computed once, cached
/// ```
///
/// ## Task
///
/// Type-safe state management for asynchronous operations with intuitive
/// state transitions.
///
/// ### Basic Usage
///
/// ```dart
/// // Create and transition through states
/// var task = Task<String>.pending(label: 'fetch-data');
/// task = task.toRunning();
/// task = task.toSuccess('Data loaded');
/// ```
///
/// ### State Checking
///
/// ```dart
/// if (task.state == TaskState.success) {
///   print('Success!');
/// }
/// ```
///
/// ### Convenience Methods
///
/// - `toPending()` - Transition to pending state
/// - `toRunning()` - Transition to running state
/// - `toRefreshing()` - Transition to refreshing state
/// - `toRetrying()` - Transition to retrying state
/// - `toSuccess(T data)` - Transition to success with data
/// - `toFailure(Object error)` - Transition to failure with error
///
/// All methods automatically preserve label, tags, and initialData.
///
/// ### Data Transformation
///
/// ```dart
/// final task = Task<int>.success(data: 42);
/// final doubled = task.mapData((data) => data * 2);
/// ```
///
/// ## Stream Transformers
///
/// Powerful stream transformers for common patterns:
///
/// ### StringSplitter
///
/// Split string streams by separator (single or multi-character):
///
/// ```dart
/// Stream.fromIterable(['Hello,', 'World!'])
///   .transform(StringSplitter(','))
///   .listen(print); // Prints 'Hello' and 'World!'
/// ```
///
/// ### Debounce
///
/// Filter out rapid-fire events, emitting only after a quiet period:
///
/// ```dart
/// searchStream
///   .transform(Debounce(Duration(milliseconds: 300)))
///   .listen(performSearch);
/// ```
///
/// ### Throttle
///
/// Limit event rate by ignoring events within a time window:
///
/// ```dart
/// clickStream
///   .transform(Throttle(Duration(milliseconds: 500)))
///   .listen(handleClick);
/// ```
///
/// ### BufferCount
///
/// Collect items into fixed-size batches:
///
/// ```dart
/// dataStream
///   .transform(BufferCount(10))
///   .listen(processBatch);
/// ```
///
/// ### BufferTime
///
/// Collect items over time intervals:
///
/// ```dart
/// eventStream
///   .transform(BufferTime(Duration(seconds: 1)))
///   .listen(processEvents);
/// ```

library;

export 'src/memoizer.dart';
export 'src/retry.dart';
export 'src/stream_transformer.dart';
export 'src/task.dart';
export 'src/task_group.dart';
export 'src/types.dart';
