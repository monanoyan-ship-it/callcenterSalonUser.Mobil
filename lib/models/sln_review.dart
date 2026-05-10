/// `SlnReviewDto`. Status: 1=Bekliyor, 2=Onaylandı, 3=Reddedildi.
class SlnReview {
  SlnReview({
    required this.id,
    required this.rating,
    required this.statusId,
    required this.createdAt,
    required this.sourceId,
    this.slnClientId,
    this.clientName,
    this.comment,
    this.externalUrl,
  });

  final int id;
  final int? slnClientId;
  final String? clientName;
  final int rating;
  final String? comment;
  final int sourceId;
  final String? externalUrl;
  final int statusId;
  final DateTime createdAt;

  bool get isPending => statusId == 1;
  bool get isApproved => statusId == 2;
  bool get isRejected => statusId == 3;

  String get statusLabel {
    switch (statusId) {
      case 1: return 'Bekliyor';
      case 2: return 'Onaylandı';
      case 3: return 'Reddedildi';
      default: return 'Bilinmiyor';
    }
  }

  factory SlnReview.fromJson(Map<String, dynamic> json) {
    DateTime created = DateTime.now();
    final c = json['createdAt'];
    if (c is String) created = DateTime.tryParse(c)?.toLocal() ?? created;
    return SlnReview(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slnClientId: (json['slnClientId'] as num?)?.toInt(),
      clientName: json['clientName'] as String?,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String?,
      sourceId: (json['sourceId'] as num?)?.toInt() ?? 0,
      externalUrl: json['externalUrl'] as String?,
      statusId: (json['statusId'] as num?)?.toInt() ?? 0,
      createdAt: created,
    );
  }
}

class SlnReviewStats {
  SlnReviewStats({
    required this.totalReviews,
    required this.pendingCount,
    required this.approvedCount,
    required this.rejectedCount,
    required this.averageRating,
  });

  final int totalReviews;
  final int pendingCount;
  final int approvedCount;
  final int rejectedCount;
  final double averageRating;

  factory SlnReviewStats.fromJson(Map<String, dynamic> json) {
    return SlnReviewStats(
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pendingCount'] as num?)?.toInt() ?? 0,
      approvedCount: (json['approvedCount'] as num?)?.toInt() ?? 0,
      rejectedCount: (json['rejectedCount'] as num?)?.toInt() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
    );
  }
}

abstract final class ReviewStatuses {
  static const int pending = 1;
  static const int approved = 2;
  static const int rejected = 3;
}
