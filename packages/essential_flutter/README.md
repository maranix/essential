# essential_flutter

Flutter widgets, components, and services building on essential_dart for accelerated UI development.

## Features

- **Widgets**: Reusable UI components.
- **Services**: Flutter-specific services.
- **Utilities**: Helpful utilities for Flutter development.

## Getting started

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  essential_flutter: ^1.0.0
```

## Usage

```dart
import 'package:essential_flutter/essential_flutter.dart';

ConditionalWrapper(
  condition: isScrollable,
  wrapper: (child) => SingleChildScrollView(child: child),
  child: MyContent(),
)
```