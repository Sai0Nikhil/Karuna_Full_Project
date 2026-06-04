class DonationModel {
  final int id;
  final String donorName;
  final int amountInr;
  final String? message;
  final int? caseId;
  final String? createdAt;

  DonationModel({
    required this.id,
    required this.donorName,
    required this.amountInr,
    this.message,
    this.caseId,
    this.createdAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) => DonationModel(
        id: json['id'] ?? 0,
        donorName: json['donorName'] ?? '',
        amountInr: json['amountInr'] ?? 0,
        message: json['message'],
        caseId: json['caseId'],
        createdAt: json['createdAt'],
      );
}
