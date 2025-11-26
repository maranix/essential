import 'package:essential_flutter/essential_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScrollableBuilder', () {
    const items = ['Item 1', 'Item 2'];
    const error = 'Something went wrong';

    Widget buildTestWidget(Widget child) {
      return MaterialApp(
        home: Scaffold(
          body: child,
        ),
      );
    }

    testWidgets(
      'shows loadingBuilder when isLoading is true and items are empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ScrollableBuilder<String>(
              items: const [],
              isLoading: true,
              itemBuilder: (context, items) => Container(),
              loadingBuilder: (context) => const Text('Loading...'),
            ),
          ),
        );

        expect(find.text('Loading...'), findsOneWidget);
      },
    );

    testWidgets(
      'shows errorBuilder when isError is true and items are empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ScrollableBuilder<String>(
              items: const [],
              isError: true,
              error: error,
              itemBuilder: (context, items) => Container(),
              errorBuilder: (context, e) => Text('Error: $e'),
            ),
          ),
        );

        expect(find.text('Error: $error'), findsOneWidget);
      },
    );

    testWidgets('shows itemBuilder when items are present and no other state', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          ScrollableBuilder<String>(
            items: items,
            itemBuilder: (context, items) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => Text(items[index]),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets(
      'shows busyItemBuilder when isLoading is true and items are present',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ScrollableBuilder<String>(
              items: items,
              isLoading: true,
              itemBuilder: (context, items) => Container(),
              busyItemBuilder: (context, items) => Column(
                children: [
                  const Text('Busy...'),
                  ...items.map(Text.new),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Busy...'), findsOneWidget);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      },
    );

    testWidgets(
      'shows busyErrorBuilder when isError is true and items are present',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ScrollableBuilder<String>(
              items: items,
              isError: true,
              error: error,
              itemBuilder: (context, items) => Container(),
              busyErrorBuilder: (context, items, e) => Column(
                children: [
                  Text('Error: $e'),
                  ...items.map(Text.new),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Error: $error'), findsOneWidget);
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to SizedBox.shrink when empty loading builder missing',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ScrollableBuilder<String>(
              items: const [],
              isLoading: true,
              itemBuilder: (context, items) => const Text('Data'),
            ),
          ),
        );

        expect(find.text('Data'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );

    testWidgets(
      'falls back to SizedBox.shrink when empty error builder missing',
      (tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            ScrollableBuilder<String>(
              items: const [],
              isError: true,
              error: error,
              itemBuilder: (context, items) => const Text('Data'),
            ),
          ),
        );

        expect(find.text('Data'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );

    testWidgets('falls back to itemBuilder when busy builder missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          ScrollableBuilder<String>(
            items: items,
            isLoading: true,
            itemBuilder: (context, items) => Column(
              children: items.map(Text.new).toList(),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('falls back to itemBuilder when busy error builder missing', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestWidget(
          ScrollableBuilder<String>(
            items: items,
            isError: true,
            error: error,
            itemBuilder: (context, items) => Column(
              children: items.map(Text.new).toList(),
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('handles null items as empty', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          ScrollableBuilder<String>(
            items: null,
            isLoading: true,
            itemBuilder: (context, items) => Container(),
            loadingBuilder: (context) => const Text('Loading...'),
          ),
        ),
      );

      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}
