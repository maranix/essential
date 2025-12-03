import 'dart:async';

import 'package:async/async.dart';
import 'package:essential_dart/src/enums.dart';
import 'package:essential_dart/src/memoizer.dart';

/// Represents the state of a task.
enum TaskState {
  /// Task is pending and hasn't started yet.
  pending,

  /// Task is currently running.
  running,

  /// Task is refreshing with previous data available.
  refreshing,

  /// Task is retrying after a failure.
  retrying,

  /// Task completed successfully.
  success,

  /// Task failed with an error.
  failure,
}

/// Default cache duration (5 minutes).
const Duration _kDefaultCacheDuration = Duration(minutes: 5);

/// A sealed class representing the state of an asynchronous operation.
///
/// [Task] encapsulates the lifecycle of an async task, providing a type-safe
/// way to handle various states such as pending, running, success, and failure.
/// It is designed to be used with pattern matching and provides convenience
/// methods for state transitions and data transformations.
///
/// The generic type [T] represents the type of data the task holds upon success.
/// The generic type [Label] represents the type of the label (default: [String]?).
/// The generic type [Tags] represents the type of the tags (default: [Set<String>]?).
sealed class Task<T, Label, Tags> {
  /// Creates a [Task] with optional metadata.
  ///
  /// - [label]: An optional label to identify or describe the task.
  /// - [tags]: Optional tags for categorizing or filtering tasks.
  /// - [initialData]: Optional initial data that can be used as a fallback.
  /// - [cachingStrategy]: The caching strategy to use (default: none).
  /// - [cacheDuration]: Duration for temporal caching (default: 5 minutes).
  Task({
    this.label,
    this.tags,
    this.initialData,
    CachingStrategy? cachingStrategy,
    Duration? cacheDuration,
    Memoizer<T>? memoizer,
    AsyncCache<T>? asyncCache,
  }) : cachingStrategy = cachingStrategy ?? CachingStrategy.none,
       cacheDuration = cacheDuration ?? _kDefaultCacheDuration,
       _memoizer =
           memoizer ??
           (cachingStrategy == CachingStrategy.memoize ? Memoizer<T>() : null),
       _asyncCache =
           asyncCache ??
           (cachingStrategy == CachingStrategy.temporal
               ? AsyncCache<T>(cacheDuration ?? _kDefaultCacheDuration)
               : null);

  /// Creates a [Task] in the [TaskState.pending] state.
  ///
  /// This state indicates that the task has been initialized but has not yet
  /// started execution.
  ///
  /// - [initialData]: Optional initial data.
  /// - [label]: Optional task label.
  /// - [tags]: Optional task tags.
  factory Task.pending({
    T? initialData,
    Label? label,
    Tags? tags,
    CachingStrategy cachingStrategy,
    Duration? cacheDuration,
  }) = TaskPending<T, Label, Tags>;

  /// Creates a [Task] in the [TaskState.running] state.
  ///
  /// This state indicates that the task is currently executing.
  ///
  /// - [initialData]: Optional initial data.
  /// - [previousData]: Data from a previous state, if any.
  /// - [label]: Optional task label.
  /// - [tags]: Optional task tags.
  factory Task.running({
    T? initialData,
    T? previousData,
    Label? label,
    Tags? tags,
    CachingStrategy cachingStrategy,
    Duration? cacheDuration,
  }) = TaskRunning<T, Label, Tags>;

  /// Creates a [Task] in the [TaskState.refreshing] state.
  ///
  /// This state indicates that the task is executing (refreshing) but has
  /// existing data from a previous successful execution.
  ///
  /// - [previousData]: The existing data being refreshed.
  /// - [initialData]: Optional initial data.
  /// - [label]: Optional task label.
  /// - [tags]: Optional task tags.
  factory Task.refreshing({
    T previousData,
    T? initialData,
    Label? label,
    Tags? tags,
    CachingStrategy cachingStrategy,
    Duration? cacheDuration,
  }) = TaskRefreshing<T, Label, Tags>;

