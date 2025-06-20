import 'package:flutter/foundation.dart';

class User {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? phoneNumber;
  String? authority;
  UserImage? image;
  bool valid;

  // Technician fields
  String? secondEmail;
  bool permisConduire;
  bool passeport;
  DateTime? birthDate;
  DateTime? expiredAt;
  UserFile? signature;
  List<dynamic>? listEquipment;

  // Client fields
  String? company;
  String? about;
  String? folderId;

  User({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.password,
    this.phoneNumber,
    this.authority,
    this.image,
    this.valid = false,
    this.secondEmail,
    this.permisConduire = false,
    this.passeport = false,
    this.birthDate,
    this.expiredAt,
    this.signature,
    this.listEquipment,
    this.company,
    this.about,
    this.folderId,
  });

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'authority': authority,
      'image': image?.toMap(),
      'valid': valid,
    };

    if (authority == 'technician') {
      map.addAll({
        'secondEmail': secondEmail,
        'permisConduire': permisConduire,
        'passeport': passeport,
        'birthDate': birthDate?.toIso8601String(),
        'expiredAt': expiredAt?.toIso8601String(),
        'signature': signature?.toMap(),
        'listEquipment': listEquipment,
      });
    }

    if (authority == 'client') {
      map.addAll({
        'company': company,
        'about': about,
        'folderId': folderId,
      });
    }

    return map;
  }

  factory User.fromMap(Map<String, dynamic> map) {
    try {
      return User(
        id: map['_id'] ?? map['id'],
        firstName: map['firstName'],
        lastName: map['lastName'],
        email: map['email'],
        password: map['password'],
        phoneNumber: map['phoneNumber'],
        authority: map['authority'] ?? map['__t'], // Fallback to __t
        image: map['image'] != null
            ? (map['image'] is Map<String, dynamic>
                ? UserImage.fromMap(map['image'] as Map<String, dynamic>)
                : UserImage.fromMap(_convertDynamicMap(map['image'])))
            : null,
        valid: map['valid'] ?? false,
        secondEmail: map['secondEmail'],
        permisConduire: map['permisConduire'] ?? false,
        passeport: map['passeport'] ?? false,
        birthDate: _parseDateTime(map['birthDate']),
        expiredAt: _parseDateTime(map['expiredAt']),
        signature: _parseSignature(map['signature']),
        listEquipment: map['listEquipment'],
        company: map['company'],
        about: map['about'],
        folderId: map['folderId'],
      );
    } catch (e) {
      debugPrint('Error parsing User: $e');
      rethrow;
    }
  }

  static UserFile? _parseSignature(dynamic signatureData) {
    if (signatureData == null) return null;
    if (signatureData is UserFile) return signatureData;

    if (signatureData is Map) {
      try {
        return UserFile.fromMap(_convertDynamicMap(signatureData));
      } catch (e) {
        debugPrint('Error parsing signature: $e');
        return null;
      }
    }

    return null;
  }

  static Map<String, dynamic> _convertDynamicMap(dynamic map) {
    if (map == null) return {};
    if (map is Map<String, dynamic>) return map;

    final Map<String, dynamic> convertedMap = {};
    (map as Map).forEach((key, value) {
      convertedMap[key.toString()] = value;
    });
    return convertedMap;
  }

  static DateTime? _parseDateTime(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return null;
    }
  }
}

class UserImage {
  final String? id;
  final String? title;
  final String? fileName;
  final String? path;
  final DateTime? uploadDate;

  UserImage({
    this.id,
    this.title,
    this.fileName,
    this.path,
    this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'fileName': fileName,
      'path': path,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }

  factory UserImage.fromMap(Map<String, dynamic> map) {
    return UserImage(
      id: map['_id'] ?? map['id'],
      title: map['title'],
      fileName: map['fileName'],
      path: map['path'],
      uploadDate: User._parseDateTime(map['uploadDate']),
    );
  }
}

class UserFile {
  final String? id;
  final String? title;
  final String? fileName;
  final String? path;
  final DateTime? uploadDate;

  UserFile({
    this.id,
    this.title,
    this.fileName,
    this.path,
    this.uploadDate,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'fileName': fileName,
      'path': path,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }

  factory UserFile.fromMap(Map<String, dynamic> map) {
    return UserFile(
      id: map['_id'] ?? map['id'],
      title: map['title'],
      fileName: map['fileName'],
      path: map['path'],
      uploadDate: User._parseDateTime(map['uploadDate']),
    );
  }
}
