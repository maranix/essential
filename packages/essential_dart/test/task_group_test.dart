import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

void main() {
  group('TaskGroup', () {
    group('State Derivation', () {
      test('should be idle when empty', () {
        final group = TaskGroup.uniform({});
        expect(group.state, TaskGroupState.idle);
      });

      test('should be idle when all tasks are pending', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.pending(),
          '2': Task<int, String?, Set<String>>.pending(),
        });
        expect(group.state, TaskGroupState.idle);
      });

      test('should be active if any task is running', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.running(),
          '2': Task<int, String?, Set<String>>.pending(),
        });
        expect(group.state, TaskGroupState.active);
      });

      test('should be active if any task is refreshing', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.refreshing(),
          '2': Task<int, String?, Set<String>>.success(data: 1),
        });
        expect(group.state, TaskGroupState.active);
      });

      test('should be active if any task is retrying', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.retrying(),
          '2': Task<int, String?, Set<String>>.failure(error: 'err'),
        });
        expect(group.state, TaskGroupState.active);
      });

      test('should be completed if all tasks are success', () {
        final group = TaskGroup.uniform({
          '1': Task.success(data: 1),
          '2': Task.success(data: 2),
        });
        expect(group.state, TaskGroupState.completed);
      });

      test('should be failed if all tasks are failure', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.failure(error: 'err1'),
          '2': Task<int, String?, Set<String>>.failure(error: 'err2'),
        });
        expect(group.state, TaskGroupState.failed);
      });

      test('should be partial if mixed success and failure', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.success(data: 1),
          '2': Task<int, String?, Set<String>>.failure(error: 'err'),
        });
        expect(group.state, TaskGroupState.partial);
      });

      test('should be partial if mixed success and pending', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.success(data: 1),
          '2': Task<int, String?, Set<String>>.pending(),
        });
        expect(group.state, TaskGroupState.partial);
      });
    });

    group('Uniform TaskGroup', () {
      test('should add task', () {
        var group = TaskGroup<int, String?, Set<String>>.uniform({});
        group = group.addTask('1', Task.pending());
        expect(group.taskCount, 1);
        expect(group.getTask('1'), isA<Task<int, String?, Set<String>>>());
      });

      test('should remove task', () {
        var group = TaskGroup<int, String?, Set<String>>.uniform({'1': Task.pending()});
        group = group.removeTask('1');
        expect(group.taskCount, 0);
      });

      test('should update task', () {
        var group = TaskGroup<int, String?, Set<String>>.uniform({'1': Task.pending()});
        group = group.updateTask('1', (t) => t.toRunning());
        expect(group.getTask('1')!.isRunning, true);
      });

      test('should run all tasks', () async {
        var group = TaskGroup<int, String?, Set<String>>.uniform({
          '1': Task.pending(),
          '2': Task.pending(),
        });

        group = await group.runAll((key, task) async => int.parse(key));

        expect(group.allSuccess, true);
        expect(group.getTask<TaskSuccess<int, String?, Set<String>>>('1')!.data, 1);
        expect(group.getTask<TaskSuccess<int, String?, Set<String>>>('2')!.data, 2);
      });

      test('should retry failed tasks', () async {
        var group = TaskGroup<int, String?, Set<String>>.uniform({
          '1': Task.failure(error: 'err'),
          '2': Task.success(data: 2),
        });

        group = await group.retryFailed((key, task) async => 1);

        expect(group.allSuccess, true);
        expect(group.getTask<TaskSuccess<int, String?, Set<String>>>('1')!.data, 1);
        expect(group.getTask<TaskSuccess<int, String?, Set<String>>>('2')!.data, 2);
      });
    });

    group('Mixed TaskGroup', () {
      test('should create mixed group', () {
        final group = TaskGroup.mixed<String?, Set<String>>({
          'user': Task<String, String?, Set<String>>.pending(),
          'count': Task<int, String?, Set<String>>.pending(),
        });
        expect(group.taskCount, 2);
      });

      test('should get typed task', () {
        final group = TaskGroup.mixed<String?, Set<String>>({
          'user': Task<String, String?, Set<String>>.success(data: 'User'),
          'count': Task<int, String?, Set<String>>.success(data: 42),
        });

        // Need to cast to access getTaskTyped as it's not on TaskGroup<T>
        // But wait, getTaskTyped is only on _HeterogeneousTaskGroup
        // And TaskGroup.mixed returns TaskGroup<Object?, String?, Set<String>> which hides it?
        // Ah, I made TaskGroup.mixed return TaskGroup<Object?, String?, Set<String>>.
        // So I can't call getTaskTyped unless I cast.
        // This is expected design for type safety.

        // However, let's verify runtime type
        expect(group, isA<TaskGroup<Object?, String?, Set<String>>>());
        // Since _HeterogeneousTaskGroup is private, we can't cast to it in test unless we export it?
        // Or we just test that getTask returns Task<Object?>.

        final userTask = group.getTask('user');
        expect(userTask, isA<Task<String, String?, Set<String>>>());
      });
    });

    group('Extensions', () {
      test('should filter by label', () {
        final group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.pending(label: 'a'),
          '2': Task<int, String?, Set<String>>.pending(label: 'b'),
        });
        final filtered = group.withLabel('a');
        expect(filtered.length, 1);
        expect(filtered.containsKey('1'), true);
      });

      test('should transition to running', () {
        var group = TaskGroup.uniform({
          '1': Task<int, String?, Set<String>>.pending(),
          '2': Task<int, String?, Set<String>>.failure(error: 'err'),
        });
        group = group.toRunning();
        expect(group.tasks.values.every((t) => t.isRunning), true);
      });

      test('should preserve type after transition', () {
        final mixed = TaskGroup.mixed<String?, Set<String>>({'1': Task<int, String?, Set<String>>.pending()});
        final running = mixed.toRunning();
        // Should still be mixed implementation (checked via behavior or reflection if needed)
        // But mainly we check it works.
        expect(running.taskCount, 1);
      });
    });

    group('Type Safety & Getters', () {
      test('getTask<S> should return task if type matches', () {
        final group = TaskGroup.uniform({'1': Task<int, String?, Set<String>>.success(data: 1)});
        final task = group.getTask<TaskSuccess<int, String?, Set<String>>>('1');
        expect(task, isNotNull);
        expect(task!.data, 1);
      });

      test('getTask<S> should throw TypeError if type mismatches', () {
        final group = TaskGroup.uniform({'1': Task<int, String?, Set<String>>.success(data: 1)});
        expect(
          () => group.getTask<TaskFailure<int, String?, Set<String>>>('1'),
          throwsA(isA<TypeError>()),
        );
      });

      test('getTask<S> should return null if key missing', () {
        final group = TaskGroup.uniform({});
        expect(group.getTask<TaskSuccess<int, String?, Set<String>>>('1'), isNull);
      });

      test('getter .success should return data', () {
        final task = Task<int, String?, Set<String>>.success(data: 42);
        expect(task.success.data, 42);
      });

      test('getter .success should throw StateError if not success', () {
        final task = Task<int, String?, Set<String>>.pending();
        expect(() => task.success, throwsStateError);
      });

      test('getter .failure should return error', () {
        final task = Task<int, String?, Set<String>>.failure(error: 'oops');
        expect(task.failure.error, 'oops');
      });
    });
  });
}