  /// Creates a [Task] in the [TaskState.retrying] state.
  ///
  /// This state indicates that the task is retrying execution after a failure.
  ///
  /// - [previousData]: Data from a previous state, if any.
  /// - [initialData]: Optional initial data.
  /// - [label]: Optional task label.
  /// - [tags]: Optional task tags.
  factory Task.retrying({
    T previousData,
    T? initialData,
    Label? label,
    Tags? tags,
    CachingStrategy cachingStrategy,
    Duration? cacheDuration,
  }) = TaskRetrying<T, Label, Tags>;

  /// Creates a [Task] in the [TaskState.success] state.
  ///
  /// This state indicates that the task has completed successfully and holds
  /// the resulting [data].
  ///
  /// - [data]: The result of the task.
  /// - [initialData]: Optional initial data.
  /// - [label]: Optional task label.
  /// - [tags]: Optional task tags.
  factory Task.success({
    required T data,
    T? initialData,
    Label? label,
    Tags? tags,
    CachingStrategy cachingStrategy,
    Duration? cacheDuration,
  }) = TaskSuccess<T, Label, Tags>;

  /// Creates a [Task] in the [TaskState.failure] state.
  ///
  /// This state indicates that the task has failed.
  ///
  /// - [error]: The error that occurred.
  /// - [stackTrace]: Optional stack trace associated with the error.
  /// - [previousData]: Data from a previous state, if any.
  /// - [initialData]: Optional initial data.
  /// - [label]: Optional task label.
  /// - [tags]: Optional task tags.
  factory Task.failure({
    required Object error,
    StackTrace? stackTrace,
    T? previousData,
    T? initialData,
    Label? label,
    Tags? tags,
    CachingStrategy cachingStrategy,
    Duration? cacheDuration,
  }) = TaskFailure<T, Label, Tags>;

  /// The current state of the task.
  TaskState get state;

  /// An optional label to identify the task.
  final Label? label;

  /// Optional tags associated with the task.
  final Tags? tags;

  /// The caching strategy for this task.
  final CachingStrategy cachingStrategy;

  /// The duration for temporal caching.
  final Duration cacheDuration;

  /// Internal memoizer for 'memoize' strategy.
  final Memoizer<T>? _memoizer;

  /// Internal async cache for 'temporal' strategy.
  final AsyncCache<T>? _asyncCache;

  /// Optional initial data for the task.
  final T? initialData;

  /// Runs a synchronous [callback] and wraps the result in a [Task].
  ///
  /// Returns [Task.success] if the callback completes successfully,
  /// or [Task.failure] if it throws an error.
  ///
  /// Example:
  /// ```dart
  /// final task = Task.runSync(() => int.parse('42'));
  /// print(task.isSuccess); // true
  /// print((task as TaskSuccess).data); // 42
  /// ```
  static Task<T, Label, Tags> runSync<T, Label, Tags>(
    T Function() callback, {
    Label? label,
    Tags? tags,
  }) {
    try {
      return Task.success(data: callback(), label: label, tags: tags);
    } on Exception catch (error, stackTrace) {
      return Task.failure(
        error: error,
        stackTrace: stackTrace,
        label: label,
        tags: tags,
      );
    }
  }

  /// Runs an asynchronous [callback] and wraps the result in a [Task].
  ///
  /// Returns a [Future] that completes with [Task.success] if the callback
  /// completes successfully, or [Task.failure] if it throws an error.
  ///
  /// Example:
  /// ```dart
  /// final task = await Task.run(() async {
  ///   await Future.delayed(Duration(milliseconds: 100));
  ///   return 'Result';
  /// });
  /// ```
  static Future<Task<T, Label, Tags>> run<T, Label, Tags>(
    FutureOr<T> Function() callback, {
    Label? label,
    Tags? tags,
  }) async {
    try {
      return Task.success(data: await callback(), label: label, tags: tags);
    } on Exception catch (error, stackTrace) {
      return Task.failure(
        error: error,
        stackTrace: stackTrace,
        label: label,
        tags: tags,
      );
    }
  }

