import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/features/calendar/presentation/utils/calendar_tokens.dart';

class AlarmDiagnosticsSheet extends StatefulWidget {
  const AlarmDiagnosticsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AlarmDiagnosticsSheet(),
    );
  }

  @override
  State<AlarmDiagnosticsSheet> createState() => _AlarmDiagnosticsSheetState();
}

class _AlarmDiagnosticsSheetState extends State<AlarmDiagnosticsSheet> {
  bool _isLoading = true;
  bool _hasExactAlarmPermission = false;
  int _pendingCount = 0;
  int _nativeFailureCount = 0;
  int _missedCount = 0;
  List<Map<String, dynamic>> _discrepancies = [];

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _isLoading = true);
    final hasPerm = await sl<AlarmPlatform>().checkExactAlarmPermission();
    final db = await DatabaseHelper.instance.database;

    final pending = await db.query(
      'pending_reminders',
      where: "state = 'unknown' OR state = 'delayed'",
    );

    final missed = await db.query(
      'pending_reminders',
      where: "state = 'missed'",
    );

    final settings = await db.query(
      'app_settings',
      where: "key = 'alarm_native_failure_count'",
    );
    final failures = settings.isNotEmpty ? (int.tryParse(settings.first['value'] as String) ?? 0) : 0;

    final unScheduledList = await db.query(
      'pending_reminders',
      where: "(state = 'unknown' OR state = 'delayed') AND (nativeScheduled IS NULL OR nativeScheduled = 0)",
    );

    if (mounted) {
      setState(() {
        _hasExactAlarmPermission = hasPerm;
        _pendingCount = pending.length;
        _missedCount = missed.length;
        _nativeFailureCount = failures;
        _discrepancies = unScheduledList;
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerTestAlarm() async {
    await RitmoExecutionKernel.instance.execute(const TestAlarmCommand(secondsFromNow: 5));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('آلارم تست تا ۵ ثانیه دیگر فعال می‌شود (گوشی را قفل کنید)'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _repairSyncAlarms() async {
    await AlarmSchedulerService.scheduleNextAlarms();
    await _runDiagnostics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('همگام‌سازی و بازنویسی آلارم‌ها با موفقیت انجام شد'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'عیب‌یابی و سلامت آلارم‌ها',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              _buildStatusCard(
                title: 'مجوز آلارم دقیق (Exact Alarm)',
                status: _hasExactAlarmPermission ? 'فعال' : 'غیرفعال (نیازمند مجوز)',
                isOk: _hasExactAlarmPermission,
                onTap: _hasExactAlarmPermission
                    ? null
                    : () => sl<AlarmPlatform>().requestExactAlarmPermission(),
              ),
              const SizedBox(height: 10),
              _buildStatusCard(
                title: 'یادآورهای در انتظار (Pending)',
                status: '$_pendingCount عدد',
                isOk: true,
              ),
              const SizedBox(height: 10),
              _buildStatusCard(
                title: 'خطاهای ثبت نیتیو (Native Failures)',
                status: '$_nativeFailureCount خطا',
                isOk: _nativeFailureCount == 0,
              ),
              const SizedBox(height: 10),
              _buildStatusCard(
                title: 'ناهمخوانی ثبت نیتیو',
                status: _discrepancies.isEmpty ? 'هیچ' : '${_discrepancies.length} مورد ثبت نشده',
                isOk: _discrepancies.isEmpty,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _triggerTestAlarm,
                icon: const Icon(Icons.alarm_on),
                label: const Text('تست آلارم ۵ ثانیه‌ای (صفحه قفل)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _repairSyncAlarms,
                icon: const Icon(Icons.build),
                label: const Text('بازسازی و همگام‌سازی مجدد آلارم‌ها'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String status,
    required bool isOk,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.withOpacity(0.08) : Colors.amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOk ? Colors.green.withOpacity(0.3) : Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isOk ? Colors.green.shade700 : Colors.amber.shade800,
            ),
          ),
          if (onTap != null)
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}
