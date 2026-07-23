import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  DeviceService._();
  static final DeviceService instance = DeviceService._();

  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'device_unique_id';

  /// دریافت یا تولید شناسه‌ی دستگاه منحصر به فرد پایدار
  Future<String> _getOrCreateDeviceId() async {
    var id = await _storage.read(key: _deviceIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await _storage.write(key: _deviceIdKey, value: id);
    }
    return id;
  }

  /// ثبت دستگاه فعلی در دیتابیس
  Future<void> registerCurrentDevice() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final deviceId = await _getOrCreateDeviceId();
      final now = DateTime.now().millisecondsSinceEpoch;

      var deviceName = 'نامشخص';
      var platform = 'نامشخص';
      var model = 'نامشخص';

      final deviceInfo = DeviceInfoPlugin();

      if (kIsWeb) {
        platform = 'Web';
        model = 'مرورگر وب';
        deviceName = 'مرورگر وب';
      } else if (Platform.isAndroid) {
        platform = 'Android';
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
        model = androidInfo.product;
      } else if (Platform.isIOS) {
        platform = 'iOS';
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        model = iosInfo.utsname.machine;
      } else if (Platform.isWindows) {
        platform = 'Windows';
        final windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName;
        model = 'کامپیوتر شخصی ویندوز';
      } else if (Platform.isMacOS) {
        platform = 'macOS';
        final macInfo = await deviceInfo.macOsInfo;
        deviceName = macInfo.computerName;
        model = macInfo.model;
      } else if (Platform.isLinux) {
        platform = 'Linux';
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceName = linuxInfo.name;
        model = 'توزیع لینوکس';
      }

      // بررسی وجود دستگاه در دیتابیس
      final existing = await db.query(
        'devices',
        where: 'id = ?',
        whereArgs: [deviceId],
      );

      if (existing.isEmpty) {
        // ابتدا تمام دستگاه‌های دیگر را غیرفعال (isCurrent = 0) می‌کنیم
        await db.update('devices', {'isCurrent': 0});

        // ثبت دستگاه جدید
        await db.insert('devices', {
          'id': deviceId,
          'deviceName': deviceName,
          'platform': platform,
          'model': model,
          'firstSeenAt': now,
          'lastActiveAt': now,
          'isCurrent': 1,
        });
      } else {
        // بروزرسانی دستگاه فعلی و مطمئن شدن از اینکه isCurrent = 1 است
        await db.update('devices', {'isCurrent': 0});

        await db.update(
          'devices',
          {
            'deviceName': deviceName,
            'platform': platform,
            'model': model,
            'lastActiveAt': now,
            'isCurrent': 1,
          },
          where: 'id = ?',
          whereArgs: [deviceId],
        );
      }
    } catch (e) {
      debugPrint('Error registering device: $e');
    }
  }

  /// دریافت تمامی دستگاه‌های ثبت شده
  Future<List<Map<String, dynamic>>> getRegisteredDevices() async {
    try {
      final db = await DatabaseHelper.instance.database;
      return await db.query('devices', orderBy: 'lastActiveAt DESC');
    } catch (e) {
      debugPrint('Error getting registered devices: $e');
      return [];
    }
  }
}
