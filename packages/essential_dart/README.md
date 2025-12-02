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

// Create a task in pending state
var task = Task<String>.pending(label: 'fetch-users');

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
  print('Data: ${(task as TaskSuccess<String>).data}');
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
final result = Task<int>.pending()
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
await networkRetry(() => fetchUser());
await networkRetry(() => fetchPosts());
await networkRetry(() => fetchComments());
```

## License

This project is licensed under the MIT License.
