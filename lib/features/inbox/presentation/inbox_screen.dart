import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/domain/models/inbox_item.dart';
import 'package:ritmo/core/services/central_inbox_service.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/features/inbox/logic/inbox_navigator.dart';
import 'package:shamsi_date/shamsi_date.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<InboxItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    final items = await CentralInboxService.getItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  String _formatDateTime(DateTime dt) {
    final jalali = Jalali.fromDateTime(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${jalali.year}/${jalali.month}/${jalali.day} - $hour:$minute';
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
    final colors = context.colors;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xff08090C) : const Color(0xffF2F5FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: RitmoIcons.back(context, color: colors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'صندوق پیام‌ها و یادآوری‌ها',
          style: TextStyle(
            color: colors.textPrimary,
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_items.any((i) => i.status == InboxStatus.UNREAD))
            TextButton(
              onPressed: () async {
                await CentralInboxService.markAllRead();
                _loadItems();
              },
              child: const Text(
                'خواندن همه',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  color: Color(0xff5B8AF5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5)))
            : _items.isEmpty
                ? _buildEmptyState(colors)
                : RefreshIndicator(
                    onRefresh: _loadItems,
                    color: const Color(0xff5B8AF5),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return _buildInboxRow(item, colors, isDarkMode);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(RitmoColors colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.card,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              CupertinoIcons.bell_slash,
              size: 48,
              color: colors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'هیچ اعلان یا یادآوری فعالی نیست',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.bold,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'همه چیز مرتب است! صندوق شما خالی است.',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Vazirmatn',
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxRow(InboxItem item, RitmoColors colors, bool isDarkMode) {
    final isUnread = item.status == InboxStatus.UNREAD;
    
    var itemColor = const Color(0xff5B8AF5);
    if (item.priority == InboxPriority.critical) {
      itemColor = Colors.redAccent;
    } else if (item.category == InboxCategory.MILESTONE) {
      itemColor = const Color(0xffFBBF24); 
    } else if (item.category == InboxCategory.INSIGHT) {
      itemColor = const Color(0xff34D399); 
    }

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (direction) async {
        await CentralInboxService.archive(item.id);
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'آیتم بایگانی شد.',
                style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 12),
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(CupertinoIcons.archivebox_fill, color: Colors.amber),
      ),
      child: RitmoTheme.glassCardLight(
        color: isUnread
            ? itemColor.withValues(alpha: 0.08)
            : colors.card.withValues(alpha: 0.6),
        border: Border.all(
          color: isUnread
              ? itemColor.withValues(alpha: 0.3)
              : colors.border.withValues(alpha: 0.5),
          width: isUnread ? 1.5 : 1.0,
        ),
        child: InkWell(
          onTap: () => InboxNavigator.open(context, item).then((_) => _loadItems()),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isUnread
                        ? itemColor.withValues(alpha: 0.15)
                        : colors.border.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: isUnread ? itemColor : colors.textSecondary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.categoryLabelFa,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isUnread ? itemColor : colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                          Text(
                            _toPersianDigits(_formatDateTime(item.createdAt)),
                            style: TextStyle(
                              fontSize: 8.5,
                              color: colors.textSecondary,
                              fontFamily: 'Vazirmatn',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                          color: colors.textPrimary,
                          fontFamily: 'Vazirmatn',
                        ),
                      ),
                      if (item.body != null && item.body!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          item.body!,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textSecondary,
                            fontFamily: 'Vazirmatn',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
