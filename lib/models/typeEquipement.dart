class TypeEquipment {
  String? id;
  String? typeName;
  String? typeEquip;
  FileModel? logo; // Modèle pour le fichier logo
  List<dynamic>? listProblems; // Liste des problèmes associés

  TypeEquipment({
    this.id,
    this.typeName,
    this.typeEquip,
    this.logo,
    this.listProblems,
  });

  // Convertir un objet TypeEquipment en Map pour l'envoi à l'API
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'typeName': typeName,
      'typeEquip': typeEquip,
      'logo': logo?.toMap(), // Convertir le logo en Map
      'listProblems': listProblems,
    };
  }

  // Convertir une réponse API (Map) en objet TypeEquipment
  factory TypeEquipment.fromMap(Map<String, dynamic> map) {
    return TypeEquipment(
      id: map['_id'],
      typeName: map['typeName'],
      typeEquip: map['typeEquip'],
      logo: map['logo'] != null ? FileModel.fromMap(map['logo']) : null,
      listProblems: map['listProblems'],
    );
  }
}

// Modèle pour le fichier logo
class FileModel {
  String? id;
  String? title;
  String? fileName;
  String? path;
  DateTime? uploadDate;

  FileModel({
    this.id,
    this.title,
    this.fileName,
    this.path,
    this.uploadDate,
  });

  // Convertir un objet FileModel en Map
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'fileName': fileName,
      'path': path,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }

  // Convertir une réponse API (Map) en objet FileModel
  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['_id'],
      title: map['title'],
      fileName: map['fileName'],
      path: map['path'],
      uploadDate:
          map['uploadDate'] != null ? DateTime.parse(map['uploadDate']) : null,
    );
  }
}
