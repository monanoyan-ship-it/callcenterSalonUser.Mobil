class SlnServiceCategory {
  SlnServiceCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.services,
    this.iconClass,
    this.color,
  });

  final int id;
  final String name;
  final String? iconClass;
  final String? color;
  final int sortOrder;
  final bool isActive;
  final List<SlnService> services;

  factory SlnServiceCategory.fromJson(Map<String, dynamic> json) {
    final raw = json['services'] as List<dynamic>? ?? [];
    return SlnServiceCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      iconClass: json['iconClass'] as String?,
      color: json['color'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      services:
          raw.map((e) => SlnService.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class SlnService {
  SlnService({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.isActive,
  });

  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final int durationMinutes;
  final double price;
  final bool isActive;

  factory SlnService.fromJson(Map<String, dynamic> json) {
    return SlnService(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      name: json['name'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SlnServiceCreate {
  SlnServiceCreate({
    required this.categoryId,
    required this.name,
    this.durationMinutes = 30,
    this.price = 0,
  });
  final int categoryId;
  final String name;
  final int durationMinutes;
  final double price;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'name': name,
        'durationMinutes': durationMinutes,
        'price': price,
      };
}

class SlnServiceCategoryCreate {
  SlnServiceCategoryCreate({
    required this.name,
    this.iconClass,
    this.color,
    this.sortOrder = 0,
  });
  final String name;
  final String? iconClass;
  final String? color;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (iconClass != null) 'iconClass': iconClass,
        if (color != null) 'color': color,
        'sortOrder': sortOrder,
      };
}
