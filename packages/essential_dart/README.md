# essential_dart

Reusable building blocks, patterns, and services for Dart to improve efficiency and code quality.

## Features

- **Memoizer**: Cache results of expensive computations with lazy/eager execution and reset functionality.
- **Task**: Type-safe state management for asynchronous operations with intuitive state transitions.
- **TaskGroup**: Manage collections of tasks with aggregate state tracking and batch operations.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_dart: ^1.3.0
```

## Usage

### Memoizer

Cache expensive computations:

```dart
import 'package:essential_dart/essential_dart.dart';

final memoizer = Memoizer<int>(
  computation: () => expensiveCalculation(),
);

final result = await memoizer.result; // Computed once, cached
final again = await memoizer.result;  // Returns cached value
```

### Task

Manage asynchronous operation states with clean, type-safe transitions:

```dart
import 'package:essential_dart/essential_dart.dart';

// Using the SimpleTask type alias (recommended for most cases)
var task = SimpleTask<String>.pending(label: 'fetch-users');

// Or use explicit types for custom Label/Tags
var customTask = Task<String, String?, Set<String>>.pending(
  label: 'fetch-users',
  tags: {'api', 'critical'},
);

// Transition to running
task = task.toRunning();

// Transition to success with data
task = task.toSuccess('User data loaded');

// Or handle failure
task = task.toFailure(Exception('Network error'));

// Retry after failure
task = task.toRetrying();

// Refresh with existing data
task = task.toRefreshing();
```

#### Custom Label and Tags Types

You can use custom types for labels and tags for better type safety:

```dart
enum TaskLabel { fetching, processing, completed }
enum TaskTag { critical, background, userInitiated }

var task = Task<int, TaskLabel, Set<TaskTag>>.pending(
  label: TaskLabel.fetching,
  tags: {TaskTag.critical, TaskTag.userInitiated},
);
```

#### Task States

Tasks can be in one of six states:
- **Pending**: Initial state, waiting to start
- **Running**: Operation in progress
- **Refreshing**: Reloading with previous data available
- **Retrying**: Retrying after a failure
- **Success**: Operation completed successfully
- **Failure**: Operation failed with an error

#### State Checking

```dart
if (task.state == TaskState.success) {
  print('Data: ${task.success.data}');
}

// Or use convenience getters
if (task.isSuccess) {
  print('Success!');
}

// Access data type-safely (throws if state doesn't match)
if (task.isSuccess) {
  print(task.success.data); 
}
```

#### Chaining Transitions

```dart
final result = SimpleTask<int>.pending()
    .toRunning()
    .toSuccess(42)
    .toRefreshing();
```

#### Data Transformation

```dart
// Transform data while preserving state
final task = Task<int>.success(data: 42);
final doubled = task.mapData((data) => data * 2);

// Transform error
final failure = Task<int>.failure(error: Exception('Error'));
final wrapped = failure.mapError((e) => CustomError(e));

#### Capturing Execution

Execute synchronous or asynchronous callbacks and automatically capture the result as a `Task`:

```dart
// Synchronous execution
final task = Task.runSync(() => int.parse('42'));

// Asynchronous execution
final asyncTask = await Task.run(() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Result';
});
```

#### Watching Execution

Create a stream that emits `Task` states (running, success, failure) as the callback executes:

```dart
Task.watch(() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Loaded';
}).listen((task) {
  if (task.isRunning) print('Running...');
  if (task.isSuccess) print('Data: ${task.effectiveData}');
  if (task.isFailure) print('Error: ${(task as TaskFailure).error}');
});
```

#### Caching

Cache task results to improve performance and reduce redundant computations:

```dart
// Memoize - cache indefinitely
final task = Task<int>.pending(
  cachingStrategy: CachingStrategy.memoize,
);

final result1 = await task.execute(() async => expensiveComputation());
final result2 = await task.execute(() async => expensiveComputation());
// result2 uses cached value, computation runs only once

// Temporal - cache for a duration
final apiTask = Task<User>.pending(
  cachingStrategy: CachingStrategy.temporal,
  cacheDuration: Duration(minutes: 5),
);

final user = await apiTask.execute(() async => fetchUser());
// Subsequent calls within 5 minutes use cached result

// Refresh cached data
final freshData = await task.refresh(() async => fetchFreshData());

// Invalidate cache manually
task.invalidateCache();
```

### TaskGroup

