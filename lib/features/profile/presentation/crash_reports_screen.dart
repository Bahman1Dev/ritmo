import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/observability/privacy_error_sink.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_pressable.dart';

class CrashReportsScreen extends StatefulWidget {
  const CrashReportsScreen({super.key});

  @override
  State<CrashReportsScreen> createState() => _CrashReportsScreenState();
}

class _CrashReportsScreenState extends State<CrashReportsScreen> {
  List<File> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    final reports = await PrivacyErrorSink.getCrashReports();
    if (mounted) {
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    await PrivacyErrorSink.clearAllReports();
    await _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          title: const Text('گزارش‌های فنی خطا', style: TextStyle(fontFamily: 'Vazirmatn')),
          actions: [
            if (_reports.isNotEmpty)
              IconButton(
                icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent),
                onPressed: _clearAll,
                tooltip: 'حذف همه لاگ‌ها',
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(CupertinoIcons.checkmark_shield_fill, size: 64, color: Colors.green),
                        const SizedBox(height: 16),
                        Text(
                          'هیچ خطایی ثبت نشده است 🌿',
                          style: TextStyle(color: colors.textPrimary, fontSize: 16, fontFamily: 'Vazirmatn'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final file = _reports[index];
                      final filename = file.path.split(Platform.pathSeparator).last;
                      return Card(
                        color: colors.card,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(filename, style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                          trailing: const Icon(CupertinoIcons.doc_text, size: 20),
                          onTap: () async {
                            final text = await file.readAsString();
                            if (context.mounted) {
                              await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: colors.card,
                                  title: Text(filename, style: const TextStyle(fontSize: 14, fontFamily: 'Vazirmatn')),
                                  content: SingleChildScrollView(
                                    child: SelectableText(
                                      text,
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(text: text));
                                        Navigator.pop(ctx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('گزارش در حافظه کپی شد')),
                                        );
                                      },
                                      child: const Text('کپی متن'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('بستن'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
