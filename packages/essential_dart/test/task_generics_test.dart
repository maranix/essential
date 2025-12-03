import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

enum TaskLabel {
  fetching,
  processing,
  completed,
}

enum TaskTag {
  critical,
  background,
  userInitiated,
}

void main() {
  group('Task Generics', () {
    test('should support custom Label type (Enum)', () {
      final task = Task<int, TaskLabel, Set<TaskTag>>.pending(
        label: TaskLabel.fetching,
      );

      expect(task.label, equals(TaskLabel.fetching));
      expect(task.label, isA<TaskLabel>());
    });

    test('should support custom Tags type (Set<Enum>)', () {
      final task = Task<int, TaskLabel, Set<TaskTag>>.pending(
        tags: {TaskTag.critical, TaskTag.userInitiated},
      );

      expect(task.tags, contains(TaskTag.critical));
      expect(task.tags, contains(TaskTag.userInitiated));
      expect(task.tags, isA<Set<TaskTag>>());
    });

    test('should support custom Tags type (List<String>)', () {
      final task = Task<int, String, List<String>>.pending(
        tags: ['tag1', 'tag2'],
      );

      expect(task.tags, equals(['tag1', 'tag2']));
      expect(task.tags, isA<List<String>>());
    });

    test('should enforce type safety for Label', () {
      // This is a compile-time check, but we can verify runtime behavior
      final task = Task<int, int, Set<String>>.pending(label: 123);
      expect(task.label, equals(123));
    });
  });

  group('TaskGroup Generics', () {
    test('should support custom Label and Tags in Uniform TaskGroup', () {
      final group = TaskGroup<int, TaskLabel, Set<TaskTag>>.uniform(
        {
          '1': Task.pending(label: TaskLabel.fetching),
          '2': Task.success(data: 1, tags: {TaskTag.background}),
        },
        label: TaskLabel.processing,
        tags: {TaskTag.critical},
      );

      expect(group.label, equals(TaskLabel.processing));
      expect(group.tags, contains(TaskTag.critical));
      expect(group.getTask('1')!.label, equals(TaskLabel.fetching));
      expect(group.getTask('2')!.tags, contains(TaskTag.background));
    });

    test('should support custom Label and Tags in Mixed TaskGroup', () {
      final group = TaskGroup.mixed<TaskLabel, Set<TaskTag>>(
        {
          '1': Task<int, TaskLabel, Set<TaskTag>>.pending(
            label: TaskLabel.fetching,
          ),
          '2': Task<String, TaskLabel, Set<TaskTag>>.success(
            data: 'ok',
            tags: {TaskTag.background},
          ),
        },
        label: TaskLabel.processing,
        tags: {TaskTag.critical},
      );

      expect(group.label, equals(TaskLabel.processing));
      expect(group.tags, contains(TaskTag.critical));

      // Check task types
      final task1 = group.getTask<TaskPending<int, TaskLabel, Set<TaskTag>>>(
        '1',
      );
      expect(task1, isNotNull);
      expect(task1!.label, equals(TaskLabel.fetching));
    });

    test('Extensions should work with custom types', () {
      final group = TaskGroup<int, TaskLabel, Set<TaskTag>>.uniform({
        '1': Task.pending(label: TaskLabel.fetching),
        '2': Task.pending(label: TaskLabel.processing),
      });

      final fetchingTasks = group.withLabel(TaskLabel.fetching);
      expect(fetchingTasks.length, 1);
      expect(fetchingTasks.containsKey('1'), isTrue);
    });
  });
}