  /// Watches the execution of a [callback], emitting [Task] states as it runs.
  ///
  /// Emits [Task.running] immediately, then executes the [callback].
  /// If the callback completes successfully, emits [Task.success].
  /// If the callback throws an error, emits [Task.failure].
  ///
  /// Example:
  /// ```dart
  /// Task.watch(() async {
  ///   await Future.delayed(Duration(seconds: 1));
  ///   return 'Loaded';
  /// }).listen((task) {
  ///   print(task.state); // running, then success
  /// });
  /// ```
  static Stream<Task<T, Label, Tags>> watch<T, Label, Tags>(
    FutureOr<T> Function() callback, {
    Label? label,
    Tags? tags,
  }) async* {
    yield Task.running(label: label, tags: tags);
    try {
      yield Task.success(data: await callback(), label: label, tags: tags);
    } on Exception catch (error, stackTrace) {
      yield Task.failure(
        error: error,
        stackTrace: stackTrace,
        label: label,
        tags: tags,
      );
    }
  }

  /// Executes a [computation] with caching based on the configured strategy.
  ///
  /// - If [cachingStrategy] is [CachingStrategy.none], runs the computation directly.
  /// - If [cachingStrategy] is [CachingStrategy.memoize], uses [Memoizer] to cache the result indefinitely.
  /// - If [cachingStrategy] is [CachingStrategy.temporal], uses [AsyncCache] with [cacheDuration].
  ///
  /// Example:
  /// ```dart
  /// final task = Task<int>.pending(cachingStrategy: CachingStrategy.memoize);
  /// final result = await task.execute(() async => expensiveComputation());
  /// ```
  Future<T> execute(Future<T> Function() computation) {
    switch (cachingStrategy) {
      case CachingStrategy.none:
        return computation();
      case CachingStrategy.memoize:
        return _memoizer!.runComputation(computation);
      case CachingStrategy.temporal:
        return _asyncCache!.fetch(computation);
    }
  }

  /// Invalidates the cache for this task.
  ///
  /// - For [CachingStrategy.memoize], resets the memoizer.
  /// - For [CachingStrategy.temporal], invalidates the async cache.
  /// - For [CachingStrategy.none], does nothing.
  ///
  /// Example:
  /// ```dart
  /// task.invalidateCache();
  /// ```
  void invalidateCache() {
    switch (cachingStrategy) {
      case CachingStrategy.none:
        break;
      case CachingStrategy.memoize:
        // Memoizer doesn't have a simple invalidate, we'd need to reset
        // But reset requires a new computation, so we can't do it here
        // User should use refresh() instead
        break;
      case CachingStrategy.temporal:
        _asyncCache?.invalidate();
    }
  }

  /// Invalidates the cache and runs the [computation].
  ///
  /// This is equivalent to calling [invalidateCache] followed by [run],
  /// but more efficient for memoize strategy.
  ///
  /// Example:
  /// ```dart
  /// final result = await task.refresh(() async => fetchFreshData());
  /// ```
  Future<T> refresh(Future<T> Function() computation) {
    switch (cachingStrategy) {
      case CachingStrategy.none:
        return computation();
      case CachingStrategy.memoize:
        return _memoizer!.reset(computation);
      case CachingStrategy.temporal:
        _asyncCache?.invalidate();
        return _asyncCache!.fetch(computation);
    }
  }
}

/// Implementation of [Task] in the pending state.
final class TaskPending<T, Label, Tags> extends Task<T, Label, Tags> {
  /// Constructs a [TaskPending] instance.
  TaskPending({
    super.initialData,
    super.label,
    super.tags,
    super.cachingStrategy,
    super.cacheDuration,
    super.memoizer,
    super.asyncCache,
  });

  @override
  TaskState get state => TaskState.pending;
}

/// Implementation of [Task] in the running state.
final class TaskRunning<T, Label, Tags> extends Task<T, Label, Tags> {
  /// Constructs a [TaskRunning] instance.
  TaskRunning({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
    super.cachingStrategy,
    super.cacheDuration,
    super.memoizer,
    super.asyncCache,
  });

