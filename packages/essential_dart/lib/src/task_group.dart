import 'dart:async';

import 'task.dart';

/// Represents the aggregate state of a task group.
///
/// This enum describes the overall state derived from all tasks in the group.
enum TaskGroupState {
  /// No tasks in the group, or all tasks are pending.
  idle,

  /// At least one task is actively running, refreshing, or retrying.
  active,

  /// All tasks have completed successfully.
  completed,

  /// Some tasks succeeded and some failed (mixed state).
  partial,

  /// All tasks have failed.
  failed,
}

/// A sealed class for managing collections of [Task] instances.
///
/// [TaskGroup] provides two variants:
/// 1. **Uniform** (`TaskGroup<T>`): All tasks share the same data type
/// 2. **Mixed** (`TaskGroup<void>`): Tasks can have different data types
///
/// Both variants offer:
/// - Task grouping and organization using labels and tags
/// - Aggregate state computation
/// - Batch operations on multiple tasks
/// - Filtering and querying by labels, tags, or states
/// - Coordinated state transitions
///
/// The implementations are private and accessed through factory constructors.
///
/// Example (Uniform):
/// ```dart
/// // All tasks return User type
/// final group = TaskGroup<User>.uniform({
///   'user-123': Task.pending(label: 'fetch-user'),
///   'user-456': Task.pending(label: 'fetch-user'),
/// });
/// ```
///
/// Example (Mixed):
/// ```dart
/// // Tasks return different types
/// final group = TaskGroup.mixed({
///   'user': Task<User>.pending(label: 'fetch-user'),
///   'posts': Task<List<Post>>.pending(label: 'fetch-posts'),
/// });
/// ```
sealed class TaskGroup<T> {
  /// Creates an empty mixed [TaskGroup].
  factory TaskGroup({
    String? label,
    Set<String> tags = const {},
  }) => TaskGroup.mixed({}, label: label, tags: tags) as TaskGroup<T>;

  /// Private constructor for subclasses.
  const TaskGroup._({
    required this.label,
    required this.tags,
  });

  /// Creates a uniform [TaskGroup] where all tasks share the same type [T].
  ///
  /// - [tasks]: A map of task keys to [Task<T>] instances.
  /// - [label]: Optional label for the group.
  /// - [tags]: Optional tags for the group.
  ///
  /// Example:
  /// ```dart
  /// final group = TaskGroup<User>.uniform({
  ///   'user-1': Task.success(data: user1),
  ///   'user-2': Task.pending(),
  /// });
  /// ```
  factory TaskGroup.uniform(
    Map<String, Task<T>> tasks, {
    String? label,
    Set<String> tags = const {},
  }) {
    return _HomogeneousTaskGroup<T>(
      tasks: Map.unmodifiable(tasks),
      state: _computeGroupState(tasks),
      label: label,
      tags: tags,
    );
  }

  /// Creates a mixed [TaskGroup] where tasks can have different types.
  ///
  /// - [tasks]: A map of task keys to [Task<Object?>] instances.
  /// - [label]: Optional label for the group.
  /// - [tags]: Optional tags for the group.
  ///
  /// Note: This returns TaskGroup&lt;Object?&gt; since there's no single type.
  ///
  /// Example:
  /// ```dart
  /// final group = TaskGroup.mixed({
  ///   'user': Task<User>.pending(),
  ///   'posts': Task<List<Post>>.pending(),
  /// });
  /// ```
  static TaskGroup<Object?> mixed(
    Map<String, Task<Object?>> tasks, {
    String? label,
    Set<String> tags = const {},
  }) {
    return _HeterogeneousTaskGroup(
      tasks: Map.unmodifiable(tasks),
      state: _computeGroupState(tasks),
      label: label,
      tags: tags,
    );
  }

  /// The current aggregate state of the group.
  TaskGroupState get state;

  /// The collection of tasks in the group.
  Map<String, Task<T>> get tasks;

