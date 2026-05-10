// Phase 11.6 — Packages (sln-packages).

class PackageDefinition {
  PackageDefinition({
    required this.id,
    required this.name,
    required this.serviceId,
    required this.serviceName,
    required this.totalSessions,
    required this.price,
    required this.pricePerSession,
    required this.validDays,
    required this.isActive,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
  final int serviceId;
  final String serviceName;
  final int totalSessions;
  final double price;
  final double pricePerSession;
  final int validDays;
  final bool isActive;

  factory PackageDefinition.fromJson(Map<String, dynamic> json) {
    return PackageDefinition(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName']?.toString() ?? '',
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      price: _money(json['price']),
      pricePerSession: _money(json['pricePerSession']),
      validDays: (json['validDays'] as num?)?.toInt() ?? 365,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class PackageDefinitionCreate {
  PackageDefinitionCreate({
    required this.name,
    required this.serviceId,
    required this.totalSessions,
    required this.price,
    this.description,
    this.validDays = 365,
    this.isActive = true,
  });

  final String name;
  final String? description;
  final int serviceId;
  final int totalSessions;
  final double price;
  final int validDays;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'serviceId': serviceId,
        'totalSessions': totalSessions,
        'price': price,
        'validDays': validDays,
        'isActive': isActive,
      };
}

class ClientPackage {
  ClientPackage({
    required this.id,
    required this.packageDefinitionId,
    required this.serviceId,
    required this.packageName,
    required this.serviceName,
    required this.totalSessions,
    required this.usedSessions,
    required this.remainingSessions,
    required this.paidAmount,
    required this.isActive,
    required this.createdAt,
    this.clientName,
    this.expiresAt,
  });

  final int id;
  final int packageDefinitionId;
  final int serviceId;
  final String packageName;
  final String serviceName;
  final String? clientName;
  final int totalSessions;
  final int usedSessions;
  final int remainingSessions;
  final double paidAmount;
  final DateTime? expiresAt;
  final bool isActive;
  final DateTime createdAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  double get progress => totalSessions == 0 ? 0 : usedSessions / totalSessions;

  factory ClientPackage.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    DateTime? parseN(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return ClientPackage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      packageDefinitionId: (json['packageDefinitionId'] as num?)?.toInt() ?? 0,
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      packageName: json['packageName']?.toString() ?? '',
      serviceName: json['serviceName']?.toString() ?? '',
      clientName: json['clientName'] as String?,
      totalSessions: (json['totalSessions'] as num?)?.toInt() ?? 0,
      usedSessions: (json['usedSessions'] as num?)?.toInt() ?? 0,
      remainingSessions: (json['remainingSessions'] as num?)?.toInt() ?? 0,
      paidAmount: _money(json['paidAmount']),
      expiresAt: parseN(json['expiresAt']),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parse(json['createdAt']),
    );
  }
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