  /// Data available from a previous state.
  final T? previousData;

  @override
  TaskState get state => TaskState.running;
}

/// Implementation of [Task] in the refreshing state.
final class TaskRefreshing<T, Label, Tags> extends Task<T, Label, Tags> {
  /// Constructs a [TaskRefreshing] instance.
  TaskRefreshing({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
    super.cachingStrategy,
    super.cacheDuration,
    super.memoizer,
    super.asyncCache,
  });

  /// The data being refreshed.
  final T? previousData;

  @override
  TaskState get state => TaskState.refreshing;
}

/// Implementation of [Task] in the retrying state.
final class TaskRetrying<T, Label, Tags> extends Task<T, Label, Tags> {
  /// Constructs a [TaskRetrying] instance.
  TaskRetrying({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
    super.cachingStrategy,
    super.cacheDuration,
    super.memoizer,
    super.asyncCache,
  });

  /// Data available from a previous state.
  final T? previousData;

  @override
  TaskState get state => TaskState.retrying;
}

/// Implementation of [Task] in the success state.
final class TaskSuccess<T, Label, Tags> extends Task<T, Label, Tags> {
  /// Constructs a [TaskSuccess] instance.
  TaskSuccess({
    required this.data,
    super.initialData,
    super.label,
    super.tags,
    super.cachingStrategy,
    super.cacheDuration,
    super.memoizer,
    super.asyncCache,
  });

  /// The result data of the task.
  final T data;

  @override
  TaskState get state => TaskState.success;
}

/// Implementation of [Task] in the failure state.
final class TaskFailure<T, Label, Tags> extends Task<T, Label, Tags> {
  /// Constructs a [TaskFailure] instance.
  TaskFailure({
    required this.error,
    this.stackTrace,
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
    super.cachingStrategy,
    super.cacheDuration,
    super.memoizer,
    super.asyncCache,
  });

  /// The error that caused the failure.
  final Object error;

  /// The stack trace associated with the error.
  final StackTrace? stackTrace;

  /// Data available from a previous state.
  final T? previousData;

  @override
  TaskState get state => TaskState.failure;
}

/// Extension providing convenience properties for checking the state of a [Task].
extension TaskInstancePropertiesX<T, Label, Tags> on Task<T, Label, Tags> {
  /// Returns `true` if the task is in the [TaskState.pending] state.
  bool get isPending => state == TaskState.pending;

  /// Returns `true` if the task is in the [TaskState.running] state.
  bool get isRunning => state == TaskState.running;

  /// Returns `true` if the task is in the [TaskState.refreshing] state.
  bool get isRefreshing => state == TaskState.refreshing;

  /// Returns `true` if the task is in the [TaskState.retrying] state.
  bool get isRetrying => state == TaskState.retrying;

  /// Returns `true` if the task is in the [TaskState.success] state.
  bool get isSuccess => state == TaskState.success;

  /// Returns `true` if the task is in the [TaskState.failure] state.
  bool get isFailure => state == TaskState.failure;

  /// Returns the effective data for the task.
  ///
  /// This property attempts to return the most relevant data available.
  /// - For [TaskSuccess], it returns [TaskSuccess.data].
  /// - For other states, it returns `previousData` if available, otherwise `initialData`.
  T? get effectiveData => switch (this) {
    TaskSuccess(data: final d) => d,
    TaskRunning(previousData: final d) => d ?? initialData,
    TaskRefreshing(previousData: final d) => d ?? initialData,
    TaskRetrying(previousData: final d) => d ?? initialData,
    TaskFailure(previousData: final d) => d ?? initialData,
    TaskPending() => initialData,
  };

  /// Returns this task as [TaskPending] or throws [StateError].
  TaskPending<T, Label, Tags> get pending =>
      _checkState<TaskPending<T, Label, Tags>>(TaskState.pending);

  /// Returns this task as [TaskRunning] or throws [StateError].
  TaskRunning<T, Label, Tags> get running =>
      _checkState<TaskRunning<T, Label, Tags>>(TaskState.running);

