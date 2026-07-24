import 'package:sqflite/sqflite.dart';

class CommandContext {
  const CommandContext({
    required this.txn,
    required this.now,
  });

  final Transaction txn;
  final DateTime now;
}
