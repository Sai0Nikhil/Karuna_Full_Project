import '../config/api_config.dart';
import '../models/donation_model.dart';
import 'api_service.dart';

class DonationService {
  static Future<List<DonationModel>> getDonationsForCase(int caseId) async {
    final data = await ApiService.get(ApiConfig.donationsForCase(caseId));
    return (data as List).map((e) => DonationModel.fromJson(e)).toList();
  }

  static Future<DonationModel> donate({
    required int caseId,
    required String donorName,
    required int amountInr,
    String? message,
    String? paymentMethod,
    String? billOffsetDetails,
  }) async {
    final data = await ApiService.post(ApiConfig.donationsForCase(caseId), {
      'donorName': donorName,
      'amountInr': amountInr,
      if (message != null && message.isNotEmpty) 'message': message,
      if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
      if (billOffsetDetails != null && billOffsetDetails.isNotEmpty) 'billOffsetDetails': billOffsetDetails,
    });
    return DonationModel.fromJson(data);
  }
}
