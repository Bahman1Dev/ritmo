import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/chat/chat_models.dart';
import 'package:ritmo/core/ai/chat/chat_repository.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/ux/ritmo_directional_icon.dart';
import 'package:ritmo/core/ux/ritmo_haptics.dart';


class ChatSessionListScreen extends StatefulWidget {
  const ChatSessionListScreen({super.key});

  @override
  State<ChatSessionListScreen> createState() => _ChatSessionListScreenState();
}

class _ChatSessionListScreenState extends State<ChatSessionListScreen> {
  List<ChatSession> _sessions = [];
  bool _isLoading = true;
  final Map<String, Timer> _pendingDeletions = {};

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    // Force execute any remaining pending deletions immediately
    _pendingDeletions.forEach((id, timer) {
      timer.cancel();
      ChatRepository.instance.deleteSession(id);
    });
    super.dispose();
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);
    try {
      final list = await ChatRepository.instance.listSessions();
      if (mounted) {
        setState(() {
          _sessions = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _dismissSession(ChatSession session) {
    RitmoHaptics.warning();
    final id = session.id;

    setState(() {
      _sessions.removeWhere((s) => s.id == id);
    });

    final timer = Timer(const Duration(seconds: 5), () async {
      _pendingDeletions.remove(id);
      await ChatRepository.instance.deleteSession(id);
    });
    _pendingDeletions[id] = timer;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'گفتگو حذف شد.',
          style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.white),
          textAlign: TextAlign.right,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: const Color(0xff1E2230),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'انصراف',
          textColor: const Color(0xff5B8AF5),
          onPressed: () {
            final pendingTimer = _pendingDeletions.remove(id);
            if (pendingTimer != null) {
              pendingTimer.cancel();
              _loadSessions();
            }
          },
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'همین الان';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} دقیقه پیش';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ساعت پیش';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} روز پیش';
    } else {
      return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RitmoTheme.buildBackgroundContainer(
        context: context,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: RitmoIcons.back(context, color: colors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'گفتگوهای دستیار هوشمند',
              style: TextStyle(
                color: colors.textPrimary,
                fontFamily: 'Vazirmatn',
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xff5B8AF5)))
              : _sessions.isEmpty
                  ? Center(
                      child: Text(
                        'هنوز هیچ گفتگویی ایجاد نشده است.',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 13,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _sessions.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        return Dismissible(
                          key: ValueKey(session.id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _dismissSession(session),
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(CupertinoIcons.trash, color: Colors.white, size: 20),
                          ),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                session.summary ?? 'گفتگوی بدون عنوان',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: colors.textPrimary,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${session.messageCount} پیام · ${_formatRelativeTime(session.lastMessageAt)}',
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 11,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ),
                              trailing: Icon(
                                CupertinoIcons.chevron_left,
                                color: colors.textSecondary.withValues(alpha: 0.5),
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.pop(context, session.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: const Color(0xff5B8AF5),
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: () async {
              RitmoHaptics.confirm();
              final s = await ChatRepository.instance.createSession();
              if (context.mounted) {
                Navigator.pop(context, s.id);
              }
            },
            child: const Icon(Icons.add, size: 24),
          ),
        ),
      ),
    );
  }
}
