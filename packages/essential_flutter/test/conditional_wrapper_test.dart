import 'package:essential_flutter/essential_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConditionalWrapper', () {
    testWidgets('wraps child when condition is true', (tester) async {
      const testKey = Key('test-child');
      const wrapperKey = Key('wrapper');

      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: true,
            wrapper: (child) => ColoredBox(
              key: wrapperKey,
              color: Colors.red,
              child: child,
            ),
            child: const Text('Hello', key: testKey),
          ),
        ),
      );

      // Verify wrapper exists
      expect(find.byKey(wrapperKey), findsOneWidget);
      // Verify child exists
      expect(find.byKey(testKey), findsOneWidget);
      // Verify child is inside wrapper
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('does not wrap child when condition is false', (tester) async {
      const testKey = Key('test-child');
      const wrapperKey = Key('wrapper');

      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: false,
            wrapper: (child) => ColoredBox(
              key: wrapperKey,
              color: Colors.red,
              child: child,
            ),
            child: const Text('Hello', key: testKey),
          ),
        ),
      );

      // Verify wrapper does not exist
      expect(find.byKey(wrapperKey), findsNothing);
      // Verify child exists
      expect(find.byKey(testKey), findsOneWidget);
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('works with Padding wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: true,
            wrapper: (child) => Padding(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
            child: const Text('Padded'),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('works with SingleChildScrollView wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: true,
            wrapper: (child) => SingleChildScrollView(child: child),
            child: const Text('Scrollable'),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Scrollable'), findsOneWidget);
    });

    testWidgets('child renders correctly in both conditions', (tester) async {
      // Test with condition true
      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: true,
            wrapper: (child) => Container(child: child),
            child: const Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);

      // Test with condition false
      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: false,
            wrapper: (child) => Container(child: child),
            child: const Text('Test'),
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('works with nested ConditionalWrappers', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConditionalWrapper(
            condition: true,
            wrapper: (child) => Padding(
              padding: const EdgeInsets.all(8),
              child: child,
            ),
            child: ConditionalWrapper(
              condition: true,
              wrapper: (child) => ColoredBox(
                color: Colors.blue,
                child: child,
              ),
              child: const Text('Nested'),
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsOneWidget);
      expect(find.byType(ColoredBox), findsWidgets);
      expect(find.text('Nested'), findsOneWidget);
    });
  });
}
