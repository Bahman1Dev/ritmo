import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/util/ritmo_number.dart';
import 'package:ritmo/features/study/domain/study_models.dart';
import 'package:uuid/uuid.dart';

class ParsedBulkTopic {
  ParsedBulkTopic({
    required this.id,
    this.parentId,
    required this.name,
  });

  final String id;
  final String? parentId;
  String name;
}

class BulkTopicsSheet extends StatefulWidget {
  const BulkTopicsSheet({super.key, required this.subjectId});

  final String subjectId;

  static Future<List<StudyTopic>?> show(BuildContext context, {required String subjectId}) {
    return showModalBottomSheet<List<StudyTopic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BulkTopicsSheet(subjectId: subjectId),
    );
  }

  @override
  State<BulkTopicsSheet> createState() => _BulkTopicsSheetState();
}

class _BulkTopicsSheetState extends State<BulkTopicsSheet> {
  final TextEditingController _textController = TextEditingController();
  List<ParsedBulkTopic> _parsedTopics = [];
  bool _isPreview = false;

  void _parseInputText() {
    final rawLines = _textController.text.split('\n');
    final parsed = <ParsedBulkTopic>[];
    String? lastParentId;

    const uuid = Uuid();

    for (final rawLine in rawLines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) continue;

      final isSub = rawLine.startsWith('  ') || rawLine.startsWith('\t') || line.trimLeft().startsWith('-') || line.trimLeft().startsWith('*');
      final cleanName = line.replaceAll(RegExp(r'^[\s\-\*\•]+'), '').trim();

      if (cleanName.isEmpty) continue;

      final id = uuid.v4();
      if (isSub && lastParentId != null) {
        parsed.add(ParsedBulkTopic(id: id, parentId: lastParentId, name: cleanName));
      } else {
        lastParentId = id;
        parsed.add(ParsedBulkTopic(id: id, parentId: null, name: cleanName));
      }
    }

    setState(() {
      _parsedTopics = parsed;
      _isPreview = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isPreview ? 'پیش‌نمایش سرفصل‌ها' : 'افزودن دسته‌جمعی سرفصل‌ها',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 18, fontWeight: FontWeight.bold, color: colors.textPrimary),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 12),

          if (!_isPreview) ...[
            Text(
              'سرفصل‌های خود را از متنی مانند پیام تلگرام یا PDF کپی و پیست کنید.\nخطوطی که با - یا فاصله شروع شوند زیرسرفصل محسوب می‌شوند.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              maxLines: 8,
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'فصل ۱: مفاهیم اولیه\n  - تعریف واژگان\n  - اصول پایه\nفصل ۲: کاربردها...',
                hintStyle: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textSecondary.withValues(alpha: 0.6)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _parseInputText,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('بررسی و پیش‌نمایش', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ] else ...[
            Text(
              'مجموع: ${RitmoNumber.faInt(_parsedTopics.length)} سرفصل استخراج شد.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _parsedTopics.length,
                itemBuilder: (context, index) {
                  final topic = _parsedTopics[index];
                  final isSub = topic.parentId != null;
                  return Padding(
                    padding: EdgeInsets.only(left: isSub ? 20 : 0, bottom: 6),
                    child: Row(
                      children: [
                        Icon(isSub ? Icons.subdirectory_arrow_right : Icons.label_important_outline, size: 16, color: colors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic.name,
                            style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: colors.textPrimary),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, size: 18, color: colors.error),
                          onPressed: () {
                            setState(() => _parsedTopics.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isPreview = false),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: Text('ویرایش متن', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final result = _parsedTopics.map((pt) {
                        return StudyTopic(
                          id: pt.id,
                          subjectId: widget.subjectId,
                          parentTopicId: pt.parentId,
                          name: pt.name,
                          origin: StudyOrigin.user,
                        );
                      }).toList();
                      Navigator.pop(context, result);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('ثبت نهایی سرفصل‌ها', style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
