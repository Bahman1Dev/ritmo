import 'package:flutter_poolakey/flutter_poolakey.dart' hide PurchaseInfo;
import 'package:ritmo/core/services/payment_gateway.dart';

class BazaarGateway implements PaymentGateway {
  // TODO: کلید واقعی از پنل بازار
  static const String _bazaarRsaKey = 'PLACEHOLDER_BAZAAR_RSA_KEY';

  bool _connected = false;

  @override
  Future<void> init() async {
    if (_connected) return;
    try {
      await FlutterPoolakey.connect(
        _bazaarRsaKey,
        onDisconnected: () {
          _connected = false;
        },
      );
      _connected = true;
    } catch (_) {
      _connected = false;
    }
  }

  @override
  Future<Map<String, String>> getProductDetails(List<String> skus) async {
    await init();
    if (!_connected) return {};
    try {
      final details = await FlutterPoolakey.getInAppSkuDetails(skus);
      final result = <String, String>{};
      for (final detail in details) {
        result[detail.sku] = detail.price;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<PurchaseResult> purchase(String sku) async {
    await init();
    if (!_connected) {
      return PurchaseResult(success: false, errorMessage: 'خطا در اتصال به کافه‌بازار');
    }
    try {
      final info = await FlutterPoolakey.purchase(sku);
      return PurchaseResult(success: true, purchaseToken: info.purchaseToken);
    } catch (e) {
      return PurchaseResult(success: false, errorMessage: _parseBazaarError(e));
    }
  }

  @override
  Future<List<PurchaseInfo>> restorePurchases() async {
    await init();
    if (!_connected) return [];
    try {
      final purchases = await FlutterPoolakey.getAllPurchasedProducts();
      return purchases.map((p) => PurchaseInfo(
        sku: p.productId,
        purchaseToken: p.purchaseToken,
        purchaseTime: p.purchaseTime,
      )).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    if (_connected) {
      await FlutterPoolakey.disconnect();
      _connected = false;
    }
  }

  String _parseBazaarError(dynamic error) {
    final str = error.toString().toLowerCase();
    if (str.contains('user canceled') || str.contains('canceled')) {
      return 'خرید توسط کاربر لغو شد.';
    }
    if (str.contains('service unavailable') || str.contains('disconnected')) {
      return 'سرویس پرداخت بازار در دسترس نیست.';
    }
    return 'خطایی در فرآیند خرید رخ داد: $error';
  }
}