  /// Returns this task as [TaskRefreshing] or throws [StateError].
  TaskRefreshing<T, Label, Tags> get refreshing =>
      _checkState<TaskRefreshing<T, Label, Tags>>(TaskState.refreshing);

  /// Returns this task as [TaskRetrying] or throws [StateError].
  TaskRetrying<T, Label, Tags> get retrying =>
      _checkState<TaskRetrying<T, Label, Tags>>(TaskState.retrying);

  /// Returns this task as [TaskSuccess] or throws [StateError].
  TaskSuccess<T, Label, Tags> get success =>
      _checkState<TaskSuccess<T, Label, Tags>>(TaskState.success);

  /// Returns this task as [TaskFailure] or throws [StateError].
  TaskFailure<T, Label, Tags> get failure =>
      _checkState<TaskFailure<T, Label, Tags>>(TaskState.failure);

  S _checkState<S extends Task<T, Label, Tags>>(TaskState expectedState) {
    if (this is S) {
      return this as S;
    }

    throw StateError(
      'Task is not in the expected state.\n'
      'Expected: $expectedState\n'
      'Actual: $state\n'
      'Fix: Check the state using is${expectedState.name[0].toUpperCase()}${expectedState.name.substring(1)} before accessing the getter.',
    );
  }
}

extension TaskInstanceTransitionX<T, Label, Tags> on Task<T, Label, Tags> {
  /// Transitions this task to a pending state.
  ///
  /// Preserves label and tags. Optionally updates initialData.
  Task<T, Label, Tags> toPending({T? initialData}) {
    return TaskPending<T, Label, Tags>(
      initialData: initialData ?? this.initialData,
      label: label,
      tags: tags,
      cachingStrategy: cachingStrategy,
      cacheDuration: cacheDuration,
      memoizer: _memoizer,
      asyncCache: _asyncCache,
    );
  }

  /// Transitions this task to a running state.
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  Task<T, Label, Tags> toRunning() {
    return TaskRunning<T, Label, Tags>(
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
      cachingStrategy: cachingStrategy,
      cacheDuration: cacheDuration,
      memoizer: _memoizer,
      asyncCache: _asyncCache,
    );
  }

  /// Transitions this task to a refreshing state.
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  /// If there's no effective data, previousData will be null.
  Task<T, Label, Tags> toRefreshing() {
    return TaskRefreshing<T, Label, Tags>(
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
      cachingStrategy: cachingStrategy,
      cacheDuration: cacheDuration,
      memoizer: _memoizer,
      asyncCache: _asyncCache,
    );
  }

  /// Transitions this task to a retrying state.
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  /// If there's no effective data, previousData will be null.
  Task<T, Label, Tags> toRetrying() {
    return TaskRetrying<T, Label, Tags>(
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
      cachingStrategy: cachingStrategy,
      cacheDuration: cacheDuration,
      memoizer: _memoizer,
      asyncCache: _asyncCache,
    );
  }

  /// Transitions this task to a success state with the provided [data].
  ///
  /// Preserves label, tags, and initialData.
  Task<T, Label, Tags> toSuccess(T data) {
    return TaskSuccess<T, Label, Tags>(
      data: data,
      initialData: initialData,
      label: label,
      tags: tags,
      cachingStrategy: cachingStrategy,
      cacheDuration: cacheDuration,
      memoizer: _memoizer,
      asyncCache: _asyncCache,
    );
  }

  /// Transitions this task to a failure state with the provided [error].
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  /// Optionally includes a [stackTrace].
  Task<T, Label, Tags> toFailure(Object error, {StackTrace? stackTrace}) {
    return TaskFailure<T, Label, Tags>(
      error: error,
      stackTrace: stackTrace,
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
      cachingStrategy: cachingStrategy,
      cacheDuration: cacheDuration,
      memoizer: _memoizer,
      asyncCache: _asyncCache,
    );
  }

