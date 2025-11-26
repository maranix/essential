# essential_dart

Reusable building blocks, patterns, and services for Dart to improve efficiency and code quality.

## Features

- **Utilities**: Helper classes and common abstractions.
- **Patterns**: Reusable code snippets to reduce boilerplate.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_dart: ^1.0.0
```

## Usage

```dart
import 'package:essential_dart/essential_dart.dart';

// Example usage of Memoizer
final memoizer = Memoizer<int>(computation: () => 42);
final result = await memoizer.result; // 42
```