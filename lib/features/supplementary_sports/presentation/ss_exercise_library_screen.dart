import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/features/supplementary_sports/presentation/widgets/shared/ss_lottie_player.dart';
import 'package:url_launcher/url_launcher.dart';

class SSExerciseLibraryScreen extends StatefulWidget {
  const SSExerciseLibraryScreen({super.key});

  @override
  State<SSExerciseLibraryScreen> createState() => _SSExerciseLibraryScreenState();
}

class _SSExerciseLibraryScreenState extends State<SSExerciseLibraryScreen> {
  List<Map<String, dynamic>> _allExercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];
  List<String> _categories = ['all'];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  String _normalizeCategoryKey(String? rawCategory) {
    final clean = (rawCategory ?? '').toLowerCase().trim();
    // ── Fitify native keys ────────────────────────────────────────
    if (clean == 'upper_body') return 'chest';          // شنا / بالاتنه
    if (clean == 'shoulder_and_back') return 'back';    // کمر / زیربغل
    if (clean == 'lower_body') return 'legs';           // پا
    if (clean == 'core') return 'abs';                  // شکم
    if (clean == 'cardio') return 'cardio';             // کاردیو
    if (clean == 'plyometric') return 'cardio';         // پلایومتریک
    if (clean == 'stretching' || clean == 'yoga') return 'stretch'; // کشش
    if (clean == 'warmup' || clean == 'balance') return 'stretch';  // گرم‌کردن

    // ── English keywords (legacy / custom exercises) ─────────────
    if (clean.contains('chest') || clean.contains('pec') ||
        clean.contains('upper_body') || clean.contains('push')) {
      return 'chest';
    }
    if (clean.contains('back') || clean.contains('lat') ||
        clean.contains('row') || clean.contains('shoulder_and_back')) {
      return 'back';
    }
    if (clean.contains('shoulder') || clean.contains('deltoid')) return 'back';
    if (clean.contains('lower_body') || clean.contains('leg') ||
        clean.contains('quad') || clean.contains('glute') ||
        clean.contains('hamstring') || clean.contains('calf')) {
      return 'legs';
    }
    if (clean.contains('arm') || clean.contains('bicep') ||
        clean.contains('tricep')) {
      return 'arms';
    }
    if (clean.contains('ab') || clean.contains('core') ||
        clean.contains('waist')) {
      return 'abs';
    }
    if (clean.contains('cardio') || clean.contains('hiit') ||
        clean.contains('run') || clean.contains('plyo')) {
      return 'cardio';
    }
    if (clean.contains('stretch') || clean.contains('recovery') ||
        clean.contains('yoga') || clean.contains('flex') ||
        clean.contains('warmup')) {
      return 'stretch';
    }
    return 'other';
  }

  String _translateCategory(String categoryKey) {
    final key = _normalizeCategoryKey(categoryKey);
    switch (key) {
      case 'all': return 'همه';
      case 'chest': return 'سینه و بالاتنه';
      case 'back': return 'پشت و زیربغل';
      case 'shoulders': return 'سرشانه';
      case 'legs': return 'پا و باسن';
      case 'arms': return 'بازو';
      case 'abs': return 'شکم و پهلو';
      case 'cardio': return 'کاردیو';
      case 'stretch': return 'کشش و یوگا';
      default: return 'سایر';
    }
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> results = await db.query('ss_exercise', orderBy: 'name ASC');

      final catKeys = <String>{'all'};
      for (final row in results) {
        final normKey = _normalizeCategoryKey(row['category']?.toString());
        catKeys.add(normKey);
      }

      const orderedKeys = ['all', 'chest', 'back', 'shoulders', 'legs', 'arms', 'abs', 'cardio', 'stretch', 'other'];
      final categoriesList = orderedKeys.where(catKeys.contains).toList();

      setState(() {
        _allExercises = results;
        _categories = categoriesList;
        _selectedCategory = 'all';
        _filterExercises();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading library exercises: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterExercises() {
    var temp = _allExercises;

    if (_selectedCategory != 'all') {
      temp = temp.where((ex) {
        final normKey = _normalizeCategoryKey(ex['category']?.toString());
        return normKey == _selectedCategory;
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      temp = temp.where((ex) {
        final name = ex['name']?.toString().toLowerCase() ?? '';
        final nameEn = ex['nameEn']?.toString().toLowerCase() ?? '';
        final equipment = ex['equipment']?.toString().toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        return name.contains(q) || nameEn.contains(q) || equipment.contains(q);
      }).toList();
    }

    setState(() {
      _filteredExercises = temp;
    });
  }

  int _getFarsiDayOfWeek(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday: return 3;
      case DateTime.tuesday: return 4;
      case DateTime.wednesday: return 5;
      case DateTime.thursday: return 6;
      case DateTime.friday: return 7;
      case DateTime.saturday: return 1;
      case DateTime.sunday: return 2;
    }
    return 1;
  }



  String _translateEquipment(String? equipment) {
    if (equipment == null || equipment.isEmpty) return 'وزن بدن';
    switch (equipment.toLowerCase()) {
      case 'dumbbell': return 'دمبل';
      case 'barbell': return 'هالتر';
      case 'kettlebell': return 'کتل‌بل';
      case 'machine': return 'دستگاه';
      case 'cable': return 'سیم‌کش';
      case 'band': return 'کش ورزشی';
      case 'none':
      case 'bodyweight': return 'وزن بدن';
      default: return equipment;
    }
  }

  Future<void> _addExerciseToTodayPlan(Map<String, dynamic> exercise) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final todayFarsiDay = _getFarsiDayOfWeek(DateTime.now());

      // Query today's plans
      final plans = await db.query(
        'ss_workout_plan',
        where: 'dayOfWeek = ?',
        whereArgs: [todayFarsiDay],
      );

      String planId;
      if (plans.isEmpty) {
        // Create new plan for today
        planId = 'plan_today_${DateTime.now().millisecondsSinceEpoch}';
        await db.insert('ss_workout_plan', {
          'id': planId,
          'dayOfWeek': todayFarsiDay,
          'muscleGroups': jsonEncode([_translateCategory((exercise['category'] ?? 'سایر').toString())]),
          'estimatedMinutes': 30,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        planId = plans.first['id'].toString();
      }

      // Query existing crossrefs to get max order index
      final crossRefs = await db.query(
        'ss_workout_exercise_crossref',
        where: 'planId = ?',
        whereArgs: [planId],
      );

      var maxOrder = 0;
      for (final ref in crossRefs) {
        final order = ref['orderIndex'] as int? ?? 0;
        if (order > maxOrder) maxOrder = order;
      }

      final crossRefId = 'ref_${planId}_${exercise['id']}_${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('ss_workout_exercise_crossref', {
        'id': crossRefId,
        'planId': planId,
        'exerciseId': exercise['id'],
        'orderIndex': maxOrder + 1,
        'difficultyOffset': 0.0,
        'targetSets': 3,
        'targetReps': 10,
        'targetWeight': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'حرکت "${exercise['name']}" با موفقیت به برنامه امروز شما اضافه شد.',
            style: const TextStyle(fontFamily: 'Vazirmatn'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } catch (e) {
      debugPrint('Error adding exercise to plan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'خطا در اضافه کردن حرکت به برنامه.',
            style: TextStyle(fontFamily: 'Vazirmatn'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showExerciseDetailSheet(Map<String, dynamic> exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 1.5),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  exercise['name']?.toString() ?? '',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                      child: SSExerciseAnimationCard(
                        category: exercise['category']?.toString() ?? 'core',
                        exerciseId: exercise['id']?.toString(),
                        height: 140,
                      ),
                    ),
                  ),
                ),
                if (exercise['nameEn'] != null && exercise['nameEn'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    exercise['nameEn'].toString(),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D5B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _translateCategory(exercise['category']?.toString() ?? ''),
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: Color(0xFF2E7D5B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _translateEquipment(exercise['equipment']?.toString()),
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'راهنمای اجرا:',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise['instructions']?.toString() ?? 'راهنمایی برای این حرکت ثبت نشده است.',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    height: 1.6,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 32),
                if (exercise['videoUrl'] != null && exercise['videoUrl'].toString().isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isDark ? Colors.redAccent.withValues(alpha: 0.8) : Colors.red.withValues(alpha: 0.8), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(CupertinoIcons.play_circle_fill, color: isDark ? Colors.redAccent : Colors.red),
                      label: Text(
                        'مشاهده ویدیو آموزش حرکت 🎥',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.redAccent : Colors.red,
                        ),
                      ),
                      onPressed: () async {
                        final urlStr = exercise['videoUrl'].toString();
                        final uri = Uri.parse(urlStr);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D5B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: const Icon(CupertinoIcons.add, color: Colors.white),
                    label: const Text(
                      'اضافه کردن به برنامه امروز',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _addExerciseToTodayPlan(exercise);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAF8),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0.5,
        leading: BackButton(
          color: isDark ? Colors.white : Colors.black87,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'کتابخانه حرکات ورزشی 📚',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Search Bar Card
            Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      style: const TextStyle(fontFamily: 'Vazirmatn'),
                      decoration: InputDecoration(
                        icon: const Icon(CupertinoIcons.search, color: Colors.grey),
                        hintText: 'جستجوی نام حرکت یا تجهیزات...',
                        hintStyle: const TextStyle(fontFamily: 'Vazirmatn', fontSize: 13, color: Colors.grey),
                        border: InputBorder.none,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _filterExercises();
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        _searchQuery = val;
                        _filterExercises();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Categories chips
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSelected = cat == _selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedCategory = cat;
                              _filterExercises();
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(colors: [Color(0xFF2E7D5B), Color(0xFF1B5E20)])
                                  : null,
                              color: isSelected ? null : (isDark ? Colors.white10 : Colors.white),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : (isDark ? Colors.white10 : Colors.black12),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _translateCategory(cat),
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredExercises.isEmpty
                      ? Center(
                          child: Text(
                            'هیچ حرکتی یافت نشد.',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 14,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredExercises.length,
                          itemBuilder: (context, idx) {
                            final ex = _filteredExercises[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0.5,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                title: Text(
                                  ex['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Text(
                                        _translateCategory(ex['category']?.toString() ?? ''),
                                        style: const TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 12,
                                          color: Color(0xFF2E7D5B),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${_translateEquipment(ex['equipment']?.toString())}',
                                        style: TextStyle(
                                          fontFamily: 'Vazirmatn',
                                          fontSize: 12,
                                          color: isDark ? Colors.white38 : Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                onTap: () => _showExerciseDetailSheet(ex),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
