import 'package:sqflite/sqflite.dart';

enum ParamType {
  text,
  integer,
  decimal,
  boolean,
  isoDate,
  isoDateTime,
  timeOfDay,
  enumeration,
  idRef,
  list,
}

class ParamSpec {
  const ParamSpec({
    required this.type,
    required this.labelFa,
    required this.required,
    this.min,
    this.max,
    this.allowed,
    this.refTable,
    this.itemType,
    this.exampleFa,
  });

  final ParamType type;
  final String labelFa;
  final bool required;
  final num? min;
  final num? max;
  final List<String>? allowed;
  final String? refTable;
  final ParamType? itemType;
  final String? exampleFa;

  Future<String?> validate(Object? value, DatabaseExecutor txn) async {
    if (required && (value == null || (value is String && value.trim().isEmpty))) {
      return '$labelFa را مشخص کنید';
    }

    if (value == null) return null;

    switch (type) {
      case ParamType.text:
        if (value is! String) return '$labelFa باید به صورت متن باشد';
        break;

      case ParamType.integer:
        int? intVal;
        if (value is int) {
          intVal = value;
        } else if (value is String) {
          intVal = int.tryParse(value);
        }
        if (intVal == null) return '$labelFa باید یک عدد صحیح باشد';
        if (min != null && intVal < min!) return '$labelFa باید حداقل $min باشد';
        if (max != null && intVal > max!) return '$labelFa باید حداکثر $max باشد';
        break;

      case ParamType.decimal:
        double? doubleVal;
        if (value is double) {
          doubleVal = value;
        } else if (value is int) {
          doubleVal = value.toDouble();
        } else if (value is String) {
          doubleVal = double.tryParse(value);
        }
        if (doubleVal == null) return '$labelFa باید یک عدد اعشاری باشد';
        if (min != null && doubleVal < min!) return '$labelFa باید حداقل $min باشد';
        if (max != null && doubleVal > max!) return '$labelFa باید حداکثر $max باشد';
        break;

      case ParamType.boolean:
        if (value is! bool) {
          final str = value.toString().toLowerCase();
          if (str != 'true' && str != 'false' && str != '1' && str != '0') {
            return '$labelFa باید بله یا خیر باشد';
          }
        }
        break;

      case ParamType.isoDate:
        if (value is! String || DateTime.tryParse(value) == null) {
          return 'تاریخ $labelFa معتبر نیست';
        }
        break;

      case ParamType.isoDateTime:
        if (value is! String || DateTime.tryParse(value) == null) {
          return 'زمان و تاریخ $labelFa معتبر نیست';
        }
        break;

      case ParamType.timeOfDay:
        if (value is! String) return 'فرمت ساعت $labelFa معتبر نیست';
        final match = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$').hasMatch(value);
        if (!match) return 'ساعت $labelFa معتبر نیست (باید به فرمت HH:mm باشد)';
        break;

      case ParamType.enumeration:
        if (allowed != null && !allowed!.contains(value.toString())) {
          return 'مقدار $labelFa پشتیبانی نمی‌شود';
        }
        break;

      case ParamType.idRef:
        if (refTable != null) {
          final idStr = value.toString();
          final List<Map<String, dynamic>> rows = await txn.query(
            refTable!,
            where: 'id = ?',
            whereArgs: [idStr],
            limit: 1,
          );
          if (rows.isEmpty) {
            return 'موردی که در $labelFa اشاره کردید پیدا نشد';
          }
        }
        break;

      case ParamType.list:
        if (value is! List) return '$labelFa باید به صورت لیست باشد';
        if (itemType != null) {
          for (final item in value) {
            final dummySpec = ParamSpec(
              type: itemType!,
              labelFa: '$labelFa (آیتم)',
              required: true,
              refTable: refTable,
              allowed: allowed,
            );
            final err = await dummySpec.validate(item, txn);
            if (err != null) return err;
          }
        }
        break;
    }

    return null;
  }

  Map<String, dynamic> toToolSchema() {
    String jsonType = 'string';
    List<String>? enumValues = allowed;

    switch (type) {
      case ParamType.text:
      case ParamType.isoDate:
      case ParamType.isoDateTime:
      case ParamType.timeOfDay:
      case ParamType.idRef:
        jsonType = 'string';
        break;
      case ParamType.integer:
        jsonType = 'integer';
        break;
      case ParamType.decimal:
        jsonType = 'number';
        break;
      case ParamType.boolean:
        jsonType = 'boolean';
        break;
      case ParamType.enumeration:
        jsonType = 'string';
        break;
      case ParamType.list:
        jsonType = 'array';
        break;
    }

    final schema = <String, dynamic>{
      'type': jsonType,
      'description': labelFa + (exampleFa != null ? ' (مثال: $exampleFa)' : ''),
    };

    if (enumValues != null && enumValues.isNotEmpty) {
      schema['enum'] = enumValues;
    }

    if (type == ParamType.list && itemType != null) {
      final dummySpec = ParamSpec(
        type: itemType!,
        labelFa: '$labelFa (آیتم)',
        required: true,
        allowed: allowed,
        refTable: refTable,
      );
      schema['items'] = dummySpec.toToolSchema();
    }

    return schema;
  }
}
