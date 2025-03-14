class User {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? password;
  String? phoneNumber;
  String? authority;
  UserImage? image; // Nested field
  bool valid;

  // Fields specific to Technician
  String? secondEmail;
  bool permisConduire;
  bool passeport;
  DateTime? birthDate;
  DateTime? expiredAt;
  String? signature;
  List<dynamic>? listEquipment; // List of equipment

  // Fields specific to Client
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

  // Convert a User object to a Map for sending to the API
  Map<String, dynamic> toMap() {
    var map = {
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

    // Add fields for Technician if authority is 'technician'
    if (authority == 'technician') {
      map['secondEmail'] = secondEmail;
      map['permisConduire'] = permisConduire;
      map['passeport'] = passeport;
      map['birthDate'] = birthDate?.toIso8601String();
      map['expiredAt'] = expiredAt?.toIso8601String();
      map['signature'] = signature;
      map['listEquipment'] = listEquipment;
    }

    // Add fields for Client if authority is 'client'
    if (authority == 'client') {
      map['company'] = company;
      map['about'] = about;
      map['folderId'] = folderId;
    }

    return map;
  }

  // Convert API response (Map) to a User object
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['_id'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      password: map['password'],
      phoneNumber: map['phoneNumber'],
      authority: map['authority'],
      image: map['image'] != null ? UserImage.fromMap(map['image']) : null,
      valid: map['valid'] ?? false,
      secondEmail: map['secondEmail'],
      permisConduire: map['permisConduire'] ?? false,
      passeport: map['passeport'] ?? false,
      birthDate:
          map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      expiredAt:
          map['expiredAt'] != null ? DateTime.parse(map['expiredAt']) : null,
      signature: map['signature'],
      listEquipment: map['listEquipment'],
      company: map['company'],
      about: map['about'],
      folderId: map['folderId'],
    );
  }
}

// Class to handle the nested 'image' field
class UserImage {
  String? id;
  String? title;
  String? fileName;
  String? path;
  DateTime? uploadDate;

  UserImage({
    this.id,
    this.title,
    this.fileName,
    this.path,
    this.uploadDate,
  });

  // Convert a UserImage object to a Map
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'fileName': fileName,
      'path': path,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }

  // Convert API response (Map) to a UserImage object
  factory UserImage.fromMap(Map<String, dynamic> map) {
    return UserImage(
      id: map['_id'],
      title: map['title'],
      fileName: map['fileName'],
      path: map['path'],
      uploadDate:
          map['uploadDate'] != null ? DateTime.parse(map['uploadDate']) : null,
    );
  }
}
