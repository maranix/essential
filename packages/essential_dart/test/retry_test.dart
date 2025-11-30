import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart' hide Retry;

void main() {
  group('RetryStrategy', () {
    test('ConstantBackoffStrategy returns constant delays', () {
      const strategy = ConstantBackoffStrategy(duration: Duration(seconds: 2));
      final iterator = strategy.delays.iterator;

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 2));

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 2));

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 2));
    });

    test('LinearBackoffStrategy returns linearly increasing delays', () {
      const strategy = LinearBackoffStrategy(
        increment: Duration(seconds: 2),
      );
      final iterator = strategy.delays.iterator;

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 1)); // 1 + 2 * 0

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 3)); // 1 + 2 * 1

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 5)); // 1 + 2 * 2
    });

    test(
      'ExponentialBackoffStrategy returns exponentially increasing delays',
      () {
        const strategy = ExponentialBackoffStrategy();
        final iterator = strategy.delays.iterator;

        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, const Duration(seconds: 1)); // 1 * 2^0

        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, const Duration(seconds: 2)); // 1 * 2^1

        expect(iterator.moveNext(), isTrue);
        expect(iterator.current, const Duration(seconds: 4)); // 1 * 2^2
      },
    );

    test('ExponentialBackoffStrategy respects maxDelay', () {
      const strategy = ExponentialBackoffStrategy(
        maxDelay: Duration(seconds: 3),
      );
      final iterator = strategy.delays.iterator;

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 1));

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 2));

      expect(iterator.moveNext(), isTrue);
      expect(iterator.current, const Duration(seconds: 3)); // capped at 3
    });
  });

  group('Retry', () {
    test('succeeds on first attempt', () async {
      var attempts = 0;
      final retry = Retry();
      final result = await retry(() async {
        attempts++;
        return 'success';
      });
      expect(result, 'success');
      expect(attempts, 1);
    });

    test('retries and succeeds', () async {
      var attempts = 0;
      final retry = Retry(
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );
      final result = await retry(
        () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('fail');
          }
          return 'success';
        },
      );
      expect(result, 'success');
      expect(attempts, 3);
    });

    test('throws RetryException after max attempts', () async {
      var attempts = 0;
      final retry = Retry(
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );
      expect(
        () => retry<void>(
          () {
            attempts++;
            throw Exception('fail');
          },
        ),
        throwsA(isA<RetryException>()),
      );
      // Wait a bit to ensure all retries would have happened
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(attempts, 3);
    });

    test('respects onRetry callback', () async {
      var attempts = 0;
      var retryCallbacks = 0;
      final retry = Retry(
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );
      final result = await retry(
        () async {
          attempts++;
          if (attempts < 2) {
            throw Exception('fail');
          }
          return 'success';
        },
        onRetry: (e, attempt) {
          retryCallbacks++;
          return true;
        },
      );
      expect(result, 'success');
      expect(attempts, 2);
      expect(retryCallbacks, 1);
    });

    test('aborts retry if onRetry returns false', () async {
      var attempts = 0;
      final retry = Retry(
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );
      expect(
        () => retry<void>(
          () {
            attempts++;
            throw Exception('fail');
          },
          onRetry: (attempt, e) {
            return false;
          },
        ),
        throwsA(isA<RetryException>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(attempts, 1);
    });

    test('static run method works', () async {
      var attempts = 0;
      final result = await Retry.run(() async {
        attempts++;
        if (attempts < 2) {
          throw Exception('fail');
        }
        return 'success';
      });
      expect(result, 'success');
      expect(attempts, 2);
    });

    test('static withExponentialBackoff works', () async {
      var attempts = 0;
      await Retry.withExponentialBackoff(
        () async {
          attempts++;
          if (attempts < 3) {
            throw Exception('fail');
          }
        },
        initialDuration: const Duration(milliseconds: 10),
        maxAttempts: 5,
      );
      expect(attempts, 3);
    });

    test('instance can be reused across multiple operations', () async {
      final retry = Retry(
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );

      // First operation
      var attempts1 = 0;
      await retry(() async {
        attempts1++;
        if (attempts1 < 2) {
          throw Exception('fail');
        }
        return 'result1';
      });
      expect(attempts1, 2);

      // Second operation with same retry instance
      var attempts2 = 0;
      await retry(() async {
        attempts2++;
        if (attempts2 < 3) {
          throw Exception('fail');
        }
        return 'result2';
      });
      expect(attempts2, 3);
    });

    test(
      'throws RetryConcurrentUseException when called concurrently',
      () async {
        final retry = Retry(
          strategy: const ConstantBackoffStrategy(
            duration: Duration(milliseconds: 100),
          ),
        );

        // Start first operation (will take time due to retries)
        final future1 = retry<void>(() {
          throw Exception('fail');
        });

        // Try to start second operation while first is in progress
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(
          () => retry(() async => 'result'),
          throwsA(isA<RetryConcurrentUseException>()),
        );

        // Wait for first operation to complete
        try {
          await future1;
        } on Exception catch (_) {
          // Expected to fail
        }
      },
    );

    test('tracks attempts correctly', () async {
      final retry = Retry(
        maxAttempts: 5,
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );

      var callCount = 0;
      try {
        await retry(() async {
          callCount++;
          if (callCount < 3) {
            throw Exception('fail');
          }
          return 'success';
        });
      } on Exception catch (_) {
        // ignore
      }

      expect(retry.attempts, 3);
      expect(retry.isRetrying, false);
    });

    test('RetryException contains correct information', () async {
      final retry = Retry(
        maxAttempts: 2,
        strategy: const ConstantBackoffStrategy(
          duration: Duration(milliseconds: 10),
        ),
      );

      try {
        await retry<void>(() {
          throw Exception('test error');
        });
      } on RetryException catch (e) {
        expect(e.attempts, 2);
        expect(e.lastError.toString(), contains('test error'));
        expect(e.stackTrace, isNotNull);
      }
    });
  });
}
