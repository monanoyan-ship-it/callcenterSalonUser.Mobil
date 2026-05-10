// Phase 11.2 — Waitlist (sln-waitlist).

class WaitlistEntry {
  WaitlistEntry({
    required this.id,
    required this.slnClientId,
    required this.clientName,
    required this.serviceId,
    required this.serviceName,
    required this.preferredDate,
    required this.statusId,
    required this.createdAt,
    this.clientPhone,
    this.branchId,
    this.branchName,
    this.preferredPersonnelId,
    this.preferredPersonnelName,
    this.preferredTimeSlot,
    this.notes,
    this.notifiedAt,
  });

  final int id;
  final int slnClientId;
  final String clientName;
  final String? clientPhone;
  final int? branchId;
  final String? branchName;
  final int serviceId;
  final String serviceName;
  final int? preferredPersonnelId;
  final String? preferredPersonnelName;
  final DateTime preferredDate;
  final String? preferredTimeSlot;
  final String? notes;
  /// 1=Bekliyor, 2=Bilgilendirildi, 3=Cevaplandi, 4=Iptal
  final int statusId;
  final DateTime? notifiedAt;
  final DateTime createdAt;

  String get statusLabel {
    switch (statusId) {
      case 1: return 'Bekliyor';
      case 2: return 'Bilgilendirildi';
      case 3: return 'Cevaplandi';
      case 4: return 'Iptal';
      default: return '?';
    }
  }

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    DateTime? parseN(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return WaitlistEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slnClientId: (json['slnClientId'] as num?)?.toInt() ?? 0,
      clientName: json['clientName']?.toString() ?? '',
      clientPhone: json['clientPhone'] as String?,
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName'] as String?,
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName']?.toString() ?? '',
      preferredPersonnelId: (json['preferredPersonnelId'] as num?)?.toInt(),
      preferredPersonnelName: json['preferredPersonnelName'] as String?,
      preferredDate: parse(json['preferredDate']),
      preferredTimeSlot: json['preferredTimeSlot'] as String?,
      notes: json['notes'] as String?,
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      notifiedAt: parseN(json['notifiedAt']),
      createdAt: parse(json['createdAt']),
    );
  }
}

class WaitlistEntryCreate {
  WaitlistEntryCreate({
    required this.slnClientId,
    required this.serviceId,
    required this.preferredDate,
    this.preferredPersonnelId,
    this.preferredTimeSlot,
    this.notes,
  });

  final int slnClientId;
  final int serviceId;
  final int? preferredPersonnelId;
  final DateTime preferredDate;
  final String? preferredTimeSlot;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'slnClientId': slnClientId,
        'serviceId': serviceId,
        if (preferredPersonnelId != null) 'preferredPersonnelId': preferredPersonnelId,
        'preferredDate': preferredDate.toUtc().toIso8601String(),
        if (preferredTimeSlot != null) 'preferredTimeSlot': preferredTimeSlot,
        if (notes != null) 'notes': notes,
      };
}
