import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Builder for the main content when data is available.
typedef ScrollableWidgetBuilder<T> =
    Widget Function(
      BuildContext context,
      List<T> items,
    );

/// Builder for the error state when no data is available.
typedef ScrollableErrorBuilder =
    Widget Function(
      BuildContext context,
      Object? error,
    );

/// Builder for the error state when data is available.
typedef ScrollableBusyErrorBuilder<T> =
    Widget Function(
      BuildContext context,
      List<T> items,
      Object? error,
    );

/// A widget that handles different loading and error states for scrollable widgets.
///
/// This widget simplifies the common pattern of displaying different UI states
/// for scrollable content like ListView, GridView, etc.
///
/// It handles 5 distinct states:
/// 1. **Empty Loading**: [isLoading] is true and [items] is empty.
/// 2. **Empty Error**: [isError] is true and [items] is empty.
/// 3. **Busy**: [isLoading] is true and [items] is not empty.
/// 4. **Busy Error**: [isError] is true and [items] is not empty.
/// 5. **Data**: [items] is not empty and neither loading nor error.
///
/// If a builder is not provided for a specific state, it falls back to a sensible default:
/// - Empty states default to [SizedBox.shrink()].
/// - Busy states default to showing the data using [itemBuilder].
class ScrollableBuilder<T> extends StatelessWidget {
  /// Creates a [ScrollableBuilder].
  const ScrollableBuilder({
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.isError = false,
    this.error,
    this.loadingBuilder,
    this.errorBuilder,
    this.busyItemBuilder,
    this.busyErrorBuilder,
    super.key,
  });

  /// Whether the widget is currently loading.
  final bool isLoading;

  /// Whether the widget is currently in an error state.
  final bool isError;

  /// The list of items to display.
  final List<T>? items;

  /// The error object, if any.
  final Object? error;

  /// Builder for the main content when data is available.
  final ScrollableWidgetBuilder<T> itemBuilder;

  /// Builder for the loading state when [items] is empty.
  final WidgetBuilder? loadingBuilder;

  /// Builder for the error state when [items] is empty.
  final ScrollableErrorBuilder? errorBuilder;

  /// Builder for the loading state when [items] is not empty.
  final ScrollableWidgetBuilder<T>? busyItemBuilder;

  /// Builder for the error state when [items] is not empty.
  final ScrollableBusyErrorBuilder<T>? busyErrorBuilder;

  bool get _hasItems => items != null && items!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return switch ((isLoading, isError, _hasItems)) {
      // 1. Empty Loading
      (true, _, false) =>
        loadingBuilder?.call(context) ?? const SizedBox.shrink(),

      // 2. Empty Error
      (_, true, false) =>
        error != null
            ? (errorBuilder?.call(context, error) ?? const SizedBox.shrink())
            : const SizedBox.shrink(),

      // 3. Busy (Loading with data)
      (true, _, true) =>
        busyItemBuilder?.call(context, items!) ?? itemBuilder(context, items!),

      // 4. Busy Error (Error with data)
      (_, true, true) =>
        error != null
            ? (busyErrorBuilder?.call(context, items!, error) ??
                  itemBuilder(context, items!))
            : itemBuilder(context, items!),

      // 5. Data (or empty with no state)
      (false, false, _) =>
        _hasItems ? itemBuilder(context, items!) : const SizedBox.shrink(),
    };
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('items', items))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DiagnosticsProperty<bool>('isError', isError))
      ..add(DiagnosticsProperty<Object?>('error', error));
  }
}
