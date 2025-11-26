## 1.1.0

- **Feature**: Added `Conditional.chain` for complex conditional rendering.
- **Feature**: Added `Conditional` widget for conditional rendering.
- **Feature**: Added `ScrollableBuilder` widget for handling loading and error states in scrollable widgets.
  - Supports 5 different states: empty loading, empty error, busy (loading with data), busy error, and data.
  - Fully customizable builders for all states with sensible defaults (no default widgets, just logic).
  - Clean API with `itemBuilder`, `loadingBuilder`, `busyItemBuilder`, etc.
  - Type-safe builders with nullable error handling.

## 1.0.0+1

- **Enhancement**: Re-exported `essential_dart` package for seamless access to all Dart utilities.
- **Documentation**: Improved documentation.

## 1.0.0

- Initial release.
- Added `ConditionalWrapper` widget for conditional wrapping.
