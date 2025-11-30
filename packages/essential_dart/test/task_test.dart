import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Task', () {
    group('Factory Constructors', () {
      group('TaskPending', () {
        test('creates pending task with no parameters', () {
          final task = Task<int>.pending();
          expect(task.isPending, isTrue);
          expect(task.initialData, isNull);
          expect(task.label, isNull);
          expect(task.tags, isEmpty);
        });

        test('creates pending task with initialData', () {
          final task = Task<int>.pending(initialData: 42);
          expect(task.isPending, isTrue);
          expect(task.initialData, equals(42));
        });

        test('creates pending task with label and tags', () {
          final task = Task<String>.pending(
            label: 'test-task',
            tags: {'tag1', 'tag2'},
          );
          expect(task.label, equals('test-task'));
          expect(task.tags, equals({'tag1', 'tag2'}));
        });

        test('creates pending task with all parameters', () {
          final task = Task<int>.pending(
            initialData: 100,
            label: 'complete-task',
            tags: {'important', 'urgent'},
          );
          expect(task.isPending, isTrue);
          expect(task.initialData, equals(100));
          expect(task.label, equals('complete-task'));
          expect(task.tags, equals({'important', 'urgent'}));
        });
      });

      group('TaskRunning', () {
        test('creates running task with no parameters', () {
          final task = Task<int>.running();
          expect(task.isRunning, isTrue);
          expect(task.initialData, isNull);
          expect((task as TaskRunning<int>).previousData, isNull);
          expect(task.label, isNull);
          expect(task.tags, isEmpty);
        });

        test('creates running task with previousData', () {
          final task = Task<int>.running(previousData: 42);
          expect(task.isRunning, isTrue);
          expect((task as TaskRunning<int>).previousData, equals(42));
        });

        test('creates running task with initialData', () {
          final task = Task<int>.running(initialData: 10);
          expect(task.initialData, equals(10));
        });

        test('creates running task with all parameters', () {
          final task = Task<String>.running(
            initialData: 'initial',
            previousData: 'previous',
            label: 'running-task',
            tags: {'active'},
          );
          expect(task.isRunning, isTrue);
          expect(task.initialData, equals('initial'));
          expect(
            (task as TaskRunning<String>).previousData,
            equals('previous'),
          );
          expect(task.label, equals('running-task'));
          expect(task.tags, equals({'active'}));
        });
      });

      group('TaskRefreshing', () {
        test('creates refreshing task with required previousData', () {
          final task = Task<int>.refreshing(previousData: 42);
          expect(task.isRefreshing, isTrue);
          expect((task as TaskRefreshing<int>).previousData, equals(42));
        });

        test('creates refreshing task with all parameters', () {
          final task = Task<String>.refreshing(
            previousData: 'old-data',
            initialData: 'initial',
            label: 'refresh-task',
            tags: {'refreshing'},
          );
          expect(task.isRefreshing, isTrue);
          expect(
            (task as TaskRefreshing<String>).previousData,
            equals('old-data'),
          );
          expect(task.initialData, equals('initial'));
          expect(task.label, equals('refresh-task'));
          expect(task.tags, equals({'refreshing'}));
        });
      });

      group('TaskRetrying', () {
        test('creates retrying task with required previousData', () {
          final task = Task<int>.retrying(previousData: 42);
          expect(task.isRetrying, isTrue);
          expect((task as TaskRetrying<int>).previousData, equals(42));
        });

        test('creates retrying task with all parameters', () {
          final task = Task<double>.retrying(
            previousData: 3.14,
            initialData: 2.71,
            label: 'retry-task',
            tags: {'retry', 'attempt-2'},
          );
          expect(task.isRetrying, isTrue);
          expect((task as TaskRetrying<double>).previousData, equals(3.14));
          expect(task.initialData, equals(2.71));
          expect(task.label, equals('retry-task'));
          expect(task.tags, equals({'retry', 'attempt-2'}));
        });
      });

      group('TaskSuccess', () {
        test('creates success task with required data', () {
          final task = Task<int>.success(data: 42);
          expect(task.isSuccess, isTrue);
          expect((task as TaskSuccess<int>).data, equals(42));
        });

        test('creates success task with all parameters', () {
          final task = Task<String>.success(
            data: 'result',
            initialData: 'initial',
            label: 'success-task',
            tags: {'completed', 'verified'},
          );
          expect(task.isSuccess, isTrue);
          expect((task as TaskSuccess<String>).data, equals('result'));
          expect(task.initialData, equals('initial'));
          expect(task.label, equals('success-task'));
          expect(task.tags, equals({'completed', 'verified'}));
        });
      });

      group('TaskFailure', () {
        test('creates failure task with required error', () {
          final error = Exception('Test error');
          final task = Task<int>.failure(error: error);
          expect(task.isFailure, isTrue);
          expect((task as TaskFailure<int>).error, equals(error));
          expect(task.stackTrace, isNull);
          expect(task.previousData, isNull);
        });

        test('creates failure task with stackTrace', () {
          final error = Exception('Test error');
          final stackTrace = StackTrace.current;
          final task = Task<int>.failure(
            error: error,
            stackTrace: stackTrace,
          );
          expect((task as TaskFailure<int>).stackTrace, equals(stackTrace));
        });

        test('creates failure task with all parameters', () {
          final error = Exception('Critical error');
          final stackTrace = StackTrace.current;
          final task = Task<String>.failure(
            error: error,
            stackTrace: stackTrace,
            previousData: 'old-data',
            initialData: 'initial',
            label: 'failed-task',
            tags: {'error', 'critical'},
          );
          expect(task.isFailure, isTrue);
          final failure = task as TaskFailure<String>;
          expect(failure.error, equals(error));
          expect(failure.stackTrace, equals(stackTrace));
          expect(failure.previousData, equals('old-data'));
          expect(task.initialData, equals('initial'));
          expect(task.label, equals('failed-task'));
          expect(task.tags, equals({'error', 'critical'}));
        });
      });
    });

    group('State Checking Getters', () {
      test('isPending returns true only for TaskPending', () {
        expect(Task<int>.pending().isPending, isTrue);
        expect(Task<int>.running().isPending, isFalse);
        expect(Task<int>.refreshing(previousData: 1).isPending, isFalse);
        expect(Task<int>.retrying(previousData: 1).isPending, isFalse);
        expect(Task<int>.success(data: 1).isPending, isFalse);
        expect(Task<int>.failure(error: Exception()).isPending, isFalse);
      });

      test('isRunning returns true only for TaskRunning', () {
        expect(Task<int>.pending().isRunning, isFalse);
        expect(Task<int>.running().isRunning, isTrue);
        expect(Task<int>.refreshing(previousData: 1).isRunning, isFalse);
        expect(Task<int>.retrying(previousData: 1).isRunning, isFalse);
        expect(Task<int>.success(data: 1).isRunning, isFalse);
        expect(Task<int>.failure(error: Exception()).isRunning, isFalse);
      });

      test('isRefreshing returns true only for TaskRefreshing', () {
        expect(Task<int>.pending().isRefreshing, isFalse);
        expect(Task<int>.running().isRefreshing, isFalse);
        expect(Task<int>.refreshing(previousData: 1).isRefreshing, isTrue);
        expect(Task<int>.retrying(previousData: 1).isRefreshing, isFalse);
        expect(Task<int>.success(data: 1).isRefreshing, isFalse);
        expect(Task<int>.failure(error: Exception()).isRefreshing, isFalse);
      });

      test('isRetrying returns true only for TaskRetrying', () {
        expect(Task<int>.pending().isRetrying, isFalse);
        expect(Task<int>.running().isRetrying, isFalse);
        expect(Task<int>.refreshing(previousData: 1).isRetrying, isFalse);
        expect(Task<int>.retrying(previousData: 1).isRetrying, isTrue);
        expect(Task<int>.success(data: 1).isRetrying, isFalse);
        expect(Task<int>.failure(error: Exception()).isRetrying, isFalse);
      });

      test('isSuccess returns true only for TaskSuccess', () {
        expect(Task<int>.pending().isSuccess, isFalse);
        expect(Task<int>.running().isSuccess, isFalse);
        expect(Task<int>.refreshing(previousData: 1).isSuccess, isFalse);
        expect(Task<int>.retrying(previousData: 1).isSuccess, isFalse);
        expect(Task<int>.success(data: 1).isSuccess, isTrue);
        expect(Task<int>.failure(error: Exception()).isSuccess, isFalse);
      });

      test('isFailure returns true only for TaskFailure', () {
        expect(Task<int>.pending().isFailure, isFalse);
        expect(Task<int>.running().isFailure, isFalse);
        expect(Task<int>.refreshing(previousData: 1).isFailure, isFalse);
        expect(Task<int>.retrying(previousData: 1).isFailure, isFalse);
        expect(Task<int>.success(data: 1).isFailure, isFalse);
        expect(Task<int>.failure(error: Exception()).isFailure, isTrue);
      });
    });

    group('effectiveData Getter', () {
      test('returns data for TaskSuccess', () {
        final task = Task<int>.success(data: 42);
        expect(task.effectiveData, equals(42));
      });

      test('returns previousData for TaskRunning', () {
        final task = Task<int>.running(previousData: 42);
        expect(task.effectiveData, equals(42));
      });

      test('returns initialData when previousData is null for TaskRunning', () {
        final task = Task<int>.running(initialData: 10);
        expect(task.effectiveData, equals(10));
      });

      test('returns previousData for TaskRefreshing', () {
        final task = Task<int>.refreshing(previousData: 42);
        expect(task.effectiveData, equals(42));
      });

      test(
        'returns initialData when previousData is null for TaskRefreshing',
        () {
          final task = Task<int?>.refreshing(
            initialData: 10,
          );
          expect(task.effectiveData, equals(10));
        },
      );

      test('returns previousData for TaskRetrying', () {
        final task = Task<int>.retrying(previousData: 42);
        expect(task.effectiveData, equals(42));
      });

      test(
        'returns initialData when previousData is null for TaskRetrying',
        () {
          final task = Task<int?>.retrying(
            initialData: 10,
          );
          expect(task.effectiveData, equals(10));
        },
      );

      test('returns previousData for TaskFailure', () {
        final task = Task<int>.failure(
          error: Exception(),
          previousData: 42,
        );
        expect(task.effectiveData, equals(42));
      });

      test('returns initialData when previousData is null for TaskFailure', () {
        final task = Task<int>.failure(
          error: Exception(),
          initialData: 10,
        );
        expect(task.effectiveData, equals(10));
      });

      test('returns initialData for TaskPending', () {
        final task = Task<int>.pending(initialData: 42);
        expect(task.effectiveData, equals(42));
      });

      test('returns null when no data is available', () {
        final task = Task<int>.pending();
        expect(task.effectiveData, isNull);
      });
    });

    group('Convenience Transition Methods', () {
      group('toPending', () {
        test('transitions from any state to pending', () {
          final running = Task<int>.running(previousData: 42);
          final pending = running.toPending();

          expect(pending.isPending, isTrue);
          expect(pending.state, equals(TaskState.pending));
        });

        test('preserves label and tags', () {
          final task = Task<int>.success(
            data: 42,
            label: 'test',
            tags: {'tag1', 'tag2'},
          );
          final pending = task.toPending();

          expect(pending.label, equals('test'));
          expect(pending.tags, equals({'tag1', 'tag2'}));
        });

        test('preserves initialData by default', () {
          final task = Task<int>.success(data: 42, initialData: 10);
          final pending = task.toPending();

          expect(pending.initialData, equals(10));
        });

        test('updates initialData when provided', () {
          final task = Task<int>.success(data: 42, initialData: 10);
          final pending = task.toPending(initialData: 20);

          expect(pending.initialData, equals(20));
        });
      });

      group('toRunning', () {
        test('transitions from pending to running', () {
          final pending = Task<int>.pending(initialData: 10);
          final running = pending.toRunning();

          expect(running.isRunning, isTrue);
          expect(running.state, equals(TaskState.running));
        });

        test('preserves effectiveData as previousData', () {
          final success = Task<int>.success(data: 42);
          final running = success.toRunning();

          expect((running as TaskRunning<int>).previousData, equals(42));
        });

        test('preserves label, tags, and initialData', () {
          final task = Task<String>.success(
            data: 'result',
            initialData: 'initial',
            label: 'test-task',
            tags: {'important'},
          );
          final running = task.toRunning();

          expect(running.initialData, equals('initial'));
          expect(running.label, equals('test-task'));
          expect(running.tags, equals({'important'}));
        });

        test('handles null effectiveData', () {
          final pending = Task<int>.pending();
          final running = pending.toRunning();

          expect((running as TaskRunning<int>).previousData, isNull);
        });
      });

      group('toRefreshing', () {
        test('transitions from success to refreshing', () {
          final success = Task<int>.success(data: 42);
          final refreshing = success.toRefreshing();

          expect(refreshing.isRefreshing, isTrue);
          expect(refreshing.state, equals(TaskState.refreshing));
        });

        test('preserves data as previousData', () {
          final success = Task<int>.success(data: 42);
          final refreshing = success.toRefreshing();

          expect((refreshing as TaskRefreshing<int>).previousData, equals(42));
        });

        test('handles null effectiveData', () {
          final pending = Task<int>.pending();
          final refreshing = pending.toRefreshing();

          expect(refreshing.isRefreshing, isTrue);
          expect((refreshing as TaskRefreshing<int>).previousData, isNull);
        });

        test('preserves label, tags, and initialData', () {
          final task = Task<String>.success(
            data: 'result',
            initialData: 'initial',
            label: 'refresh-task',
            tags: {'refresh'},
          );
          final refreshing = task.toRefreshing();

          expect(refreshing.initialData, equals('initial'));
          expect(refreshing.label, equals('refresh-task'));
          expect(refreshing.tags, equals({'refresh'}));
        });

        test('scenario: refresh when initial load failed', () {
          // Simulate: initial data fetch failed, user wants to refresh
          final failure = Task<String>.failure(
            error: Exception('Network error'),
            label: 'fetch-users',
          );

          // User triggers refresh - should work even with no previous data
          final refreshing = failure.toRefreshing();

          expect(refreshing.isRefreshing, isTrue);
          expect((refreshing as TaskRefreshing<String>).previousData, isNull);
          expect(refreshing.label, equals('fetch-users'));
        });

        test('scenario: refresh when nothing was displayed', () {
          // Simulate: data fetched but nothing received/displayed
          final success = Task<List<String>>.success(
            data: [], // Empty list - nothing to display
            label: 'fetch-items',
          );

          // User triggers refresh to reload
          final refreshing = success.toRefreshing();

          expect(refreshing.isRefreshing, isTrue);
          expect(
            (refreshing as TaskRefreshing<List<String>>).previousData,
            equals([]),
          );
          expect(refreshing.label, equals('fetch-items'));
        });
      });

      group('toRetrying', () {
        test('transitions from failure to retrying', () {
          final failure = Task<int>.failure(
            error: Exception(),
            previousData: 10,
          );
          final retrying = failure.toRetrying();

          expect(retrying.isRetrying, isTrue);
          expect(retrying.state, equals(TaskState.retrying));
        });

        test('preserves previousData', () {
          final failure = Task<int>.failure(
            error: Exception(),
            previousData: 42,
          );
          final retrying = failure.toRetrying();

          expect((retrying as TaskRetrying<int>).previousData, equals(42));
        });

        test('handles null effectiveData', () {
          final pending = Task<int>.pending();
          final retrying = pending.toRetrying();

          expect(retrying.isRetrying, isTrue);
          expect((retrying as TaskRetrying<int>).previousData, isNull);
        });

        test('preserves label, tags, and initialData', () {
          final task = Task<int>.failure(
            error: Exception(),
            previousData: 10,
            initialData: 5,
            label: 'retry-task',
            tags: {'retry'},
          );
          final retrying = task.toRetrying();

          expect(retrying.initialData, equals(5));
          expect(retrying.label, equals('retry-task'));
          expect(retrying.tags, equals({'retry'}));
        });

        test('scenario: retry after failed fetch with no previous data', () {
          // Simulate: initial data fetch failed, user wants to retry
          final failure = Task<Map<String, dynamic>>.failure(
            error: Exception('Connection timeout'),
            label: 'fetch-profile',
            tags: {'api'},
          );

          // User triggers retry - should work even with no previous data
          final retrying = failure.toRetrying();

          expect(retrying.isRetrying, isTrue);
          expect(
            (retrying as TaskRetrying<Map<String, dynamic>>).previousData,
            isNull,
          );
          expect(retrying.label, equals('fetch-profile'));
          expect(retrying.tags, equals({'api'}));
        });

        test('scenario: retry preserves previous successful data', () {
          // Simulate: had data, then update failed, user retries
          final failure = Task<int>.failure(
            error: Exception('Update failed'),
            previousData: 42, // Previous successful data
            label: 'update-count',
          );

          // User triggers retry - should preserve the previous data
          final retrying = failure.toRetrying();

          expect(retrying.isRetrying, isTrue);
          expect((retrying as TaskRetrying<int>).previousData, equals(42));
          expect(retrying.label, equals('update-count'));
        });
      });

      group('toSuccess', () {
        test('transitions from running to success', () {
          final running = Task<int>.running();
          final success = running.toSuccess(42);

          expect(success.isSuccess, isTrue);
          expect(success.state, equals(TaskState.success));
          expect((success as TaskSuccess<int>).data, equals(42));
        });

        test('preserves label, tags, and initialData', () {
          final task = Task<String>.running(
            initialData: 'initial',
            label: 'success-task',
            tags: {'completed'},
          );
          final success = task.toSuccess('result');

          expect((success as TaskSuccess<String>).data, equals('result'));
          expect(success.initialData, equals('initial'));
          expect(success.label, equals('success-task'));
          expect(success.tags, equals({'completed'}));
        });

        test('works from any state', () {
          final pending = Task<int>.pending();
          final success = pending.toSuccess(100);

          expect(success.isSuccess, isTrue);
          expect((success as TaskSuccess<int>).data, equals(100));
        });
      });

      group('toFailure', () {
        test('transitions from running to failure', () {
          final running = Task<int>.running(previousData: 10);
          final error = Exception('Test error');
          final failure = running.toFailure(error);

          expect(failure.isFailure, isTrue);
          expect(failure.state, equals(TaskState.failure));
          expect((failure as TaskFailure<int>).error, equals(error));
        });

        test('preserves effectiveData as previousData', () {
          final success = Task<int>.success(data: 42);
          final failure = success.toFailure(Exception());

          expect((failure as TaskFailure<int>).previousData, equals(42));
        });

        test('includes stackTrace when provided', () {
          final running = Task<int>.running();
          final stackTrace = StackTrace.current;
          final failure = running.toFailure(
            Exception(),
            stackTrace: stackTrace,
          );

          expect((failure as TaskFailure<int>).stackTrace, equals(stackTrace));
        });

        test('preserves label, tags, and initialData', () {
          final task = Task<String>.running(
            previousData: 'old',
            initialData: 'initial',
            label: 'failed-task',
            tags: {'error'},
          );
          final failure = task.toFailure(Exception('Error'));

          expect((failure as TaskFailure<String>).previousData, equals('old'));
          expect(failure.initialData, equals('initial'));
          expect(failure.label, equals('failed-task'));
          expect(failure.tags, equals({'error'}));
        });

        test('handles null effectiveData', () {
          final pending = Task<int>.pending();
          final failure = pending.toFailure(Exception());

          expect((failure as TaskFailure<int>).previousData, isNull);
        });
      });

      group('state getter', () {
        test('returns correct state for each task type', () {
          expect(Task<int>.pending().state, equals(TaskState.pending));
          expect(Task<int>.running().state, equals(TaskState.running));
          expect(
            Task<int>.refreshing(previousData: 1).state,
            equals(TaskState.refreshing),
          );
          expect(
            Task<int>.retrying(previousData: 1).state,
            equals(TaskState.retrying),
          );
          expect(Task<int>.success(data: 1).state, equals(TaskState.success));
          expect(
            Task<int>.failure(error: Exception()).state,
            equals(TaskState.failure),
          );
        });
      });
    });

    group('mapData Method', () {
      test('transforms data in TaskSuccess', () {
        final task = Task<int>.success(data: 42);
        final transformed = task.mapData((data) => data * 2);

        expect(transformed.isSuccess, isTrue);
        expect((transformed as TaskSuccess<int>).data, equals(84));
      });

      test('transforms data type in TaskSuccess', () {
        final task = Task<int>.success(data: 42);
        final transformed = task.mapData((data) => data.toString());

        expect(transformed.isSuccess, isTrue);
        expect((transformed as TaskSuccess<String>).data, equals('42'));
      });

      test('transforms previousData in TaskRunning', () {
        final task = Task<int>.running(previousData: 10);
        final transformed = task.mapData((data) => data * 3);

        expect(transformed.isRunning, isTrue);
        expect((transformed as TaskRunning<int>).previousData, equals(30));
      });

      test('handles null previousData in TaskRunning', () {
        final task = Task<int>.running();
        final transformed = task.mapData((data) => data * 2);

        expect(transformed.isRunning, isTrue);
        expect((transformed as TaskRunning<int>).previousData, isNull);
      });

      test('transforms previousData in TaskRefreshing', () {
        final task = Task<String>.refreshing(previousData: 'hello');
        final transformed = task.mapData((data) => data.toUpperCase());

        expect(transformed.isRefreshing, isTrue);
        expect(
          (transformed as TaskRefreshing<String>).previousData,
          equals('HELLO'),
        );
      });

      test('transforms previousData in TaskRetrying', () {
        final task = Task<double>.retrying(previousData: 3.14);
        final transformed = task.mapData((data) => data.toInt());

        expect(transformed.isRetrying, isTrue);
        expect((transformed as TaskRetrying<int>).previousData, equals(3));
      });

      test('transforms previousData in TaskFailure', () {
        final task = Task<int>.failure(
          error: Exception(),
          previousData: 100,
        );
        final transformed = task.mapData((data) => data ~/ 2);

        expect(transformed.isFailure, isTrue);
        expect((transformed as TaskFailure<int>).previousData, equals(50));
      });

      test('preserves error in TaskFailure', () {
        final error = Exception('Test');
        final task = Task<int>.failure(error: error);
        final transformed = task.mapData((data) => data * 2);

        expect((transformed as TaskFailure<int>).error, equals(error));
      });

      test('transforms initialData in TaskPending', () {
        final task = Task<int>.pending(initialData: 5);
        final transformed = task.mapData((data) => data * 10);

        expect(transformed.isPending, isTrue);
        expect(transformed.initialData, equals(50));
      });

      test('handles null initialData in TaskPending', () {
        final task = Task<int>.pending();
        final transformed = task.mapData((data) => data * 2);

        expect(transformed.isPending, isTrue);
        expect(transformed.initialData, isNull);
      });

      test('preserves label and tags', () {
        final task = Task<int>.success(
          data: 42,
          label: 'test',
          tags: {'tag1', 'tag2'},
        );
        final transformed = task.mapData((data) => data.toString());

        expect(transformed.label, equals('test'));
        expect(transformed.tags, equals({'tag1', 'tag2'}));
      });
    });

    group('mapError Method', () {
      test('transforms error in TaskFailure', () {
        final task = Task<int>.failure(error: Exception('Original'));
        final transformed = task.mapError((error) => Exception('Transformed'));

        expect(transformed.isFailure, isTrue);
        expect(
          (transformed as TaskFailure<int>).error.toString(),
          contains('Transformed'),
        );
      });

      test('preserves stackTrace in TaskFailure', () {
        final stackTrace = StackTrace.current;
        final task = Task<int>.failure(
          error: Exception('Test'),
          stackTrace: stackTrace,
        );
        final transformed = task.mapError((error) => Exception('New'));

        expect(
          (transformed as TaskFailure<int>).stackTrace,
          equals(stackTrace),
        );
      });

      test('preserves previousData in TaskFailure', () {
        final task = Task<int>.failure(
          error: Exception('Test'),
          previousData: 42,
        );
        final transformed = task.mapError((error) => Exception('New'));

        expect((transformed as TaskFailure<int>).previousData, equals(42));
      });

      test('returns same task for non-failure states', () {
        final pending = Task<int>.pending();
        expect(pending.mapError((e) => Exception('New')), same(pending));

        final running = Task<int>.running();
        expect(running.mapError((e) => Exception('New')), same(running));

        final refreshing = Task<int>.refreshing(previousData: 1);
        expect(refreshing.mapError((e) => Exception('New')), same(refreshing));

        final retrying = Task<int>.retrying(previousData: 1);
        expect(retrying.mapError((e) => Exception('New')), same(retrying));

        final success = Task<int>.success(data: 42);
        expect(success.mapError((e) => Exception('New')), same(success));
      });

      test('preserves label and tags', () {
        final task = Task<int>.failure(
          error: Exception('Test'),
          label: 'error-task',
          tags: {'error'},
        );
        final transformed = task.mapError((error) => Exception('New'));

        expect(transformed.label, equals('error-task'));
        expect(transformed.tags, equals({'error'}));
      });
    });

    group('transform Method', () {
      test('updates data in TaskSuccess', () {
        final task = Task<int>.success(data: 42);
        final transformed = task.transform(
          updateData: (oldData) => (oldData ?? 0) * 2,
        );

        expect((transformed as TaskSuccess<int>).data, equals(84));
      });

      test('updates previousData in TaskRunning', () {
        final task = Task<int>.running(previousData: 10);
        final transformed = task.transform(
          updatePrevious: (oldPrev) => (oldPrev ?? 0) + 5,
        );

        expect((transformed as TaskRunning<int>).previousData, equals(15));
      });

      test('updates previousData in TaskRefreshing', () {
        final task = Task<String>.refreshing(previousData: 'hello');
        final transformed = task.transform(
          updatePrevious: (oldPrev) => oldPrev?.toUpperCase(),
        );

        expect(
          (transformed as TaskRefreshing<String>).previousData,
          equals('HELLO'),
        );
      });

      test('updates previousData in TaskRetrying', () {
        final task = Task<int>.retrying(previousData: 100);
        final transformed = task.transform(
          updatePrevious: (oldPrev) => (oldPrev ?? 0) ~/ 2,
        );

        expect((transformed as TaskRetrying<int>).previousData, equals(50));
      });

      test('updates error in TaskFailure', () {
        final task = Task<int>.failure(error: Exception('Old'));
        final transformed = task.transform(
          updateError: (oldError) => Exception('New'),
        );

        expect(
          (transformed as TaskFailure<int>).error.toString(),
          contains('New'),
        );
      });

      test('updates previousData in TaskFailure', () {
        final task = Task<int>.failure(
          error: Exception('Test'),
          previousData: 42,
        );
        final transformed = task.transform(
          updatePrevious: (oldPrev) => (oldPrev ?? 0) * 2,
        );

        expect((transformed as TaskFailure<int>).previousData, equals(84));
      });

      test('handles null return from updateError', () {
        final error = Exception('Original');
        final task = Task<int>.failure(error: error);
        final transformed = task.transform(
          updateError: (oldError) => null,
        );

        expect((transformed as TaskFailure<int>).error, equals(error));
      });

      test('updates initialData in TaskPending', () {
        final task = Task<int>.pending(initialData: 10);
        final transformed = task.transform(
          updateData: (oldData) => (oldData ?? 0) * 5,
        );

        expect(transformed.initialData, equals(50));
      });

      test('preserves label and tags', () {
        final task = Task<int>.success(
          data: 42,
          label: 'transform-test',
          tags: {'test'},
        );
        final transformed = task.transform(
          updateData: (oldData) => (oldData ?? 0) * 2,
        );

        expect(transformed.label, equals('transform-test'));
        expect(transformed.tags, equals({'test'}));
      });

      test('preserves stackTrace in TaskFailure', () {
        final stackTrace = StackTrace.current;
        final task = Task<int>.failure(
          error: Exception('Test'),
          stackTrace: stackTrace,
        );
        final transformed = task.transform(
          updateError: (oldError) => Exception('New'),
        );

        expect(
          (transformed as TaskFailure<int>).stackTrace,
          equals(stackTrace),
        );
      });
    });

    group('copyWith Method', () {
      test('copies TaskPending with new initialData', () {
        final task = Task<int>.pending(initialData: 10);
        final copied = task.copyWith(initialData: 20);

        expect(copied.isPending, isTrue);
        expect(copied.initialData, equals(20));
      });

      test('copies TaskPending with new label', () {
        final task = Task<int>.pending(label: 'old');
        final copied = task.copyWith(label: 'new');

        expect(copied.label, equals('new'));
      });

      test('copies TaskPending with new tags', () {
        final task = Task<int>.pending(tags: {'old'});
        final copied = task.copyWith(tags: {'new'});

        expect(copied.tags, equals({'new'}));
      });

      test('copies TaskRunning with new previousData', () {
        final task = Task<int>.running(previousData: 10);
        final copied = task.copyWith(previousData: 20);

        expect((copied as TaskRunning<int>).previousData, equals(20));
      });

      test('copies TaskRunning preserving existing values', () {
        final task = Task<int>.running(
          previousData: 10,
          initialData: 5,
          label: 'test',
          tags: {'tag'},
        );
        final copied = task.copyWith();

        expect((copied as TaskRunning<int>).previousData, equals(10));
        expect(copied.initialData, equals(5));
        expect(copied.label, equals('test'));
        expect(copied.tags, equals({'tag'}));
      });

      test('copies TaskRefreshing with new previousData', () {
        final task = Task<String>.refreshing(previousData: 'old');
        final copied = task.copyWith(previousData: 'new');

        expect((copied as TaskRefreshing<String>).previousData, equals('new'));
      });

      test('copies TaskRetrying with new previousData', () {
        final task = Task<int>.retrying(previousData: 100);
        final copied = task.copyWith(previousData: 200);

        expect((copied as TaskRetrying<int>).previousData, equals(200));
      });

      test('copies TaskSuccess with new data', () {
        final task = Task<int>.success(data: 42);
        final copied = task.copyWith(data: 84);

        expect((copied as TaskSuccess<int>).data, equals(84));
      });

      test('copies TaskSuccess preserving existing values', () {
        final task = Task<String>.success(
          data: 'result',
          initialData: 'initial',
          label: 'success',
          tags: {'done'},
        );
        final copied = task.copyWith();

        expect((copied as TaskSuccess<String>).data, equals('result'));
        expect(copied.initialData, equals('initial'));
        expect(copied.label, equals('success'));
        expect(copied.tags, equals({'done'}));
      });

      test('copies TaskFailure with new error', () {
        final task = Task<int>.failure(error: Exception('Old'));
        final newError = Exception('New');
        final copied = task.copyWith(error: newError);

        expect((copied as TaskFailure<int>).error, equals(newError));
      });

      test('copies TaskFailure with new stackTrace', () {
        final task = Task<int>.failure(error: Exception('Test'));
        final newStackTrace = StackTrace.current;
        final copied = task.copyWith(stackTrace: newStackTrace);

        expect((copied as TaskFailure<int>).stackTrace, equals(newStackTrace));
      });

      test('copies TaskFailure with new previousData', () {
        final task = Task<int>.failure(
          error: Exception('Test'),
          previousData: 10,
        );
        final copied = task.copyWith(previousData: 20);

        expect((copied as TaskFailure<int>).previousData, equals(20));
      });

      test('copies TaskFailure preserving existing values', () {
        final error = Exception('Test');
        final stackTrace = StackTrace.current;
        final task = Task<int>.failure(
          error: error,
          stackTrace: stackTrace,
          previousData: 42,
          initialData: 10,
          label: 'failed',
          tags: {'error'},
        );
        final copied = task.copyWith();

        final failure = copied as TaskFailure<int>;
        expect(failure.error, equals(error));
        expect(failure.stackTrace, equals(stackTrace));
        expect(failure.previousData, equals(42));
        expect(copied.initialData, equals(10));
        expect(copied.label, equals('failed'));
        expect(copied.tags, equals({'error'}));
      });
    });

    group('copyWithOrNull Method', () {
      test('replaces all values in TaskPending with null', () {
        final task = Task<int>.pending(
          initialData: 10,
          label: 'test',
          tags: {'tag'},
        );
        final copied = task.copyWithOrNull();

        expect(copied.isPending, isTrue);
        expect(copied.initialData, isNull);
        expect(copied.label, isNull);
        expect(copied.tags, isEmpty);
      });

      test('replaces values in TaskPending with provided values', () {
        final task = Task<int>.pending();
        final copied = task.copyWithOrNull(
          initialData: 20,
          label: 'new',
          tags: {'new-tag'},
        );

        expect(copied.initialData, equals(20));
        expect(copied.label, equals('new'));
        expect(copied.tags, equals({'new-tag'}));
      });

      test('replaces all values in TaskRunning with null', () {
        final task = Task<int>.running(
          previousData: 10,
          initialData: 5,
          label: 'test',
          tags: {'tag'},
        );
        final copied = task.copyWithOrNull();

        expect(copied.isRunning, isTrue);
        expect((copied as TaskRunning<int>).previousData, isNull);
        expect(copied.initialData, isNull);
        expect(copied.label, isNull);
        expect(copied.tags, isEmpty);
      });

      test('replaces values in TaskRefreshing with provided values', () {
        final task = Task<String>.refreshing(previousData: 'old');
        final copied = task.copyWithOrNull(
          previousData: 'new',
          label: 'refreshed',
        );

        expect((copied as TaskRefreshing<String>).previousData, equals('new'));
        expect(copied.label, equals('refreshed'));
      });

      test('replaces values in TaskRetrying with null', () {
        final task = Task<int>.retrying(
          previousData: 100,
          initialData: 50,
        );
        final copied = task.copyWithOrNull();

        expect((copied as TaskRetrying<int>).previousData, isNull);
        expect(copied.initialData, isNull);
      });

      test('replaces data in TaskSuccess', () {
        final task = Task<int>.success(data: 42);
        final copied = task.copyWithOrNull(data: 84);

        expect((copied as TaskSuccess<int>).data, equals(84));
      });

      test('replaces error in TaskFailure', () {
        final task = Task<int>.failure(error: Exception('Old'));
        final newError = Exception('New');
        final copied = task.copyWithOrNull(error: newError);

        expect((copied as TaskFailure<int>).error, equals(newError));
      });

      test('replaces all values in TaskFailure with null where possible', () {
        final task = Task<int>.failure(
          error: Exception('Test'),
          stackTrace: StackTrace.current,
          previousData: 42,
          initialData: 10,
          label: 'failed',
          tags: {'error'},
        );
        final newError = Exception('Required');
        final copied = task.copyWithOrNull(error: newError);

        final failure = copied as TaskFailure<int>;
        expect(failure.error, equals(newError));
        expect(failure.stackTrace, isNull);
        expect(failure.previousData, isNull);
        expect(copied.initialData, isNull);
        expect(copied.label, isNull);
        expect(copied.tags, isEmpty);
      });
    });

    group('Edge Cases and Complex Scenarios', () {
      test('handles complex type transformations', () {
        final task = Task<List<int>>.success(data: [1, 2, 3]);
        final transformed = task.mapData((data) => data.length);

        expect((transformed as TaskSuccess<int>).data, equals(3));
      });

      test('handles nullable types correctly', () {
        final task = Task<int?>.success(data: null);
        expect((task as TaskSuccess<int?>).data, isNull);
      });

      test('preserves empty tags set', () {
        final task = Task<int>.pending(tags: {});
        expect(task.tags, isEmpty);
      });

      test('handles multiple tag operations', () {
        final task = Task<int>.success(
          data: 42,
          tags: {'tag1', 'tag2', 'tag3'},
        );
        final copied = task.copyWith(tags: {'new1', 'new2'});

        expect(copied.tags, equals({'new1', 'new2'}));
      });

      test('effectiveData prioritizes correctly in complex scenario', () {
        final task = Task<int>.running(
          previousData: 100,
          initialData: 50,
        );
        expect(task.effectiveData, equals(100));

        final task2 = Task<int>.running(initialData: 50);
        expect(task2.effectiveData, equals(50));

        final task3 = Task<int>.running();
        expect(task3.effectiveData, isNull);
      });

      test('convenience methods preserve all metadata', () {
        final oldTask = Task<int>.success(
          data: 42,
          initialData: 10,
          label: 'complete',
          tags: {'important', 'verified'},
        );

        final newTask = oldTask.toRefreshing();

        expect(newTask.isRefreshing, isTrue);
        expect((newTask as TaskRefreshing<int>).previousData, equals(42));
        expect(newTask.initialData, equals(10));
        expect(newTask.label, equals('complete'));
        expect(newTask.tags, equals({'important', 'verified'}));
      });

      test('chaining multiple transitions', () {
        final task = Task<int>.success(data: 10, label: 'start');
        final result = task.toRunning().toSuccess(20).toRefreshing();

        expect(result.isRefreshing, isTrue);
        expect((result as TaskRefreshing<int>).previousData, equals(20));
        expect(result.label, equals('start'));
      });

      test('handles error transformation with different error types', () {
        final task = Task<int>.failure(error: 'String error');
        final transformed = task.mapError(
          (error) => Exception(error.toString()),
        );

        expect((transformed as TaskFailure<int>).error, isA<Exception>());
      });

      test('copyWith on TaskSuccess maintains type safety', () {
        final task = Task<String>.success(data: 'hello');
        final copied = task.copyWith(data: 'world');

        expect((copied as TaskSuccess<String>).data, equals('world'));
      });

      test('transform with multiple update functions', () {
        final task = Task<int>.failure(
          error: Exception('Test'),
          previousData: 10,
        );
        final transformed = task.transform(
          updateError: (oldError) => Exception('New error'),
          updatePrevious: (oldPrev) => (oldPrev ?? 0) * 3,
        );

        final failure = transformed as TaskFailure<int>;
        expect(failure.error.toString(), contains('New error'));
        expect(failure.previousData, equals(30));
      });

      test('effectiveData with all null values', () {
        final pending = Task<int>.pending();
        expect(pending.effectiveData, isNull);

        final running = Task<int>.running();
        expect(running.effectiveData, isNull);

        final failure = Task<int>.failure(error: Exception());
        expect(failure.effectiveData, isNull);
      });

      test('preserves const tags across operations', () {
        const tags = {'const-tag'};
        final task = Task<int>.pending(tags: tags);
        final copied = task.copyWith(initialData: 10);

        expect(copied.tags, equals(tags));
      });
    });

    group('Type Safety and Generics', () {
      test('works with custom class types', () {
        final task = Task<_TestData>.success(
          data: _TestData('test', 42),
        );
        expect(task.isSuccess, isTrue);
        expect((task as TaskSuccess<_TestData>).data.name, equals('test'));
        expect(task.data.value, equals(42));
      });

      test('transforms custom types correctly', () {
        final task = Task<_TestData>.success(
          data: _TestData('original', 10),
        );
        final transformed = task.mapData(
          (data) => _TestData(data.name.toUpperCase(), data.value * 2),
        );

        final result = transformed as TaskSuccess<_TestData>;
        expect(result.data.name, equals('ORIGINAL'));
        expect(result.data.value, equals(20));
      });

      test('handles List types', () {
        final task = Task<List<String>>.success(data: ['a', 'b', 'c']);
        final transformed = task.mapData(
          (data) => data.map((s) => s.toUpperCase()).toList(),
        );

        expect(
          (transformed as TaskSuccess<List<String>>).data,
          equals(['A', 'B', 'C']),
        );
      });

      test('handles Map types', () {
        final task = Task<Map<String, int>>.success(
          data: {'a': 1, 'b': 2},
        );
        final transformed = task.mapData((data) => data.length);

        expect((transformed as TaskSuccess<int>).data, equals(2));
      });

      test('handles nested generic types', () {
        final task = Task<List<Map<String, int>>>.success(
          data: [
            {'a': 1},
            {'b': 2},
          ],
        );
        expect(task.isSuccess, isTrue);
        expect(
          (task as TaskSuccess<List<Map<String, int>>>).data.length,
          equals(2),
        );
      });
    });

    group('State Transitions', () {
      test('simulates pending to running transition', () {
        final pending = Task<int>.pending(
          initialData: 0,
          label: 'fetch-data',
          tags: {'api'},
        );

        final running = pending.toRunning();

        expect(running.isRunning, isTrue);
        expect(running.label, equals('fetch-data'));
        expect(running.tags, equals({'api'}));
      });

      test('simulates running to success transition', () {
        final running = Task<int>.running(
          previousData: 10,
          label: 'fetch-data',
        );

        final success = running.toSuccess(42);

        expect(success.isSuccess, isTrue);
        expect((success as TaskSuccess<int>).data, equals(42));
      });

      test('simulates running to failure transition', () {
        final running = Task<int>.running(previousData: 10);
        final error = Exception('Network error');

        final failure = running.toFailure(error);

        expect(failure.isFailure, isTrue);
        expect((failure as TaskFailure<int>).previousData, equals(10));
      });

      test('simulates success to refreshing transition', () {
        final success = Task<int>.success(data: 42);

        final refreshing = success.toRefreshing();

        expect(refreshing.isRefreshing, isTrue);
        expect((refreshing as TaskRefreshing<int>).previousData, equals(42));
      });

      test('simulates failure to retrying transition', () {
        final failure = Task<int>.failure(
          error: Exception('First attempt'),
          previousData: 10,
        );

        final retrying = failure.toRetrying();

        expect(retrying.isRetrying, isTrue);
        expect((retrying as TaskRetrying<int>).previousData, equals(10));
      });
    });

    group('Task.from Instance Method', () {
      test('transitions to pending', () {
        final task = Task<int>.running(previousData: 42);
        final pending = task.from(task, newTask: TaskState.pending);

        expect(pending.isPending, isTrue);
        expect(
          pending.initialData,
          equals(42),
        ); // Uses previousData as initialData
      });

      test('transitions to running', () {
        final task = Task<int>.pending(initialData: 10);
        final running = task.from(task, newTask: TaskState.running);

        expect(running.isRunning, isTrue);
        expect((running as TaskRunning<int>).previousData, equals(10));
      });

      test('transitions to refreshing', () {
        final task = Task<int>.success(data: 42);
        final refreshing = task.from(task, newTask: TaskState.refreshing);

        expect(refreshing.isRefreshing, isTrue);
        expect((refreshing as TaskRefreshing<int>).previousData, equals(42));
      });

      test('transitions to retrying', () {
        final task = Task<int>.failure(error: Exception(), previousData: 10);
        final retrying = task.from(task, newTask: TaskState.retrying);

        expect(retrying.isRetrying, isTrue);
        expect((retrying as TaskRetrying<int>).previousData, equals(10));
      });

      test('transitions to success with data', () {
        final task = Task<int>.running();
        final success = task.from(task, newTask: TaskState.success, data: 42);

        expect(success.isSuccess, isTrue);
        expect((success as TaskSuccess<int>).data, equals(42));
      });

      test('throws StateError when transitioning to success without data', () {
        final task = Task<int>.running();

        expect(
          () => task.from(task, newTask: TaskState.success),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('The "data" parameter cannot be null'),
            ),
          ),
        );
      });

      test('transitions to failure with error', () {
        final task = Task<int>.running();
        final error = Exception('Fail');
        final failure = task.from(
          task,
          newTask: TaskState.failure,
          error: error,
        );

        expect(failure.isFailure, isTrue);
        expect((failure as TaskFailure<int>).error, equals(error));
      });

      test('throws StateError when transitioning to failure without error', () {
        final task = Task<int>.running();

        expect(
          () => task.from(task, newTask: TaskState.failure),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('The "error" parameter cannot be null'),
            ),
          ),
        );
      });
    });
    group('Static Methods', () {
      group('runSync', () {
        test('returns TaskSuccess on successful execution', () {
          final task = Task.runSync(() => 42);
          expect(task.isSuccess, isTrue);
          expect((task as TaskSuccess<int>).data, equals(42));
        });

        test('returns TaskFailure on error', () {
          final error = Exception('Sync error');
          final task = Task.runSync(() => throw error);
          expect(task.isFailure, isTrue);
          expect((task as TaskFailure).error, equals(error));
        });
      });

      group('run', () {
        test('returns TaskSuccess on successful async execution', () async {
          final task = await Task.run(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 'Async Result';
          });
          expect(task.isSuccess, isTrue);
          expect((task as TaskSuccess<String>).data, equals('Async Result'));
        });

        test('returns TaskFailure on async error', () async {
          final error = Exception('Async error');
          final task = await Task.run(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            throw error;
          });
          expect(task.isFailure, isTrue);
          expect((task as TaskFailure).error, equals(error));
        });
      });

      group('watch', () {
        test('emits running then success on successful execution', () {
          final stream = Task.watch(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            return 100;
          });

          expect(
            stream,
            emitsInOrder([
              isA<TaskRunning<int>>(),
              isA<TaskSuccess<int>>().having((t) => t.data, 'data', 100),
            ]),
          );
        });

        test('emits running then failure on error', () {
          final error = Exception('Stream error');
          final stream = Task.watch(() async {
            await Future<void>.delayed(const Duration(milliseconds: 10));
            throw error;
          });

          expect(
            stream,
            emitsInOrder([
              isA<TaskRunning<dynamic>>(),
              isA<TaskFailure<dynamic>>().having(
                (t) => t.error,
                'error',
                error,
              ),
            ]),
          );
        });
      });
    });
  });
}

// Helper class for testing custom types
class _TestData {
  _TestData(this.name, this.value);

  final String name;
  final int value;
}