  /// An optional label for the entire group.
  final String? label;

  /// A set of tags for categorizing the group.
  final Set<String> tags;

  /// The total number of tasks in the group.
  int get taskCount;

  /// Adds a task to the group with the given [key].
  ///
  /// Returns a new [TaskGroup] with the task added. If a task with the same
  /// key already exists, it will be replaced.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.addTask('task3', Task.pending(tags: {'critical'}));
  /// ```
  TaskGroup<T> addTask(String key, Task<T> task);

  /// Removes the task with the given [key] from the group.
  ///
  /// Returns a new [TaskGroup] without the specified task. If the key doesn't
  /// exist, returns the current group unchanged.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.removeTask('task1');
  /// ```
  TaskGroup<T> removeTask(String key);

  /// Updates the task with the given [key] using the [updater] function.
  ///
  /// Returns a new [TaskGroup] with the updated task. If the key doesn't
  /// exist, returns the current group unchanged.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.updateTask('task2', (task) => task.toRunning());
  /// ```
  TaskGroup<T> updateTask(String key, Task<T> Function(Task<T> task) updater);

  /// Gets the task with the given [key].
  ///
  /// Returns the task if it exists and matches type [S].
  /// Throws [TypeError] if the task exists but is not of type [S].
  ///
  /// Example:
  /// ```dart
  /// final task = group.getTask<TaskSuccess<User>>('user-1');
  /// ```
  S? getTask<S extends Task<T>>(String key);

  /// Creates a copy of this group with the given [tasks].
  ///
  /// Used by extensions to preserve the specific subclass type.
  TaskGroup<T> _createCopy(Map<String, Task<T>> tasks);

  /// Computes the aggregate state from all tasks.
  ///
  /// Logic:
  /// - If any task is running/refreshing/retrying -> TaskGroupState.active
  /// - If all tasks succeeded (and not empty) -> TaskGroupState.completed
  /// - If all tasks failed (and not empty) -> TaskGroupState.failed
  /// - If tasks is empty or all pending -> TaskGroupState.idle
  /// - Otherwise (mix of success/failure) -> TaskGroupState.partial
  static TaskGroupState _computeGroupState(Map<String, Task<Object?>> tasks) {
    if (tasks.isEmpty) {
      return TaskGroupState.idle;
    }

    var hasActive = false;
    var hasPending = false;
    var hasSuccess = false;
    var hasFailure = false;

    for (final task in tasks.values) {
      switch (task.state) {
        case TaskState.running:
        case TaskState.refreshing:
        case TaskState.retrying:
          hasActive = true;
        case TaskState.pending:
          hasPending = true;
        case TaskState.success:
          hasSuccess = true;
        case TaskState.failure:
          hasFailure = true;
      }
    }

    if (hasActive) {
      return TaskGroupState.active;
    }
    if (hasSuccess && !hasFailure && !hasPending) {
      return TaskGroupState.completed;
    }
    if (hasFailure && !hasSuccess && !hasPending) {
      return TaskGroupState.failed;
    }
    if (hasPending && !hasSuccess && !hasFailure) {
      return TaskGroupState.idle;
    }

    return TaskGroupState.partial;
  }
}

/// Private implementation of [TaskGroup] for homogeneous task collections.
///
/// All tasks in this group share the same data type [T], enabling type-safe
/// operations and batch processing.
final class _HomogeneousTaskGroup<T> extends TaskGroup<T> {
  /// Constructs a [_HomogeneousTaskGroup] instance.
  const _HomogeneousTaskGroup({
    required this.tasks,
    required this.state,
    super.label,
    super.tags = const {},
  }) : super._();

  /// The collection of tasks, all of type [Task<T>].
  @override
  final Map<String, Task<T>> tasks;

  @override
  final TaskGroupState state;

  @override
  int get taskCount => tasks.length;

