import 'package:helpdeskfrontend/models/typeEquipement.dart';

class Equipment {
  String? id;
  String? serialNumber; // Changed from SN
  String? designation; // Changed from nomPice
  String? version; // New field
  String? barcode; // New field
  DateTime?
      inventoryDate; // Changed from startDateSupport (and type to DateTime)
  bool assigned; // New field (default false)
  String reference; // New field (default 'OPM_APP')
  TypeEquipment? typeEquipment; // Kept but matches TypeEquipment in schema

  Equipment({
    this.id,
    this.serialNumber,
    required this.designation,
    this.version,
    this.barcode,
    this.inventoryDate,
    this.assigned = false, // Default value
    this.reference = 'OPM_APP', // Default value
    this.typeEquipment,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'serialNumber': serialNumber,
      'designation': designation,
      'version': version,
      'barcode': barcode,
      'inventoryDate': inventoryDate?.toIso8601String(),
      'assigned': assigned,
      'reference': reference,
      'TypeEquipment': typeEquipment?.toMap(),
    };
  }

  // Convert from API response (Map)
  factory Equipment.fromMap(Map<String, dynamic> map) {
    return Equipment(
      id: map['_id'],
      serialNumber: map['serialNumber'],
      designation: map['designation'],
      version: map['version'],
      barcode: map['barcode'],
      inventoryDate: map['inventoryDate'] != null
          ? DateTime.parse(map['inventoryDate'])
          : null,
      assigned: map['assigned'] ?? false,
      reference: map['reference'] ?? 'OPM_APP',
      typeEquipment: map['TypeEquipment'] != null
          ? TypeEquipment.fromMap(map['TypeEquipment'])
          : null,
    );
  }
}
