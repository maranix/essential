# essential_flutter

Flutter widgets, components, and services building on essential_dart for accelerated UI development.

## Features

- **ConditionalWrapper**: Conditionally wrap widgets without nested ternaries.
- **ScrollableBuilder**: Handle loading and error states for scrollable widgets.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_flutter: ^1.0.0
```

## Usage

### ConditionalWrapper

Avoid nested ternary operators when conditionally wrapping widgets:

```dart
import 'package:essential_flutter/essential_flutter.dart';

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