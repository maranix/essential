import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Task Caching', () {
    group('CachingStrategy.none', () {
      test('should execute computation every time', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.none,
        );

        final result1 = await task.execute(() async {
          executionCount++;
          return 42;
        });

        final result2 = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result1, 42);
        expect(result2, 100);
        expect(executionCount, 2);
      });

      test('should not cache across state transitions', () async {
        var executionCount = 0;
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.none,
        );

        await task.execute(() async {
          executionCount++;
          return 1;
        });

        task = task.toRunning();
        await task.execute(() async {
          executionCount++;
          return 2;
        });

        expect(executionCount, 2);
      });

      test('invalidateCache should do nothing', () {
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.none,
        );

        expect(task.invalidateCache, returnsNormally);
      });

      test('refresh should execute computation', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.none,
        );

        final result = await task.refresh(() async {
          executionCount++;
          return 42;
        });

        expect(result, 42);
        expect(executionCount, 1);
      });
    });

    group('CachingStrategy.memoize', () {
      test('should cache result indefinitely', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await task.execute(() async {
          executionCount++;
          return 42;
        });

        final result2 = await task.execute(() async {
          executionCount++;
          return 100;
        });

        final result3 = await task.execute(() async {
          executionCount++;
          return 200;
        });

        expect(result1, 42);
        expect(result2, 42); // Cached
        expect(result3, 42); // Cached
        expect(executionCount, 1);
      });

      test('should preserve cache across state transitions', () async {
        var executionCount = 0;
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toRunning();
        final result2 = await task.execute(() async {
          executionCount++;
          return 100;
        });

        task = task.toSuccess(42);
        final result3 = await task.execute(() async {
          executionCount++;
          return 200;
        });

        expect(result1, 42);
        expect(result2, 42); // Cached from pending state
        expect(result3, 42); // Still cached
        expect(executionCount, 1);
      });

      test('refresh should invalidate and re-execute', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await task.execute(() async {
          executionCount++;
          return 42;
        });

        final result2 = await task.refresh(() async {
          executionCount++;
          return 100;
        });

        final result3 = await task.execute(() async {
          executionCount++;
          return 200;
        });

        expect(result1, 42);
        expect(result2, 100); // Refreshed
        expect(result3, 100); // Cached new value
        expect(executionCount, 2);
      });

      test('should handle errors in cached computation', () {
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        expect(
          () => task.execute(() async => throw Exception('Error')),
          throwsA(isA<Exception>()),
        );

        // Second call should also throw (error is cached)
        expect(
          () => task.execute(() async => 42),
          throwsA(isA<Exception>()),
        );
      });

      test('should work with different data types', () async {
        final stringTask = Task<String>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await stringTask.execute(() async => 'Hello');
        final result2 = await stringTask.execute(() async => 'World');

        expect(result1, 'Hello');
        expect(result2, 'Hello'); // Cached
      });

      test('should handle null values', () async {
        final task = Task<int?>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await task.execute(() async => null);
        final result2 = await task.execute(() async => 42);

        expect(result1, null);
        expect(result2, null); // Cached null
      });
    });

    group('CachingStrategy.temporal', () {
      test('should cache for specified duration', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(milliseconds: 100),
        );

        final result1 = await task.execute(() async {
          executionCount++;
          return 42;
        });

        // Within cache duration
        final result2 = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result1, 42);
        expect(result2, 42); // Cached
        expect(executionCount, 1);

        // Wait for cache to expire
        await Future<void>.delayed(const Duration(milliseconds: 150));

        final result3 = await task.execute(() async {
          executionCount++;
          return 200;
        });

        expect(result3, 200); // Re-executed after expiration
        expect(executionCount, 2);
      });

      test('should use default cache duration when not specified', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
        );

        final result = await task.execute(() async {
          executionCount++;
          return 42;
        });

        expect(result, 42);
        expect(executionCount, 1);
        expect(task.cacheDuration, const Duration(minutes: 5));
      });

      test('invalidateCache should clear cache', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(hours: 1),
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task.invalidateCache();

        final result = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result, 100); // Re-executed after invalidation
        expect(executionCount, 2);
      });

      test('refresh should invalidate and re-execute', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(hours: 1),
        );

        final result1 = await task.execute(() async {
          executionCount++;
          return 42;
        });

        final result2 = await task.refresh(() async {
          executionCount++;
          return 100;
        });

        expect(result1, 42);
        expect(result2, 100); // Refreshed
        expect(executionCount, 2);
      });

      test('should preserve cache across state transitions', () async {
        var executionCount = 0;
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(seconds: 10),
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toRunning();
        final result = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result, 42); // Cached from pending state
        expect(executionCount, 1);
      });

      test('should handle very short cache durations', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(milliseconds: 1),
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        await Future<void>.delayed(const Duration(milliseconds: 5));

        await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(executionCount, 2); // Re-executed after expiration
      });
    });

    group('State Transitions with Caching', () {
      test('toPending preserves cache', () async {
        var executionCount = 0;
        var task = Task<int>.running(
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toPending();
        final result = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result, 42); // Cache preserved
        expect(executionCount, 1);
      });

      test('toRunning preserves cache', () async {
        var executionCount = 0;
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toRunning();
        final result = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result, 42);
        expect(executionCount, 1);
      });

      test('toSuccess preserves cache', () async {
        var executionCount = 0;
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toSuccess(100);
        final result = await task.execute(() async {
          executionCount++;
          return 200;
        });

        expect(result, 42); // Cache preserved
        expect(executionCount, 1);
      });

      test('toFailure preserves cache', () async {
        var executionCount = 0;
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toFailure(Exception('Error'));
        final result = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result, 42);
        expect(executionCount, 1);
      });

      test('toRefreshing preserves cache', () async {
        var executionCount = 0;
        var task = Task<int>.success(
          data: 100,
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toRefreshing();
        final result = await task.execute(() async {
          executionCount++;
          return 200;
        });

        expect(result, 42);
        expect(executionCount, 1);
      });

      test('toRetrying preserves cache', () async {
        var executionCount = 0;
        var task = Task<int>.failure(
          error: 'Error',
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async {
          executionCount++;
          return 42;
        });

        task = task.toRetrying();
        final result = await task.execute(() async {
          executionCount++;
          return 100;
        });

        expect(result, 42);
        expect(executionCount, 1);
      });
    });

    group('Edge Cases', () {
      test('should handle concurrent executions with memoize', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final futures = List.generate(
          10,
          (_) => task.execute(() async {
            executionCount++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 42;
          }),
        );

        final results = await Future.wait(futures);

        expect(results.every((r) => r == 42), true);
        expect(
          executionCount,
          1,
        ); // Only executed once despite concurrent calls
      });

      test('should handle concurrent executions with temporal', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(seconds: 1),
        );

        final futures = List.generate(
          5,
          (_) => task.execute(() async {
            executionCount++;
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 42;
          }),
        );

        final results = await Future.wait(futures);

        expect(results.every((r) => r == 42), true);
        expect(executionCount, 1); // Only executed once
      });

      test('should handle empty/zero duration', () async {
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: Duration.zero,
        );

        var executionCount = 0;
        await task.execute(() async {
          executionCount++;
          return 42;
        });

        // Wait for the event loop to finish
        await Future<void>.delayed(Duration.zero);

        await task.execute(() async {
          executionCount++;
          return 100;
        });

        // With zero duration, cache expires immediately
        expect(executionCount, 2);
      });

      test('should work with complex data types', () async {
        final task = Task<Map<String, dynamic>>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await task.execute(() async => {'key': 'value'});
        final result2 = await task.execute(() async => {'other': 'data'});

        expect(result1, {'key': 'value'});
        expect(result2, {'key': 'value'}); // Cached
      });

      test('should handle tasks created with different constructors', () async {
        final tasks = [
          Task<int>.pending(cachingStrategy: CachingStrategy.memoize),
          Task<int>.running(cachingStrategy: CachingStrategy.memoize),
          Task<int>.success(
            data: 1,
            cachingStrategy: CachingStrategy.memoize,
          ),
          Task<int>.failure(
            error: 'err',
            cachingStrategy: CachingStrategy.memoize,
          ),
        ];

        for (final task in tasks) {
          var count = 0;
          await task.execute(() async {
            count++;
            return 42;
          });
          final result = await task.execute(() async {
            count++;
            return 100;
          });
          expect(result, 42);
          expect(count, 1);
        }
      });

      test('should handle rapid refresh calls', () async {
        var executionCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final futures = List.generate(
          5,
          (i) => task.refresh(() async {
            executionCount++;
            return i;
          }),
        );

        await Future.wait(futures);

        // Each refresh should execute
        expect(executionCount, 5);
      });

      test('should maintain separate caches for different tasks', () async {
        final task1 = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );
        final task2 = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        final result1 = await task1.execute(() async => 42);
        final result2 = await task2.execute(() async => 100);

        expect(result1, 42);
        expect(result2, 100); // Different cache
      });

      test('should handle label and tags with caching', () async {
        var task = Task<int>.pending(
          label: 'test-task',
          tags: {'important', 'cached'},
          cachingStrategy: CachingStrategy.memoize,
        );

        await task.execute(() async => 42);

        task = task.toRunning();

        expect(task.label, 'test-task');
        expect(task.tags, {'important', 'cached'});
        expect(task.cachingStrategy, CachingStrategy.memoize);
      });
    });

    group('Real-world Scenarios', () {
      test('API call with memoization', () async {
        var apiCallCount = 0;
        final task = Task<Map<String, dynamic>>.pending(
          cachingStrategy: CachingStrategy.memoize,
          label: 'fetch-user',
        );

        Future<Map<String, dynamic>> fetchUser() async {
          apiCallCount++;
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return {'id': 1, 'name': 'John'};
        }

        // Multiple calls should only hit API once
        final user1 = await task.execute(fetchUser);
        final user2 = await task.execute(fetchUser);
        final user3 = await task.execute(fetchUser);

        expect(user1, {'id': 1, 'name': 'John'});
        expect(user2, user1);
        expect(user3, user1);
        expect(apiCallCount, 1);
      });

      test('Expensive computation with temporal caching', () async {
        var computationCount = 0;
        final task = Task<int>.pending(
          cachingStrategy: CachingStrategy.temporal,
          cacheDuration: const Duration(milliseconds: 200),
        );

        Future<int> expensiveComputation() async {
          computationCount++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return 42;
        }

        // First call
        await task.execute(expensiveComputation);
        expect(computationCount, 1);

        // Within cache duration
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await task.execute(expensiveComputation);
        expect(computationCount, 1); // Still cached

        // After cache expiration
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await task.execute(expensiveComputation);
        expect(computationCount, 2); // Re-executed
      });

      test('User-triggered refresh', () async {
        var fetchCount = 0;
        final task = Task<String>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        Future<String> fetchData() async {
          fetchCount++;
          return 'Data $fetchCount';
        }

        // Initial load
        final data1 = await task.execute(fetchData);
        expect(data1, 'Data 1');

        // User clicks refresh button
        final data2 = await task.refresh(fetchData);
        expect(data2, 'Data 2');

        // Subsequent calls use new cached value
        final data3 = await task.execute(fetchData);
        expect(data3, 'Data 2');
      });

      test('Task lifecycle with caching', () async {
        var task = Task<int>.pending(
          cachingStrategy: CachingStrategy.memoize,
        );

        // Start execution
        task = task.toRunning();
        final result = await task.execute(() async => 42);

        // Complete successfully
        task = task.toSuccess(result);
        expect(task.success.data, 42);

        // Refresh data
        task = task.toRefreshing();
        final newResult = await task.refresh(() async => 100);

        task = task.toSuccess(newResult);
        expect(task.success.data, 100);

        // Cache should have new value
        final cachedResult = await task.execute(() async => 200);
        expect(cachedResult, 100); // Cached from refresh
      });
    });
  });
}
