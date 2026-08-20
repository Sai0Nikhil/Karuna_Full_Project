import 'dart:convert';
import 'package:flutter/material.dart' show Color;
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
  static Future<AiAnalysisResult?> analyzePhoto(
    String base64DataUrl, {
    double? lat,
    double? lon,
    String? description,
  }) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/analyze-photo',
        {
          'imageDataUrl': base64DataUrl,
          if (lat != null) 'lat': lat.toString(),
          if (lon != null) 'lon': lon.toString(),
          if (description != null && description.isNotEmpty) 'description': description,
        },
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
    String language = 'English',
  }) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/firstaid',
        {
          'species': species,
          'injuryDescription': injuryDescription,
          'locationContext': locationContext ?? '',
          'language': language,
        },
        auth: false,
      );
      return FirstAidResult.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // ─── 4. Get detailed instruction for one first aid step ─────────────────
  static Future<String?> getDetailedInstruction({
    required String step,
    required String animal,
  }) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/firstaid',
        {
          'species': animal,
          'injuryDescription': step,
          'locationContext': 'street / public place',
          'language': 'English',
        },
        auth: false,
      );
      final result = FirstAidResult.fromJson(data);
      if (result.immediateSteps.isNotEmpty) {
        return result.immediateSteps.join('\n\n');
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ─── 5. Sita chatbot – reuses firstaid endpoint with conversation context ─
  static Future<String?> chatWithSita({
    required String message,
    String species = 'animal',
    String context = '',
    String language = 'English',
  }) async {
    try {
      final data = await ApiService.post(
        '${ApiConfig.baseUrl}/ai/firstaid',
        {
          'species': species,
          'injuryDescription': message,
          'locationContext': context,
          'language': language,
        },
        auth: false,
      );
      // Sita formats the structured response into a friendly message
      final result = FirstAidResult.fromJson(data);
      final buf = StringBuffer();
      if (result.immediateSteps.isNotEmpty) {
        buf.writeln('Here\'s what you should do right now:\n');
        for (int i = 0; i < result.immediateSteps.length; i++) {
          buf.writeln('${i + 1}. ${result.immediateSteps[i]}');
        }
      }
      if (result.doNotDo.isNotEmpty) {
        buf.writeln('\n⚠️ Please avoid:\n');
        for (final w in result.doNotDo) {
          buf.writeln('• $w');
        }
      }
      if (result.whenToCallVet != null) {
        buf.writeln('\n📞 ${result.whenToCallVet}');
      }
      if (result.estimatedWaitAdvice != null) {
        buf.writeln('\n🕐 ${result.estimatedWaitAdvice}');
      }
      return buf.toString().trim();
    } catch (e) {
      return null;
    }
  }

  // ─── 5. NGO case summary ─────────────────────────────────────────────────
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
  final String? medicines;     // JSON array string
  final String? localSupport;  // JSON array of {name, address, phone}
  final String? disclaimer;
  final int? estimatedCostInr;
  final String? aiSummary;
  final String? confidence;
  // optional — set by photo analysis
  final String? species;

  AiAnalysisResult({
    this.probableCondition,
    this.severity,
    this.injuryType,
    this.firstAidSteps,
    this.medicines,
    this.localSupport,
    this.disclaimer,
    this.estimatedCostInr,
    this.aiSummary,
    this.confidence,
    this.species,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) => AiAnalysisResult(
        probableCondition: json['probableCondition'],
        severity: json['severity'],
        injuryType: json['injuryType'],
        firstAidSteps: json['firstAidSteps'] is List
            ? jsonEncode(json['firstAidSteps'])
            : json['firstAidSteps'],
        medicines: json['medicines'] is List
            ? jsonEncode(json['medicines'])
            : json['medicines'],
        localSupport: json['localSupport'] is List
            ? jsonEncode(json['localSupport'])
            : json['localSupport'],
        disclaimer: json['disclaimer'],
        estimatedCostInr: json['estimatedCostInr'],
        aiSummary: json['aiSummary'],
        confidence: json['confidence'],
        species: json['species'],
      );

  List<String> get firstAidList {
    if (firstAidSteps == null || firstAidSteps!.isEmpty) return [];
    try {
      final decoded = jsonDecode(firstAidSteps!);
      if (decoded is List) return decoded.cast<String>();
    } catch (_) {}
    return [];
  }

  List<Map<String, dynamic>> get localSupportList {
    if (localSupport == null || localSupport!.isEmpty) return [];
    try {
      final decoded = jsonDecode(localSupport!);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    } catch (_) {}
    return [];
  }

  List<Map<String, dynamic>> get medicineList {
    if (medicines == null || medicines!.isEmpty) return [];
    try {
      final decoded = jsonDecode(medicines!);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
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

  Color get severityColor {
    switch (severity?.toLowerCase()) {
      case 'critical': return const Color(0xFFDC2626);
      case 'urgent':   return const Color(0xFFD97706);
      case 'routine':  return const Color(0xFF16A34A);
      default:         return const Color(0xFFD97706);
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