Manage multiple tasks as a single unit:

```dart
// Create a group of tasks
var group = TaskGroup<int>.uniform({
  'users': Task.pending(),
  'posts': Task.pending(),
});

// Run all tasks
group = await group.runAll((key, task) async {
  return await fetchCount(key);
});

// Check aggregate state
if (group.isCompleted) {
  print('All done!');
} else if (group.isPartial) {
  print('Some failed or pending');
}

// Access individual tasks type-safely
final userCount = group.getTask<TaskSuccess<int>>('users');
if (userCount != null) {
  print('Users: ${userCount.data}');
}

// Retry only failed tasks
group = await group.retryFailed((key, task) => fetchCount(key));

// Customize execution strategy (parallel or sequential)
// Default is TaskGroupExecutionStrategy.parallel
group = await group.runAll(
  (key, task) => fetchCount(key),
  strategy: TaskGroupExecutionStrategy.sequential,
);
```

### Retry

Handle temporary failures with configurable retry strategies:

```dart
import 'package:essential_dart/essential_dart.dart';

// Static methods for one-off operations
final result = await Retry.run(() => fetchData());

// Exponential backoff for network requests
await Retry.withExponentialBackoff(
  () => api.fetchUser(userId),
  initialDuration: Duration(milliseconds: 500),
  multiplier: 2.0,
  maxDelay: Duration(seconds: 5),
  maxAttempts: 5,
);

// Linear backoff with progress logging
await Retry.withLinearBackoff(
  () => uploadFile(file),
  initialDuration: Duration(seconds: 1),
  increment: Duration(seconds: 1),
  maxAttempts: 4,
  onRetry: (error, attempt) {
    print('Upload failed: $error. Retrying (attempt $attempt)...');
    return true; // Return false to abort retry
  },
);

// Reusable instances for multiple operations
final networkRetry = Retry(
  maxAttempts: 5,
  strategy: ExponentialBackoffStrategy(
    initialDuration: Duration(milliseconds: 500),
    multiplier: 2.0,
    maxDelay: Duration(seconds: 5),
  ),
);

// Use the same retry configuration across multiple operations
await networkRetry(() => fetchComments());
```

### Interval

Work with generic ranges of comparable values (int, double, DateTime, etc.):

```dart
// Integer intervals
final range = Interval(1, 10);
print(range.contains(5)); // true
print(range.length);      // 9 (for num/int)

// DateTime intervals
final period = Interval(
  DateTime(2023, 1, 1),
  DateTime(2023, 1, 31),
);
print(period.duration.inDays); // 30

// Set operations
final a = Interval(10, 20);
final b = Interval(15, 25);

if (a.overlaps(b)) {
  final intersection = a.intersection(b); // [15, 20]
  final span = a.span(b);                 // [10, 25]
}
```

### Stream Transformers

Powerful stream transformers for common patterns:

#### StringSplitter

Split string streams by separator (supports single or multi-character separators):

```dart
import 'package:essential_dart/essential_dart.dart';

// Split by newline (default)
Stream.fromIterable(['line1\nline2', '\nline3'])
  .transform(StringSplitter())
  .listen(print); // Prints: line1, line2, line3

// Split by custom separator
Stream.fromIterable(['a,b', ',c'])
  .transform(StringSplitter(','))
  .listen(print); // Prints: a, b, c

// Multi-character separator
Stream.fromIterable(['a--b', '--c'])
  .transform(StringSplitter('--'))
  .listen(print); // Prints: a, b, c
```

#### Debounce

Filter out rapid-fire events, emitting only after a quiet period:

```dart
// Search as user types
searchController.stream
  .transform(Debounce(Duration(milliseconds: 300)))
  .listen(performSearch);
```

#### Throttle

Limit event rate by ignoring events within a time window:

```dart
// Prevent double-clicks
buttonClickStream
  .transform(Throttle(Duration(milliseconds: 500)))
  .listen(handleClick);
```

#### BufferCount

Collect items into fixed-size batches:

```dart
// Process data in batches of 10
dataStream
  .transform(BufferCount(10))
  .listen((batch) => processBatch(batch));
```

#### BufferTime

Collect items over time intervals:

```dart
// Aggregate events every second
eventStream
  .transform(BufferTime(Duration(seconds: 1)))
  .listen((events) => processEvents(events));
```

## License

This project is licensed under the MIT License.
