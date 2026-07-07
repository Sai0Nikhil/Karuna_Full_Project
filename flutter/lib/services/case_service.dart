import '../config/api_config.dart';
import '../models/case_model.dart';
import 'api_service.dart';

class CaseService {
  static Future<List<CaseModel>> getAllCases() async {
    final data = await ApiService.get(ApiConfig.cases);
    return (data as List).map((e) => CaseModel.fromJson(e)).toList();
  }

  static Future<List<CaseModel>> getOpenCases() async {
    final data = await ApiService.get(ApiConfig.openCases);
    return (data as List).map((e) => CaseModel.fromJson(e)).toList();
  }

  static Future<List<CaseModel>> getMyCases() async {
    final data = await ApiService.get(ApiConfig.myCases);
    return (data as List).map((e) => CaseModel.fromJson(e)).toList();
  }

  static Future<CaseModel> getCase(int id) async {
    final data = await ApiService.get(ApiConfig.caseById(id));
    return CaseModel.fromJson(data);
  }

  static Future<CaseModel> createCase({
    required String reporterName,
    String? reporterContact,
    String? species,
    String? injuryType,
    String? severity,
    String? locationLabel,
    double? latitude,
    double? longitude,
    String? probableCondition,
    String? imageDataUrl,
  }) async {
    final body = {
      'reporterName': reporterName,
      if (reporterContact != null) 'reporterContact': reporterContact,
      if (species != null) 'species': species,
      if (injuryType != null) 'injuryType': injuryType,
      if (severity != null) 'severity': severity,
      if (locationLabel != null) 'locationLabel': locationLabel,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (probableCondition != null) 'probableCondition': probableCondition,
      if (imageDataUrl != null) 'imageDataUrl': imageDataUrl,
    };
    final data = await ApiService.post(ApiConfig.cases, body);
    return CaseModel.fromJson(data);
  }

  static Future<CaseModel> assignCase(int id, {String? responderId, String? responderName, String? ngo}) async {
    final data = await ApiService.post(ApiConfig.assignCase(id), {
      if (responderId != null) 'responderId': responderId,
      if (responderName != null) 'responderName': responderName,
      if (ngo != null) 'ngo': ngo,
    });
    return CaseModel.fromJson(data);
  }

  static Future<CaseModel> advanceStatus(int id, String status, {String actor = 'NGO Staff'}) async {
    final data = await ApiService.post(ApiConfig.advanceCase(id), {
      'event': status,
      'actor': actor,
    });
    return CaseModel.fromJson(data);
  }

  static Future<CaseModel> addNote(int id, String text) async {
    final data = await ApiService.post(ApiConfig.caseNotes(id), {'text': text});
    return CaseModel.fromJson(data);
  }
}
