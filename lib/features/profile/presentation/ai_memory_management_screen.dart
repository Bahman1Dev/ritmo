import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/memory/ai_memory_service.dart';
import 'package:ritmo/core/ai/memory/memory_models.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:sqflite/sqflite.dart';

class AiMemoryManagementScreen extends StatefulWidget {
  const AiMemoryManagementScreen({super.key});

  @override
  State<AiMemoryManagementScreen> createState() => _AiMemoryManagementScreenState();
}

class _AiMemoryManagementScreenState extends State<AiMemoryManagementScreen> {
  bool _isLoading = true;
  bool _memoryEnabled = true;
  bool _implicitEnabled = true;

  List<MemoryEntry> _activeMemories = [];
  List<MemoryEntry> _archivedMemories = [];

  final _textController = TextEditingController();
  String _selectedDomain = 'core';

  final List<Map<String, String>> _domainsList = [
    {'key': 'core', 'label': 'عمومی و شخصی'},
    {'key': 'health', 'label': 'سلامت و داروها'},
    {'key': 'cycle', 'label': 'چرخه بدنی'},
    {'key': 'worship', 'label': 'عبادت و معنویت'},
    {'key': 'wellbeing', 'label': 'بهزیستی'},
    {'key': 'goals', 'label': 'اهداف'},
    {'key': 'konkur', 'label': 'کنکور'},
    {'key': 'courses', 'label': 'دوره‌های آموزشی'},
    {'key': 'sports', 'label': 'ورزش تکمیلی'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettingsAndData();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndData() async {
    setState(() => _isLoading = true);
    try {
      final db = await DatabaseHelper.instance.database;
      
      // Load settings
      final settings = await db.query('app_settings');
      final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
      
      _memoryEnabled = (settingsMap['ai_memory_enabled'] ?? 'true') == 'true';
      _implicitEnabled = (settingsMap['ai_memory_implicit_enabled'] ?? 'true') == 'true';

      // Load active and archived memories
      final List<Map<String, dynamic>> rows = await db.query('ai_memory', orderBy: 'createdAt DESC');
      final allMemories = rows.map(MemoryEntry.fromMap).toList();

      setState(() {
        _activeMemories = allMemories.where((m) => m.status == MemoryStatus.active).toList();
        _archivedMemories = allMemories.where((m) => m.status == MemoryStatus.archived).toList();
      });
    } catch (e) {
      debugPrint('Error loading memory management data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleSetting(String key, bool val) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert(
        'app_settings',
        {'key': key, 'value': val ? 'true' : 'false', 'updatedAt': now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      setState(() {
        if (key == 'ai_memory_enabled') _memoryEnabled = val;
        if (key == 'ai_memory_implicit_enabled') _implicitEnabled = val;
      });
      _showToast('تنظیمات با موفقیت به‌روزرسانی شد.');
    } catch (e) {
      debugPrint('Error toggling setting: $e');
      _showToast('خطا در ذخیره تنظیمات.', isError: true);
    }
  }

  Future<void> _addManualMemory() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showToast('لطفاً ابتدا فکت مورد نظر را بنویسید.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final op = MemoryOp(
        op: 'ADD',
        content: text,
        type: MemoryType.preference,
        domain: _selectedDomain,
        importance: 10, // Manual/explicit memory has maximum importance
        sensitive: _selectedDomain == 'health' || _selectedDomain == 'cycle',
      );

      await AiMemoryService.instance.applyOperations([op]);
      _textController.clear();
      _showToast('حافظه جدید با موفقیت ثبت شد.');
      await _loadSettingsAndData();
    } catch (e) {
      debugPrint('Error adding manual memory: $e');
      _showToast('خطا در ذخیره حافظه جدید.', isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePin(MemoryEntry memory) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'ai_memory',
        {'pinned': memory.pinned ? 0 : 1, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [memory.id],
      );
      _showToast(memory.pinned ? 'حافظه از حالت پین خارج شد.' : 'حافظه پین شد.');
      await _loadSettingsAndData();
    } catch (e) {
      debugPrint('Error toggling memory pin: $e');
    }
  }

  Future<void> _editMemory(MemoryEntry memory) async {
    final editController = TextEditingController(text: memory.content);
    unawaited(showDialog(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('ویرایش حافظه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold)),
            content: TextField(
              controller: editController,
              maxLines: 3,
              style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 13),
              decoration: RitmoTheme.inputDecoration(
                context,
                label: 'محتوای حافظه شناختی',
                icon: CupertinoIcons.pencil,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: colors.primary),
                onPressed: () async {
                  final text = editController.text.trim();
                  if (text.isNotEmpty) {
                    Navigator.pop(context);
                    setState(() => _isLoading = true);
                    final op = MemoryOp(
                      op: 'UPDATE',
                      id: memory.id,
                      content: text,
                      type: memory.type,
                      domain: memory.domain,
                      importance: memory.importance,
                      sensitive: memory.sensitive,
                      expiresAt: memory.expiresAt,
                    );
                    await AiMemoryService.instance.applyOperations([op]);
                    _showToast('تغییرات با موفقیت اعمال شد.');
                    await _loadSettingsAndData();
                  }
                },
                child: const Text('ذخیره', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _archiveOrRestoreMemory(MemoryEntry memory, MemoryStatus targetStatus) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.update(
        'ai_memory',
        {
          'status': targetStatus.name,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [memory.id],
      );
      _showToast(targetStatus == MemoryStatus.archived ? 'حافظه به بایگانی انتقال یافت.' : 'حافظه بازیابی شد.');
      await _loadSettingsAndData();
    } catch (e) {
      debugPrint('Error archiving/restoring memory: $e');
    }
  }

  Future<void> _deleteMemoryPermanently(MemoryEntry memory) async {
    unawaited(showDialog(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('حذف دائمی حافظه', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
            content: const Text(
              'آیا مطمئن هستید که می‌خواهید این حافظه را برای همیشه و بدون امکان بازیابی حذف کنید؟',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  final db = await DatabaseHelper.instance.database;
                  await db.delete('ai_memory', where: 'id = ?', whereArgs: [memory.id]);
                  _showToast('حافظه برای همیشه حذف شد.');
                  await _loadSettingsAndData();
                },
                child: const Text('حذف دائمی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
              ),
            ],
          ),
        );
      },
    ));
  }

  Future<void> _clearAllMemories() async {
    unawaited(showDialog(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('پاک‌سازی کل حافظه دستیار', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent)),
            content: const Text(
              '⚠️ هشدار بسیار مهم:\nبا تأیید این عملیات، تمامی اطلاعات و فکت‌های شناختی که دستیار از گفتگو با شما به خاطر سپرده است، کاملاً پاک شده و هوش مصنوعی تمام پیش‌فرض‌های مربوط به شما را فراموش خواهد کرد.\n\nآیا مایل به ادامه هستید؟',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, height: 1.6),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  Navigator.pop(context);
                  // Double confirmation step
                  _showSecondClearConfirmation();
                },
                child: const Text('ادامه پاک‌سازی', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSecondClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: colors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('تأیید نهایی پاک‌سازی', style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 14, fontWeight: FontWeight.bold)),
            content: const Text(
              'برای پاک کردن نهایی و قطعی کل داده‌های حافظه، روی دکمه زیر کلیک کنید.',
              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('انصراف', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  final db = await DatabaseHelper.instance.database;
                  await db.delete('ai_memory');
                  _showToast('کل حافظه شناختی با موفقیت پاک‌سازی شد.');
                  await _loadSettingsAndData();
                },
                child: const Text('بله، کاملاً فراموش کن!', style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
        ),
        backgroundColor: isError ? Colors.redAccent : const Color(0xff5B8AF5),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getDomainLabel(String domain) {
    final match = _domainsList.firstWhere((d) => d['key'] == domain, orElse: () => {'key': '', 'label': domain});
    return match['label']!;
  }

  String _getTypeLabel(MemoryType type) {
    switch (type) {
      case MemoryType.identity: return 'هویت';
      case MemoryType.preference: return 'علاقه';
      case MemoryType.constraint: return 'محدودیت';
      case MemoryType.goal: return 'هدف';
      case MemoryType.episode: return 'رویداد';
      case MemoryType.insight: return 'بینش';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Group active memories by domain
    final groupedActive = <String, List<MemoryEntry>>{};
    for (final m in _activeMemories) {
      groupedActive.putIfAbsent(m.domain, () => []).add(m);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'مدیریت حافظه دستیار 🧠',
            style: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.bold, fontSize: 17, color: colors.textPrimary),
          ),
          leading: IconButton(
            icon: RitmoIcons.back(context, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Stack(
          children: [
            // Background Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDarkMode
                        ? [const Color(0xff08090C), const Color(0xff12141C)]
                        : [const Color(0xffF2F5FA), const Color(0xffE5ECF6)],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // 1. Settings Switches
                        RitmoTheme.glassCardLight(
                          borderRadius: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تنظیمات حریم خصوصی و یادگیری',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SwitchListTile(
                                  activeThumbColor: colors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('فعال‌سازی سیستم حافظه', style: TextStyle(fontSize: 12.5, fontFamily: 'Vazirmatn', color: colors.textPrimary)),
                                  subtitle: Text('به دستیار اجازه می‌دهد داده‌های از پیش‌دانسته شما را در گفتگوها استفاده کند.', style: TextStyle(fontSize: 10.5, fontFamily: 'Vazirmatn', color: colors.textSecondary)),
                                  value: _memoryEnabled,
                                  onChanged: (val) => _toggleSetting('ai_memory_enabled', val),
                                ),
                                const Divider(color: Colors.white10),
                                SwitchListTile(
                                  activeThumbColor: colors.primary,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('یادگیری خودکار تدریجی', style: TextStyle(fontSize: 12.5, fontFamily: 'Vazirmatn', color: colors.textPrimary)),
                                  subtitle: Text('استخراج خودکار علایق و محدودیت‌های شما در پس‌زمینه گفتگوها', style: TextStyle(fontSize: 10.5, fontFamily: 'Vazirmatn', color: colors.textSecondary)),
                                  value: _implicitEnabled,
                                  onChanged: _memoryEnabled ? (val) => _toggleSetting('ai_memory_implicit_enabled', val) : null,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colors.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_outline, size: 16, color: colors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '🔒 حریم خصوصی: حافظه شناختی ریتمو به صورت کاملاً آفلاین و محلی بر روی دستگاه شما ذخیره می‌شود و با هیچ سرور ابری همگام‌سازی نخواهد شد.',
                                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 2. Add manual Memory Entry
                        if (_memoryEnabled) ...[
                          RitmoTheme.glassCardLight(
                            borderRadius: 20,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'افزودن دستی فکت به حافظه دستیار',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _textController,
                                    maxLines: 2,
                                    style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 12.5),
                                    decoration: RitmoTheme.inputDecoration(
                                      context,
                                      label: 'مثال: به بادام‌زمینی آلرژی دارم یا کمردرد خفیف دارم.',
                                      icon: Icons.psychology,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Text(
                                        'حوزه مربوطه: ',
                                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 11.5, color: colors.textSecondary),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: colors.card,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: colors.border),
                                          ),
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedDomain,
                                              dropdownColor: colors.card,
                                              style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12, color: colors.textPrimary),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() => _selectedDomain = val);
                                                }
                                              },
                                              items: _domainsList.map((d) {
                                                return DropdownMenuItem<String>(
                                                  value: d['key'],
                                                  child: Text(d['label']!),
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 40,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      onPressed: _addManualMemory,
                                      child: const Text(
                                        'ذخیره حافظه جدید 💾',
                                        style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // 3. Active Memories grouped by domain
                        Text(
                          'فهرست حافظه‌های فعال دستیار',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_activeMemories.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'هنوز حافظه‌ای ثبت نشده است.',
                                style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textSecondary, fontSize: 12),
                              ),
                            ),
                          )
                        else
                          ...groupedActive.entries.map((group) {
                            final domain = group.key;
                            final list = group.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: RitmoTheme.glassCardLight(
                                borderRadius: 16,
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  title: Row(
                                    children: [
                                      Icon(CupertinoIcons.folder, size: 16, color: colors.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        _getDomainLabel(domain),
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${list.length} مورد',
                                          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: list.map((m) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        border: Border(top: BorderSide(color: Colors.white10)),
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        title: Text(
                                          m.content,
                                          style: TextStyle(
                                            fontFamily: 'Vazirmatn',
                                            fontSize: 12.5,
                                            color: colors.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              // Type badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.06),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  _getTypeLabel(m.type),
                                                  style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9.5, color: colors.textSecondary),
                                                ),
                                              ),
                                              // Source badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: m.source == MemorySource.explicit
                                                      ? Colors.teal.withValues(alpha: 0.1)
                                                      : Colors.blue.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  m.source == MemorySource.explicit ? 'صریح' : 'خودکار',
                                                  style: TextStyle(
                                                    fontFamily: 'Vazirmatn',
                                                    fontSize: 9.5,
                                                    color: m.source == MemorySource.explicit ? Colors.tealAccent : Colors.lightBlueAccent,
                                                  ),
                                                ),
                                              ),
                                              // Importance badge
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'اهمیت: ${m.importance}',
                                                  style: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 9.5, color: Colors.orangeAccent),
                                                ),
                                              ),
                                              if (m.sensitive)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.redAccent.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'حساس 🔒',
                                                    style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 9.5, color: Colors.redAccent),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Pin/Unpin
                                            IconButton(
                                              icon: Icon(
                                                m.pinned ? CupertinoIcons.pin_fill : CupertinoIcons.pin,
                                                size: 16,
                                                color: m.pinned ? Colors.amber : colors.textSecondary,
                                              ),
                                              onPressed: () => _togglePin(m),
                                            ),
                                            // Actions PopupMenu
                                            PopupMenuButton<String>(
                                              icon: Icon(Icons.more_vert, size: 18, color: colors.textSecondary),
                                              color: colors.card,
                                              onSelected: (action) {
                                                if (action == 'edit') {
                                                  _editMemory(m);
                                                } else if (action == 'archive') {
                                                  _archiveOrRestoreMemory(m, MemoryStatus.archived);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(CupertinoIcons.pencil, size: 14, color: colors.textPrimary),
                                                      const SizedBox(width: 8),
                                                      Text('ویرایش', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                                PopupMenuItem(
                                                  value: 'archive',
                                                  child: Row(
                                                    children: [
                                                      Icon(CupertinoIcons.archivebox, size: 14, color: colors.textPrimary),
                                                      const SizedBox(width: 8),
                                                      Text('بایگانی', style: TextStyle(fontFamily: 'Vazirmatn', color: colors.textPrimary, fontSize: 12)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          }),

                        const SizedBox(height: 16),

                        // 4. Archived memories
                        if (_archivedMemories.isNotEmpty) ...[
                          RitmoTheme.glassCardLight(
                            borderRadius: 16,
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  Icon(CupertinoIcons.archivebox, size: 16, color: colors.textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'حافظه‌های بایگانی‌شده',
                                    style: TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: colors.textSecondary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${_archivedMemories.length} مورد',
                                      style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              children: _archivedMemories.map((m) {
                                return Container(
                                  decoration: const BoxDecoration(
                                    border: Border(top: BorderSide(color: Colors.white10)),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                    title: Text(
                                      m.content,
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 12,
                                        color: colors.textSecondary,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'حوزه: ${_getDomainLabel(m.domain)}',
                                        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 10, color: colors.textSecondary.withValues(alpha: 0.6)),
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Restore
                                        IconButton(
                                          icon: const Icon(CupertinoIcons.arrow_counterclockwise, size: 16, color: Colors.tealAccent),
                                          onPressed: () => _archiveOrRestoreMemory(m, MemoryStatus.active),
                                        ),
                                        // Delete permanently
                                        IconButton(
                                          icon: const Icon(CupertinoIcons.trash, size: 16, color: Colors.redAccent),
                                          onPressed: () => _deleteMemoryPermanently(m),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // 5. Reset button
                        if (_activeMemories.isNotEmpty || _archivedMemories.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              icon: const Icon(CupertinoIcons.trash, color: Colors.redAccent, size: 16),
                              label: const Text(
                                'پاک‌کردن کل حافظه دستیار',
                                style: TextStyle(fontFamily: 'Vazirmatn', color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12.5),
                              ),
                              onPressed: _clearAllMemories,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
