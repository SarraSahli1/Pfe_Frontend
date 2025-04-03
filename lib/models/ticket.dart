class Ticket {
  final String id;
  final String title;
  final String description;
  final String status;
  final String typeTicket;
  final DateTime creationDate;
  final DateTime? finishDate;
  final DateTime? resolvedDate;
  final DateTime? assignedDate;
  final DateTime? closedDate;
  final String? chatId;
  final String? solutionId;
  final String clientId;
  final String? helpdeskUserId;
  final List<String>? equipmentHelpdeskIds;
  final List<String>? equipmentSoftIds;
  final List<String>? equipmentHardIds;
  final List<String>? technicienIds;
  final List<String>? fileUrls;

  Ticket({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.typeTicket,
    required this.creationDate,
    this.finishDate,
    this.resolvedDate,
    this.assignedDate,
    this.closedDate,
    this.chatId,
    this.solutionId,
    required this.clientId,
    this.helpdeskUserId,
    this.equipmentHelpdeskIds,
    this.equipmentSoftIds,
    this.equipmentHardIds,
    this.technicienIds,
    this.fileUrls,
  });
  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse list items
    List<String> _parseList(dynamic list) {
      if (list is! List) return [];
      return list
          .map((item) {
            if (item is String) return item;
            if (item is Map) return item['_id']?.toString() ?? '';
            return item?.toString() ?? '';
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return Ticket(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      typeTicket: json['typeTicket']?.toString() ?? '',
      creationDate: DateTime.parse(
          json['creationDate']?.toString() ?? DateTime.now().toIso8601String()),
      finishDate: json['finishDate'] != null
          ? DateTime.parse(json['finishDate']!.toString())
          : null,
      resolvedDate: json['resolvedDate'] != null
          ? DateTime.parse(json['resolvedDate']!.toString())
          : null,
      assignedDate: json['assignedDate'] != null
          ? DateTime.parse(json['assignedDate']!.toString())
          : null,
      closedDate: json['closedDate'] != null
          ? DateTime.parse(json['closedDate']!.toString())
          : null,
      chatId: json['chat']?.toString(),
      solutionId: json['solution']?.toString(),
      clientId: json['clientId']?.toString() ?? '',
      helpdeskUserId: json['helpdeskUser']?.toString(),
      equipmentHelpdeskIds: _parseList(json['equipmentHelpdesk']),
      equipmentSoftIds: _parseList(json['equipmentSoftId']),
      equipmentHardIds: _parseList(json['equipmentHardId']),
      technicienIds: _parseList(json['technicienId']),
      fileUrls: _parseList(json['listOfFiles']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': status,
      'typeTicket': typeTicket,
      'creationDate': creationDate.toIso8601String(),
      'finishDate': finishDate?.toIso8601String(),
      'resolvedDate': resolvedDate?.toIso8601String(),
      'assignedDate': assignedDate?.toIso8601String(),
      'closedDate': closedDate?.toIso8601String(),
      'chat': chatId,
      'solution': solutionId,
      'clientId': clientId,
      'helpdeskUser': helpdeskUserId,
      'equipmentHelpdesk': equipmentHelpdeskIds,
      'equipmentSoftId': equipmentSoftIds,
      'equipmentHardId': equipmentHardIds,
      'technicienId': technicienIds,
      'listOfFiles': fileUrls,
    };
  }
}
