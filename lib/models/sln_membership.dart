/// `SlnMembershipPlanDto`.
class SlnMembershipPlan {
  SlnMembershipPlan({
    required this.id,
    required this.name,
    required this.durationType,
    required this.durationDays,
    required this.price,
    required this.discountPercent,
    required this.priorityBooking,
    required this.isActive,
    required this.activeMembers,
    this.description,
    this.iconClass,
    this.color,
  });

  final int id;
  final String name;
  final String? description;
  final String? iconClass;
  final String? color;
  final int durationType;
  final int durationDays;
  final double price;
  final int discountPercent;
  final bool priorityBooking;
  final bool isActive;
  final int activeMembers;

  factory SlnMembershipPlan.fromJson(Map<String, dynamic> json) {
    return SlnMembershipPlan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      iconClass: json['iconClass'] as String?,
      color: json['color'] as String?,
      durationType: (json['durationType'] as num?)?.toInt() ?? 1,
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 30,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      priorityBooking: json['priorityBooking'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      activeMembers: (json['activeMembers'] as num?)?.toInt() ?? 0,
    );
  }
}

class SlnMembershipPlanCreate {
  SlnMembershipPlanCreate({
    required this.name,
    this.description,
    this.durationDays = 30,
    this.price = 0,
    this.discountPercent = 0,
    this.priorityBooking = false,
    this.isActive = true,
  });

  final String name;
  final String? description;
  final int durationDays;
  final double price;
  final int discountPercent;
  final bool priorityBooking;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty) 'description': description,
        'durationType': 1,
        'durationDays': durationDays,
        'price': price,
        'discountPercent': discountPercent,
        'priorityBooking': priorityBooking,
        'isActive': isActive,
      };
}

/// `SlnClientMembershipDto` — bir müşterinin satın aldığı üyelik.
/// Status: 1=Aktif, 2=Donduruldu, 3=İptal, 4=Süresi doldu.
class SlnClientMembership {
  SlnClientMembership({
    required this.id,
    required this.planName,
    required this.clientName,
    required this.discountPercent,
    required this.startDate,
    required this.paidAmount,
    required this.statusId,
    this.planColor,
    this.endDate,
    this.currentPeriodStart,
    this.currentPeriodEnd,
  });

  final int id;
  final String planName;
  final String? planColor;
  final String clientName;
  final int discountPercent;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final double paidAmount;
  final int statusId;

  bool get isActive => statusId == 1;
  bool get isFrozen => statusId == 2;
  bool get isCancelled => statusId == 3;
  bool get isExpired => statusId == 4;

  String get statusLabel {
    switch (statusId) {
      case 1: return 'Aktif';
      case 2: return 'Donduruldu';
      case 3: return 'İptal';
      case 4: return 'Süresi doldu';
      default: return 'Bilinmiyor';
    }
  }

  factory SlnClientMembership.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnClientMembership(
      id: (json['id'] as num?)?.toInt() ?? 0,
      planName: json['planName'] as String? ?? '',
      planColor: json['planColor'] as String?,
      clientName: json['clientName'] as String? ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      startDate: parse(json['startDate']) ?? DateTime.now(),
      endDate: parse(json['endDate']),
      currentPeriodStart: parse(json['currentPeriodStart']),
      currentPeriodEnd: parse(json['currentPeriodEnd']),
      paidAmount: (json['paidAmount'] as num?)?.toDouble() ?? 0,
      statusId: (json['statusId'] as num?)?.toInt() ?? 0,
    );
  }
}
