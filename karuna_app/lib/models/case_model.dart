class CaseModel {
  final int id;
  final String reporterName;
  final String? reporterContact;
  final String? species;
  final String? injuryType;
  final String? severity; // 'critical' | 'urgent' | 'routine'
  final String? status;   // reported, assigned, collected, at_clinic, in_treatment, discharged, adopted, released
  final String? locationLabel;
  final double? latitude;
  final double? longitude;
  final String? probableCondition;
  final String? firstAidSteps;
  final String? assignedResponder;
  final String? ngo;
  final int? estimatedCostInr;
  final String? notes;
  final String? imageDataUrl;
  final String? createdAt;

  CaseModel({
    required this.id,
    required this.reporterName,
    this.reporterContact,
    this.species,
    this.injuryType,
    this.severity,
    this.status,
    this.locationLabel,
    this.latitude,
    this.longitude,
    this.probableCondition,
    this.firstAidSteps,
    this.assignedResponder,
    this.ngo,
    this.estimatedCostInr,
    this.notes,
    this.imageDataUrl,
    this.createdAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
        id: json['id'] ?? 0,
        reporterName: json['reporterName'] ?? '',
        reporterContact: json['reporterContact'],
        species: json['species'],
        injuryType: json['injuryType'],
        severity: json['severity'],
        status: json['status'],
        locationLabel: json['locationLabel'],
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        probableCondition: json['probableCondition'],
        firstAidSteps: json['firstAidSteps'],
        assignedResponder: json['assignedResponder'],
        ngo: json['ngo'],
        estimatedCostInr: json['estimatedCostInr'],
        notes: json['notes'],
        imageDataUrl: json['imageDataUrl'],
        createdAt: json['createdAt'],
      );

  String get speciesEmoji {
    switch (species?.toLowerCase()) {
      case 'dog': return '🐕';
      case 'cat': return '🐈';
      case 'cow': return '🐄';
      case 'bird': return '🦜';
      default: return '🐾';
    }
  }

  bool get isCritical => severity == 'critical';
  bool get isResolved => ['discharged', 'adopted', 'released'].contains(status);
  bool get isAssigned => assignedResponder != null && assignedResponder!.isNotEmpty;
}
