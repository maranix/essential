import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Position of the loader when displaying data with loading state.
///
/// Specifies the position of the loader relative to the scrollable content.
/// [start] indicates the beginning of the scrollable extent, while [end] indicates its conclusion.
/// These positions are determined by the axis of the scrollable widget.
enum LoaderPosition {
  /// Position the loader at the start of the scrollable extent.
  start,

  /// Position the loader at the end of the scrollable extent.
  end,
}

/// Default adaptive loading widget that works on both Material and Cupertino.
class _DefaultLoadingWidget extends StatelessWidget {
  const _DefaultLoadingWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: switch (defaultTargetPlatform) {
        (TargetPlatform.iOS || TargetPlatform.macOS) =>
          const CupertinoActivityIndicator(),
        _ => const CircularProgressIndicator(),
      },
    );
  }
}

/// Default adaptive error widget that works on both Material and Cupertino.
class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Colors.black87;
    final iconColor = isDark ? Colors.red.shade300 : Colors.red.shade700;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              defaultTargetPlatform == TargetPlatform.iOS ||
                      defaultTargetPlatform == TargetPlatform.macOS
                  ? CupertinoIcons.exclamationmark_triangle
                  : Icons.error_outline,
              size: 48,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            Text(
              'An error occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that handles different loading and error states for scrollable widgets.
///
/// This widget simplifies the common pattern of displaying different UI states
/// for scrollable content like ListView, GridView, etc. It handles:
///
/// 1. **Loading with no data**: Shows a loading indicator
/// 2. **Loaded with data**: Shows the scrollable content
/// 3. **Loading with data**: Shows existing data with an optional loader
/// 4. **Error**: Shows an error widget
/// 5. **Error with data**: Shows existing data with an error indicator
///
/// Example:
/// ```dart
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
class ScrollableBuilder<T> extends StatelessWidget {
  /// Creates a [ScrollableBuilder].
  ///
  /// The [dataBuilder] is required and will be called when data is available.
  /// All other builders are optional and will use adaptive default widgets if not provided.
  const ScrollableBuilder({
    required this.data,
    required this.isLoading,
    required this.dataBuilder,
    this.error,
    this.scrollDirection = Axis.vertical,
    this.loadingBuilder,
    this.loadingWithDataBuilder,
    this.errorBuilder,
    this.errorWithDataBuilder,
    this.showLoaderWithData = true,
    this.loaderPosition = LoaderPosition.end,
    this.loaderPadding,
    this.scrollPhysics,
    super.key,
  });

  /// The data to display. Can be null or empty.
  final List<T>? data;

  /// Whether the widget is currently loading.
  final bool isLoading;

  /// The error object if an error occurred. Can be null.
  final Object? error;

  /// The scroll direction of the scrollable content.
  ///
  /// This is used to determine loader positioning when [showLoaderWithData] is true.
  final Axis scrollDirection;

  /// Builder for the main content when data is available.
  ///
  /// This is called when [data] is not null and not empty.
  final Widget Function(BuildContext context, List<T> data) dataBuilder;

  /// Builder for the loading state when no data is available.
  ///
  /// If not provided, uses a default adaptive loading widget.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Builder for the loading state when data is available.
  ///
  /// If not provided and [showLoaderWithData] is true, a default loader
  /// will be positioned based on [loaderPosition] and [scrollDirection].
  ///
  /// If provided, this builder has full control over how to display
  /// the data and loading indicator together.
  final Widget Function(BuildContext context, List<T> data)?
  loadingWithDataBuilder;

  /// Builder for the error state when no data is available.
  ///
  /// If not provided, uses a default adaptive error widget.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builder for the error state when data is available.
  ///
  /// If not provided, displays the data normally (using [dataBuilder]).
  /// You can provide a custom builder to show both data and error indicator.
  final Widget Function(BuildContext context, List<T> data, Object error)?
  errorWithDataBuilder;

  /// Whether to show a loader when loading with existing data.
  ///
  /// Only applies when [loadingWithDataBuilder] is not provided.
  /// Defaults to true.
  final bool showLoaderWithData;

  /// Position of the loader when showing data with loading state.
  ///
  /// Only applies when [showLoaderWithData] is true and
  /// [loadingWithDataBuilder] is not provided.
  ///
  /// Defaults to [LoaderPosition.end] (bottom for vertical, right for horizontal).
  final LoaderPosition loaderPosition;

  /// Padding around the loader when showing data with loading state.
  ///
  /// Only applies when [showLoaderWithData] is true and
  /// [loadingWithDataBuilder] is not provided.
  final EdgeInsets? loaderPadding;

  /// The scroll physics to use for the scrollable content.
  ///
  /// If not provided, uses the default scroll physics for the platform.
  final ScrollPhysics? scrollPhysics;

  bool get _hasData => data != null && data!.isNotEmpty;
  bool get _hasError => error != null;

  @override
  Widget build(BuildContext context) {
    // State 1: Loading with no data
    if (isLoading && !_hasData && !_hasError) {
      return loadingBuilder?.call(context) ?? const _DefaultLoadingWidget();
    }

    // State 2: Error with no data
    if (_hasError && !_hasData) {
      return errorBuilder?.call(context, error!) ??
          _DefaultErrorWidget(error: error!);
    }

    // State 3: Loaded with data (no loading, no error)
    if (_hasData && !isLoading && !_hasError) {
      return dataBuilder(context, data!);
    }

    // State 4: Loading with data
    if (isLoading && _hasData) {
      // Use custom builder if provided
      if (loadingWithDataBuilder != null) {
        return loadingWithDataBuilder!(context, data!);
      }

      // Otherwise, show data with optional loader
      final content = dataBuilder(context, data!);

      if (!showLoaderWithData) {
        return content;
      }

      return _buildDataWithLoader(context, content);
    }

    // State 5: Error with data
    if (_hasError && _hasData) {
      // Use custom builder if provided
      if (errorWithDataBuilder != null) {
        return errorWithDataBuilder!(context, data!, error!);
      }

      // Otherwise, just show the data
      return dataBuilder(context, data!);
    }

    // Fallback: no data, no loading, no error
    return const SizedBox.shrink();
  }

  Widget _buildDataWithLoader(BuildContext context, Widget content) {
    final loader = Padding(
      padding:
          loaderPadding ??
          (scrollDirection == Axis.vertical
              ? const EdgeInsets.all(16)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child:
              defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS
              ? const CupertinoActivityIndicator()
              : const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );

    if (scrollDirection == Axis.vertical) {
      return Column(
        children: [
          if (loaderPosition == LoaderPosition.start) loader,
          Expanded(child: content),
          if (loaderPosition == LoaderPosition.end) loader,
        ],
      );
    } else {
      return Row(
        children: [
          if (loaderPosition == LoaderPosition.start) loader,
          Expanded(child: content),
          if (loaderPosition == LoaderPosition.end) loader,
        ],
      );
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('data', data))
      ..add(DiagnosticsProperty<bool>('isLoading', isLoading))
      ..add(DiagnosticsProperty<Object?>('error', error))
      ..add(EnumProperty<Axis>('scrollDirection', scrollDirection))
      ..add(
        DiagnosticsProperty<bool>('showLoaderWithData', showLoaderWithData),
      )
      ..add(
        EnumProperty<LoaderPosition>('loaderPosition', loaderPosition),
      )
      ..add(
        DiagnosticsProperty<EdgeInsets?>('loaderPadding', loaderPadding),
      )
      ..add(
        DiagnosticsProperty<ScrollPhysics?>('scrollPhysics', scrollPhysics),
      );
  }
}
