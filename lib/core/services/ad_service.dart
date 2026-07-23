import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/premium_service.dart';
import 'package:ritmo/features/premium/presentation/premium_upgrade_sheet.dart';
import 'package:sqflite/sqflite.dart';
// Conditionally import tapsell_plus to avoid compilation issues if any,
// but since it's already in pubspec, standard import is fine. We just guard execution.
import 'package:tapsell_plus/tapsell_plus.dart';

class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();

  static const String _tapsellAppId = 'PLACEHOLDER_TAPSELL_APP_ID';
  static const String _bannerZoneId = 'PLACEHOLDER_BANNER_ZONE_ID';
  static const String _interstitialZoneId = 'PLACEHOLDER_INTERSTITIAL_ZONE_ID';

  bool _initialized = false;

  bool get _isTapsellSupported {
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    if (PremiumService.instance.isPremium) return;
    if (!_isTapsellSupported) return;
    if (_initialized) return;

    try {
      await TapsellPlus.instance.initialize(_tapsellAppId);
      _initialized = true;
    } catch (e) {
      debugPrint('AdService: Tapsell initialization failed: $e');
    }
  }

  /// Returns a banner ad widget if the user is free, otherwise returns an empty SizedBox.
  Widget getBannerAd() {
    if (PremiumService.instance.isPremium) {
      return const SizedBox.shrink();
    }

    return StatefulBuilder(
      builder: (context, setState) {
        if (!_isTapsellSupported) {
          return _buildSimulatedBannerAd(context);
        }

        if (!_initialized) {
          init().then((_) {
            if (context.mounted) setState(() {});
          });
          return const SizedBox.shrink();
        }

        try {
          return Container(
            alignment: Alignment.center,
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 50,
            child: const TapsellPlusBannerAd(
              zoneId: _bannerZoneId,
              bannerType: TapsellPlusBannerType.BANNER_320x50,
              margin: EdgeInsets.all(0),
            ),
          );
        } catch (e) {
          debugPrint('AdService banner rendering error: $e; falling back to simulated ad');
          return _buildSimulatedBannerAd(context);
        }
      },
    );
  }

  Widget _buildSimulatedBannerAd(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xff1A1A2E), Color(0xff22223B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFFA500).withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xffFFA500),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'تبلیغ',
              style: TextStyle(
                color: Colors.black,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                fontFamily: 'Vazirmatn',
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ریتم؛ دستیار هوشمند و ریتمیک شما 💎',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'خرید اشتراک پریمیوم برای حذف تبلیغات و دسترسی کامل',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 9,
                    fontFamily: 'Vazirmatn',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              PremiumUpgradeSheet.show(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFFA500),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'ارتقا',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  /// Shows an interstitial ad if allowed (max 1 per day, free users only)
  Future<void> showInterstitialAd([BuildContext? context]) async {
    if (PremiumService.instance.isPremium) return;

    final db = await DatabaseHelper.instance.database;
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);

    // Check daily limit
    final settings = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['last_interstitial_ad_date'],
    );

    if (settings.isNotEmpty && settings.first['value'] == todayStr) {
      debugPrint('AdService: Interstitial daily limit reached.');
      return;
    }

    if (!_isTapsellSupported) {
      if (context != null && context.mounted) {
        _showSimulatedInterstitial(context, todayStr);
      }
      return;
    }

    await init();
    if (!_initialized) {
      if (context != null && context.mounted) {
        _showSimulatedInterstitial(context, todayStr);
      }
      return;
    }

    try {
      // Request and show ad
      final adResponse = await TapsellPlus.instance.requestInterstitialAd(_interstitialZoneId);
      if (adResponse.isNotEmpty) {
        await TapsellPlus.instance.showInterstitialAd(adResponse);

        // Save show date to DB
        await db.insert(
          'app_settings',
          {'key': 'last_interstitial_ad_date', 'value': todayStr},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('AdService interstitial error: $e; falling back to simulated');
      if (context != null && context.mounted) {
        _showSimulatedInterstitial(context, todayStr);
      }
    }
  }

  void _showSimulatedInterstitial(BuildContext context, String todayStr) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Interstitial Ad',
      barrierColor: Colors.black.withValues(alpha: 0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return _SimulatedInterstitialDialog(
          onClose: () async {
            try {
              final db = await DatabaseHelper.instance.database;
              await db.insert(
                'app_settings',
                {'key': 'last_interstitial_ad_date', 'value': todayStr},
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            } catch (_) {}
          },
        );
      },
    );
  }
}

class _SimulatedInterstitialDialog extends StatefulWidget {
  const _SimulatedInterstitialDialog({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_SimulatedInterstitialDialog> createState() => _SimulatedInterstitialDialogState();
}

class _SimulatedInterstitialDialogState extends State<_SimulatedInterstitialDialog> {
  int _secondsLeft = 3;
  bool _canClose = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          _canClose = true;
        }
      });
      return _secondsLeft > 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xff1E1E2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffFFA500).withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFA500),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'تبلیغ شبیه‌سازی‌شده',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _canClose
                        ? () {
                            widget.onClose();
                            Navigator.pop(context);
                          }
                        : null,
                    icon: Icon(
                      _canClose ? Icons.close : Icons.hourglass_empty,
                      size: 16,
                      color: _canClose ? Colors.white : Colors.white24,
                    ),
                    label: Text(
                      _canClose ? 'بستن تبلیغ' : 'بستن بعد از $_secondsLeft ثانیه',
                      style: TextStyle(
                        color: _canClose ? Colors.white : Colors.white24,
                        fontSize: 11,
                        fontFamily: 'Vazirmatn',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Icon(
                Icons.star_purple500_outlined,
                size: 64,
                color: Color(0xffFFA500),
              ),
              const SizedBox(height: 16),
              const Text(
                'نسخه پریمیوم ریتم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Vazirmatn',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'با خرید اشتراک ویژه، تمام تبلیغات را حذف کنید و به موتورهای برنامه‌ریزی هوش مصنوعی، ماژول دوره‌ها و کنکور دسترسی کامل داشته باشید.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Vazirmatn',
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  PremiumUpgradeSheet.show(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffFFA500),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text(
                  'مشاهده گزینه‌های ارتقا 💎',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TapsellPlusBannerAd extends StatefulWidget {

  const TapsellPlusBannerAd({
    super.key,
    required this.zoneId,
    required this.bannerType,
    required this.margin,
  });
  final String zoneId;
  final TapsellPlusBannerType bannerType;
  final EdgeInsets margin;

  @override
  State<TapsellPlusBannerAd> createState() => _TapsellPlusBannerAdState();
}

class _TapsellPlusBannerAdState extends State<TapsellPlusBannerAd> {
  String? _responseId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    try {
      await TapsellPlus.instance.requestStandardBannerAd(
        widget.zoneId,
        widget.bannerType,
        onResponse: (map) {
          final respId = map['response_id'];
          if (respId != null && mounted) {
            _responseId = respId;
            TapsellPlus.instance.showStandardBannerAd(
              respId,
              TapsellPlusHorizontalGravity.BOTTOM,
              TapsellPlusVerticalGravity.CENTER,
              margin: widget.margin,
            );
          }
        },
        onError: (map) {
          debugPrint("TapsellPlusBannerAd load error: ${map['error_message']}");
        },
      );
    } catch (e) {
      debugPrint('TapsellPlusBannerAd error: $e');
    }
  }

  @override
  void dispose() {
    if (_responseId != null) {
      TapsellPlus.instance.destroyStandardBanner(_responseId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: Colors.transparent,
    );
  }
}
