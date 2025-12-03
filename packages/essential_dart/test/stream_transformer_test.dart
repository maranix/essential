import 'dart:async';

import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

void main() {
  group('StringSplitter', () {
    test('splits by newline by default', () async {
      final stream = Stream.fromIterable(['a\nb', '\nc']);
      final result = await stream.transform(const StringSplitter()).toList();
      expect(result, ['a', 'b', 'c']);
    });

    test('splits by custom single character separator', () async {
      final stream = Stream.fromIterable(['a,b', ',c']);
      final result = await stream.transform(const StringSplitter(',')).toList();
      expect(result, ['a', 'b', 'c']);
    });

    test('splits by custom multi-character separator', () async {
      final stream = Stream.fromIterable(['a--b', '--c']);
      final result = await stream
          .transform(const StringSplitter('--'))
          .toList();
      expect(result, ['a', 'b', 'c']);
    });

    test('handles separator split across chunks', () async {
      final stream = Stream.fromIterable(['a-', '-b']);
      final result = await stream
          .transform(const StringSplitter('--'))
          .toList();
      expect(result, ['a', 'b']);
    });

    test('handles empty stream', () async {
      const stream = Stream<String>.empty();
      final result = await stream.transform(const StringSplitter()).toList();
      expect(result, isEmpty);
    });

    test('handles stream with no separators', () async {
      final stream = Stream.fromIterable(['abc']);
      final result = await stream.transform(const StringSplitter()).toList();
      expect(result, ['abc']);
    });

    test('handles stream ending with separator', () async {
      final stream = Stream.fromIterable(['a\n']);
      final result = await stream.transform(const StringSplitter()).toList();
      expect(result, ['a']);
    });

    test('handles stream starting with separator', () async {
      final stream = Stream.fromIterable(['\na']);
      final result = await stream.transform(const StringSplitter()).toList();
      expect(result, ['', 'a']);
    });

    test('handles consecutive separators', () async {
      final stream = Stream.fromIterable(['a\n\nb']);
      final result = await stream.transform(const StringSplitter()).toList();
      expect(result, ['a', '', 'b']);
    });
  });

  group('Debounce', () {
    test('debounces events', () async {
      final controller = StreamController<int>();
      final result = <int>[];

      controller.stream
          .transform(const Debounce<int>(Duration(milliseconds: 100)))
          .listen(result.add);

      controller.add(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(2);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      controller.add(4);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await controller.close();

      expect(result, [3, 4]);
    });
  });

  group('Throttle', () {
    test('throttles events', () async {
      final controller = StreamController<int>();
      final result = <int>[];

      controller.stream
          .transform(const Throttle<int>(Duration(milliseconds: 100)))
          .listen(result.add);

      controller
        ..add(1) // Emitted
        ..add(2); // Ignored
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.add(3); // Ignored
      await Future<void>.delayed(
        const Duration(milliseconds: 60),
      ); // Total 110ms
      controller.add(4); // Emitted
      await Future<void>.delayed(const Duration(milliseconds: 110));
      await controller.close();

      expect(result, [1, 4]);
    });
  });

  group('BufferCount', () {
    test('buffers events by count', () async {
      final stream = Stream.fromIterable([1, 2, 3, 4, 5]);
      final result = await stream.transform(const BufferCount<int>(2)).toList();
      expect(result, [
        [1, 2],
        [3, 4],
        [5],
      ]);
    });
  });

  group('BufferTime', () {
    test('buffers events by time', () async {
      final controller = StreamController<int>();
      final result = <List<int>>[];

      controller.stream
          .transform(const BufferTime<int>(Duration(milliseconds: 100)))
          .listen(result.add);

      controller
        ..add(1)
        ..add(2);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      controller.add(3);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      await controller.close();

      expect(result, [
        [1, 2],
        [3],
      ]);
    });
  });
}
