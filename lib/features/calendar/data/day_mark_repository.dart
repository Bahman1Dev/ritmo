import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

enum DayMarkKind { normal, rest, travel, special }

class DayMark {
  const DayMark({
    required this.dateStr,
    required this.kind,
    this.note,
  });

  final String dateStr;
  final DayMarkKind kind;
  final String? note;

  static DayMarkKind parseKind(String? val) {
    switch (val?.toUpperCase()) {
      case 'REST':    return DayMarkKind.rest;
      case 'TRAVEL':  return DayMarkKind.travel;
      case 'SPECIAL': return DayMarkKind.special;
      default:        return DayMarkKind.normal;
    }
  }

  static String codeOf(DayMarkKind k) {
    switch (k) {
      case DayMarkKind.rest:    return 'REST';
      case DayMarkKind.travel:  return 'TRAVEL';
      case DayMarkKind.special: return 'SPECIAL';
      case DayMarkKind.normal:  return 'NORMAL';
    }
  }
}

/// K43 — Repository for managing Day Marks (REST, TRAVEL, SPECIAL, NORMAL)
/// in `day_marks` table (v83 migration).
class DayMarkRepository {
  DayMarkRepository._();
  static final DayMarkRepository instance = DayMarkRepository._();

  Future<DayMark?> getMark(String dateStr) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('day_marks', where: 'date = ?', whereArgs: [dateStr], limit: 1);
      if (rows.isEmpty) return null;
      final row = rows.first;
      return DayMark(
        dateStr: dateStr,
        kind: DayMark.parseKind(row['kind']?.toString()),
        note: row['note']?.toString(),
      );
    } catch (e) {
      debugPrint('[DayMarkRepository] getMark error: $e');
      return null;
    }
  }

  Future<void> setMark(String dateStr, DayMarkKind kind, {String? note}) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final kindCode = DayMark.codeOf(kind);

      if (kind == DayMarkKind.normal) {
        await db.delete('day_marks', where: 'date = ?', whereArgs: [dateStr]);
      } else {
        await db.insert(
          'day_marks',
          {
            'date': dateStr,
            'kind': kindCode,
            'note': note,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('[DayMarkRepository] setMark error: $e');
    }
  }
}
