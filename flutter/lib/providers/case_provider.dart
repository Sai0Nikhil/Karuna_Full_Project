import 'package:flutter/foundation.dart';
import '../models/case_model.dart';
import '../services/case_service.dart';

class CaseProvider extends ChangeNotifier {
  List<CaseModel> _myCases = [];
  List<CaseModel> _openCases = [];
  List<CaseModel> _allCases = [];
  CaseModel? _selectedCase;
  bool _loading = false;
  String? _error;

  List<CaseModel> get myCases => _myCases;
  List<CaseModel> get openCases => _openCases;
  List<CaseModel> get allCases => _allCases;
  CaseModel? get selectedCase => _selectedCase;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchMyCases() async {
    _setLoading(true);
    try {
      _myCases = await CaseService.getMyCases();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchOpenCases() async {
    _setLoading(true);
    try {
      _openCases = await CaseService.getOpenCases();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAllCases() async {
    _setLoading(true);
    try {
      _allCases = await CaseService.getAllCases();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchCase(int id) async {
    _setLoading(true);
    try {
      _selectedCase = await CaseService.getCase(id);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    _setLoading(false);
  }

  Future<CaseModel?> createCase({
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
    _setLoading(true);
    try {
      final newCase = await CaseService.createCase(
        reporterName: reporterName,
        reporterContact: reporterContact,
        species: species,
        injuryType: injuryType,
        severity: severity,
        locationLabel: locationLabel,
        latitude: latitude,
        longitude: longitude,
        probableCondition: probableCondition,
        imageDataUrl: imageDataUrl,
      );
      _myCases.insert(0, newCase);
      _error = null;
      _setLoading(false);
      return newCase;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<bool> advanceStatus(int id, String status) async {
    try {
      final updated = await CaseService.advanceStatus(id, status);
      _updateCaseInLists(updated);
      _selectedCase = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addNote(int id, String text) async {
    try {
      final updated = await CaseService.addNote(id, text);
      _selectedCase = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updateCaseInLists(CaseModel updated) {
    _allCases = _allCases.map((c) => c.id == updated.id ? updated : c).toList();
    _openCases = _openCases.map((c) => c.id == updated.id ? updated : c).toList();
    _myCases = _myCases.map((c) => c.id == updated.id ? updated : c).toList();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
