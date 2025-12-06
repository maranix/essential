import 'package:essential_dart/essential_dart.dart';
import 'package:test/test.dart';

void main() {
  group('Interval', () {
    test('int interval basic properties', () {
      const interval = Interval(1, 10);
      expect(interval.start, 1);
      expect(interval.end, 10);
      expect(interval.length, 9);
      expect(interval.toString(), '[1, 10]');
      expect(interval.isEmpty, isFalse); // inferred via standard checks
    });

    test('Interval.checked valdiation', () {
      expect(() => Interval.checked(10, 1), throwsArgumentError);
      expect(Interval.checked(1, 1), isA<Interval<int>>());
    });

    test('contains value', () {
      const interval = Interval(5, 15);
      expect(interval.contains(5), isTrue);
      expect(interval.contains(15), isTrue);
      expect(interval.contains(10), isTrue);
      expect(interval.contains(4), isFalse);
      expect(interval.contains(16), isFalse);
    });

    test('containsInterval', () {
      const parent = Interval(0, 100);
      const child = Interval(10, 20);
      const overlapping = Interval(90, 110);
      const disjoint = Interval(200, 300);

      expect(parent.containsInterval(child), isTrue);
      expect(parent.containsInterval(parent), isTrue);
      expect(parent.containsInterval(overlapping), isFalse);
      expect(parent.containsInterval(disjoint), isFalse);
    });

    test('overlaps', () {
      const i1 = Interval(10, 20);
      const i2 = Interval(15, 25);
      const i3 = Interval(20, 30); // Single point overlap
      const i4 = Interval(30, 40); // No overlap

      expect(i1.overlaps(i2), isTrue);
      expect(i2.overlaps(i1), isTrue);
      expect(i1.overlaps(i3), isTrue); // [20] is shared
      expect(i1.overlaps(i4), isFalse);
    });

    test('intersection', () {
      const i1 = Interval(10, 20);
      const i2 = Interval(15, 25);
      const i3 = Interval(20, 30);
      const i4 = Interval(30, 40);

      expect(i1.intersection(i2), equals(const Interval(15, 20)));
      expect(i1.intersection(i3), equals(const Interval(20, 20)));
      expect(i1.intersection(i4), isNull);
    });

    test('span', () {
      const i1 = Interval(10, 20);
      const i2 = Interval(30, 40);

      expect(i1.span(i2), equals(const Interval(10, 40)));
    });

    test('double interval', () {
      const interval = Interval(1.5, 2.5);
      expect(interval.length, 1.0);
      expect(interval.contains(2), isTrue);
    });

    test('DateTime interval', () {
      final start = DateTime(2023);
      final end = DateTime(2023, 1, 2);
      final interval = Interval(start, end);

      expect(interval.duration, equals(const Duration(days: 1)));
      expect(interval.contains(start.add(const Duration(hours: 12))), isTrue);
    });

    test('String interval (lexicographical)', () {
      const interval = Interval('apple', 'cherry');
      expect(interval.contains('banana'), isTrue);
      expect(interval.contains('date'), isFalse);
      expect(interval.contains('ant'), isFalse);
    });

    test('equality and hashCode', () {
      const i1 = Interval(1, 5);
      const i2 = Interval(1, 5);
      const i3 = Interval(1, 6);

      expect(i1, equals(i2));
      expect(i1.hashCode, equals(i2.hashCode));
      expect(i1, isNot(equals(i3)));
    });

    test('compareTo', () {
      const i1 = Interval(1, 10);
      const i2 = Interval(1, 10);
      const i3 = Interval(2, 5);
      const i4 = Interval(1, 11);

      expect(i1.compareTo(i2), 0);
      expect(i1.compareTo(i3), -1); // 1 < 2
      expect(i3.compareTo(i1), 1);
      expect(i1.compareTo(i4), -1); // start equal, 10 < 11
    });
  });
}
