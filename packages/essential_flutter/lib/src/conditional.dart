import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A type definition for a case in a conditional chain, pairing a boolean condition with a widget.
///
/// Used by [Conditional.chain] to define a specific condition and the widget to render
/// if that condition is met.
///
/// The first element of the tuple is the `condition` (a [bool]), and the named
/// parameter `widget` is the [Widget] to display if the condition is `true`.
typedef ConditionalCase = (
  bool condition, {
  Widget widget,
});

/// A widget that conditionally renders one of two widgets based on a boolean [condition].
///
/// This widget evaluates a boolean condition and displays either the [onTrue] widget
/// if the condition is `true`, or the [onFalse] widget if the condition is `false`.
/// It's a convenient way to encapsulate conditional UI logic within the widget tree.
///
/// For more complex conditional rendering with multiple conditions, consider using
/// the [Conditional.chain] method.
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:essential_flutter/essential_flutter.dart';
///
/// class MyConditionalWidget extends StatelessWidget {
///   final bool isLoggedIn;
///
///   const MyConditionalWidget({super.key, required this.isLoggedIn});
///
///   @override
///   Widget build(BuildContext context) {
///     return Conditional(
///       condition: isLoggedIn,
///       onTrue: const Text('Welcome back!'),
///       onFalse: OutlinedButton(
///         onPressed: () { /* handle login */ },
///         child: const Text('Please Log In'),
///       ),
///     );
///   }
/// }
/// ```
class Conditional extends StatelessWidget {
  const Conditional({
    super.key,
    required this.condition,
    required this.onTrue,
    this.onFalse = const SizedBox.shrink(),
  });

  /// {@macro conditional.listenable}
  const factory Conditional.listenable({
    Key? key,
    required ValueListenable<bool> listenable,
    required Widget onTrue,
    Widget onFalse,
  }) = _ConditionalListenable;

  /// The condition to evaluate.
  final bool condition;

  /// The widget to render if [condition] is `true`.
  final Widget onTrue;

  /// The widget to render if [condition] is `false`.
  /// Defaults to `SizedBox.shrink()`.
  final Widget onFalse;

  /// Creates a widget that renders the first [ConditionalCase] whose condition is true.
  ///
  /// If no condition is true, [fallback] is rendered.
  ///
  /// The [Conditional.chain] method allows you to define a sequence of conditions
  /// and their corresponding widgets. It renders the widget associated with the first
  /// condition that evaluates to `true`.
  ///
  /// If no conditions are met, it renders the optional [fallback] widget, which defaults to `SizedBox.shrink()`.
  ///
  /// This is useful for scenarios where you have multiple mutually exclusive states to display.
  ///
  /// ```dart
  /// import 'package:flutter/material.dart';
  /// import 'package:essential_flutter/essential_flutter.dart';
  ///
  /// enum UserStatus {
  ///   loading,
  ///   loggedIn,
  ///   loggedOut,
  ///   error,
  /// }
  ///
  /// class UserStatusDisplay extends StatelessWidget {
  ///   final UserStatus status;
  ///
  ///   const UserStatusDisplay({super.key, required this.status});
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Conditional.chain(
  ///       [
  ///         (status == UserStatus.loading, widget: const CircularProgressIndicator()),
  ///         (status == UserStatus.loggedIn, widget: const Text('Welcome back!')),
  ///         (status == UserStatus.loggedOut, widget: const Text('Please log in.')),
  ///       ],
  ///       fallback: const Text('An unexpected error occurred.'),
  ///     );
  ///   }
  /// }
  /// ```
  static Widget chain({
    required List<ConditionalCase> cases,
    Widget fallback = const SizedBox.shrink(),
  }) {
    for (final caseItem in cases) {
      if (caseItem.$1) {
        return caseItem.widget;
      }
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    return condition ? onTrue : onFalse;
  }
}

/// {@template conditional.listenable}
/// Creates a [Conditional] widget that listens to a [ValueListenable] (e.g., [ValueNotifier]).
///
/// The widget rebuilds whenever the [listenable] notifies its listeners.
///
/// ```dart
/// final ValueNotifier<bool> _isLoggedIn = ValueNotifier(false);
///
/// Conditional.listenable(
///   listenable: _isLoggedIn,
///   onTrue: const Text('Welcome back!'),
///   onFalse: const Text('Please Log In'),
/// )
/// ```
/// {@endtemplate}
class _ConditionalListenable extends Conditional {
  /// {@macro conditional.listenable}
  const _ConditionalListenable({
    super.key,
    required this.listenable,
    required super.onTrue,
    super.onFalse = const SizedBox.shrink(),
  }) : super(condition: false);

  final ValueListenable<bool> listenable;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: listenable,
      builder: (context, value, _) => switch (value) {
        true => onTrue,
        false => onFalse,
      },
    );
  }
}
