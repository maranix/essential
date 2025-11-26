// ignore_for_file: avoid_print

import 'package:essential_dart/essential_dart.dart';

void main() async {
  final memoizer = Memoizer<int>(computation: () => 42);
  final result = await memoizer.result;

  print(result);

  print(await memoizer.runComputation(() => 45)); // 42
}
