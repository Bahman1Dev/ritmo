import 'package:flutter/foundation.dart';

/// An abstract command that can be executed and undone.
abstract class UndoableCommand {
  Future<void> execute();
  Future<void> undo();
  String get description;
}

/// A lightweight stack managing undoable operations for calendar and domain actions.
class CommandStack {
  CommandStack._();
  static final CommandStack instance = CommandStack._();

  final List<UndoableCommand> _undoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;

  void push(UndoableCommand command) {
    _undoStack.add(command);
  }

  Future<bool> undoLast() async {
    if (_undoStack.isEmpty) return false;
    final command = _undoStack.removeLast();
    try {
      await command.undo();
      return true;
    } catch (e) {
      debugPrint('[CommandStack] Error undoing command "${command.description}": $e');
      return false;
    }
  }

  void clear() {
    _undoStack.clear();
  }
}