  /// Transitions the task to a new state based on the provided [newTask] state.
  ///
  /// This method serves as a unified interface for state transitions, allowing
  /// dynamic state changes based on enum values.
  ///
  /// - [newTask]: The target state to transition to.
  /// - [data]: The data to set when transitioning to [TaskState.success].
  ///   Also used as `initialData` when transitioning to [TaskState.pending].
  /// - [error]: The error to set when transitioning to [TaskState.failure].
  /// - [trace]: The stack trace to set when transitioning to [TaskState.failure].
  ///
  /// Throws [StateError] if:
  /// - Transitioning to [TaskState.success] and [data] is null.
  /// - Transitioning to [TaskState.failure] and [error] is null.
  Task<T, Label, Tags> from(
    Task<T, Label, Tags> old, {
    required TaskState newTask,
    T? data,
    Object? error,
    StackTrace? trace,
  }) => switch (newTask) {
    TaskState.pending => toPending(initialData: data ?? effectiveData),
    TaskState.running => toRunning(),
    TaskState.retrying => toRetrying(),
    TaskState.refreshing => toRefreshing(),
    TaskState.success => () {
      if (data == null) {
        throw StateError(
          'Failed to transition to TaskState.success: The "data" parameter cannot be null.\n'
          'When transitioning to the success state, you must provide a valid data value.\n'
          'Fix: Ensure that the "data" argument is passed and is not null when calling from(..., newTask: TaskState.success, data: ...).',
        );
      }
      return toSuccess(data);
    }(),
    TaskState.failure => () {
      if (error == null) {
        throw StateError(
          'Failed to transition to TaskState.failure: The "error" parameter cannot be null.\n'
          'When transitioning to the failure state, you must provide an error object.\n'
          'Fix: Ensure that the "error" argument is passed and is not null when calling from(..., newTask: TaskState.failure, error: ...).',
        );
      }
      return toFailure(error, stackTrace: trace);
    }(),
  };
}

extension TaskInstanceTransformX<T, Label, Tags> on Task<T, Label, Tags> {
  /// Transform data for all states, producing Task<U, Label, Tags>
  Task<U, Label, Tags> mapData<U>(U Function(T data) transform) =>
      switch (this) {
        TaskSuccess(data: final d) => TaskSuccess(
          data: transform(d),
          label: label,
          tags: tags,
          initialData: initialData != null ? transform(initialData as T) : null,
        ),
        TaskRunning(previousData: final d) => TaskRunning<U, Label, Tags>(
          previousData: d != null ? transform(d) : null,
          label: label,
          tags: tags,
          initialData: initialData != null ? transform(initialData as T) : null,
        ),
        TaskRefreshing(previousData: final d) => TaskRefreshing<U, Label, Tags>(
          previousData: d != null ? transform(d) : null,
          label: label,
          tags: tags,
          initialData: initialData != null ? transform(initialData as T) : null,
        ),
        TaskRetrying(previousData: final d) => TaskRetrying<U, Label, Tags>(
          previousData: d != null ? transform(d) : null,
          label: label,
          tags: tags,
          initialData: initialData != null ? transform(initialData as T) : null,
        ),
        TaskFailure(previousData: final d, error: final e) =>
          TaskFailure<U, Label, Tags>(
            previousData: d != null ? transform(d) : null,
            error: e,
            label: label,
            tags: tags,
            initialData: initialData != null
                ? transform(initialData as T)
                : null,
          ),
        TaskPending() => TaskPending<U, Label, Tags>(
          initialData: initialData != null ? transform(initialData as T) : null,
          label: label,
          tags: tags,
        ),
      };

  /// Transform error in failure state
  Task<T, Label, Tags> mapError(Object Function(Object error) transform) =>
      switch (this) {
        TaskFailure(
          error: final e,
          previousData: final d,
          stackTrace: final s,
        ) =>
          TaskFailure(
            error: transform(e),
            previousData: d,
            stackTrace: s,
            label: label,
            tags: tags,
            initialData: initialData,
          ),
        _ => this,
      };

