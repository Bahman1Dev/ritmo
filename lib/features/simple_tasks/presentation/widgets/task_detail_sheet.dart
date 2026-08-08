import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';
import 'package:ritmo/features/simple_tasks/data/simple_task_repository.dart';
import 'package:ritmo/features/simple_tasks/data/task_attachment_repository.dart';
import 'package:ritmo/features/simple_tasks/data/task_step_repository.dart';
import 'package:ritmo/features/simple_tasks/domain/simple_task.dart';
import 'package:ritmo/features/simple_tasks/domain/task_attachment.dart';
import 'package:ritmo/features/simple_tasks/domain/task_step.dart';
import 'package:ritmo/features/simple_tasks/presentation/widgets/task_step_list.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TaskDetailSheet extends StatefulWidget {
  const TaskDetailSheet({
    super.key,
    required this.task,
    required this.onTaskUpdated,
    required this.onTaskDeleted,
  });

  final SimpleTask task;
  final VoidCallback onTaskUpdated;
  final VoidCallback onTaskDeleted;

  static Future<void> show(
    BuildContext context, {
    required SimpleTask task,
    required VoidCallback onTaskUpdated,
    required VoidCallback onTaskDeleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TaskDetailSheet(
        task: task,
        onTaskUpdated: onTaskUpdated,
        onTaskDeleted: onTaskDeleted,
      ),
    );
  }

  @override
  State<TaskDetailSheet> createState() => _TaskDetailSheetState();
}

