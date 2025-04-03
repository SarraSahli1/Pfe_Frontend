class Technicien {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? secondEmail;
  final String authority;
  final String? phoneNumber;
  final bool? permisConduire;
  final bool? passeport;
  final DateTime? birthDate;
  final DateTime? expiredAt;
  final String? signatureId;
  final List<String>? listEquipment;

  Technicien({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.authority,
    this.secondEmail,
    this.phoneNumber,
    this.permisConduire,
    this.passeport,
    this.birthDate,
    this.expiredAt,
    this.signatureId,
    this.listEquipment,
  });

  String get fullName => '$firstName $lastName';

  factory Technicien.fromJson(Map<String, dynamic> json) {
    return Technicien(
      id: json['_id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      authority: json['authority'],
      secondEmail: json['secondEmail'],
      phoneNumber: json['phoneNumber'],
      permisConduire: json['permisConduire'],
      passeport: json['passeport'],
      birthDate:
          json['birthDate'] != null ? DateTime.parse(json['birthDate']) : null,
      expiredAt:
          json['expiredAt'] != null ? DateTime.parse(json['expiredAt']) : null,
      signatureId: json['signature']?.toString(),
      listEquipment: json['listEquipment'] != null
          ? List<String>.from(json['listEquipment'].map((x) => x.toString()))
          : null,
    );
  }
}
