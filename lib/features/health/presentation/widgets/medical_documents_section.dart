import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path_utils;
import 'package:path_provider/path_provider.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_date_picker.dart';
import 'package:ritmo/features/health/models/health_models.dart';
import 'package:ritmo/l10n/app_localizations.dart';
import 'package:sqflite/sqflite.dart';

class MedicalDocumentsSection extends StatefulWidget {
  const MedicalDocumentsSection({
    super.key,
  });

  @override
  State<MedicalDocumentsSection> createState() => _MedicalDocumentsSectionState();
}

class _MedicalDocumentsSectionState extends State<MedicalDocumentsSection> {
  List<MedicalDocument> _documents = [];
  Map<String, List<String>> _docImagesMap = {}; // Maps documentId -> list of imagePaths
  bool _isLoading = true;
  String _filterCategory = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadData();
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

  String _formatJalaliDate(int epochMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final j = Jalali.fromDateTime(dt);
    return _toPersianDigits('${j.year}/${j.month}/${j.day}');
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Load documents
      final docResults = await db.query('medical_documents', orderBy: 'documentDate DESC');
      final docs = docResults.map(MedicalDocument.fromMap).toList();

      // 2. Load images for each document
      final imagesMap = <String, List<String>>{};
      final imgResults = await db.query('medical_document_images', orderBy: 'pageNumber ASC');
      
      for (final img in imgResults) {
        final docId = img['documentId']! as String;
        final path = img['imagePath']! as String;
        imagesMap.putIfAbsent(docId, () => []).add(path);
      }

      // Update image count in models
      for (final doc in docs) {
        doc.imageCount = imagesMap[doc.id]?.length ?? 0;
      }

      if (mounted) {
        setState(() {
          _documents = docs;
          _docImagesMap = imagesMap;
        });
      }
    } catch (e) {
      debugPrint('Error loading medical documents: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }



  Future<void> _saveDocument(MedicalDocument doc, List<String> imagePaths) async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      await db.transaction((txn) async {
        // Insert/Replace Document
        await txn.insert(
          'medical_documents',
          doc.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Delete existing images if editing
        await txn.delete(
          'medical_document_images',
          where: 'documentId = ?',
          whereArgs: [doc.id],
        );

        // Insert new images
        for (var i = 0; i < imagePaths.length; i++) {
          final imgId = 'img_${doc.id}_$i';
          await txn.insert(
            'medical_document_images',
            {
              'id': imgId,
              'documentId': doc.id,
              'imagePath': imagePaths[i],
              'pageNumber': i + 1,
              'caption': 'Page ${i + 1}',
            },
          );
        }
      });

      await _loadData();
    } catch (e) {
      debugPrint('Error saving medical document: $e');
    }
  }

  Future<void> _deleteDocument(String id) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete('medical_documents', where: 'id = ?', whereArgs: [id]);
      await _loadData();
    } catch (e) {
      debugPrint('Error deleting document: $e');
    }
  }

  String _getCategoryLabel(String cat) {
    switch (cat) {
      case 'BLOOD_TEST':
        return 'آزمایش خون';
      case 'URINE_TEST':
        return 'آزمایش ادرار';
      case 'IMAGING':
        return 'تصویربرداری';
      case 'PATHOLOGY':
        return 'پاتولوژی';
      case 'SONOGRAPHY':
        return 'سونوگرافی';
      case 'PRESCRIPTION':
        return 'نسخه پزشک';
      case 'OTHER':
      default:
        return 'سایر مدارک';
    }
  }

  void _showAttachmentViewer(String docTitle, List<String> paths, int initialPage) {
    showDialog(
      context: context,
      builder: (context) => _MultiPageViewer(
        docTitle: docTitle,
        imagePaths: paths,
        initialPage: initialPage,
      ),
    );
  }

  void _showAddEditSheet({MedicalDocument? doc}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: RitmoTheme.glassCardLight(
          child: _MedicalDocumentForm(
            document: doc,
            existingImages: doc != null ? (_docImagesMap[doc.id] ?? []) : [],
            onSave: (savedDoc, images) {
              _saveDocument(savedDoc, images);
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



    final filteredDocs = _documents.where((d) {
      if (_filterCategory == 'ALL') return true;
      return d.category == _filterCategory;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.medicalDocumentsTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddEditSheet,
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(l10n.medicalDocumentsAddTitle, style: const TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Category Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', 'همه'),
                _buildFilterChip('BLOOD_TEST', 'آزمایش خون'),
                _buildFilterChip('URINE_TEST', 'آزمایش ادرار'),
                _buildFilterChip('IMAGING', 'تصویربرداری'),
                _buildFilterChip('SONOGRAPHY', 'سونوگرافی'),
                _buildFilterChip('PRESCRIPTION', 'نسخه پزشک'),
                _buildFilterChip('OTHER', 'سایر'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoading) Center(child: CircularProgressIndicator(color: colors.primary)) else _buildDocsList(filteredDocs),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String cat, String label) {
    final colors = context.colors;
    final isSelected = _filterCategory == cat;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: isSelected ? Colors.white : colors.textPrimary)),
        selected: isSelected,
        selectedColor: colors.primary,
        backgroundColor: colors.card,
        onSelected: (val) {
          if (val) {
            setState(() {
              _filterCategory = cat;
            });
          }
        },
      ),
    );
  }

  Widget _buildDocsList(List<MedicalDocument> docs) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.medicalDocumentsNoDocs,
            style: TextStyle(color: colors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final images = _docImagesMap[doc.id] ?? [];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            title: Text(
              doc.title,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colors.textPrimary),
            ),
            subtitle: Text(
              '${_getCategoryLabel(doc.category)} · ${_formatJalaliDate(doc.documentDate)}',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
            ),
            childrenPadding: const EdgeInsets.all(12),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (doc.labName != null && doc.labName!.isNotEmpty) ...[
                Text(
                  'مرکز صادرکننده: ${doc.labName}',
                  style: TextStyle(fontSize: 13, color: colors.textPrimary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
              ],
              if (doc.summary != null && doc.summary!.isNotEmpty) ...[
                Text(
                  'خلاصه گزارش:',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                Text(
                  doc.summary!,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
              ],
              if (doc.doctorNotes != null && doc.doctorNotes!.isNotEmpty) ...[
                Text(
                  'توصیه پزشک:',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                Text(
                  doc.doctorNotes!,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
              ],
              if (doc.userNotes != null && doc.userNotes!.isNotEmpty) ...[
                Text(
                  'یادداشت کاربر:',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                Text(
                  doc.userNotes!,
                  style: TextStyle(fontSize: 13, color: colors.textPrimary),
                ),
                const SizedBox(height: 6),
              ],
              if (images.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'تصاویر مدرک (${_toPersianDigits(images.length.toString())} صفحه):',
                  style: TextStyle(fontSize: 12, color: colors.textSecondary),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, i) {
                      return GestureDetector(
                        onTap: () => _showAttachmentViewer(doc.title, images, i),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(images[i]),
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: colors.primary),
                    onPressed: () => _showAddEditSheet(doc: doc),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: colors.medicalRed),
                    onPressed: () => _confirmDelete(doc.id),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          title: const Text('حذف مدرک', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn')),
          content: Text(
            l10n.medicalDocumentsDeleteConfirm,
            style: const TextStyle(fontFamily: 'Vazirmatn'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn')),
            ),
            ElevatedButton(
              onPressed: () {
                _deleteDocument(id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: colors.medicalRed),
              child: const Text('حذف', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn')),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiPageViewer extends StatefulWidget {

  const _MultiPageViewer({
    required this.docTitle,
    required this.imagePaths,
    required this.initialPage,
  });
  final String docTitle;
  final List<String> imagePaths;
  final int initialPage;

  @override
  State<_MultiPageViewer> createState() => _MultiPageViewerState();
}

class _MultiPageViewerState extends State<_MultiPageViewer> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagePaths.length,
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.imagePaths[index]),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
          // Header info
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _toPersianDigits('صفحه ${_currentPage + 1} از ${widget.imagePaths.length}'),
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Vazirmatn'),
                  ),
                ),
                FloatingActionButton.small(
                  onPressed: () => Navigator.pop(context),
                  backgroundColor: Colors.black.withValues(alpha: 0.6),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicalDocumentForm extends StatefulWidget {

  const _MedicalDocumentForm({
    this.document,
    required this.existingImages,
    required this.onSave,
  });
  final MedicalDocument? document;
  final List<String> existingImages;
  final Function(MedicalDocument, List<String>) onSave;

  @override
  State<_MedicalDocumentForm> createState() => _MedicalDocumentFormState();
}

class _MedicalDocumentFormState extends State<_MedicalDocumentForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _labNameController;
  late TextEditingController _summaryController;
  late TextEditingController _doctorNotesController;
  late TextEditingController _userNotesController;

  late DateTime _selectedDate;
  String _category = 'BLOOD_TEST';
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    final d = widget.document;
    _titleController = TextEditingController(text: d?.title ?? '');
    _labNameController = TextEditingController(text: d?.labName ?? '');
    _summaryController = TextEditingController(text: d?.summary ?? '');
    _doctorNotesController = TextEditingController(text: d?.doctorNotes ?? '');
    _userNotesController = TextEditingController(text: d?.userNotes ?? '');

    if (d != null) {
      _selectedDate = DateTime.fromMillisecondsSinceEpoch(d.documentDate);
      _category = d.category;
      _imagePaths = List.from(widget.existingImages);
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _labNameController.dispose();
    _summaryController.dispose();
    _doctorNotesController.dispose();
    _userNotesController.dispose();
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

  Future<void> _pickDate() async {
    final picked = await RitmoDatePicker.showJalali(
      context: context,
      initialDate: Jalali.fromDateTime(_selectedDate),
      firstDate: Jalali.fromDateTime(DateTime.now().subtract(const Duration(days: 365 * 5))),
      lastDate: Jalali.fromDateTime(DateTime.now().add(const Duration(days: 365))),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked.toDateTime();
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage();
      if (picked.isNotEmpty) {
        final appDir = await getApplicationDocumentsDirectory();
        final copiedPaths = <String>[];
        
        for (final file in picked) {
          final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}_${copiedPaths.length}.jpg';
          final saved = await File(file.path).copy(path_utils.join(appDir.path, fileName));
          copiedPaths.add(saved.path);
        }

        setState(() {
          _imagePaths.addAll(copiedPaths);
        });
      }
    } catch (e) {
      debugPrint('Error picking medical images: $e');
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final doc = MedicalDocument(
      id: widget.document?.id ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      category: _category,
      documentDate: _selectedDate.millisecondsSinceEpoch,
      labName: _labNameController.text.trim().isEmpty ? null : _labNameController.text.trim(),
      summary: _summaryController.text.trim().isEmpty ? null : _summaryController.text.trim(),
      doctorNotes: _doctorNotesController.text.trim().isEmpty ? null : _doctorNotesController.text.trim(),
      userNotes: _userNotesController.text.trim().isEmpty ? null : _userNotesController.text.trim(),
      createdAt: widget.document?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(doc, _imagePaths);
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
                widget.document == null ? l10n.medicalDocumentsAddTitle : l10n.medicalDocumentsEditTitle,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.medicalDocumentsDocTitle, icon: Icons.title),
                validator: (val) => val == null || val.trim().isEmpty ? 'لطفاً عنوان مدرک را وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.medicalDocumentsCategory, icon: Icons.category),
                dropdownColor: colors.card,
                items: const [
                  DropdownMenuItem(value: 'BLOOD_TEST', child: Text('آزمایش خون')),
                  DropdownMenuItem(value: 'URINE_TEST', child: Text('آزمایش ادرار')),
                  DropdownMenuItem(value: 'IMAGING', child: Text('تصویربرداری')),
                  DropdownMenuItem(value: 'PATHOLOGY', child: Text('پاتولوژی')),
                  DropdownMenuItem(value: 'SONOGRAPHY', child: Text('سونوگرافی')),
                  DropdownMenuItem(value: 'PRESCRIPTION', child: Text('نسخه پزشک')),
                  DropdownMenuItem(value: 'OTHER', child: Text('سایر مدارک')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _labNameController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.medicalDocumentsLabName, icon: Icons.business),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summaryController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.medicalDocumentsSummary, icon: Icons.summarize),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _doctorNotesController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.medicalDocumentsDoctorNotes, icon: Icons.notes),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _userNotesController,
                style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn'),
                decoration: RitmoTheme.inputDecoration(context, label: l10n.medicalDocumentsUserNotes, icon: Icons.note_alt_outlined),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              // Document images selection
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.add_photo_alternate, color: colors.primary),
                label: Text(
                  l10n.medicalDocumentsSelectImages,
                  style: TextStyle(color: colors.textPrimary, fontFamily: 'Vazirmatn', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (_imagePaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, i) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePaths[i]),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imagePaths.removeAt(i);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                  l10n.medicalDocumentsSave,
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
