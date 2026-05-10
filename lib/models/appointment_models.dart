/// Backend `SlnAppointmentDto` ile birebir eşleşir.
class Appointment {
  Appointment({
    required this.id,
    required this.slnClientId,
    required this.clientName,
    required this.personnelId,
    required this.personnelName,
    required this.serviceIds,
    required this.serviceNames,
    required this.durationMinutes,
    required this.startTime,
    required this.endTime,
    required this.statusId,
    required this.isPrepaid,
    required this.prepaidAmount,
    required this.depositAmount,
    required this.clientNoShowCount,
    required this.clientIsBlacklisted,
    this.clientPhone,
    this.branchId,
    this.branchName,
    this.notes,
  });

  final int id;
  final int slnClientId;
  final String clientName;
  final String? clientPhone;
  final int personnelId;
  final String personnelName;
  final int? branchId;
  final String? branchName;
  final List<int> serviceIds;
  final List<String> serviceNames;
  final int durationMinutes;
  final DateTime startTime;
  final DateTime endTime;
  final int statusId;
  final String? notes;
  final bool isPrepaid;
  final double prepaidAmount;
  final double depositAmount;
  final int clientNoShowCount;
  final bool clientIsBlacklisted;

  bool get isPlanned => statusId == AppointmentStatuses.planned;
  bool get isConfirmed => statusId == AppointmentStatuses.confirmed;
  bool get isCompleted => statusId == AppointmentStatuses.completed;
  bool get isCancelled => statusId == AppointmentStatuses.cancelled;

  String get statusLabel {
    switch (statusId) {
      case AppointmentStatuses.planned:
        return 'Planlandı';
      case AppointmentStatuses.confirmed:
        return 'Onaylandı';
      case AppointmentStatuses.completed:
        return 'Tamamlandı';
      case AppointmentStatuses.cancelled:
        return 'İptal';
      default:
        return 'Bilinmiyor';
    }
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final svcIds = json['serviceIds'] as List<dynamic>? ?? [];
    final svcNames = json['serviceNames'] as List<dynamic>? ?? [];
    DateTime parse(dynamic v) {
      if (v is String) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      if (v != null) return DateTime.tryParse(v.toString())?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    return Appointment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slnClientId: (json['slnClientId'] as num?)?.toInt() ?? 0,
      clientName: json['clientName'] as String? ?? '',
      clientPhone: json['clientPhone'] as String?,
      personnelId: (json['personnelId'] as num?)?.toInt() ?? 0,
      personnelName: json['personnelName'] as String? ?? '',
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName'] as String?,
      serviceIds: svcIds.map((e) => (e as num).toInt()).toList(),
      serviceNames: svcNames.map((e) => e.toString()).toList(),
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      startTime: parse(json['startTime']),
      endTime: parse(json['endTime']),
      statusId: (json['statusId'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      isPrepaid: json['isPrepaid'] as bool? ?? false,
      prepaidAmount: _money(json['prepaidAmount']),
      depositAmount: _money(json['depositAmount']),
      clientNoShowCount: (json['clientNoShowCount'] as num?)?.toInt() ?? 0,
      clientIsBlacklisted: json['clientIsBlacklisted'] as bool? ?? false,
    );
  }

  static double _money(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}

class AppointmentCreate {
  AppointmentCreate({
    required this.slnClientId,
    required this.personnelId,
    required this.serviceIds,
    required this.startTime,
    this.notes,
  });

  final int slnClientId;
  final int personnelId;
  final List<int> serviceIds;
  final DateTime startTime;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'slnClientId': slnClientId,
        'personnelId': personnelId,
        'serviceIds': serviceIds,
        'startTime': startTime.toUtc().toIso8601String(),
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };
}

abstract final class AppointmentStatuses {
  static const int planned = 1;
  static const int confirmed = 2;
  static const int completed = 3;
  static const int cancelled = 4;
}

/// `PUT /api/sln-appointments/{id}/status` yanıtı.
class AppointmentStatusUpdate {
  AppointmentStatusUpdate({this.penalty = 0, this.message});
  final double penalty;
  final String? message;

  factory AppointmentStatusUpdate.fromJson(Map<String, dynamic> json) {
    return AppointmentStatusUpdate(
      penalty: (json['penalty'] is num)
          ? (json['penalty'] as num).toDouble()
          : double.tryParse('${json['penalty']}') ?? 0,
      message: json['message'] as String?,
    );
  }
}
