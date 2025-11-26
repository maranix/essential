/// Reusable Flutter widgets and utilities.
///
/// This library provides essential Flutter widgets to improve code quality and reduce boilerplate:
///
/// - **ConditionalWrapper**: Conditionally wrap a widget based on a boolean condition,
///   avoiding nested ternary operators.
///
/// - **ScrollableBuilder**: Handle different loading and error states for scrollable widgets
///   like ListView, GridView, etc. Supports loading, error, and data states with customizable builders.
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
///
/// ScrollableBuilder<String>(
///   data: items,
///   isLoading: isLoading,
///   error: error,
///   dataBuilder: (context, items) => ListView.builder(
///     itemCount: items.length,
///     itemBuilder: (context, index) => ListTile(
///       title: Text(items[index]),
///     ),
///   ),
/// )
/// ```
library;

export 'package:essential_dart/essential_dart.dart';

export 'src/conditional.dart';
export 'src/conditional_wrapper.dart';
export 'src/scrollable_builder.dart';
