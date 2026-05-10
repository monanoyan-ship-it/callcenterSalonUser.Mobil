// Phase 11.8 — Module Requests (sln-module-requests).

class ModuleRequest {
  ModuleRequest({
    required this.id,
    required this.moduleId,
    required this.requestTypeId,
    required this.statusId,
    required this.requestedAt,
    this.moduleName,
    this.moduleIcon,
    this.catalogPrice,
    this.statusName,
    this.requestTypeName,
    this.requestNotes,
    this.adminNotes,
    this.reviewedAt,
    this.reviewedByName,
  });

  final int id;
  final int moduleId;
  final String? moduleName;
  final String? moduleIcon;
  final double? catalogPrice;
  /// 1=Aktivasyon, 2=Iptal
  final int requestTypeId;
  final String? requestTypeName;
  /// 1=Bekliyor, 2=Onaylandi, 3=Reddedildi, 4=Iptal
  final int statusId;
  final String? statusName;
  final String? requestNotes;
  final String? adminNotes;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final String? reviewedByName;

  String get statusLabel => statusName ?? _defaultStatus();
  String _defaultStatus() {
    switch (statusId) {
      case 1: return 'Bekliyor';
      case 2: return 'Onaylandi';
      case 3: return 'Reddedildi';
      case 4: return 'Iptal';
      default: return '?';
    }
  }

  factory ModuleRequest.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    DateTime? parseN(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return ModuleRequest(
      id: (json['id'] as num?)?.toInt() ?? 0,
      moduleId: (json['moduleId'] as num?)?.toInt() ?? 0,
      moduleName: json['moduleName'] as String?,
      moduleIcon: json['moduleIcon'] as String?,
      catalogPrice: (json['catalogPrice'] as num?)?.toDouble(),
      requestTypeId: (json['requestTypeId'] as num?)?.toInt() ?? 1,
      requestTypeName: json['requestTypeName'] as String?,
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      statusName: json['statusName'] as String?,
      requestNotes: json['requestNotes'] as String?,
      adminNotes: json['adminNotes'] as String?,
      requestedAt: parse(json['requestedAt']),
      reviewedAt: parseN(json['reviewedAt']),
      reviewedByName: json['reviewedByName'] as String?,
    );
  }
}

class AvailableModule {
  AvailableModule({
    required this.id,
    required this.name,
    this.icon,
    this.description,
    this.price,
  });

  final int id;
  final String name;
  final String? icon;
  final String? description;
  final double? price;

  factory AvailableModule.fromJson(Map<String, dynamic> json) {
    return AvailableModule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? (json['catalogPrice'] as num?)?.toDouble(),
    );
  }
}
