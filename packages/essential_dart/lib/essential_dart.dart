/// Reusable building blocks, patterns, and utilities for Dart.
///
/// This library provides essential utilities to improve code efficiency and quality:
///
/// - **Memoizer**: Cache results of expensive computations with support for
///   lazy/eager execution and reset functionality.
///
/// Example:
/// ```dart
/// import 'package:essential_dart/essential_dart.dart';
///
/// // Memoize an expensive computation
/// final memoizer = Memoizer<int>(
///   computation: () => expensiveCalculation(),
/// );
///
/// // Access the cached result
/// final result = await memoizer.result;
/// ```

library;

export 'src/memoizer.dart';
