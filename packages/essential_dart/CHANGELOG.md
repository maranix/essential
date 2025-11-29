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
- Comprehensive test suite with 132 tests covering all functionality

## 1.0.0+1

- Updated package metadata and documentation.

## 1.0.0

- Initial release.
- Added `Memoizer` utility for caching computation results.
