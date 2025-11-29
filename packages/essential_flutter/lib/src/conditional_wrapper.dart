import 'package:flutter/foundation.dart';
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

  /// {@macro conditional_wrapper.listenable}
  factory ConditionalWrapper.listenable({
    Key? key,
    required ValueListenable<bool> listenable,
    required Widget Function(Widget child) wrapper,
    required Widget child,
  }) = _ConditionalWrapperListenable;

  /// {@macro conditional_wrapper.stream}
  const factory ConditionalWrapper.stream({
    Key? key,
    required Stream<bool> stream,
    required Widget Function(Widget child) wrapper,
    required Widget child,
    bool initialData,
  }) = _ConditionalWrapperStream;

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

/// {@template conditional_wrapper.listenable}
/// Creates a [ConditionalWrapper] that listens to a [ValueListenable] (e.g., [ValueNotifier]).
///
/// The widget rebuilds whenever the [listenable] notifies its listeners.
///
/// Initial value of the [listenable] is used as the [condition].
///
/// ```dart
/// final ValueNotifier<bool> _isScrollable = ValueNotifier(false);
///
/// ConditionalWrapper.listenable(
///   listenable: _isScrollable,
///   wrapper: (child) => SingleChildScrollView(child: child),
///   child: MyContent(),
/// )
/// ```
/// {@endtemplate}
class _ConditionalWrapperListenable extends ConditionalWrapper {
  /// {@macro conditional_wrapper.listenable}
  _ConditionalWrapperListenable({
    super.key,
    required this.listenable,
    required super.wrapper,
    required super.child,
  }) : super(condition: listenable.value);

  final ValueListenable<bool> listenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, value, widget) => switch (value) {
        true => wrapper(widget!),
        false => widget!,
      },
      child: child,
    );
  }
}

/// {@template conditional_wrapper.stream}
/// Creates a [ConditionalWrapper] that listens to a [Stream].
///
/// The widget rebuilds whenever the [stream] emits a new value.
///
/// [initialData] is used as the initial condition and the initial data for the [StreamBuilder].
/// Defaults to `false`.
///
/// ```dart
/// final Stream<bool> _isScrollableStream = Stream.value(true);
///
/// ConditionalWrapper.stream(
///   stream: _isScrollableStream,
///   wrapper: (child) => SingleChildScrollView(child: child),
///   child: MyContent(),
///   initialData: false,
/// )
/// ```
/// {@endtemplate}
class _ConditionalWrapperStream extends ConditionalWrapper {
  /// {@macro conditional_wrapper.stream}
  const _ConditionalWrapperStream({
    super.key,
    required this.stream,
    required super.wrapper,
    required super.child,
    this.initialData = false,
  }) : super(condition: initialData);

  final Stream<bool> stream;
  final bool initialData;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: stream,
      initialData: initialData,
      builder: (context, snapshot) => switch (snapshot.data ?? initialData) {
        true => wrapper(child),
        false => child,
      },
    );
  }
}
