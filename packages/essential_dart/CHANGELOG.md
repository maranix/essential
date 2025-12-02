## 1.3.0

- Added `TaskGroup` API for managing collections of tasks with aggregate state.
  - Support for homogeneous (`TaskGroup.uniform`) and heterogeneous (`TaskGroup.mixed`) groups.
  - Aggregate state derivation (Active, Completed, Failed, Idle, Partial).
  - Batch operations (`runAll`, `mapTasks`, `retryFailed`) for homogeneous groups.
  - Query extensions (`withLabel`, `withTags`, `byState`, `where`).
  - State transition extensions (`toRunning`, `toPending`, `resetFailed`).
  - Stream support via `watch`.
- Enhanced `Task` API:
  - Added type-safe state getters (`.success`, `.failure`, `.pending`, etc.) that throw detailed `StateError` if the state doesn't match.
  - Added `effectiveData` getter to retrieve data from current or previous states.

## 1.2.0
- Added `Retry` utility for retrying asynchronous operations with configurable strategies.
- Added `RetryStrategy` interface and implementations:
  - `ConstantBackoffStrategy`
  - `LinearBackoffStrategy`
  - `ExponentialBackoffStrategy`

## 1.1.0

- Added `Task` API for type-safe asynchronous operation state management
- Added `TaskState` enum for explicit state representation
- Added convenience transition methods:
  - `toPending()` - Transition to pending state
  - `toRunning()` - Transition to running state
  - `toRefreshing()` - Transition to refreshing state (allows null previousData)
  - `toRetrying()` - Transition to retrying state (allows null previousData)
  - `toSuccess(T data)` - Transition to success state with data
  - `toFailure(Object error, {StackTrace? stackTrace})` - Transition to failure state
- Added `state` getter to all Task classes
- All transition methods automatically propagate label, tags, and initialData
- Updated state checking getters to use `TaskState` enum
- Added `run` and `runSync` methods to `Task` for executing callbacks and returning `Task` objects.
- Added `watch` method to `Task` for creating streams that emit `Task` states.
- Comprehensive test suite with 138 tests covering all functionality

## 1.0.0+1

- Updated package metadata and documentation.

## 1.0.0

- Initial release.
- Added `Memoizer` utility for caching computation results.
