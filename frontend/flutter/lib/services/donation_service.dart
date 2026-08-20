import '../config/api_config.dart';
import '../models/donation_model.dart';
import 'api_service.dart';

class DonationService {
  static List<dynamic> _extractContent(dynamic data) {
    if (data is Map && data.containsKey('content')) {
      return data['content'] as List<dynamic>;
    }
    if (data is List) return data;
    return [];
  }

  static Future<List<DonationModel>> getDonationsForCase(int caseId) async {
    final data = await ApiService.get(ApiConfig.donationsForCase(caseId));
    return _extractContent(data).map((e) => DonationModel.fromJson(e)).toList();
  }

  static Future<DonationModel> donate({
    required int caseId,
    required String donorName,
    required int amountInr,
    String? message,
    String? paymentMethod,
    String? billOffsetDetails,
  }) async {
    final data = await ApiService.post(ApiConfig.donations, {
      'caseId': caseId,
      'amount': amountInr.toDouble(),
      'currency': 'INR',
      'paymentProvider': paymentMethod ?? 'DummyPaymentProvider',
      'paymentReference': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'message': message ?? 'Offsetting treatment bills',
    });
    return DonationModel.fromJson(data);
  }
}
