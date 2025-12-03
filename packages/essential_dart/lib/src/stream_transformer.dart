import 'dart:async';

const _kNewLineCharacter = '\n';

/// A [StreamTransformer] that splits a [Stream] of [String]s into lines.
///
/// This transformer is similar to [LineSplitter] but it allows specifying a
/// custom [separator] which can be a single character or a multi-character
/// string.
///
/// Example:
/// ```dart
/// Stream.fromIterable(['Hello,', 'World!'])
///   .transform(StringSplitter(','))
///   .listen(print); // Prints 'Hello' and 'World!'
/// ```
final class StringSplitter extends StreamTransformerBase<String, String> {
  /// Creates a new [StringSplitter] with the given [separator].
  ///
  /// The [separator] defaults to the newline character.
  const StringSplitter([this.separator = _kNewLineCharacter]);
  final String separator;

  @override
  Stream<String> bind(Stream<String> stream) {
    return Stream.eventTransformed(
      stream,
      (sink) => _StringSplitterSink(sink, separator),
    );
  }
}

final class _StringSplitterSink implements EventSink<String> {
  _StringSplitterSink(this._sink, this.separator);

  final EventSink<String> _sink;
  final String separator;

  String _buffer = '';

  @override
  void add(String event) {
    if (event.isEmpty) {
      return;
    }

    final data = _buffer + event;
    var index = 0;

    while (true) {
      final nextIndex = data.indexOf(separator, index);
      if (nextIndex == -1) {
        break;
      }

      _sink.add(data.substring(index, nextIndex));
      index = nextIndex + separator.length;
    }

    _buffer = data.substring(index);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_buffer.isNotEmpty) {
      _sink.add(_buffer);
      _buffer = '';
    }
    _sink.close();
  }
}

/// A [StreamTransformer] that filters out items emitted by the source [Stream]
/// that are followed by another item within a specified [duration].
///
/// Example:
/// ```dart
/// Stream.fromIterable([1, 2, 3])
///   .transform(Debounce(Duration(milliseconds: 100)))
///   .listen(print); // Prints 3
/// ```
final class Debounce<T> extends StreamTransformerBase<T, T> {
  /// Creates a new [Debounce] transformer with the given [duration].
  const Debounce(this.duration);
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    return Stream.eventTransformed(
      stream,
      (sink) => _DebounceSink(sink, duration),
    );
  }
}

final class _DebounceSink<T> implements EventSink<T> {
  _DebounceSink(this._sink, this.duration);

  final EventSink<T> _sink;
  final Duration duration;
  Timer? _timer;

  @override
  void add(T event) {
    _timer?.cancel();
    _timer = Timer(duration, () => _sink.add(event));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _timer?.cancel();
    _sink.close();
  }
}

/// A [StreamTransformer] that emits the first item emitted by the source [Stream],
/// then ignores subsequent items for a specified [duration].
///
/// Example:
/// ```dart
/// Stream.periodic(Duration(milliseconds: 100), (i) => i)
///   .transform(Throttle(Duration(milliseconds: 250)))
///   .listen(print); // Prints 0, 3, 6...
/// ```
final class Throttle<T> extends StreamTransformerBase<T, T> {
  /// Creates a new [Throttle] transformer with the given [duration].
  const Throttle(this.duration);
  final Duration duration;

  @override
  Stream<T> bind(Stream<T> stream) {
    return Stream.eventTransformed(
      stream,
      (sink) => _ThrottleSink(sink, duration),
    );
  }
}

final class _ThrottleSink<T> implements EventSink<T> {
  _ThrottleSink(this._sink, this.duration);

  final EventSink<T> _sink;
  final Duration duration;
  Timer? _timer;

  @override
  void add(T event) {
    if (_timer != null) {
      return;
    }

    _sink.add(event);
    _timer = Timer(duration, () {
      _timer = null;
    });
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    _timer?.cancel();
    _sink.close();
  }
}

/// A [StreamTransformer] that collects items emitted by the source [Stream]
/// into a [List] of size [count].
///
/// Example:
/// ```dart
/// Stream.fromIterable([1, 2, 3, 4])
///   .transform(BufferCount(2))
///   .listen(print); // Prints [1, 2] and [3, 4]
/// ```
final class BufferCount<T> extends StreamTransformerBase<T, List<T>> {
  /// Creates a new [BufferCount] transformer with the given [count].
  const BufferCount(this.count);
  final int count;

  @override
  Stream<List<T>> bind(Stream<T> stream) {
    return Stream.eventTransformed(
      stream,
      (sink) => _BufferCountSink<T>(sink, count),
    );
  }
}

final class _BufferCountSink<T> implements EventSink<T> {
  _BufferCountSink(this._sink, this.count);

  final EventSink<List<T>> _sink;
  final int count;
  final List<T> _buffer = [];

  @override
  void add(T event) {
    _buffer.add(event);
    if (_buffer.length >= count) {
      _sink.add(List<T>.of(_buffer));
      _buffer.clear();
    }
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _sink.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_buffer.isNotEmpty) {
      _sink.add(List<T>.of(_buffer));
      _buffer.clear();
    }
    _sink.close();
  }
}

/// A [StreamTransformer] that collects items emitted by the source [Stream]
/// into a [List] and emits them periodically every [duration].
///
/// Example:
/// ```dart
/// Stream.periodic(Duration(milliseconds: 100), (i) => i)
///   .transform(BufferTime(Duration(milliseconds: 250)))
///   .listen(print); // Prints [0, 1], [2, 3, 4]...
/// ```
final class BufferTime<T> extends StreamTransformerBase<T, List<T>> {
  /// Creates a new [BufferTime] transformer with the given [duration].
  const BufferTime(this.duration);
  final Duration duration;

  @override
  Stream<List<T>> bind(Stream<T> stream) {
    final controller = StreamController<List<T>>(sync: true);
    Timer? timer;
    final buffer = <T>[];

    void emit() {
      if (buffer.isNotEmpty) {
        controller.add(List<T>.of(buffer));
        buffer.clear();
      }
    }

    controller.onListen = () {
      timer = Timer.periodic(duration, (_) => emit());

      final subscription = stream.listen(
        buffer.add,
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          emit();
          controller.close();
        },
      );

      controller.onCancel = () {
        timer?.cancel();
        subscription.cancel();
      };
    };

    return controller.stream;
  }
}
