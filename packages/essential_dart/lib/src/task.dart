import 'dart:async';

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

/// A sealed class representing the state of an asynchronous operation.
///
/// [Task] encapsulates the lifecycle of an async task, providing a type-safe
/// way to handle various states such as pending, running, success, and failure.
/// It is designed to be used with pattern matching and provides convenience
/// methods for state transitions and data transformations.
///
/// The generic type [T] represents the type of data the task holds upon success.
sealed class Task<T> {
  /// Creates a [Task] with optional metadata.
  ///
  /// - [label]: An optional string to identify or describe the task.
  /// - [tags]: A set of strings for categorizing or filtering tasks.
  /// - [initialData]: Optional initial data that can be used as a fallback.
  const Task({this.label, this.tags = const {}, this.initialData});

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
    String? label,
    Set<String> tags,
  }) = TaskPending<T>;

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
    String? label,
    Set<String> tags,
  }) = TaskRunning<T>;

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
    String? label,
    Set<String> tags,
  }) = TaskRefreshing<T>;

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
    String? label,
    Set<String> tags,
  }) = TaskRetrying<T>;

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
    String? label,
    Set<String> tags,
  }) = TaskSuccess<T>;

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
    String? label,
    Set<String> tags,
  }) = TaskFailure<T>;

  /// The current state of the task.
  TaskState get state;

  /// An optional label to identify the task.
  final String? label;

  /// A set of tags associated with the task.
  final Set<String> tags;

  /// Captures the result of a synchronous [callback] into a [Task].
  ///
  /// Returns [Task.success] if the callback completes successfully,
  /// or [Task.failure] if it throws an error.
  ///
  /// Example:
  /// ```dart
  /// final task = Task.captureSync(() => int.parse('42'));
  /// print(task.isSuccess); // true
  /// print((task as TaskSuccess).data); // 42
  /// ```
  static Task<T> captureSync<T>(T Function() callback) {
    try {
      return Task.success(data: callback());
    } catch (error, stackTrace) {
      return Task.failure(error: error, stackTrace: stackTrace);
    }
  }

  /// Captures the result of an asynchronous [callback] into a [Task].
  ///
  /// Returns a [Future] that completes with [Task.success] if the callback
  /// completes successfully, or [Task.failure] if it throws an error.
  ///
  /// Example:
  /// ```dart
  /// final task = await Task.capture(() async {
  ///   await Future.delayed(Duration(milliseconds: 100));
  ///   return 'Result';
  /// });
  /// ```
  static Future<Task<T>> capture<T>(FutureOr<T> Function() callback) async {
    try {
      return Task.success(data: await callback());
    } catch (error, stackTrace) {
      return Task.failure(error: error, stackTrace: stackTrace);
    }
  }

  /// Creates a [Stream] that emits [Task] states as the [callback] executes.
  ///
  /// Emits [Task.running] immediately, then executes the [callback].
  /// If the callback completes successfully, emits [Task.success].
  /// If the callback throws an error, emits [Task.failure].
  ///
  /// Example:
  /// ```dart
  /// Task.stream(() async {
  ///   await Future.delayed(Duration(seconds: 1));
  ///   return 'Loaded';
  /// }).listen((task) {
  ///   print(task.state); // running, then success
  /// });
  /// ```
  static Stream<Task<T>> stream<T>(FutureOr<T> Function() callback) async* {
    yield Task.running();
    try {
      yield Task.success(data: await callback());
    } catch (error, stackTrace) {
      yield Task.failure(error: error, stackTrace: stackTrace);
    }
  }

  /// Optional initial data for the task.
  final T? initialData;
}

/// Implementation of [Task] in the pending state.
final class TaskPending<T> extends Task<T> {
  /// Constructs a [TaskPending] instance.
  const TaskPending({
    super.initialData,
    super.label,
    super.tags,
  });

  @override
  TaskState get state => TaskState.pending;
}

