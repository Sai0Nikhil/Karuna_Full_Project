import '../config/api_config.dart';
import '../models/adoption_model.dart';
import 'api_service.dart';

class AdoptionService {
  static Future<List<AdoptionModel>> getAdoptionsForCase(int caseId) async {
    final data = await ApiService.get(ApiConfig.adoptionsForCase(caseId));
    return (data as List).map((e) => AdoptionModel.fromJson(e)).toList();
  }

  static Future<AdoptionModel> applyForAdoption({
    required int caseId,
    required String applicantName,
    required String contact,
    required String reason,
    String? adopterIdUrl,
  }) async {
    final data = await ApiService.post(ApiConfig.applyAdoption(caseId), {
      'applicantName': applicantName,
      'contact': contact,
      'reason': reason,
      if (adopterIdUrl != null && adopterIdUrl.isNotEmpty) 'adopterIdUrl': adopterIdUrl,
    });
    return AdoptionModel.fromJson(data);
  }

  static Future<AdoptionModel> addCheckin({
    required int appId,
    required String text,
    String? photoUrl,
  }) async {
    final data = await ApiService.post('${ApiConfig.adoptions}/$appId/checkin', {
      'text': text,
      'photoUrl': photoUrl ?? '',
    });
    return AdoptionModel.fromJson(data);
  }
}
