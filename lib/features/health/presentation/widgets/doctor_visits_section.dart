import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/native_bridge.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

class DoctorVisitsSection extends StatefulWidget {
  const DoctorVisitsSection({
    super.key,
  });

  @override
  State<DoctorVisitsSection> createState() => _DoctorVisitsSectionState();
}

class _DoctorVisitsSectionState extends State<DoctorVisitsSection> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DoctorVisit> _upcomingVisits = [];
  List<DoctorVisit> _pastVisits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  String _formatJalaliDateTime(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final j = Jalali.fromDateTime(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return _toPersianDigits('${j.year}/${j.month}/${j.day} ساعت $hour:$minute');
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final results = await db.query('doctor_visits', orderBy: 'visitDateTime ASC');
      
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final upcoming = <DoctorVisit>[];
      final past = <DoctorVisit>[];

      for (final map in results) {
        final visit = DoctorVisit.fromMap(map);
        if (visit.visitDateTime > nowMs && visit.status == 'UPCOMING') {
          upcoming.add(visit);
        } else {
          past.add(visit);
        }
      }

      // Sort past visits descending (most recent first)
      past.sort((a, b) => b.visitDateTime.compareTo(a.visitDateTime));

      if (mounted) {
        setState(() {
          _upcomingVisits = upcoming;
          _pastVisits = past;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading doctor visits: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _saveVisit(DoctorVisit visit) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'doctor_visits',
        visit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Handle alarm scheduling — registered in pending_reminders so it survives
      // device reboots (BootReceiver reads from active_reminders_snapshot which
      // is built by SnapshotSyncService from pending_reminders).
      final alarmId = 'visit_${visit.id}';
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (visit.status == 'UPCOMING') {
        final reminderTime = visit.visitDateTime - (visit.reminderBefore * 60 * 1000);
        if (reminderTime > nowMs) {
          // Upsert into pending_reminders so the snapshot + zone check can work.
          // routineId is NULL intentionally (doctor visits are not in routines table).
          // SQLite allows multiple NULLs in a UNIQUE index so no conflict occurs.
          await db.insert(
            'pending_reminders',
            {
              'id': alarmId,
              'routineId': null,
              'scheduleId': null,
              'originalTime': reminderTime,
              'scheduledTime': reminderTime,
              'state': 'unknown',
              'deferCount': 0,
              'createdAt': nowMs,
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await NativeBridge.scheduleExactAlarm(
            id: alarmId,
            timeMsUTC: reminderTime,
            title: 'نوبت پزشک: ${visit.doctorName}',
            isEssential: true,
          );
          // Sync snapshot so BootReceiver can restore this alarm after reboot
          await SnapshotSyncService.syncAll();
        } else {
          await NativeBridge.cancelAlarm(alarmId);
          await db.delete('pending_reminders', where: 'id = ?', whereArgs: [alarmId]);
        }
      } else {
        await NativeBridge.cancelAlarm(alarmId);
        await db.delete('pending_reminders', where: 'id = ?', whereArgs: [alarmId]);
      }

      _loadData();
    } catch (e) {
      debugPrint('Error saving visit: $e');
    }
  }

  Future<void> _deleteVisit(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('doctor_visits', where: 'id = ?', whereArgs: [id]);
      await NativeBridge.cancelAlarm('visit_$id');
      // Remove from pending_reminders so snapshot stays clean
      await db.delete('pending_reminders', where: 'id = ?', whereArgs: ['visit_$id']);
      await SnapshotSyncService.syncAll();
      _loadData();
    } catch (e) {
      debugPrint('Error deleting visit: $e');
    }
  }

  Future<void> _updateVisitStatus(DoctorVisit visit, String newStatus) async {
    final updated = DoctorVisit(
      id: visit.id,
      doctorName: visit.doctorName,
      specialty: visit.specialty,
      clinicName: visit.clinicName,
      clinicAddress: visit.clinicAddress,
      clinicPhone: visit.clinicPhone,
      visitDateTime: visit.visitDateTime,
      visitType: visit.visitType,
      status: newStatus,
      reason: visit.reason,
      doctorNotes: visit.doctorNotes,
      userNotes: visit.userNotes,
      followUpDate: visit.followUpDate,
      reminderBefore: visit.reminderBefore,
      attachmentPath: visit.attachmentPath,
      createdAt: visit.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _saveVisit(updated);
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return;
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('امکان برقراری تماس با شماره $phone وجود ندارد.'),
            backgroundColor: context.colors.medicalRed,
          ),
        );
      }
    }
  }

  Future<void> _openMap(String? address) async {
    if (address == null || address.trim().isEmpty) return;
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('امکان باز کردن نقشه وجود ندارد.')),
        );
      }
    }
  }

  void _showAttachmentViewer(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(32),
                    color: context.colors.card,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, color: context.colors.medicalRed, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'خطا در بارگذاری تصویر نسخه',
                          style: TextStyle(fontFamily: 'Vazirmatn', color: context.colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () => Navigator.pop(context),
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                child: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditSheet({DoctorVisit? visit}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoTheme.glassCardLight(
          child: _DoctorVisitForm(
            visit: visit,
            onSave: (newVisit) {
              _saveVisit(newVisit);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;



    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.doctorVisits,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddEditSheet,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(l10n.doctorVisitsAddTitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            indicatorColor: colors.primary,
            labelColor: colors.textPrimary,
            unselectedLabelColor: colors.textSecondary,
            tabs: [
              Tab(text: l10n.doctorVisitsTabUpcoming),
              Tab(text: l10n.doctorVisitsTabPast),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 350,
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildVisitsList(_upcomingVisits, isPast: false),
                      _buildVisitsList(_pastVisits, isPast: true),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsList(List<DoctorVisit> visits, {required bool isPast}) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (visits.isEmpty) {
      return Center(
        child: Text(
          isPast ? l10n.doctorVisitsNoPast : l10n.doctorVisitsNoUpcoming,
          style: TextStyle(color: colors.textSecondary, fontFamily: 'Vazirmatn'),
        ),
      );
    }

    return ListView.builder(
      itemCount: visits.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final visit = visits[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            visit.doctorName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (visit.specialty != null && visit.specialty!.isNotEmpty)
                            Text(
                              visit.specialty!,
                              style: TextStyle(fontSize: 12, color: colors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    _buildVisitTypeBadge(visit.visitType),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: colors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _formatJalaliDateTime(visit.visitDateTime),
                      style: TextStyle(fontSize: 13, color: colors.textPrimary),
                    ),
                  ],
                ),
                if (visit.clinicName != null && visit.clinicName!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.business, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        visit.clinicName!,
                        style: TextStyle(fontSize: 13, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ],
                if (visit.clinicAddress != null && visit.clinicAddress!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _openMap(visit.clinicAddress),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: colors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            visit.clinicAddress!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.primary,
                              decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (visit.clinicPhone != null && visit.clinicPhone!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: () => _callPhone(visit.clinicPhone),
                    child: Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: colors.success),
                        const SizedBox(width: 6),
                        Text(
                          _toPersianDigits(visit.clinicPhone!),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (visit.reason != null && visit.reason!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'علت مراجعه: ${visit.reason}',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
                if (visit.doctorNotes != null && visit.doctorNotes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'توصیه پزشک: ${visit.doctorNotes}',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
                if (visit.attachmentPath != null && visit.attachmentPath!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => _showAttachmentViewer(visit.attachmentPath!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.image, size: 16, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'مشاهده نسخه / مدرک ثبت شده',
                            style: TextStyle(fontSize: 12, color: colors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, size: 18, color: colors.primary),
                      onPressed: () => _showAddEditSheet(visit: visit),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: colors.medicalRed),
                      onPressed: () => _confirmDelete(visit.id),
                    ),
                    if (!isPast) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _updateVisitStatus(visit, 'COMPLETED'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.success,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('انجام شد', style: TextStyle(fontSize: 12, fontFamily: 'Vazirmatn')),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitTypeBadge(String type) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    var label = '';
    var color = colors.primary;

    switch (type) {
      case 'ONLINE':
        label = l10n.doctorVisitsTypeOnline;
        color = colors.warning;
      case 'TELEPHONE':
        label = l10n.doctorVisitsTypeTelephone;
        color = colors.success;
      case 'IN_PERSON':
      default:
        label = l10n.doctorVisitsTypeInPerson;
        color = colors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            l10n.doctorVisitsDelete,
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
          ),
          content: Text(
            l10n.doctorVisitsDeleteConfirm,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.doctorVisitsCancel, style: const TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteVisit(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.medicalRed),
              child: Text(
                l10n.doctorVisitsConfirm,
                style: const TextStyle(color: Colors.white, fontFamily: 'Vazirmatn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorVisitForm extends StatefulWidget {

  const _DoctorVisitForm({this.visit, required this.onSave});
  final DoctorVisit? visit;
  final Function(DoctorVisit) onSave;

  @override
  State<_DoctorVisitForm> createState() => _DoctorVisitFormState();
}

class _DoctorVisitFormState extends State<_DoctorVisitForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _doctorNameController;
  late TextEditingController _specialtyController;
  late TextEditingController _clinicNameController;
  late TextEditingController _clinicAddressController;
  late TextEditingController _clinicPhoneController;
  late TextEditingController _reasonController;
  late TextEditingController _notesController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String _visitType = 'IN_PERSON';
  int _reminderBefore = 60;
  String? _attachmentPath;

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    _doctorNameController = TextEditingController(text: v?.doctorName ?? '');
    _specialtyController = TextEditingController(text: v?.specialty ?? '');
    _clinicNameController = TextEditingController(text: v?.clinicName ?? '');
    _clinicAddressController = TextEditingController(text: v?.clinicAddress ?? '');
    _clinicPhoneController = TextEditingController(text: v?.clinicPhone ?? '');
    _reasonController = TextEditingController(text: v?.reason ?? '');
    _notesController = TextEditingController(text: v?.doctorNotes ?? '');

    if (v != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(v.visitDateTime);
      _selectedDate = DateTime(dt.year, dt.month, dt.day);
      _selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      _visitType = v.visitType;
      _reminderBefore = v.reminderBefore;
      _attachmentPath = v.attachmentPath;
    } else {
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
    }
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    _specialtyController.dispose();
    _clinicNameController.dispose();
    _clinicAddressController.dispose();
    _clinicPhoneController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _toPersianDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    var result = input;
    for (var i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], persian[i]);
    }
    return result;
  }

  String _normalizeDigits(String input) {
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    var result = input;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]).replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  Future<void> _pickDate() async {
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(_selectedDate),
      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365))),
      lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 365 * 2))),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked.toDateTime();
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primary,
              onPrimary: Colors.white,
              surface: context.colors.card,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'visit_attachment_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedFile = await File(picked.path).copy(path_utils.join(appDir.path, fileName));
        setState(() {
          _attachmentPath = savedFile.path;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    ).millisecondsSinceEpoch;

    final cleanPhone = _normalizeDigits(_clinicPhoneController.text.trim());
    final now = DateTime.now().millisecondsSinceEpoch;

    final visit = DoctorVisit(
      id: widget.visit?.id ?? 'visit_${DateTime.now().millisecondsSinceEpoch}',
      doctorName: _doctorNameController.text.trim(),
      specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
      clinicName: _clinicNameController.text.trim().isEmpty ? null : _clinicNameController.text.trim(),
      clinicAddress: _clinicAddressController.text.trim().isEmpty ? null : _clinicAddressController.text.trim(),
      clinicPhone: cleanPhone.isEmpty ? null : cleanPhone,
      visitDateTime: finalDateTime,
      visitType: _visitType,
      status: widget.visit?.status ?? 'UPCOMING',
      reason: _reasonController.text.trim().isEmpty ? null : _reasonController.text.trim(),
      doctorNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      userNotes: widget.visit?.userNotes,
      followUpDate: widget.visit?.followUpDate,
      reminderBefore: _reminderBefore,
      attachmentPath: _attachmentPath,
      createdAt: widget.visit?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(visit);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;
    final mediaQuery = MediaQuery.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.visit == null ? l10n.doctorVisitsAddTitle : l10n.doctorVisitsEditTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _doctorNameController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsDoctorName, icon: Icons.person),
                validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً نام پزشک را وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _specialtyController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsSpecialty, icon: Icons.star_border),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _visitType,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsType, icon: Icons.category),
                dropdownColor: colors.card,
                items: [
                  DropdownMenuItem(value: 'IN_PERSON', child: Text(l10n.doctorVisitsTypeInPerson)),
                  DropdownMenuItem(value: 'ONLINE', child: Text(l10n.doctorVisitsTypeOnline)),
                  DropdownMenuItem(value: 'TELEPHONE', child: Text(l10n.doctorVisitsTypeTelephone)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _visitType = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(Icons.calendar_today, color: colors.primary, size: 18),
                      label: Text(
                        _toPersianDigits(
                          '${Jalali.fromDateTime(_selectedDate).year}/${Jalali.fromDateTime(_selectedDate).month}/${Jalali.fromDateTime(_selectedDate).day}',
                        ),
                        style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: Icon(Icons.access_time, color: colors.primary, size: 18),
                      label: Text(
                        _toPersianDigits('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                        style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clinicNameController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsClinicName, icon: Icons.business),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clinicAddressController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsClinicAddress, icon: Icons.location_on),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _clinicPhoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsClinicPhone, icon: Icons.phone),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _reminderBefore,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsReminder, icon: Icons.notifications),
                dropdownColor: colors.card,
                items: [
                  DropdownMenuItem(value: 0, child: Text(l10n.doctorVisitsReminderNone)),
                  DropdownMenuItem(value: 15, child: Text(l10n.doctorVisitsReminder15m)),
                  DropdownMenuItem(value: 30, child: Text(l10n.doctorVisitsReminder30m)),
                  DropdownMenuItem(value: 60, child: Text(l10n.doctorVisitsReminder1h)),
                  DropdownMenuItem(value: 120, child: Text(l10n.doctorVisitsReminder2h)),
                  DropdownMenuItem(value: 1440, child: Text(l10n.doctorVisitsReminder1d)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _reminderBefore = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsReason, icon: Icons.question_answer),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.doctorVisitsNotes, icon: Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.add_photo_alternate, color: colors.primary),
                      label: Text(
                        _attachmentPath == null ? l10n.doctorVisitsAddAttachment : 'تغییر نسخه / سند',
                        style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_attachmentPath != null) ...[
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          _attachmentPath = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border: Border.all(color: colors.medicalRed),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.delete_forever, color: colors.medicalRed),
                      ),
                    ),
                  ],
                ],
              ),
              if (_attachmentPath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_attachmentPath!),
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  l10n.doctorVisitsSave,
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