/// Implementation of [Task] in the running state.
final class TaskRunning<T> extends Task<T> {
  /// Constructs a [TaskRunning] instance.
  const TaskRunning({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  /// Data available from a previous state.
  final T? previousData;

  @override
  TaskState get state => TaskState.running;
}

/// Implementation of [Task] in the refreshing state.
final class TaskRefreshing<T> extends Task<T> {
  /// Constructs a [TaskRefreshing] instance.
  const TaskRefreshing({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  /// The data being refreshed.
  final T? previousData;

  @override
  TaskState get state => TaskState.refreshing;
}

/// Implementation of [Task] in the retrying state.
final class TaskRetrying<T> extends Task<T> {
  /// Constructs a [TaskRetrying] instance.
  const TaskRetrying({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  /// Data available from a previous state.
  final T? previousData;

  @override
  TaskState get state => TaskState.retrying;
}

/// Implementation of [Task] in the success state.
final class TaskSuccess<T> extends Task<T> {
  /// Constructs a [TaskSuccess] instance.
  const TaskSuccess({
    required this.data,
    super.initialData,
    super.label,
    super.tags,
  });

  /// The result data of the task.
  final T data;

  @override
  TaskState get state => TaskState.success;
}

/// Implementation of [Task] in the failure state.
final class TaskFailure<T> extends Task<T> {
  /// Constructs a [TaskFailure] instance.
  const TaskFailure({
    required this.error,
    this.stackTrace,
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
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
extension TaskInstancePropertiesX<T> on Task<T> {
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
}

extension TaskInstanceTransitionX<T> on Task<T> {
  /// Transitions this task to a pending state.
  ///
  /// Preserves label and tags. Optionally updates initialData.
  Task<T> toPending({T? initialData}) {
    return TaskPending<T>(
      initialData: initialData ?? this.initialData,
      label: label,
      tags: tags,
    );
  }

  /// Transitions this task to a running state.
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  Task<T> toRunning() {
    return TaskRunning<T>(
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
    );
  }

  /// Transitions this task to a refreshing state.
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  /// If there's no effective data, previousData will be null.
  Task<T> toRefreshing() {
    return TaskRefreshing<T>(
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
    );
  }

  /// Transitions this task to a retrying state.
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  /// If there's no effective data, previousData will be null.
  Task<T> toRetrying() {
    return TaskRetrying<T>(
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
    );
  }

  /// Transitions this task to a success state with the provided [data].
  ///
  /// Preserves label, tags, and initialData.
  Task<T> toSuccess(T data) {
    return TaskSuccess<T>(
      data: data,
      initialData: initialData,
      label: label,
      tags: tags,
    );
  }

  /// Transitions this task to a failure state with the provided [error].
  ///
  /// Preserves label, tags, and initialData.
  /// The current effective data becomes previousData in the new state.
  /// Optionally includes a [stackTrace].
  Task<T> toFailure(Object error, {StackTrace? stackTrace}) {
    return TaskFailure<T>(
      error: error,
      stackTrace: stackTrace,
      previousData: effectiveData,
      initialData: initialData,
      label: label,
      tags: tags,
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
  Task<T> from(
    Task<T> old, {
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

extension TaskInstanceTransformX<T> on Task<T> {
  /// Transform data for all states, producing Task<U>
  Task<U> mapData<U>(U Function(T data) transform) => switch (this) {
    TaskSuccess(data: final d) => TaskSuccess(
      data: transform(d),
      label: label,
      tags: tags,
      initialData: initialData as U?,
    ),
    TaskRunning(previousData: final d) => TaskRunning<U>(
      previousData: d != null ? transform(d) : null,
      label: label,
      tags: tags,
      initialData: initialData as U?,
    ),
    TaskRefreshing(previousData: final d) => TaskRefreshing<U>(
      previousData: d != null ? transform(d) : null,
      label: label,
      tags: tags,
      initialData: initialData as U?,
    ),
    TaskRetrying(previousData: final d) => TaskRetrying<U>(
      previousData: d != null ? transform(d) : null,
      label: label,
      tags: tags,
      initialData: initialData as U?,
    ),
    TaskFailure(previousData: final d, error: final e) => TaskFailure<U>(
      previousData: d != null ? transform(d) : null,
      error: e,
      label: label,
      tags: tags,
      initialData: initialData as U?,
    ),
    TaskPending() => TaskPending<U>(
      initialData: initialData != null ? transform(initialData as T) : null,
      label: label,
      tags: tags,
    ),
  };

  /// Transform error in failure state
  Task<T> mapError(Object Function(Object error) transform) => switch (this) {
    TaskFailure(error: final e, previousData: final d, stackTrace: final s) =>
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
  Task<T> transform({
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

extension TaskInstanceCopyWithX<T> on Task<T> {
  Task<T> copyWith({
    T? initialData,
    String? label,
    Set<String>? tags,
    T? previousData,
    T? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return switch (this) {
      TaskPending<T>() => TaskPending(
        initialData: initialData ?? this.initialData,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskRunning<T>(previousData: final p) => TaskRunning(
        initialData: initialData ?? this.initialData,
        previousData: previousData ?? p,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskRefreshing<T>(previousData: final p) => TaskRefreshing(
        initialData: initialData ?? this.initialData,
        previousData: previousData ?? p,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskRetrying<T>(previousData: final p) => TaskRetrying(
        initialData: initialData ?? this.initialData,
        previousData: previousData ?? p,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),

      TaskSuccess<T>(data: final d) => TaskSuccess(
        initialData: initialData ?? this.initialData,
        data: data ?? d,
        label: label ?? this.label,
        tags: tags ?? this.tags,
      ),
      TaskFailure<T>(
        error: final e,
        stackTrace: final s,
        previousData: final p,
      ) =>
        TaskFailure(
          initialData: initialData ?? this.initialData,
          error: error ?? e,
          stackTrace: stackTrace ?? s,
          previousData: previousData ?? p,
          label: label ?? this.label,
          tags: tags ?? this.tags,
        ),
    };
  }

  Task<T> copyWithOrNull({
    T? initialData,
    String? label,
    Set<String>? tags,
    T? previousData,
    T? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return switch (this) {
      TaskPending<T>() => TaskPending(
        initialData: initialData,
        label: label,
        tags: tags ?? const {},
      ),

      TaskRunning<T>() => TaskRunning(
        initialData: initialData,
        previousData: previousData,
        label: label,
        tags: tags ?? const {},
      ),

      TaskRefreshing<T>() => TaskRefreshing(
        initialData: initialData,
        previousData: previousData,
        label: label,
        tags: tags ?? const {},
      ),

      TaskRetrying<T>() => TaskRetrying(
        initialData: initialData,
        previousData: previousData,
        label: label,
        tags: tags ?? const {},
      ),

      TaskSuccess<T>() => TaskSuccess(
        initialData: initialData,
        data: data as T,
        label: label,
        tags: tags ?? const {},
      ),

      TaskFailure<T>() => TaskFailure(
        initialData: initialData,
        error: error!,
        stackTrace: stackTrace,
        previousData: previousData,
        label: label,
        tags: tags ?? const {},
      ),
    };
  }
}
