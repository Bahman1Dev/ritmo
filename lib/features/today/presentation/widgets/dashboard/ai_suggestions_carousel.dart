import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ritmo/core/theme/ritmo_theme.dart';
import 'package:ritmo/core/utils/ritmo_toast.dart';
import 'package:ritmo/features/today/presentation/assistant_suggestions_service.dart';

class AiSuggestionsCarousel extends StatefulWidget {

  const AiSuggestionsCarousel({
    super.key,
    required this.onSuggestionApplied,
  });
  final VoidCallback onSuggestionApplied;

  @override
  State<AiSuggestionsCarousel> createState() => _AiSuggestionsCarouselState();
}

class _AiSuggestionsCarouselState extends State<AiSuggestionsCarousel> {
  List<AssistantSuggestion> _suggestions = [];
  bool _isLoading = true;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final list = await AssistantSuggestionsService.getPendingSuggestions();
      if (mounted) {
        setState(() {
          _suggestions = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleApply(AssistantSuggestion suggestion) async {
    try {
      final success = await AssistantSuggestionsService.applySuggestion(suggestion.id, context);
      if (success && mounted) {
        RitmoToast.show(
          context,
          'پیشنهاد با موفقیت اعمال شد.',
          icon: CupertinoIcons.sparkles,
          iconColor: const Color(0xff06B6D4),
        );
        _loadSuggestions();
        widget.onSuggestionApplied();
      }
    } catch (e) {
      debugPrint('Error applying suggestion: $e');
    }
  }

  Future<void> _handleDismiss(AssistantSuggestion suggestion) async {
    try {
      await AssistantSuggestionsService.dismissSuggestion(suggestion.id);
      if (mounted) {
        RitmoToast.show(
          context,
          'پیشنهاد رد شد.',
          icon: CupertinoIcons.clear_circled,
          iconColor: Colors.grey,
        );
        _loadSuggestions();
      }
    } catch (e) {
      debugPrint('Error dismissing suggestion: $e');
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ENERGY':
        return Icons.bolt_rounded;
      case 'SPORTS':
        return Icons.fitness_center_rounded;
      case 'CIRCADIAN':
        return Icons.menu_book_rounded;
      case 'COGNITIVE':
        return Icons.spa_rounded;
      default:
        return CupertinoIcons.sparkles;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'ENERGY':
        return const Color(0xffFBBF24); // Gold
      case 'SPORTS':
        return const Color(0xff10B981); // Emerald
      case 'CIRCADIAN':
        return const Color(0xff6366F1); // Indigo
      case 'COGNITIVE':
        return const Color(0xffEC4899); // Pink
      default:
        return const Color(0xff06B6D4); // Cyan
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'پیشنهادهای هوشمند ریتمو ✨',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                  fontFamily: 'Vazirmatn',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 185,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _suggestions.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                final color = _getColor(suggestion.suggestionType);
                final icon = _getIcon(suggestion.suggestionType);

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: RitmoTheme.glassCardLight(
                    borderRadius: RitmoRadius.cardLarge,
                    color: colors.card.withValues(alpha: 0.65),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                suggestion.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: colors.textPrimary,
                                  fontFamily: 'Vazirmatn',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              suggestion.body,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.6,
                                color: colors.textSecondary,
                                fontFamily: 'Vazirmatn',
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _handleDismiss(suggestion),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: Text(
                                  'رد پیشنهاد',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.textSecondary,
                                    fontFamily: 'Vazirmatn',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleApply(suggestion),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: color.withValues(alpha: 0.15),
                                  foregroundColor: color,
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(RitmoRadius.chip),
                                    side: BorderSide(color: color.withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(CupertinoIcons.sparkles, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'اعمال پیشنهاد',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_suggestions.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _suggestions.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? colors.primary
                        : colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
