import 'package:ritmo/core/services/bazaar_gateway.dart';
import 'package:ritmo/core/services/myket_gateway.dart';

abstract class PaymentGateway {
  Future<void> init();
  Future<Map<String, String>> getProductDetails(List<String> skus);
  Future<PurchaseResult> purchase(String sku);
  Future<List<PurchaseInfo>> restorePurchases();
  Future<void> dispose();
}

class PurchaseResult {

  PurchaseResult({required this.success, this.purchaseToken, this.errorMessage});
  final bool success;
  final String? purchaseToken;
  final String? errorMessage;
}

class PurchaseInfo {

  PurchaseInfo({required this.sku, required this.purchaseToken, required this.purchaseTime});
  final String sku;
  final String purchaseToken;
  final int purchaseTime;
}

class PaymentService {
  static PaymentGateway? _gateway;

  static PaymentGateway get gateway {
    if (_gateway == null) {
      const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'bazaar');
      if (flavor == 'myket') {
        _gateway = MyketGateway();
      } else {
        _gateway = BazaarGateway();
      }
    }
    return _gateway!;
  }
}