  /// General transform helper
  Task<T, Label, Tags> transform({
    T? Function(T? oldData)? updateData,
    Object? Function(Object? oldError)? updateError,
    T? Function(T? oldPrevious)? updatePrevious,
  }) => switch (this) {
    TaskSuccess(data: final d) => TaskSuccess(
      data: updateData != null ? updateData(d) as T : d,
      label: label,
      tags: tags,
      initialData: initialData,
    ),
    TaskRunning(previousData: final d) => TaskRunning(
      previousData: updatePrevious != null ? updatePrevious(d) : d,
      label: label,
      tags: tags,
      initialData: initialData,
    ),
    TaskRefreshing(previousData: final d) => TaskRefreshing(
      previousData: updatePrevious != null ? updatePrevious(d) : d,
      label: label,
      tags: tags,
      initialData: initialData,
    ),
    TaskRetrying(previousData: final d) => TaskRetrying(
      previousData: updatePrevious != null ? updatePrevious(d) : d,
      label: label,
      tags: tags,
      initialData: initialData,
    ),
    TaskFailure(error: final e, previousData: final d, stackTrace: final s) =>
      TaskFailure(
        error: updateError != null ? updateError(e) ?? e : e,
        previousData: updatePrevious != null ? updatePrevious(d) : d,
        stackTrace: s,
        label: label,
        tags: tags,
        initialData: initialData,
      ),
    TaskPending() => TaskPending(
      initialData: updateData != null ? updateData(initialData) : initialData,
      label: label,
      tags: tags,
    ),
  };
}

extension TaskInstanceCopyWithX<T, Label, Tags> on Task<T, Label, Tags> {
  Task<T, Label, Tags> copyWith({
    T? initialData,
    Label? label,
    Tags? tags,
    T? previousData,
    T? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return switch (this) {
      TaskPending<T, Label, Tags>() => TaskPending(
        initialData: initialData ?? this.initialData,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskRunning<T, Label, Tags>(previousData: final p) => TaskRunning(
        initialData: initialData ?? this.initialData,
        previousData: previousData ?? p,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskRefreshing<T, Label, Tags>(previousData: final p) => TaskRefreshing(
        initialData: initialData ?? this.initialData,
        previousData: previousData ?? p,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskRetrying<T, Label, Tags>(previousData: final p) => TaskRetrying(
        initialData: initialData ?? this.initialData,
        previousData: previousData ?? p,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskSuccess<T, Label, Tags>(data: final d) => TaskSuccess(
        data: data ?? d,
        initialData: initialData ?? this.initialData,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskFailure<T, Label, Tags>(
        error: final e,
        stackTrace: final s,
        previousData: final p,
      ) =>
        TaskFailure(
          error: error ?? e,
          stackTrace: stackTrace ?? s,
          previousData: previousData ?? p,
          initialData: initialData ?? this.initialData,
          label: label ?? this.label,
          tags: tags ?? this.tags,
        ),
    };
  }

  Task<T, Label, Tags> copyWithOrNull({
    T? initialData,
    Label? label,
    Tags? tags,
    T? previousData,
    T? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return switch (this) {
      TaskPending<T, Label, Tags>() => TaskPending(
        initialData: initialData,
        label: label,
        tags: tags,
      ),

      TaskRunning<T, Label, Tags>() => TaskRunning(
        initialData: initialData,
        previousData: previousData,
        label: label,
        tags: tags,
      ),

      TaskRefreshing<T, Label, Tags>() => TaskRefreshing(
        initialData: initialData,
        previousData: previousData,
        label: label,
        tags: tags,
      ),

      TaskRetrying<T, Label, Tags>() => TaskRetrying(
        initialData: initialData,
        previousData: previousData,
        label: label,
        tags: tags,
      ),

      TaskSuccess<T, Label, Tags>() => TaskSuccess(
        initialData: initialData,
        data: data as T,
        label: label,
        tags: tags,
      ),

      TaskFailure<T, Label, Tags>() => TaskFailure(
        initialData: initialData,
        error: error!,
        stackTrace: stackTrace,
        previousData: previousData,
        label: label,
        tags: tags,
      ),
    };
  }
}

/// A [Task] with default types for label ([String]?) and tags ([Set<String>]).
typedef SimpleTask<T> = Task<T, String?, Set<String>>;
