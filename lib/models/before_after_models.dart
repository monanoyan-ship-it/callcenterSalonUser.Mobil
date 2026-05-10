// Phase 11.3 — BeforeAfterPhoto (sln-before-after).

class BeforeAfterPhoto {
  BeforeAfterPhoto({
    required this.id,
    required this.slnClientId,
    required this.clientName,
    required this.isPublic,
    required this.createdAt,
    this.serviceId,
    this.serviceName,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.notes,
    this.personnelId,
    this.personnelName,
  });

  final int id;
  final int slnClientId;
  final String clientName;
  final int? serviceId;
  final String? serviceName;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? notes;
  final int? personnelId;
  final String? personnelName;
  final bool isPublic;
  final DateTime createdAt;

  factory BeforeAfterPhoto.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    return BeforeAfterPhoto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slnClientId: (json['slnClientId'] as num?)?.toInt() ?? 0,
      clientName: json['clientName']?.toString() ?? '',
      serviceId: (json['serviceId'] as num?)?.toInt(),
      serviceName: json['serviceName'] as String?,
      beforePhotoUrl: json['beforePhotoUrl'] as String?,
      afterPhotoUrl: json['afterPhotoUrl'] as String?,
      notes: json['notes'] as String?,
      personnelId: (json['personnelId'] as num?)?.toInt(),
      personnelName: json['personnelName'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      createdAt: parse(json['createdAt']),
    );
  }
}

class BeforeAfterPhotoCreate {
  BeforeAfterPhotoCreate({
    required this.slnClientId,
    this.serviceId,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.notes,
    this.personnelId,
    this.isPublic = false,
  });

  final int slnClientId;
  final int? serviceId;
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final String? notes;
  final int? personnelId;
  final bool isPublic;

  Map<String, dynamic> toJson() => {
        'slnClientId': slnClientId,
        if (serviceId != null) 'serviceId': serviceId,
        if (beforePhotoUrl != null) 'beforePhotoUrl': beforePhotoUrl,
        if (afterPhotoUrl != null) 'afterPhotoUrl': afterPhotoUrl,
        if (notes != null) 'notes': notes,
        if (personnelId != null) 'personnelId': personnelId,
        'isPublic': isPublic,
      };
}
