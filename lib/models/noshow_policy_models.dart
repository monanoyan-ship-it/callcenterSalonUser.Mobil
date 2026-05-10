// Phase 11.5 — NoShow Policy (sln-noshow-policy).

class NoShowPolicy {
  NoShowPolicy({
    required this.id,
    required this.requireDeposit,
    required this.depositAmount,
    required this.freeCancellationHours,
    required this.lateCancellationFee,
    required this.noShowFee,
    required this.blacklistThreshold,
    required this.isActive,
  });

  final int id;
  final bool requireDeposit;
  final double depositAmount;
  final int freeCancellationHours;
  final double lateCancellationFee;
  final double noShowFee;
  final int blacklistThreshold;
  final bool isActive;

  factory NoShowPolicy.fromJson(Map<String, dynamic> json) {
    return NoShowPolicy(
      id: (json['id'] as num?)?.toInt() ?? 0,
      requireDeposit: json['requireDeposit'] as bool? ?? false,
      depositAmount: _money(json['depositAmount']),
      freeCancellationHours: (json['freeCancellationHours'] as num?)?.toInt() ?? 24,
      lateCancellationFee: _money(json['lateCancellationFee']),
      noShowFee: _money(json['noShowFee']),
      blacklistThreshold: (json['blacklistThreshold'] as num?)?.toInt() ?? 3,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class NoShowPolicyUpdate {
  NoShowPolicyUpdate({
    required this.requireDeposit,
    required this.depositAmount,
    required this.freeCancellationHours,
    required this.lateCancellationFee,
    required this.noShowFee,
    required this.blacklistThreshold,
    required this.isActive,
  });

  final bool requireDeposit;
  final double depositAmount;
  final int freeCancellationHours;
  final double lateCancellationFee;
  final double noShowFee;
  final int blacklistThreshold;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'requireDeposit': requireDeposit,
        'depositAmount': depositAmount,
        'freeCancellationHours': freeCancellationHours,
        'lateCancellationFee': lateCancellationFee,
        'noShowFee': noShowFee,
        'blacklistThreshold': blacklistThreshold,
        'isActive': isActive,
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
