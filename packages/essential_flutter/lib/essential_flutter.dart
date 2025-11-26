/// Reusable Flutter widgets and utilities.
///
/// This library provides essential Flutter widgets to improve code quality and reduce boilerplate:
///
/// - **ConditionalWrapper**: Conditionally wrap a widget based on a boolean condition,
///   avoiding nested ternary operators.
///
/// Example:
/// ```dart
/// import 'package:essential_flutter/essential_flutter.dart';
///
/// ConditionalWrapper(
///   condition: isScrollable,
///   wrapper: (child) => SingleChildScrollView(child: child),
///   child: MyContent(),
/// )
/// ```
library;

export 'package:essential_dart/essential_dart.dart';

export 'src/conditional_wrapper.dart';