class _TaskDetailSheetState extends State<TaskDetailSheet> {
  late SimpleTask _task;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  List<TaskStep> _steps = [];
  List<TaskAttachment> _attachments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _titleController = TextEditingController(text: _task.title);
    _noteController = TextEditingController(text: _task.note ?? '');
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final steps = await TaskStepRepository.instance.forTask(_task.id);
      final attachments = await TaskAttachmentRepository.instance.forTask(_task.id);
      if (mounted) {
        setState(() {
          _steps = steps;
          _attachments = attachments;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _playSoundIfEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final soundEnabled = prefs.getString('tasks_completion_sound_enabled') == 'true';
    if (soundEnabled) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _toggleDone() async {
    RitmoHaptics.tap();
    final newDone = !_task.isDone;
    if (newDone) {
      await _playSoundIfEnabled();
    }
    await SimpleTaskRepository.instance.setDone(_task.id, done: newDone);
    setState(() {
      _task = _task.copyWith(isDone: newDone, doneAt: newDone ? DateTime.now() : null);
    });
    widget.onTaskUpdated();
  }

  Future<void> _toggleStar() async {
    RitmoHaptics.tap();
    final newStar = !_task.isImportant;
    await SimpleTaskRepository.instance.setImportant(_task.id, important: newStar);
    setState(() {
      _task = _task.copyWith(
        isImportant: newStar,
        importantAt: newStar ? DateTime.now() : null,
        clearImportantAt: !newStar,
      );
    });
    widget.onTaskUpdated();
  }

  Future<void> _saveTitle() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty || newTitle == _task.title) return;
    final updated = _task.copyWith(title: newTitle);
    await SimpleTaskRepository.instance.updateTask(updated);
    setState(() => _task = updated);
    widget.onTaskUpdated();
  }

  Future<void> _saveNote() async {
    final newNote = _noteController.text.trim();
    if (newNote == (_task.note ?? '')) return;
    final updated = _task.copyWith(note: newNote.isEmpty ? null : newNote);
    await SimpleTaskRepository.instance.updateTask(updated);
    setState(() => _task = updated);
    widget.onTaskUpdated();
  }

  Future<void> _setQuickReminder(Duration offset, String label) async {
    final now = DateTime.now();
    final targetMs = now.add(offset).millisecondsSinceEpoch;
    final reminderId = 'rem_${_task.id}';

    await SimpleTaskRepository.instance.addPendingReminder(
      reminderId: reminderId,
      title: 'یادآور کار: ${_task.title}',
      body: _task.note ?? '',
      scheduledTimeMs: targetMs,
      taskId: _task.id,
    );

    final updated = _task.copyWith(reminderAtMs: targetMs, reminderId: reminderId);
    await SimpleTaskRepository.instance.updateTask(updated);
    setState(() => _task = updated);
    widget.onTaskUpdated();

    if (mounted) {
      RitmoToast.show(context, 'یادآور برای $label تنظیم شد', icon: CupertinoIcons.bell);
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await FilePickerPlatform.instance.pickFiles();
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        final att = await TaskAttachmentRepository.instance.add(
          taskId: _task.id,
          sourceFile: file,
          fileName: fileName,
        );

        setState(() => _attachments.add(att));
        widget.onTaskUpdated();
      }
    } catch (e) {
      if (mounted) {
        RitmoToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          icon: Icons.error_outline,
          iconColor: context.colors.medicalRed,
        );
      }
    }
  }

  Future<void> _deleteAttachment(TaskAttachment att) async {
    await TaskAttachmentRepository.instance.delete(att.id);
    setState(() => _attachments.removeWhere((a) => a.id == att.id));
    widget.onTaskUpdated();
  }

  Future<void> _confirmAndDeleteTask() async {
    final prefs = await SharedPreferences.getInstance();
    final confirmDelete = prefs.getString('tasks_confirm_delete') ?? 'true';

    if (confirmDelete == 'true' && mounted) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: context.colors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'حذف کار؟',
            style: TextStyle(
              color: context.colors.medicalRed,
              fontFamily: 'Vazirmatn',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'کار «${_task.title}» حذف شود؟',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text('انصراف', style: TextStyle(color: context.colors.textSecondary, fontFamily: 'Vazirmatn')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: Text('حذف', style: TextStyle(color: context.colors.medicalRed, fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final taskSnapshot = _task;
    final stepsSnapshot = List<TaskStep>.from(_steps);

    await SimpleTaskRepository.instance.delete(_task.id);
    if (mounted) Navigator.pop(context);
    widget.onTaskDeleted();

    if (mounted) {
      RitmoToast.show(
        context,
        'کار «${taskSnapshot.title}» حذف شد',
        icon: CupertinoIcons.trash,
        actionLabel: 'برگردان',
        onAction: () async {
          await SimpleTaskRepository.instance.restoreTask(taskSnapshot);
          for (final s in stepsSnapshot) {
            await TaskStepRepository.instance.add(taskId: s.taskId, title: s.title);
          }
          widget.onTaskUpdated();
        },
      );
    }
  }

  String _formatShamsiDate(DateTime dt) {
    final j = Jalali.fromDateTime(dt);
    return '${PersianDigits.toPersian(j.year)}/${PersianDigits.toPersian(j.month.toString().padLeft(2, '0'))}/${PersianDigits.toPersian(j.day.toString().padLeft(2, '0'))}';
  }

  Widget _buildNoteWithLinks(String noteText, BuildContext context) {
    final colors = context.colors;
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)|(www\.[^\s]+)');
    final matches = urlPattern.allMatches(noteText);

    if (matches.isEmpty) {
      return Text(
        noteText,
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary, height: 1.5),
      );
    }

    final spans = <TextSpan>[];
    int lastMatchEnd = 0;

    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: noteText.substring(lastMatchEnd, match.start),
          style: TextStyle(color: colors.textPrimary),
        ));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(color: colors.primary, decoration: TextDecoration.underline),
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < noteText.length) {
      spans.add(TextSpan(
        text: noteText.substring(lastMatchEnd),
        style: TextStyle(color: colors.textPrimary),
      ));
    }

    return InkWell(
      onTap: () async {
        for (final match in matches) {
          var urlStr = match.group(0)!;
          if (!urlStr.startsWith('http')) urlStr = 'https://$urlStr';
          final uri = Uri.tryParse(urlStr);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            break;
          }
        }
      },
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, height: 1.5),
          children: spans,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: colors.border, width: 1),
            ),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colors.primary))
                : ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4.5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colors.textTertiary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // 1. Header: Checkbox + Title + Star
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _task.isDone ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                              color: _task.isDone ? colors.success : colors.textTertiary,
                              size: 26,
                            ),
                            onPressed: _toggleDone,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _titleController,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _task.isDone ? colors.textTertiary : colors.textPrimary,
                                decoration: _task.isDone ? TextDecoration.lineThrough : null,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'عنوان کار...',
                              ),
                              onEditingComplete: _saveTitle,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _task.isImportant ? CupertinoIcons.star_fill : CupertinoIcons.star,
                              color: _task.isImportant ? colors.accent : colors.textTertiary,
                              size: 24,
                            ),
                            onPressed: _toggleStar,
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // 2. Sub-steps
                      Text(
                        'زیرگام‌ها',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TaskStepList(
                        taskId: _task.id,
                        steps: _steps,
                        onStepsChanged: _loadData,
                      ),
                      const Divider(height: 24),

                      // 3. Reminders Quick Buttons
                      Text(
                        'یادآور',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('امشب ۲۱:۰۰', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                            onPressed: () => _setQuickReminder(const Duration(hours: 4), 'امشب ۲۱:۰۰'),
                          ),
                          ActionChip(
                            label: const Text('فردا صبح ۰۹:۰۰', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                            onPressed: () => _setQuickReminder(const Duration(days: 1), 'فردا صبح ۰۹:۰۰'),
                          ),
                          ActionChip(
                            label: const Text('هفته بعد', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                            onPressed: () => _setQuickReminder(const Duration(days: 7), 'هفته بعد'),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // 4. Note
                      Text(
                        'یادداشت',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'توضیحات و لینک‌های مرتبط...',
                          hintStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textTertiary),
                          filled: true,
                          fillColor: colors.surfaceSunken,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.border),
                          ),
                        ),
                        onChanged: (_) => _saveNote(),
                      ),
                      if (_noteController.text.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _buildNoteWithLinks(_noteController.text, context),
                      ],
                      const Divider(height: 24),

                      // 5. Attachments
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'پیوست‌ها (${PersianDigits.toPersian(_attachments.length)})',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickAttachment,
                            icon: const Icon(CupertinoIcons.paperclip, size: 16),
                            label: const Text('+ افزودن فایل', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11)),
                          ),
                        ],
                      ),
                      if (_attachments.isNotEmpty)
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _attachments.length,
                          itemBuilder: (context, index) {
                            final att = _attachments[index];
                            final sizeKb = (att.fileSizeBytes / 1024).toStringAsFixed(1);
                            return ListTile(
                              dense: true,
                              leading: const Icon(CupertinoIcons.doc_fill),
                              title: Text(att.fileName, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textPrimary)),
                              subtitle: Text('${PersianDigits.toPersian(sizeKb)} KB', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary)),
                              trailing: IconButton(
                                icon: Icon(CupertinoIcons.trash, color: colors.medicalRed, size: 18),
                                onPressed: () => _deleteAttachment(att),
                              ),
                            );
                          },
                        ),
                      const Divider(height: 24),

                      // 6. Timestamp Footer
                      Text(
                        'ساخته‌شده: ${_formatShamsiDate(_task.createdAt)}',
                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.textTertiary),
                      ),
                      if (_task.doneAt != null)
                        Text(
                          'انجام‌شده: ${_formatShamsiDate(_task.doneAt!)}',
                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11, color: colors.success),
                        ),
                      const SizedBox(height: 20),

                      // 7. Delete Button
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.medicalRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _confirmAndDeleteTask,
                        icon: const Icon(CupertinoIcons.trash, size: 18),
                        label: const Text('حذف کار', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
