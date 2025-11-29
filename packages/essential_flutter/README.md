# essential_flutter

Flutter widgets, components, and services building on essential_dart for accelerated UI development.

## Features

- **ConditionalWrapper**: Conditionally wrap widgets without nested ternaries.
- **ScrollableBuilder**: Handle loading and error states for scrollable widgets.
- **Conditional**: Conditionally render widgets based on a boolean condition.
- **Conditional.chain**: Chain multiple conditions for complex conditional rendering.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_flutter: ^1.1.0
```

## Usage

### ConditionalWrapper

Avoid nested ternary operators when conditionally wrapping widgets:

```dart
ConditionalWrapper(
  condition: isScrollable,
  wrapper: (child) => SingleChildScrollView(child: child),
  child: MyContent(),
)
```

### ScrollableBuilder

Handle different loading and error states for scrollable widgets like `ListView`, `GridView`, etc.

#### Basic Usage

```dart
ScrollableBuilder<String>(
  items: items,
  isLoading: isLoading,
  itemBuilder: (context, items) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ListTile(
      title: Text(items[index]),
    ),
  ),
)
```

#### Handling States

You can provide optional builders for specific states. If a builder is not provided, it falls back to a sensible default (usually showing the data or nothing).

```dart
ScrollableBuilder<Product>(
  items: products,
  isLoading: isLoading,
  isError: hasError,
  error: errorObject,
  
  // Main content
  itemBuilder: (context, products) => GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    itemCount: products.length,
    itemBuilder: (context, index) => ProductCard(products[index]),
  ),
  
  // Loading when no data
  loadingBuilder: (context) => Center(child: CircularProgressIndicator()),
  
  // Error when no data
  errorBuilder: (context, error) => Center(child: Text('Error: $error')),
  
  // Loading when data exists (e.g. loading more)
  busyItemBuilder: (context, products) => Column(
    children: [
      LinearProgressIndicator(),
      Expanded(
        child: GridView.builder(
          // ... existing grid config
        ),
      ),
    ],
  ),
)
```

### Conditional

Conditionally render widgets based on a boolean condition.

```dart
Conditional(
  condition: isLoggedIn,
  onTrue: const Text('Welcome back!'),
  onFalse: OutlinedButton(
    onPressed: () { /* handle login */ },
    child: const Text('Please Log In'),
  ),
)
```

For more complex scenarios, you can use `Conditional.chain`:

```dart
enum UserStatus {
  loading,
  loggedIn,
  loggedOut,
  error,
}

Conditional.chain(
  [
    (status == UserStatus.loading, widget: const CircularProgressIndicator()),
    (status == UserStatus.loggedIn, widget: const Text('Welcome back!')),
    (status == UserStatus.loggedOut, widget: const Text('Please log in.')),
  ],
  fallback: const Text('An unexpected error occurred.'),
)
```

### Conditional.listenable

Listen to a `ValueListenable` (e.g., `ValueNotifier`) and rebuild when the value changes:

```dart
final ValueNotifier<bool> _isLoggedIn = ValueNotifier(false);

Conditional.listenable(
  listenable: _isLoggedIn,
  onTrue: const Text('Welcome back!'),
  onFalse: const Text('Please Log In'),
)
```

### ConditionalWrapper.listenable

Listen to a `ValueListenable` and conditionally wrap a widget:

```dart
final ValueNotifier<bool> _isScrollable = ValueNotifier(false);

ConditionalWrapper.listenable(
  listenable: _isScrollable,
  wrapper: (child) => SingleChildScrollView(child: child),
  child: MyContent(),
)
```

### ConditionalWrapper.stream

Listen to a `Stream` and conditionally wrap a widget:

```dart
final Stream<bool> _isScrollableStream = Stream.value(true);

ConditionalWrapper.stream(
  stream: _isScrollableStream,
  wrapper: (child) => SingleChildScrollView(child: child),
  child: MyContent(),
  initialData: false,
)
```
