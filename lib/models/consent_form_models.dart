// Phase 11.4 — Consent Forms (sln-consent-forms).

class ConsentForm {
  ConsentForm({
    required this.id,
    required this.title,
    required this.htmlContent,
    required this.requireSignature,
    required this.isActive,
    required this.signedCount,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String htmlContent;
  final bool requireSignature;
  final bool isActive;
  final int signedCount;
  final DateTime createdAt;

  factory ConsentForm.fromJson(Map<String, dynamic> json) {
    DateTime parse(dynamic v) {
      if (v is String && v.isNotEmpty) return DateTime.tryParse(v)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }
    return ConsentForm(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      htmlContent: json['htmlContent']?.toString() ?? '',
      requireSignature: json['requireSignature'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      signedCount: (json['signedCount'] as num?)?.toInt() ?? 0,
      createdAt: parse(json['createdAt']),
    );
  }
}

class ConsentFormCreate {
  ConsentFormCreate({
    required this.title,
    required this.htmlContent,
    this.requireSignature = false,
    this.isActive = true,
  });

  final String title;
  final String htmlContent;
  final bool requireSignature;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'title': title,
        'htmlContent': htmlContent,
        'requireSignature': requireSignature,
        'isActive': isActive,
      };
}
