import 'package:flutter/services.dart';
import 'package:ritmo/core/services/payment_gateway.dart';

class MyketGateway implements PaymentGateway {
  static const MethodChannel _channel = MethodChannel('com.ritmo.app/myket_billing');

  // TODO: کلید واقعی از پنل مایکت
  static const String _myketRsaKey = 'PLACEHOLDER_MYKET_RSA_KEY';

  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      final success = await _channel.invokeMethod('init', {'rsaKey': _myketRsaKey}) ?? false;
      _initialized = success;
    } catch (_) {
      _initialized = false;
    }
  }

  @override
  Future<Map<String, String>> getProductDetails(List<String> skus) async {
    await init();
    if (!_initialized) return {};
    try {
      final details = await _channel.invokeMethod('getProductDetails', {'skus': skus});
      if (details == null) return {};
      return details.map((key, value) => MapEntry(key.toString(), value.toString()));
    } catch (_) {
      return {};
    }
  }

  @override
  Future<PurchaseResult> purchase(String sku) async {
    await init();
    if (!_initialized) {
      return PurchaseResult(success: false, errorMessage: 'خطا در اتصال به مایکت');
    }
    try {
      final result = await _channel.invokeMethod('purchase', {'sku': sku});
      if (result != null && result['success'] == true) {
        return PurchaseResult(success: true, purchaseToken: result['purchaseToken']?.toString());
      }
      return PurchaseResult(success: false, errorMessage: result?['errorMessage']?.toString() ?? 'خرید با خطا مواجه شد.');
    } catch (e) {
      return PurchaseResult(success: false, errorMessage: 'خطای سیستمی: $e');
    }
  }

  @override
  Future<List<PurchaseInfo>> restorePurchases() async {
    await init();
    if (!_initialized) return [];
    try {
      final list = await _channel.invokeMethod('restorePurchases');
      if (list == null) return [];
      return list.map((item) {
        final map = item as Map;
        return PurchaseInfo(
          sku: map['sku'].toString(),
          purchaseToken: map['purchaseToken'].toString(),
          purchaseTime: int.tryParse(map['purchaseTime'].toString()) ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await _channel.invokeMethod('dispose');
      _initialized = false;
    }
  }
}
