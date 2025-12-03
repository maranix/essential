## 2.0.0

### Breaking Changes

- **Task and TaskGroup now require generic type parameters for Label and Tags**
  - `Task<T>` → `Task<T, Label, Tags>`
  - `TaskGroup<T>` → `TaskGroup<T, Label, Tags>`
  - All subclasses, extensions, and methods updated to use generic parameters
  - `label` field type changed from `String?` to `Label?`
  - `tags` field type changed from `Set<String>` to `Tags?`
  
  **Migration:**
  ```dart
  // Before
  final task = Task<int>.pending(label: 'fetch', tags: {'api'});
  final group = TaskGroup<User>.uniform({...});
  
  // After - Option 1: Use type aliases
  final task = SimpleTask<int>.pending(label: 'fetch', tags: {'api'});
  final group = SimpleTaskGroup<User>.uniform({...});
  
  // After - Option 2: Explicit types
  final task = Task<int, String?, Set<String>>.pending(label: 'fetch', tags: {'api'});
  final group = TaskGroup<User, String?, Set<String>>.uniform({...});
  ```

### New Features

- Added `SimpleTask<T>` type alias for `Task<T, String?, Set<String>>`
- Added `SimpleTaskGroup<T>` type alias for `TaskGroup<T, String?, Set<String>>`
- Support for custom Label and Tags types (enums, custom classes, etc.)
- Full type safety for labels and tags throughout the API
- **Stream Transformers**: Added powerful stream transformation utilities:
  - `StringSplitter`: Split string streams by separator (single or multi-character)
  - `Debounce`: Filter rapid-fire events, emit after quiet period
  - `Throttle`: Limit event rate by ignoring events within time window
  - `BufferCount`: Collect items into fixed-size batches
  - `BufferTime`: Collect items over time intervals

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
  - Added caching support with `CachingStrategy` enum (none, memoize, temporal).
  - Added `execute()` method for cached task execution.
  - Added `invalidateCache()` method to clear cached results.
  - Added `refresh()` method to invalidate cache and re-execute.
  - Cache persists across state transitions.
  - Default cache duration: 5 minutes for temporal strategy.


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
