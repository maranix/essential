/// A generic immutable interval (range) between two values of type [T].
///
/// The interval is closed, meaning it includes both [start] and [end].
/// [T] must be [Comparable].
class Interval<T extends Comparable<dynamic>>
    implements Comparable<Interval<T>> {
  /// Creates a new [Interval] from [start] to [end].
  ///
  /// The interval represents the range `[start, end]`.
  ///
  /// Throws [ArgumentError] if [start] is greater than [end] when using [Interval.checked].
  /// This default constructor does not validate for `const` efficiency,
  /// but logically [start] should be less than or equal to [end].
  const Interval(this.start, this.end);

  /// Validates the interval and ensures [start] <= [end].
  ///
  /// Throws [ArgumentError] if [start] > [end].
  factory Interval.checked(T start, T end) {
    if (start.compareTo(end) > 0) {
      throw ArgumentError.value(
        end,
        'end',
        'The end value must be greater than or equal to the start value.',
      );
    }
    return Interval(start, end);
  }

  /// The start value of this interval (inclusive).
  final T start;

  /// The end value of this interval (inclusive).
  final T end;

  /// Returns `true` if this interval is empty (i.e., `start > end`).
  bool get isEmpty => start.compareTo(end) > 0;

  /// Returns `true` if this interval is not empty.
  bool get isNotEmpty => !isEmpty;

  /// Returns `true` if this interval contains [value].
  ///
  /// i.e., `start <= value <= end`.
  bool contains(T value) {
    return start.compareTo(value) <= 0 && end.compareTo(value) >= 0;
  }

  /// Returns `true` if this interval completely contains [other].
  ///
  /// i.e., `start <= other.start` and `other.end <= end`.
  bool containsInterval(Interval<T> other) {
    return start.compareTo(other.start) <= 0 && end.compareTo(other.end) >= 0;
  }

  /// Returns `true` if this interval overlaps with [other].
  ///
  /// i.e., `start <= other.end` and `other.start <= end`.
  bool overlaps(Interval<T> other) {
    return start.compareTo(other.end) <= 0 && other.start.compareTo(end) <= 0;
  }

  /// Returns the intersection of this interval and [other], or `null` if they do not intersect.
  ///
  /// The intersection is the largest interval contained in both this and [other].
  Interval<T>? intersection(Interval<T> other) {
    if (!overlaps(other)) {
      return null;
    }

    final newStart = start.compareTo(other.start) >= 0 ? start : other.start;
    final newEnd = end.compareTo(other.end) <= 0 ? end : other.end;

    return Interval(newStart, newEnd);
  }

  /// Returns the minimal interval that contains both this interval and [other].
  ///
  /// This is also known as the convex hull or span of the two intervals.
  /// If the intervals are disjoint, this returns the interval spanning from the
  /// minimum start to the maximum end, including the gap.
  Interval<T> span(Interval<T> other) {
    final newStart = start.compareTo(other.start) <= 0 ? start : other.start;
    final newEnd = end.compareTo(other.end) >= 0 ? end : other.end;

    return Interval(newStart, newEnd);
  }

  @override
  int compareTo(Interval<T> other) {
    final startComparison = start.compareTo(other.start);
    if (startComparison != 0) {
      return startComparison;
    }
    return end.compareTo(other.end);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Interval<T> && start == other.start && end == other.end;
  }

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end]';
}

/// Extension methods for [Interval]s of [num] (int, double).
extension NumIntervalExtension on Interval<num> {
  /// Returns the length of the interval (`end - start`).
  num get length => end - start;
}

/// Extension methods for [Interval]s of [DateTime].
extension DateTimeIntervalExtension on Interval<DateTime> {
  /// Returns the duration of the interval (`end - start`).
  Duration get duration => end.difference(start);
}
