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

sealed class Task<T> {
  const Task({this.label, this.tags = const {}, this.initialData});

  factory Task.pending({
    T? initialData,
    String? label,
    Set<String> tags,
  }) = TaskPending<T>;

  factory Task.running({
    T? initialData,
    T? previousData,
    String? label,
    Set<String> tags,
  }) = TaskRunning<T>;

  factory Task.refreshing({
    T previousData,
    T? initialData,
    String? label,
    Set<String> tags,
  }) = TaskRefreshing<T>;

  factory Task.retrying({
    T previousData,
    T? initialData,
    String? label,
    Set<String> tags,
  }) = TaskRetrying<T>;

  factory Task.success({
    required T data,
    T? initialData,
    String? label,
    Set<String> tags,
  }) = TaskSuccess<T>;

  factory Task.failure({
    required Object error,
    StackTrace? stackTrace,
    T? previousData,
    T? initialData,
    String? label,
    Set<String> tags,
  }) = TaskFailure<T>;

  /// The current state of this task.
  TaskState get state;

  final String? label;
  final Set<String> tags;
  final T? initialData;

  bool get isPending => state == TaskState.pending;
  bool get isRunning => state == TaskState.running;
  bool get isRefreshing => state == TaskState.refreshing;
  bool get isRetrying => state == TaskState.retrying;
  bool get isSuccess => state == TaskState.success;
  bool get isFailure => state == TaskState.failure;

  T? get effectiveData => switch (this) {
    TaskSuccess(data: final d) => d,
    TaskRunning(previousData: final d) => d ?? initialData,
    TaskRefreshing(previousData: final d) => d ?? initialData,
    TaskRetrying(previousData: final d) => d ?? initialData,
    TaskFailure(previousData: final d) => d ?? initialData,
    TaskPending() => initialData,
  };

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

final class TaskPending<T> extends Task<T> {
  const TaskPending({
    super.initialData,
    super.label,
    super.tags,
  });

  @override
  TaskState get state => TaskState.pending;
}

final class TaskRunning<T> extends Task<T> {
  const TaskRunning({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  final T? previousData;

  @override
  TaskState get state => TaskState.running;
}

final class TaskRefreshing<T> extends Task<T> {
  const TaskRefreshing({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  final T? previousData;

  @override
  TaskState get state => TaskState.refreshing;
}

final class TaskRetrying<T> extends Task<T> {
  const TaskRetrying({
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  final T? previousData;

  @override
  TaskState get state => TaskState.retrying;
}

final class TaskSuccess<T> extends Task<T> {
  const TaskSuccess({
    required this.data,
    super.initialData,
    super.label,
    super.tags,
  });

  final T data;

  @override
  TaskState get state => TaskState.success;
}

final class TaskFailure<T> extends Task<T> {
  const TaskFailure({
    required this.error,
    this.stackTrace,
    this.previousData,
    super.initialData,
    super.label,
    super.tags,
  });

  final Object error;
  final StackTrace? stackTrace;
  final T? previousData;

  @override
  TaskState get state => TaskState.failure;
}
