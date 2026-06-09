class AdoptionModel {
  final int id;
  final String applicantName;
  final String contact;
  final String reason;
  final int? caseId;
  final String? status;
  final String? createdAt;
  final String? adopterIdUrl;
  final String? checkinsLogs;

  AdoptionModel({
    required this.id,
    required this.applicantName,
    required this.contact,
    required this.reason,
    this.caseId,
    this.status,
    this.createdAt,
    this.adopterIdUrl,
    this.checkinsLogs,
  });

  factory AdoptionModel.fromJson(Map<String, dynamic> json) => AdoptionModel(
        id: json['id'] ?? 0,
        applicantName: json['applicantName'] ?? '',
        contact: json['contact'] ?? '',
        reason: json['reason'] ?? '',
        caseId: json['caseId'],
        status: json['status'],
        createdAt: json['createdAt'],
        adopterIdUrl: json['adopterIdUrl'],
        checkinsLogs: json['checkinsLogs'],
      );
}
