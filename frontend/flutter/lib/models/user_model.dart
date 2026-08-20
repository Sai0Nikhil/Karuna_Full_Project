class UserModel {
  final int userId;
  final String name;
  final String email;
  final String role; // lowercase: 'citizen' | 'ngo' | 'vet'
  final String token;
  final String? ngoName;
  final String? clinicName;

  UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.token,
    this.ngoName,
    this.clinicName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: json['userId'] ?? 0,
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        role: (json['role'] ?? 'citizen').toString().toLowerCase(), // always lowercase
        token: json['token'] ?? '',
        ngoName: json['ngoName'],
        clinicName: json['clinicName'],
      );

  bool get isCitizen => role == 'citizen';
  bool get isNgo     => role == 'ngo';
  bool get isVet     => role == 'vet';

  String get displayOrgName => clinicName ?? ngoName ?? '';
}
