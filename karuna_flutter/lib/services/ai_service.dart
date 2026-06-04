import 'dart:convert';
import '../config/api_config.dart';
import 'api_service.dart';

/// Gemini AI Service – Flutter side
/// Connects to the backend's /api/ai/* endpoints
class AiService {
  // ─── 1. Analyze a case from text (called in Report Step 2 before submit) ───
  static Future<AiAnalysisResult?> analyzeCase({
    required String species,
    required String injuryType,
    String? description,
    String? locationLabel,
  }) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/analyze',
        {
          'species': species,
          'injuryType': injuryType,
          'description': description ?? '',
          'locationLabel': locationLabel ?? '',
        },
      );
      return AiAnalysisResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ─── 2. Analyze a photo (base64 data URL) ────────────────────────────────
  static Future<AiAnalysisResult?> analyzePhoto(String base64DataUrl) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/analyze-photo',
        {'imageDataUrl': base64DataUrl},
      );
      return AiAnalysisResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ─── 3. First Aid chatbot (public, no auth needed) ───────────────────────
  static Future<FirstAidResult?> getFirstAid({
    required String species,
    required String injuryDescription,
    String? locationContext,
  }) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/firstaid',
        {
          'species': species,
          'injuryDescription': injuryDescription,
          'locationContext': locationContext ?? '',
        },
        auth: false,
      );
      return FirstAidResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ─── 4. NGO case summary ─────────────────────────────────────────────────
  static Future<CaseSummaryResult?> getCaseSummary(int caseId) async {
    try {
      final data = await ApiService.get('${ApiConfig.baseUrl}/ai/summary/$caseId');
      return CaseSummaryResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────

class AiAnalysisResult {
  final String? probableCondition;
  final String? severity;
  final String? injuryType;
  final String? firstAidSteps; // JSON array string
  final int? estimatedCostInr;
  final String? aiSummary;
  final String? confidence;

  AiAnalysisResult({
    this.probableCondition,
    this.severity,
    this.injuryType,
    this.firstAidSteps,
    this.estimatedCostInr,
    this.aiSummary,
    this.confidence,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) => AiAnalysisResult(
        probableCondition: json['probableCondition'],
        severity: json['severity'],
        injuryType: json['injuryType'],
        firstAidSteps: json['firstAidSteps'],
        estimatedCostInr: json['estimatedCostInr'],
        aiSummary: json['aiSummary'],
        confidence: json['confidence'],
      );

  List<String> get firstAidList {
    if (firstAidSteps == null || firstAidSteps!.isEmpty) return [];
    try {
      final decoded = jsonDecode(firstAidSteps!);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  String get severityLabel {
    switch (severity?.toLowerCase()) {
      case 'critical': return '🔴 Critical';
      case 'urgent':   return '🟡 Urgent';
      case 'routine':  return '🟢 Routine';
      default:         return '🟡 Urgent';
    }
  }
}

class FirstAidResult {
  final List<String> immediateSteps;
  final List<String> doNotDo;
  final String? whenToCallVet;
  final String? estimatedWaitAdvice;

  FirstAidResult({
    required this.immediateSteps,
    required this.doNotDo,
    this.whenToCallVet,
    this.estimatedWaitAdvice,
  });

  factory FirstAidResult.fromJson(Map<String, dynamic> json) => FirstAidResult(
        immediateSteps: List<String>.from(json['immediateSteps'] ?? []),
        doNotDo: List<String>.from(json['doNotDo'] ?? []),
        whenToCallVet: json['whenToCallVet'],
        estimatedWaitAdvice: json['estimatedWaitAdvice'],
      );
}

class CaseSummaryResult {
  final String? headline;
  final String? summary;
  final String? urgencyNote;
  final String? progressNote;
  final String? recommendedNextStep;

  CaseSummaryResult({
    this.headline,
    this.summary,
    this.urgencyNote,
    this.progressNote,
    this.recommendedNextStep,
  });

  factory CaseSummaryResult.fromJson(Map<String, dynamic> json) => CaseSummaryResult(
        headline: json['headline'],
        summary: json['summary'],
        urgencyNote: json['urgencyNote'],
        progressNote: json['progressNote'],
        recommendedNextStep: json['recommendedNextStep'],
      );
}
