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

library;

export 'src/memoizer.dart';
export 'src/task.dart';
