/// `SlnClientDto` ile birebir.
class SlnClient {
  SlnClient({
    required this.id,
    required this.fullName,
    required this.isFavorite,
    required this.createdAt,
    required this.visitCount,
    required this.totalSpent,
    this.uid,
    this.phone,
    this.email,
    this.genderId,
    this.birthDate,
    this.hairColor,
    this.lastVisit,
  });

  final int id;
  final String? uid;
  final String fullName;
  final String? phone;
  final String? email;
  final int? genderId;
  final DateTime? birthDate;
  final String? hairColor;
  final bool isFavorite;
  final DateTime createdAt;
  final int visitCount;
  final double totalSpent;
  final DateTime? lastVisit;

  factory SlnClient.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnClient(
      id: (json['id'] as num?)?.toInt() ?? 0,
      uid: json['uid']?.toString(),
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      genderId: (json['genderId'] as num?)?.toInt(),
      birthDate: parse(json['birthDate']),
      hairColor: json['hairColor'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      visitCount: (json['visitCount'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      lastVisit: parse(json['lastVisit']),
    );
  }
}

/// Detay endpoint (`GET /api/sln-clients/{id}`) ile gelir; SlnClientDto'nun
/// genişletilmiş sürümü.
class SlnClientDetail extends SlnClient {
  SlnClientDetail({
    required super.id,
    required super.fullName,
    required super.isFavorite,
    required super.createdAt,
    required super.visitCount,
    required super.totalSpent,
    super.uid,
    super.phone,
    super.email,
    super.genderId,
    super.birthDate,
    super.hairColor,
    super.lastVisit,
    this.phone2,
    this.marriageDate,
    this.occupation,
    this.city,
    this.address,
    this.whiteRatioPercent,
    this.skinType,
    this.notes,
  });

  final String? phone2;
  final DateTime? marriageDate;
  final String? occupation;
  final String? city;
  final String? address;
  final int? whiteRatioPercent;
  final String? skinType;
  final String? notes;

  factory SlnClientDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnClientDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      uid: json['uid']?.toString(),
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String?,
      phone2: json['phone2'] as String?,
      email: json['email'] as String?,
      genderId: (json['genderId'] as num?)?.toInt(),
      birthDate: parse(json['birthDate']),
      marriageDate: parse(json['marriageDate']),
      occupation: json['occupation'] as String?,
      city: json['city'] as String?,
      address: json['address'] as String?,
      hairColor: json['hairColor'] as String?,
      whiteRatioPercent: (json['whiteRatioPercent'] as num?)?.toInt(),
      skinType: json['skinType'] as String?,
      notes: json['notes'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
      visitCount: (json['visitCount'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
      lastVisit: parse(json['lastVisit']),
    );
  }
}

class SlnClientCreate {
  SlnClientCreate({
    required this.fullName,
    this.phone,
    this.phone2,
    this.email,
    this.genderId,
    this.birthDate,
    this.notes,
  });

  final String fullName;
  final String? phone;
  final String? phone2;
  final String? email;
  final int? genderId;
  final DateTime? birthDate;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (phone2 != null && phone2!.isNotEmpty) 'phone2': phone2,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (genderId != null) 'genderId': genderId,
        if (birthDate != null) 'birthDate': birthDate!.toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}
