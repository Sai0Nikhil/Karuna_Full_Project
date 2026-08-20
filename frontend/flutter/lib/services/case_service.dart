import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/case_model.dart';
import 'api_service.dart';

class CaseService {
  // Helper: extract list from Spring Page or plain list
  static List<dynamic> _extractContent(dynamic data) {
    if (data is Map && data.containsKey('content')) {
      return data['content'] as List<dynamic>;
    }
    if (data is List) return data;
    return [];
  }

  static Future<List<CaseModel>> getAllCases() async {
    final data = await ApiService.get(ApiConfig.cases);
    return _extractContent(data).map((e) => CaseModel.fromJson(e)).toList();
  }

  static Future<List<CaseModel>> getOpenCases() async {
    final data = await ApiService.get(ApiConfig.openCases);
    return _extractContent(data).map((e) => CaseModel.fromJson(e)).toList();
  }

  static Future<List<CaseModel>> getMyCases() async {
    final data = await ApiService.get(ApiConfig.myCases);
    return _extractContent(data).map((e) => CaseModel.fromJson(e)).toList();
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
    String? imageDataUrl, // Fallback base64
    String? photoPath, // Local file path to upload first
    String? firstAidSteps,
    int? estimatedCostInr,
    String? notes,
  }) async {
    String? imageUrl = imageDataUrl;
    
    // Upload local file if photoPath is provided
    if (photoPath != null) {
      final uploadedUrl = await uploadImage(File(photoPath));
      if (uploadedUrl != null) {
        imageUrl = uploadedUrl;
      }
    }

    // Build a descriptive title from available info
    final speciesStr = species ?? 'Animal';
    final injuryStr = injuryType ?? 'injury';
    final locationStr = locationLabel ?? 'Unknown location';
    final title = '$speciesStr with $injuryStr at $locationStr';

    // Map Flutter severity strings to backend PriorityLevel enum
    String? priorityStr;
    if (severity != null) {
      switch (severity.toLowerCase()) {
        case 'critical': priorityStr = 'CRITICAL'; break;
        case 'urgent':   priorityStr = 'URGENT';   break;
        default:         priorityStr = 'ROUTINE';
      }
    }

    final body = <String, dynamic>{
      'title': title,
      'description': probableCondition ?? '$speciesStr reported at $locationStr',
      if (species != null)           'species': species,
      if (injuryType != null)        'injuryType': injuryType,
      if (priorityStr != null)       'priority': priorityStr,
      if (locationLabel != null)     'locationLabel': locationLabel,
      if (locationLabel != null)     'location': locationLabel,
      if (latitude != null)          'latitude': latitude,
      if (longitude != null)         'longitude': longitude,
      if (probableCondition != null) 'probableCondition': probableCondition,
      if (imageUrl != null)          'imageUrl': imageUrl,
      if (firstAidSteps != null)     'firstAidSteps': firstAidSteps,
      if (estimatedCostInr != null)  'estimatedCostInr': estimatedCostInr,
      if (notes != null)             'notes': notes,
    };
    final data = await ApiService.post(ApiConfig.cases, body);
    return CaseModel.fromJson(data);
  }

  // Upload image as multipart, returns the URL
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/image');
      final request = http.MultipartRequest('POST', uri);
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await request.send().timeout(ApiConfig.timeout);
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final json = jsonDecode(body);
        return json['imageUrl'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<CaseModel> assignCase(
    int id, {
    String? responderId,
    String? responderName,
    String? ngo,
  }) async {
    final data = await ApiService.post(ApiConfig.assignCase(id), {
      if (responderId != null) 'primaryVolunteerId': responderId,
    });
    return CaseModel.fromJson(data);
  }

  // Advance status — backend expects {status: "ASSIGNED"} at POST /api/cases/{id}/status
  static Future<CaseModel> advanceStatus(int id, String status) async {
    final data = await ApiService.post(ApiConfig.advanceCase(id), {
      'status': status.toUpperCase(),
    });
    return CaseModel.fromJson(data);
  }

  // Update notes via PUT /api/cases/{id}
  static Future<CaseModel> addNote(int id, String text) async {
    final data = await ApiService.put(ApiConfig.caseById(id), {'notes': text});
    return CaseModel.fromJson(data);
  }
}
