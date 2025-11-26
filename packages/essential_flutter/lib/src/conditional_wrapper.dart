import 'package:flutter/widgets.dart';

/// A widget that conditionally wraps its [child] with another widget.
///
/// This widget helps avoid nested ternary operators when you need to
/// conditionally wrap a widget based on a boolean condition.
///
/// If [condition] is `true`, the [child] is wrapped using the [wrapper] builder.
/// If [condition] is `false`, the [child] is returned directly without wrapping.
///
/// Example:
/// ```dart
/// ConditionalWrapper(
///   condition: isScrollable,
///   wrapper: (child) => SingleChildScrollView(child: child),
///   child: MyContent(),
/// )
/// ```
///
/// This is equivalent to but more readable than:
/// ```dart
/// isScrollable
///   ? SingleChildScrollView(child: MyContent())
///   : MyContent()
/// ```
class ConditionalWrapper extends StatelessWidget {
  /// Creates a [ConditionalWrapper].
  ///
  /// The [condition], [wrapper], and [child] arguments must not be null.
  const ConditionalWrapper({
    required this.condition,
    required this.wrapper,
    required this.child,
    super.key,
  });

  /// Whether to wrap the [child] with the [wrapper].
  final bool condition;

  /// A builder function that wraps the [child] when [condition] is `true`.
  ///
  /// This function receives the [child] widget and should return a widget
  /// that wraps it.
  final Widget Function(Widget child) wrapper;

  /// The child widget to conditionally wrap.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return condition ? wrapper(child) : child;
  }
}