  @override
  TaskGroup<T> addTask(String key, Task<T> task) {
    final newTasks = Map<String, Task<T>>.from(tasks)..[key] = task;
    return _HomogeneousTaskGroup<T>(
      tasks: Map.unmodifiable(newTasks),
      state: TaskGroup._computeGroupState(newTasks),
      label: label,
      tags: tags,
    );
  }

  @override
  TaskGroup<T> removeTask(String key) {
    if (!tasks.containsKey(key)) {
      return this;
    }
    final newTasks = Map<String, Task<T>>.from(tasks)..remove(key);
    return _HomogeneousTaskGroup<T>(
      tasks: Map.unmodifiable(newTasks),
      state: TaskGroup._computeGroupState(newTasks),
      label: label,
      tags: tags,
    );
  }

  @override
  TaskGroup<T> updateTask(String key, Task<T> Function(Task<T> task) updater) {
    final task = tasks[key];
    if (task == null) {
      return this;
    }

    final newTask = updater(task);
    final newTasks = Map<String, Task<T>>.from(tasks)..[key] = newTask;

    return _HomogeneousTaskGroup<T>(
      tasks: Map.unmodifiable(newTasks),
      state: TaskGroup._computeGroupState(newTasks),
      label: label,
      tags: tags,
    );
  }

  @override
  S? getTask<S extends Task<T>>(String key) {
    final task = tasks[key];
    if (task == null) return null;
    if (task is S) return task;
    throw TypeError();
  }

  @override
  TaskGroup<T> _createCopy(Map<String, Task<T>> tasks) {
    return _HomogeneousTaskGroup<T>(
      tasks: Map.unmodifiable(tasks),
      state: TaskGroup._computeGroupState(tasks),
      label: label,
      tags: tags,
    );
  }
}

/// Private implementation of [TaskGroup] for heterogeneous task collections.
///
/// Tasks in this group can have different data types, providing maximum
/// flexibility for managing diverse workflows.
final class _HeterogeneousTaskGroup extends TaskGroup<Object?> {
  /// Constructs a [_HeterogeneousTaskGroup] instance.
  const _HeterogeneousTaskGroup({
    required this.tasks,
    required this.state,
    super.label,
    super.tags = const {},
  }) : super._();

  /// The collection of tasks, each can be of any type [Task<Object?>].
  @override
  final Map<String, Task<Object?>> tasks;

  @override
  final TaskGroupState state;

  @override
  int get taskCount => tasks.length;

  @override
  TaskGroup<Object?> addTask(String key, Task<Object?> task) {
    final newTasks = Map<String, Task<Object?>>.from(tasks)..[key] = task;
    return _HeterogeneousTaskGroup(
      tasks: Map.unmodifiable(newTasks),
      state: TaskGroup._computeGroupState(newTasks),
      label: label,
      tags: tags,
    );
  }

  @override
  TaskGroup<Object?> removeTask(String key) {
    if (!tasks.containsKey(key)) {
      return this;
    }
    final newTasks = Map<String, Task<Object?>>.from(tasks)..remove(key);
    return _HeterogeneousTaskGroup(
      tasks: Map.unmodifiable(newTasks),
      state: TaskGroup._computeGroupState(newTasks),
      label: label,
      tags: tags,
    );
  }

  @override
  TaskGroup<Object?> updateTask(
    String key,
    Task<Object?> Function(Task<Object?> task) updater,
  ) {
    final task = tasks[key];
    if (task == null) {
      return this;
    }

    final newTask = updater(task);
    final newTasks = Map<String, Task<Object?>>.from(tasks)..[key] = newTask;

    return _HeterogeneousTaskGroup(
      tasks: Map.unmodifiable(newTasks),
      state: TaskGroup._computeGroupState(newTasks),
      label: label,
      tags: tags,
    );
  }

  @override
  S? getTask<S extends Task<Object?>>(String key) {
    final task = tasks[key];
    if (task == null) return null;
    if (task is S) return task;
    throw TypeError();
  }

