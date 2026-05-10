// Phase 10 — Pazarlama modelleri.
// SlnCampaign / SlnEmailCampaign / SlnWinbackRule / SlnGiftCard backend DTOs.

class SlnCampaign {
  SlnCampaign({
    required this.id,
    required this.name,
    required this.messageTemplate,
    required this.totalRecipients,
    required this.sentCount,
    required this.statusId,
    required this.createdAt,
    this.segmentFilter,
    this.scheduledAt,
    this.sentAt,
  });

  final int id;
  final String name;
  final String messageTemplate;
  final String? segmentFilter;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int totalRecipients;
  final int sentCount;
  final int statusId; // 1=Taslak, 2=Zamanlandi, 3=Gonderildi, 4=Hata
  final DateTime createdAt;

  String get statusLabel {
    switch (statusId) {
      case 1: return 'Taslak';
      case 2: return 'Zamanlandi';
      case 3: return 'Gonderildi';
      case 4: return 'Hata';
      default: return '?';
    }
  }

  factory SlnCampaign.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnCampaign(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      messageTemplate: json['messageTemplate']?.toString() ?? '',
      segmentFilter: json['segmentFilter'] as String?,
      scheduledAt: parse(json['scheduledAt']),
      sentAt: parse(json['sentAt']),
      totalRecipients: (json['totalRecipients'] as num?)?.toInt() ?? 0,
      sentCount: (json['sentCount'] as num?)?.toInt() ?? 0,
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class SlnCampaignCreate {
  SlnCampaignCreate({
    required this.name,
    required this.messageTemplate,
    this.segmentFilter,
    this.scheduledAt,
  });

  final String name;
  final String messageTemplate;
  final String? segmentFilter;
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() => {
        'name': name,
        'messageTemplate': messageTemplate,
        if (segmentFilter != null) 'segmentFilter': segmentFilter,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toUtc().toIso8601String(),
      };
}

class SlnEmailCampaign {
  SlnEmailCampaign({
    required this.id,
    required this.subject,
    required this.htmlBody,
    required this.totalRecipients,
    required this.sentCount,
    required this.openCount,
    required this.clickCount,
    required this.statusId,
    required this.createdAt,
    this.segmentFilter,
    this.scheduledAt,
    this.sentAt,
  });

  final int id;
  final String subject;
  final String htmlBody;
  final String? segmentFilter;
  final DateTime? scheduledAt;
  final DateTime? sentAt;
  final int totalRecipients;
  final int sentCount;
  final int openCount;
  final int clickCount;
  final int statusId;
  final DateTime createdAt;

  String get statusLabel {
    switch (statusId) {
      case 1: return 'Taslak';
      case 2: return 'Zamanlandi';
      case 3: return 'Gonderildi';
      case 4: return 'Hata';
      default: return '?';
    }
  }

  factory SlnEmailCampaign.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnEmailCampaign(
      id: (json['id'] as num?)?.toInt() ?? 0,
      subject: json['subject']?.toString() ?? '',
      htmlBody: json['htmlBody']?.toString() ?? '',
      segmentFilter: json['segmentFilter'] as String?,
      scheduledAt: parse(json['scheduledAt']),
      sentAt: parse(json['sentAt']),
      totalRecipients: (json['totalRecipients'] as num?)?.toInt() ?? 0,
      sentCount: (json['sentCount'] as num?)?.toInt() ?? 0,
      openCount: (json['openCount'] as num?)?.toInt() ?? 0,
      clickCount: (json['clickCount'] as num?)?.toInt() ?? 0,
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      createdAt: parse(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class SlnEmailCampaignCreate {
  SlnEmailCampaignCreate({
    required this.subject,
    required this.htmlBody,
    this.segmentFilter,
    this.scheduledAt,
  });

  final String subject;
  final String htmlBody;
  final String? segmentFilter;
  final DateTime? scheduledAt;

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'htmlBody': htmlBody,
        if (segmentFilter != null) 'segmentFilter': segmentFilter,
        if (scheduledAt != null) 'scheduledAt': scheduledAt!.toUtc().toIso8601String(),
      };
}

class SlnWinbackRule {
  SlnWinbackRule({
    required this.id,
    required this.name,
    required this.inactiveDays,
    required this.channelId,
    required this.messageTemplate,
    required this.isActive,
    required this.createdAt,
    this.discountPercent,
  });

  final int id;
  final String name;
  final int inactiveDays;
  final int channelId; // 1=SMS, 2=Email
  final String messageTemplate;
  final int? discountPercent;
  final bool isActive;
  final DateTime createdAt;

  String get channelLabel => channelId == 2 ? 'E-posta' : 'SMS';

  factory SlnWinbackRule.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    return SlnWinbackRule(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      inactiveDays: (json['inactiveDays'] as num?)?.toInt() ?? 30,
      channelId: (json['channelId'] as num?)?.toInt() ?? 1,
      messageTemplate: json['messageTemplate']?.toString() ?? '',
      discountPercent: (json['discountPercent'] as num?)?.toInt(),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parse(json['createdAt']),
    );
  }
}

class SlnWinbackRuleCreate {
  SlnWinbackRuleCreate({
    required this.name,
    this.inactiveDays = 30,
    this.channelId = 1,
    required this.messageTemplate,
    this.discountPercent,
    this.isActive = true,
  });

  final String name;
  final int inactiveDays;
  final int channelId;
  final String messageTemplate;
  final int? discountPercent;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'inactiveDays': inactiveDays,
        'channelId': channelId,
        'messageTemplate': messageTemplate,
        if (discountPercent != null) 'discountPercent': discountPercent,
        'isActive': isActive,
      };
}

class SlnWinbackPreview {
  SlnWinbackPreview({
    required this.ruleId,
    required this.ruleName,
    required this.eligibleClients,
    required this.smsReachableClients,
    required this.emailReachableClients,
    required this.missingContactCount,
    required this.discountPercent,
    required this.messagePreview,
    required this.candidates,
  });

  final int ruleId;
  final String ruleName;
  final int eligibleClients;
  final int smsReachableClients;
  final int emailReachableClients;
  final int missingContactCount;
  final double discountPercent;
  final String messagePreview;
  final List<SlnWinbackCandidate> candidates;

  factory SlnWinbackPreview.fromJson(Map<String, dynamic> json) {
    final raw = json['candidates'] as List<dynamic>? ?? [];
    return SlnWinbackPreview(
      ruleId: (json['ruleId'] as num?)?.toInt() ?? 0,
      ruleName: json['ruleName']?.toString() ?? '',
      eligibleClients: (json['eligibleClients'] as num?)?.toInt() ?? 0,
      smsReachableClients: (json['smsReachableClients'] as num?)?.toInt() ?? 0,
      emailReachableClients: (json['emailReachableClients'] as num?)?.toInt() ?? 0,
      missingContactCount: (json['missingContactCount'] as num?)?.toInt() ?? 0,
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
      messagePreview: json['messagePreview']?.toString() ?? '',
      candidates: raw
          .map((e) => SlnWinbackCandidate.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SlnWinbackCandidate {
  SlnWinbackCandidate({
    required this.clientId,
    required this.clientName,
    required this.inactiveDays,
    this.phone,
    this.email,
    this.lastVisitAt,
  });

  final int clientId;
  final String clientName;
  final String? phone;
  final String? email;
  final DateTime? lastVisitAt;
  final int inactiveDays;

  factory SlnWinbackCandidate.fromJson(Map<String, dynamic> json) {
    DateTime? parse(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnWinbackCandidate(
      clientId: (json['clientId'] as num?)?.toInt() ?? 0,
      clientName: json['clientName']?.toString() ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      lastVisitAt: parse(json['lastVisitAt']),
      inactiveDays: (json['inactiveDays'] as num?)?.toInt() ?? 0,
    );
  }
}

class SlnGiftCard {
  SlnGiftCard({
    required this.id,
    required this.code,
    required this.originalAmount,
    required this.remainingBalance,
    required this.isActive,
    required this.createdAt,
    this.recipientName,
    this.recipientPhone,
    this.senderName,
    this.message,
    this.expiresAt,
    this.soldByName,
  });

  final int id;
  final String code;
  final double originalAmount;
  final double remainingBalance;
  final String? recipientName;
  final String? recipientPhone;
  final String? senderName;
  final String? message;
  final DateTime? expiresAt;
  final bool isActive;
  final String? soldByName;
  final DateTime createdAt;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isUsedUp => remainingBalance <= 0;

  factory SlnGiftCard.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    DateTime? parseN(dynamic v) {
      if (v == null) return null;
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal();
      return null;
    }
    return SlnGiftCard(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      originalAmount: _money(json['originalAmount']),
      remainingBalance: _money(json['remainingBalance']),
      recipientName: json['recipientName'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      senderName: json['senderName'] as String?,
      message: json['message'] as String?,
      expiresAt: parseN(json['expiresAt']),
      isActive: json['isActive'] as bool? ?? true,
      soldByName: json['soldByName'] as String?,
      createdAt: parse(json['createdAt']),
    );
  }
}

class SlnGiftCardCreate {
  SlnGiftCardCreate({
    required this.amount,
    this.paymentMethodId = 1,
    this.recipientName,
    this.recipientPhone,
    this.senderName,
    this.message,
    this.expiresAt,
  });

  final double amount;
  final int paymentMethodId;
  final String? recipientName;
  final String? recipientPhone;
  final String? senderName;
  final String? message;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'paymentMethodId': paymentMethodId,
        if (recipientName != null) 'recipientName': recipientName,
        if (recipientPhone != null) 'recipientPhone': recipientPhone,
        if (senderName != null) 'senderName': senderName,
        if (message != null) 'message': message,
        if (expiresAt != null) 'expiresAt': expiresAt!.toUtc().toIso8601String(),
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
