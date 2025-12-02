import 'dart:async';

typedef SyncComputation<T> = T Function();

typedef AsyncComputation<T> = Future<T> Function();

typedef Computation<T> = FutureOr<T> Function();