  /// Gets a task with a specific type [T].
  ///
  /// Returns `null` if the task doesn't exist or is not of  @override
  Task<T>? getTaskTyped<T>(String key) {
    final task = tasks[key];
    if (task is Task<T>) {
      return task;
    }
    return null;
  }

  @override
  TaskGroup<Object?> _createCopy(Map<String, Task<Object?>> tasks) {
    return _HeterogeneousTaskGroup(
      tasks: Map.unmodifiable(tasks),
      state: TaskGroup._computeGroupState(tasks),
      label: label,
      tags: tags,
    );
  }
}

/// Extension providing query and filtering operations for [TaskGroup].
///
/// These work on both homogeneous and heterogeneous task groups.
extension TaskGroupQueryX<T> on TaskGroup<T> {
  /// Returns all tasks that have the specified [label].
  ///
  /// Example:
  /// ```dart
  /// final userTasks = group.withLabel('fetch-user');
  /// ```
  Map<String, Task<T>> withLabel(String label) {
    return Map.fromEntries(
      tasks.entries.where((entry) => entry.value.label == label),
    );
  }

  /// Returns all tasks that have all of the specified [tags].
  ///
  /// Example:
  /// ```dart
  /// final criticalTasks = group.withTags({'critical', 'api'});
  /// ```
  Map<String, Task<T>> withTags(Set<String> tags) {
    return Map.fromEntries(
      tasks.entries.where((entry) => entry.value.tags.containsAll(tags)),
    );
  }

  /// Returns all tasks that have any of the specified [tags].
  ///
  /// Example:
  /// ```dart
  /// final taggedTasks = group.withAnyTag({'api', 'database'});
  /// ```
  Map<String, Task<T>> withAnyTag(Set<String> tags) {
    return Map.fromEntries(
      tasks.entries.where(
        (entry) => entry.value.tags.any((tag) => tags.contains(tag)),
      ),
    );
  }

  /// Returns all tasks in the specified [state].
  ///
  /// Example:
  /// ```dart
  /// final runningTasks = group.byState(TaskState.running);
  /// ```
  Map<String, Task<T>> byState(TaskState state) {
    return Map.fromEntries(
      tasks.entries.where((entry) => entry.value.state == state),
    );
  }

  /// Returns all tasks that match the given [predicate].
  ///
  /// Example:
  /// ```dart
  /// final tasks = group.where((key, task) =>
  ///   task.tags.contains('api') && task.isSuccess
  /// );
  /// ```
  Map<String, Task<T>> where(
    bool Function(String key, Task<T> task) predicate,
  ) {
    return Map.fromEntries(
      tasks.entries.where((entry) => predicate(entry.key, entry.value)),
    );
  }
}

/// Extension providing aggregate state properties for [TaskGroup].
extension TaskGroupStateX<T> on TaskGroup<T> {
  /// Returns `true` if the group is in the [TaskGroupState.idle] state.
  bool get isIdle => state == TaskGroupState.idle;

  /// Returns `true` if the group is in the [TaskGroupState.active] state.
  bool get isActive => state == TaskGroupState.active;

  /// Returns `true` if the group is in the [TaskGroupState.completed] state.
  bool get isCompleted => state == TaskGroupState.completed;

  /// Returns `true` if the group is in the [TaskGroupState.partial] state.
  bool get isPartial => state == TaskGroupState.partial;

  /// Returns `true` if the group is in the [TaskGroupState.failed] state.
  bool get isFailed => state == TaskGroupState.failed;

  /// Returns `true` if all tasks have completed successfully.
  ///
  /// Example:
  /// ```dart
  /// if (group.allSuccess) {
  ///   print('All tasks completed!');
  /// }
  /// ```
  bool get allSuccess =>
      tasks.isNotEmpty && tasks.values.every((t) => t.isSuccess);

