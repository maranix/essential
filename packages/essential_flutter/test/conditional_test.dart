import 'package:essential_flutter/essential_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Conditional', () {
    testWidgets('renders onTrue when condition is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Conditional(
            condition: true,
            onTrue: Text('True'),
            onFalse: Text('False'),
          ),
        ),
      );

      expect(find.text('True'), findsOneWidget);
      expect(find.text('False'), findsNothing);
    });

    testWidgets('renders onFalse when condition is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Conditional(
            condition: false,
            onTrue: Text('True'),
            onFalse: Text('False'),
          ),
        ),
      );

      expect(find.text('False'), findsOneWidget);
      expect(find.text('True'), findsNothing);
    });

    testWidgets(
      'renders SizedBox.shrink when onFalse is omitted and condition is false',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Conditional(
              condition: false,
              onTrue: Text('True'),
            ),
          ),
        );

        expect(find.text('True'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );
  });

  group('Conditional.chain', () {
    testWidgets('renders first true case', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Conditional.chain(
            cases: [
              (false, widget: const Text('Case 1')),
              (true, widget: const Text('Case 2')),
              (true, widget: const Text('Case 3')),
            ],
          ),
        ),
      );

      expect(find.text('Case 2'), findsOneWidget);
      expect(find.text('Case 1'), findsNothing);
      expect(find.text('Case 3'), findsNothing);
    });

    testWidgets('renders fallback if no case is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Conditional.chain(
            cases: [
              (false, widget: const Text('Case 1')),
              (false, widget: const Text('Case 2')),
            ],
            fallback: const Text('Fallback'),
          ),
        ),
      );

      expect(find.text('Fallback'), findsOneWidget);
      expect(find.text('Case 1'), findsNothing);
      expect(find.text('Case 2'), findsNothing);
    });

    testWidgets(
      'renders default fallback if no case is true and fallback is omitted',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Conditional.chain(
              cases: [
                (false, widget: const Text('Case 1')),
              ],
            ),
          ),
        );

        expect(find.text('Case 1'), findsNothing);
        expect(find.byType(SizedBox), findsOneWidget);
      },
    );
  });

  testWidgets('renders fallback if cases list is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Conditional.chain(
          cases: [],
          fallback: const Text('Empty Cases Fallback'),
        ),
      ),
    );

    expect(find.text('Empty Cases Fallback'), findsOneWidget);
  });

  testWidgets(
    'renders default fallback if cases list is empty and fallback is omitted',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Conditional.chain(
            cases: [],
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
    },
  );

  group('Conditional.listenable', () {
    testWidgets('updates when ValueListenable changes', (tester) async {
      final notifier = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        MaterialApp(
          home: Conditional.listenable(
            listenable: notifier,
            onTrue: const Text('True'),
            onFalse: const Text('False'),
          ),
        ),
      );

      expect(find.text('True'), findsOneWidget);
      expect(find.text('False'), findsNothing);

      notifier.value = false;
      await tester.pump();

      expect(find.text('False'), findsOneWidget);
      expect(find.text('True'), findsNothing);
    });

    testWidgets('renders initial false state correctly', (tester) async {
      final notifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Conditional.listenable(
            listenable: notifier,
            onTrue: const Text('True'),
            onFalse: const Text('False'),
          ),
        ),
      );

      expect(find.text('False'), findsOneWidget);
      expect(find.text('True'), findsNothing);
    });
  });
}
