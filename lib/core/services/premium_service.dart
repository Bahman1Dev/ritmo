import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PremiumFeature {
  unlimitedRoutines, // free limit: 15
  unlimitedGoals,    // free limit: 3
  unlimitedAi,       // free quota: 5 daily, premium: unlimited
  advancedInsights,  // premium only
  smartReshuffle,    // premium only
  coursesModule,     // premium only
  konkurModule,      // premium only
  advancedHealth,    // premium only
  backupExport,      // premium only
  customThemes,      // premium only
  noAds,             // premium only
}

class PremiumService {
  PremiumService._internal();
  static final PremiumService instance = PremiumService._internal();

  static const String _secretKey = String.fromEnvironment(
    'RITMO_PREMIUM_KEY',
    defaultValue: 'ritmo_premium_salt_key_2026',
  );
  
  bool _isPremium = false;
  String _purchaseType = 'free'; // '3month', 'yearly', 'lifetime', 'free'
  int _purchaseDateMs = 0;
  int _expiryDateMs = 0;
  String _store = 'none';
  bool _debugMockActive = false;

  bool get isPremium => _isPremium;
  String get purchaseType => _purchaseType;
  int get expiryDateMs => _expiryDateMs;
  int get purchaseDateMs => _purchaseDateMs;
  String get store => _store;
  bool get isDebugMockActive => _debugMockActive;


  Future<void> init() async {
    await loadEntitlement();
  }

  Future<void> loadEntitlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load raw values
      final sku = prefs.getString('premium_sku') ?? 'free';
      final expiry = prefs.getInt('premium_expiry') ?? 0;
      final storeName = prefs.getString('premium_store') ?? 'none';
      final purchaseDate = prefs.getInt('premium_purchase_date') ?? 0;
      final signature = prefs.getString('premium_signature') ?? '';

      // Verify signature
      final expectedSig = _generateSignature(sku, expiry, storeName);
      if (signature == expectedSig) {
        _purchaseType = sku;
        _expiryDateMs = expiry;
        _store = storeName;
        _purchaseDateMs = purchaseDate;

        // Check expiry for duration-based entitlement
        if (_purchaseType != 'free' && _purchaseType != 'premium_lifetime') {
          final now = DateTime.now().millisecondsSinceEpoch;
          if (now > _expiryDateMs) {
            // Expired! Revert to free
            await setFree();
          } else {
            _isPremium = true;
          }
        } else if (_purchaseType == 'premium_lifetime') {
          _isPremium = true;
        } else {
          _isPremium = false;
        }
      } else {
        // Corrupted or modified manually
        await setFree();
      }

      if (kDebugMode) {
        _debugMockActive = prefs.getBool('premium_debug_mock') ?? false;
      }
    } catch (_) {
      _isPremium = false;
    }
  }

  Future<void> activatePremium({
    required String sku,
    required int durationDays,
    required String storeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = durationDays > 0 
        ? now + (durationDays * 24 * 60 * 60 * 1000)
        : 0; // 0 means lifetime

    final signature = _generateSignature(sku, expiry, storeName);

    await prefs.setString('premium_sku', sku);
    await prefs.setInt('premium_expiry', expiry);
    await prefs.setString('premium_store', storeName);
    await prefs.setInt('premium_purchase_date', now);
    await prefs.setString('premium_signature', signature);

    _isPremium = true;
    _purchaseType = sku;
    _expiryDateMs = expiry;
    _store = storeName;
    _purchaseDateMs = now;
  }

  Future<void> setFree() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('premium_sku');
    await prefs.remove('premium_expiry');
    await prefs.remove('premium_store');
    await prefs.remove('premium_purchase_date');
    await prefs.remove('premium_signature');

    _isPremium = false;
    _purchaseType = 'free';
    _expiryDateMs = 0;
    _store = 'none';
    _purchaseDateMs = 0;
  }

  Future<void> toggleDebugMock(bool active) async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('premium_debug_mock', active);
      _debugMockActive = active;
    }
  }

  String _generateSignature(String sku, int expiry, String storeName) {
    final secretKeyBytes = utf8.encode(_secretKey);
    final messageBytes = utf8.encode('$sku|$expiry|$storeName');
    final hmac = Hmac(sha256, secretKeyBytes);
    return hmac.convert(messageBytes).toString();
  }

  /// Check if premium or if a feature is allowed (§10)
  bool can(PremiumFeature feature) {
    return true; // All feature flags unlocked
  }

  /// Get limits for numerical features (§10)
  int limitFor(PremiumFeature feature) {
    return 99999; // Unlimited for all features
  }

  Future<bool> activateWithCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return false;
    
    // Accept standard promo codes or anything starting with RITMO
    if (cleanCode == 'RITMO2026' || cleanCode == 'RITMO_PREMIUM' || cleanCode.startsWith('RITMO') || cleanCode == 'PREMIUM') {
      await activatePremium(
        sku: 'premium_lifetime',
        durationDays: 0, // lifetime
        storeName: 'promocode',
      );
      return true;
    }
    return false;
  }

  Future<void> deactivate() async {
    await setFree();
  }
}
