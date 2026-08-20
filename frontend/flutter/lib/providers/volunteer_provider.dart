import 'package:flutter/foundation.dart';
import '../models/case_model.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class VolunteerProvider extends ChangeNotifier {
  List<CaseModel> _assignedCases = [];
  List<CaseModel> _openCases = [];
  bool _loading = false;
  String? _error;

  List<CaseModel> get assignedCases => _assignedCases;
  List<CaseModel> get openCases => _openCases;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadAssignedCases() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.get('${ApiConfig.baseUrl}/cases/my');
      _assignedCases = _extractList(data);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> loadOpenCases() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiService.get(ApiConfig.openCases);
      _openCases = _extractList(data);
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> acceptCase(int caseId) async {
    try {
      await ApiService.put('${ApiConfig.baseUrl}/cases/$caseId/accept', {});
      await loadAssignedCases();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> advanceStatus(int caseId, String newStatus) async {
    try {
      await ApiService.put(
        '${ApiConfig.baseUrl}/cases/$caseId/status',
        {'status': newStatus},
      );
      await loadAssignedCases();
      return true;
    } catch (_) {
      return false;
    }
  }

  List<CaseModel> _extractList(dynamic data) {
    List<dynamic> raw;
    if (data is Map && data.containsKey('content')) {
      raw = data['content'] as List<dynamic>;
    } else if (data is List) {
      raw = data;
    } else {
      raw = [];
    }
    return raw.map((e) => CaseModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
