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
  data: items,
  isLoading: isLoading,
  error: error,
  dataBuilder: (context, items) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ListTile(
      title: Text(items[index]),
    ),
  ),
)
```

#### Supported States

1. **Loading with no data**: Shows adaptive loading indicator
2. **Loaded with data**: Shows your scrollable content
3. **Loading with data**: Shows data with optional loader (customizable position)
4. **Error**: Shows adaptive error widget
5. **Error with data**: Shows data (or custom error + data UI)

#### Custom Builders

```dart
ScrollableBuilder<Product>(
  data: products,
  isLoading: isLoading,
  error: error,
  dataBuilder: (context, products) => GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
    ),
    itemCount: products.length,
    itemBuilder: (context, index) => ProductCard(products[index]),
  ),
  loadingBuilder: (context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Loading products...'),
      ],
    ),
  ),
  errorBuilder: (context, error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 48, color: Colors.red),
        SizedBox(height: 16),
        Text('Failed to load products'),
        SizedBox(height: 8),
        ElevatedButton(
          onPressed: retry,
          child: Text('Retry'),
        ),
      ],
    ),
  ),
)
```

#### Loader Positioning

Control where the loader appears when loading with existing data:

```dart
ScrollableBuilder<Message>(
  data: messages,
  isLoading: isLoadingMore,
  dataBuilder: (context, messages) => ListView.builder(
    itemCount: messages.length,
    itemBuilder: (context, index) => MessageTile(messages[index]),
  ),
  showLoaderWithData: true,
  loaderPosition: LoaderPosition.end, // bottom for vertical scroll
  loaderPadding: EdgeInsets.all(16),
)
```

#### Horizontal Scrolling

```dart
ScrollableBuilder<Item>(
  data: items,
  isLoading: isLoading,
  scrollDirection: Axis.horizontal,
  dataBuilder: (context, items) => ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: items.length,
    itemBuilder: (context, index) => ItemCard(items[index]),
  ),
  loaderPosition: LoaderPosition.end, // right side for horizontal
)
```