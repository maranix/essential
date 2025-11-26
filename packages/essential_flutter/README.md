# essential_flutter

Flutter widgets, components, and services building on essential_dart for accelerated UI development.

## Features

- **Unified Access**: Re-exports all `essential_dart` utilities for seamless integration.
- **Widgets**: Reusable UI components.
- **Services**: Flutter-specific services.
- **Architecture**: Patterns for clean Flutter architecture.
- **ConditionalWrapper**: Conditionally wrap widgets without nested ternaries.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_flutter: ^1.0.0
```

## Usage

```dart
import 'package:essential_flutter/essential_flutter.dart';

// Access both Flutter widgets and Dart utilities with a single import

// Use Flutter-specific widgets
ConditionalWrapper(
  condition: isScrollable,
  wrapper: (child) => SingleChildScrollView(child: child),
  child: MyContent(),
)

// Access essential_dart utilities directly
final memoizer = Memoizer<int>(computation: () => 42);
final result = await memoizer.result; // 42
```