import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Memoizer', () {
    group('Lazy execution', () {
      test('does not run computation on creation', () {
        var runCount = 0;
        Memoizer<int>(
          computation: () {
            runCount++;
            return 42;
          },
        );
        expect(runCount, 0);
      });

      test('runs computation when run() is called', () async {
        var runCount = 0;
        final memoizer = Memoizer<int>(
          computation: () {
            runCount++;
            return 42;
          },
        );
        expect(await memoizer.run(), 42);
        expect(runCount, 1);
      });

      test('runs computation when result is accessed', () async {
        var runCount = 0;
        final memoizer = Memoizer<int>(
          computation: () {
            runCount++;
            return 42;
          },
        );
        expect(await memoizer.result, 42);
        expect(runCount, 1);
      });
    });

    group('Non-lazy execution', () {
      test('runs computation immediately on creation', () async {
        var runCount = 0;
        final memoizer = Memoizer<int>(
          lazy: false,
          computation: () {
            runCount++;
            return 42;
          },
        );
        expect(memoizer.hasRun, isTrue);
        expect(await memoizer.result, 42);
        expect(runCount, 1);
      });

      test('throws MemoizerConfigurationException if computation is null', () {
        expect(
          () => Memoizer<int>(lazy: false),
          throwsA(isA<MemoizerConfigurationException>()),
        );
      });
    });

    group('Caching', () {
      test('runs computation only once', () async {
        var runCount = 0;
        final memoizer = Memoizer<int>(
          computation: () {
            runCount++;
            return 42;
          },
        );

        expect(await memoizer.run(), 42);
        expect(await memoizer.run(), 42);
        expect(await memoizer.result, 42);
        expect(runCount, 1);
      });

      test('caches exception', () async {
        var runCount = 0;
        final memoizer = Memoizer<int>(
          computation: () {
            runCount++;
            throw Exception('Failure');
          },
        );

        await expectLater(memoizer.run(), throwsException);
        await expectLater(memoizer.run(), throwsException);
        expect(runCount, 1);
      });
    });

    group('runComputation', () {
      test('executes provided computation', () async {
        final memoizer = Memoizer<int>();
        expect(await memoizer.runComputation(() => 42), 42);
      });

      test('ignores subsequent computations', () async {
        final memoizer = Memoizer<int>();
        expect(await memoizer.runComputation(() => 42), 42);
        expect(await memoizer.runComputation(() => 100), 42);
      });
    });

    group('Reset', () {
      test('resets and runs new computation', () async {
        var runCount = 0;
        final memoizer = Memoizer<int>(
          computation: () {
            runCount++;
            return 42;
          },
        );

        expect(await memoizer.run(), 42);
        expect(runCount, 1);

        expect(
          await memoizer.reset(() {
            runCount++;
            return 100;
          }),
          100,
        );
        expect(runCount, 2);
        expect(await memoizer.result, 100);
      });
    });

    group('Exceptions', () {
      test(
        'run() throws MemoizerConfigurationException if no default computation',
        () {
          final memoizer = Memoizer<int>();
          expect(
            memoizer.run,
            throwsA(isA<MemoizerConfigurationException>()),
          );
        },
      );
    });
  });
}