  /// Returns `true` if any task has failed.
  ///
  /// Example:
  /// ```dart
  /// if (group.anyFailure) {
  ///   print('At least one task failed');
  /// }
  /// ```
  bool get anyFailure => tasks.values.any((t) => t.isFailure);

  /// Returns `true` if all tasks have failed.
  bool get allFailure =>
      tasks.isNotEmpty && tasks.values.every((t) => t.isFailure);

  /// Returns `true` if any task is currently running, refreshing, or retrying.
  bool get anyActive => tasks.values.any(
    (t) => t.isRunning || t.isRefreshing || t.isRetrying,
  );

  /// Returns a map of task state counts.
  ///
  /// Example:
  /// ```dart
  /// final counts = group.stateCounts;
  /// print('Success: ${counts[TaskState.success]}');
  /// print('Failed: ${counts[TaskState.failure]}');
  /// ```
  Map<TaskState, int> get stateCounts {
    final counts = <TaskState, int>{};
    for (final state in TaskState.values) {
      counts[state] = 0;
    }
    for (final task in tasks.values) {
      counts[task.state] = (counts[task.state] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns the number of completed (successful) tasks.
  int get successCount =>
      tasks.values.where((t) => t.state == TaskState.success).length;

  /// Returns the number of failed tasks.
  int get failureCount =>
      tasks.values.where((t) => t.state == TaskState.failure).length;
}

/// Extension providing batch operations for homogeneous [TaskGroup<T>].
///
/// These operations only work on homogeneous groups where all tasks share
/// the same type [T]. They will not be available on heterogeneous groups.
extension TaskGroupHomogeneousOpsX<T> on TaskGroup<T> {
  /// Executes the [callback] for all tasks and updates them with the results.
  ///
  /// Example:
  /// ```dart
  /// final updated = await group.runAll((key, task) async {
  ///   return await fetchUser(key);
  /// });
  /// ```
  Future<TaskGroup<T>> runAll(
    Future<T> Function(String key, Task<T> task) callback,
  ) async {
    // First, mark all as running
    final currentGroup = toRunning();

    // TODO: Implement parallel execution or sequential?
    // For now, let's do parallel execution
    final futures = currentGroup.tasks.entries.map((entry) async {
      try {
        final data = await callback(entry.key, entry.value);
        return MapEntry(entry.key, entry.value.toSuccess(data));
      } on Exception catch (e, s) {
        return MapEntry(entry.key, entry.value.toFailure(e, stackTrace: s));
      }
    });

    final entries = await Future.wait(futures);
    return _createCopy(Map.fromEntries(entries));
  }

  /// Applies the [transform] function to all tasks.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.mapTasks((key, task) => task.toRunning());
  /// ```
  TaskGroup<T> mapTasks(Task<T> Function(String key, Task<T> task) transform) {
    final newTasks = tasks.map(
      (key, task) => MapEntry(key, transform(key, task)),
    );
    return _createCopy(newTasks);
  }

  /// Updates all tasks that match the [predicate] using the [updater] function.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.updateWhere(
  ///   (key, task) => task.isFailure,
  ///   (key, task) => task.toRetrying(),
  /// );
  /// ```
  TaskGroup<T> updateWhere(
    bool Function(String key, Task<T> task) predicate,
    Task<T> Function(String key, Task<T> task) updater,
  ) {
    final newTasks = Map<String, Task<T>>.from(tasks);
    for (final entry in tasks.entries) {
      if (predicate(entry.key, entry.value)) {
        newTasks[entry.key] = updater(entry.key, entry.value);
      }
    }
    return _createCopy(newTasks);
  }

  /// Retries all failed tasks using the [callback].
  ///
  /// Example:
  /// ```dart
  /// final updated = await group.retryFailed((key, task) async {
  ///   return await fetchData(key);
  /// });
  /// ```
  Future<TaskGroup<T>> retryFailed(
    Future<T> Function(String key, Task<T> task) callback,
  ) async {
    // Identify failed tasks
    final failedKeys = tasks.entries
        .where((e) => e.value.isFailure)
        .map((e) => e.key)
        .toSet();

    if (failedKeys.isEmpty) {
      return this;
    }

    // Mark failed tasks as retrying
    final currentGroup = updateWhere(
      (key, task) => failedKeys.contains(key),
      (key, task) => task.toRetrying(),
    );

    // Execute callback only for retrying tasks
    final futures = failedKeys.map((key) async {
      final task = currentGroup.getTask(key)!;
      try {
        final data = await callback(key, task);
        return MapEntry(key, task.toSuccess(data));
      } on Exception catch (e, s) {
        return MapEntry(key, task.toFailure(e, stackTrace: s));
      }
    });

    final results = await Future.wait(futures);

    // Merge results back
    final newTasks = Map<String, Task<T>>.from(currentGroup.tasks);
    for (final entry in results) {
      newTasks[entry.key] = entry.value;
    }

    return _createCopy(newTasks);
  }
}

/// Extension providing state transition methods for [TaskGroup].
extension TaskGroupTransitionsX<T> on TaskGroup<T> {
  /// Transitions all tasks to the running state.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.toRunning();
  /// ```
  TaskGroup<T> toRunning() {
    final newTasks = Map<String, Task<T>>.from(tasks).map(
      (key, task) => MapEntry(key, task.toRunning()),
    );
    return _createCopy(newTasks);
  }

  /// Transitions all tasks to the pending state.
  TaskGroup<T> toPending() {
    final newTasks = Map<String, Task<T>>.from(tasks).map(
      (key, task) => MapEntry(key, task.toPending()),
    );
    return _createCopy(newTasks);
  }

  /// Resets all failed tasks to pending state.
  ///
  /// Example:
  /// ```dart
  /// final updated = group.resetFailed();
  /// ```
  TaskGroup<T> resetFailed() {
    final newTasks = Map<String, Task<T>>.from(tasks);
    for (final entry in tasks.entries) {
      if (entry.value.isFailure) {
        newTasks[entry.key] = entry.value.toPending();
      }
    }
    return _createCopy(newTasks);
  }
}

/// Extension providing stream-based operations for homogeneous [TaskGroup<T>].
///
/// TODO: Implement stream support for watching group state changes
/// Note: This is optional and can be implemented later
extension TaskGroupStreamX<T> on TaskGroup<T> {
  /// Watches the execution of all tasks, emitting [TaskGroup] states as they change.
  ///
  /// Example:
  /// ```dart
  /// group.watch((key, task) async {
  ///   return await fetchData(key);
  /// }).listen((group) {
  ///   print('Group state: ${group.state}');
  /// });
  /// ```
  Stream<TaskGroup<T>> watch(
    Future<T> Function(String key, Task<T> task) callback,
  ) async* {
    // Emit initial running state
    var currentGroup = toRunning();
    yield currentGroup;

    final controller = StreamController<TaskGroup<T>>();
    var completedCount = 0;
    final totalCount = currentGroup.taskCount;

    if (totalCount == 0) {
      await controller.close();
      return;
    }

    for (final entry in currentGroup.tasks.entries) {
      final key = entry.key;
      final task = entry.value;

      // Execute callback for each task
      Future<void> executeTask() async {
        try {
          final data = await callback(key, task);
          currentGroup = currentGroup.updateTask(
            key,
            (t) => t.toSuccess(data),
          );
        } on Exception catch (e, s) {
          currentGroup = currentGroup.updateTask(
            key,
            (t) => t.toFailure(e, stackTrace: s),
          );
        }
        controller.add(currentGroup);
        completedCount++;
        if (completedCount == totalCount) {
          await controller.close();
        }
      }

      // Fire and forget, but errors are handled inside
      await executeTask();
    }

    yield* controller.stream;
  }
}
