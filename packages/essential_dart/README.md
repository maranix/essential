# essential_dart

Reusable building blocks, patterns, and services for Dart to improve efficiency and code quality.

## Features

- **Memoizer**: Cache results of expensive computations with lazy/eager execution and reset functionality.
- **Task**: Type-safe state management for asynchronous operations with intuitive state transitions.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_dart: ^1.1.0
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
```

## License

This project is licensed under the MIT License.
