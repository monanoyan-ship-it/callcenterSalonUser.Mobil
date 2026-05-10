// Phase 11.7 — Personnel Service Prices (sln-personnel-prices).

class PersonnelServicePrice {
  PersonnelServicePrice({
    required this.id,
    required this.personnelId,
    required this.personnelName,
    required this.serviceId,
    required this.serviceName,
    required this.price,
  });

  final int id;
  final int personnelId;
  final String personnelName;
  final int serviceId;
  final String serviceName;
  final double price;

  factory PersonnelServicePrice.fromJson(Map<String, dynamic> json) {
    return PersonnelServicePrice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      personnelId: (json['personnelId'] as num?)?.toInt() ?? 0,
      personnelName: json['personnelName']?.toString() ?? '',
      serviceId: (json['serviceId'] as num?)?.toInt() ?? 0,
      serviceName: json['serviceName']?.toString() ?? '',
      price: _money(json['price']),
    );
  }
}

class PersonnelServicePriceCreate {
  PersonnelServicePriceCreate({
    required this.personnelId,
    required this.serviceId,
    required this.price,
  });

  final int personnelId;
  final int serviceId;
  final double price;

  Map<String, dynamic> toJson() => {
        'personnelId': personnelId,
        'serviceId': serviceId,
        'price': price,
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
