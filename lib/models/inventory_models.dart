// Phase 9 — Envanter modelleri (Products / Suppliers / Recipes).
// Backend SlnProductDto, SlnSupplierDto, SlnRecipeDto ile birebir.

class SlnProduct {
  SlnProduct({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.purchasePrice,
    required this.salePrice,
    required this.stockQuantity,
    required this.minStockLevel,
    required this.unit,
    required this.isActive,
    this.barcode,
    this.brandName,
  });

  final int id;
  final String name;
  final String? barcode;
  final String categoryName;
  final String? brandName;
  final double purchasePrice;
  final double salePrice;
  final double stockQuantity;
  final double minStockLevel;
  final String unit;
  final bool isActive;

  bool get isLowStock => stockQuantity <= minStockLevel;

  factory SlnProduct.fromJson(Map<String, dynamic> json) {
    return SlnProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      barcode: json['barcode'] as String?,
      categoryName: json['categoryName']?.toString() ?? '',
      brandName: json['brandName'] as String?,
      purchasePrice: _money(json['purchasePrice']),
      salePrice: _money(json['salePrice']),
      stockQuantity: _money(json['stockQuantity']),
      minStockLevel: _money(json['minStockLevel']),
      unit: json['unit']?.toString() ?? 'Adet',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SlnProductCreate {
  SlnProductCreate({
    required this.categoryId,
    required this.name,
    this.brandId,
    this.barcode,
    this.purchasePrice = 0,
    this.salePrice = 0,
    this.stockQuantity = 0,
    this.minStockLevel = 0,
    this.unit = 'Adet',
  });

  final int categoryId;
  final int? brandId;
  final String name;
  final String? barcode;
  final double purchasePrice;
  final double salePrice;
  final double stockQuantity;
  final double minStockLevel;
  final String unit;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        if (brandId != null) 'brandId': brandId,
        'name': name,
        if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
        'purchasePrice': purchasePrice,
        'salePrice': salePrice,
        'stockQuantity': stockQuantity,
        'minStockLevel': minStockLevel,
        'unit': unit,
      };
}

class SlnProductCategory {
  SlnProductCategory({required this.id, required this.name});
  final int id;
  final String name;

  factory SlnProductCategory.fromJson(Map<String, dynamic> json) =>
      SlnProductCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class SlnBrand {
  SlnBrand({required this.id, required this.name});
  final int id;
  final String name;

  factory SlnBrand.fromJson(Map<String, dynamic> json) => SlnBrand(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class SlnSupplier {
  SlnSupplier({
    required this.id,
    required this.name,
    required this.balance,
    required this.isActive,
    this.contactPerson,
    this.phone,
    this.email,
  });

  final int id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final double balance;
  final bool isActive;

  factory SlnSupplier.fromJson(Map<String, dynamic> json) {
    return SlnSupplier(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      contactPerson: json['contactPerson'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      balance: _money(json['balance']),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class SlnSupplierCreate {
  SlnSupplierCreate({
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.taxNumber,
    this.notes,
  });

  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNumber;
  final String? notes;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (contactPerson != null) 'contactPerson': contactPerson,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (taxNumber != null) 'taxNumber': taxNumber,
        if (notes != null) 'notes': notes,
      };
}

class SlnRecipe {
  SlnRecipe({
    required this.id,
    required this.name,
    required this.estimatedCost,
    required this.isActive,
    required this.items,
    this.description,
    this.iconClass,
    this.serviceId,
    this.serviceName,
    this.photoUrl,
  });

  final int id;
  final String name;
  final String? description;
  final String? iconClass;
  final int? serviceId;
  final String? serviceName;
  final double estimatedCost;
  final String? photoUrl;
  final bool isActive;
  final List<SlnRecipeItem> items;

  factory SlnRecipe.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List<dynamic>? ?? [];
    return SlnRecipe(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      iconClass: json['iconClass'] as String?,
      serviceId: (json['serviceId'] as num?)?.toInt(),
      serviceName: json['serviceName'] as String?,
      estimatedCost: _money(json['estimatedCost']),
      photoUrl: json['photoUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      items: raw
          .map((e) => SlnRecipeItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SlnRecipeItem {
  SlnRecipeItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.cost,
    required this.sortOrder,
    this.notes,
  });

  final int id;
  final int productId;
  final String productName;
  final double quantity;
  final String unit;
  final double cost;
  final String? notes;
  final int sortOrder;

  factory SlnRecipeItem.fromJson(Map<String, dynamic> json) {
    return SlnRecipeItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName']?.toString() ?? '',
      quantity: _money(json['quantity']),
      unit: json['unit']?.toString() ?? 'gr',
      cost: _money(json['cost']),
      notes: json['notes'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }
}

class SlnRecipeCreate {
  SlnRecipeCreate({
    required this.name,
    this.description,
    this.iconClass,
    this.serviceId,
    this.photoUrl,
    this.isActive = true,
    required this.items,
  });

  final String name;
  final String? description;
  final String? iconClass;
  final int? serviceId;
  final String? photoUrl;
  final bool isActive;
  final List<SlnRecipeItemCreate> items;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        if (iconClass != null) 'iconClass': iconClass,
        if (serviceId != null) 'serviceId': serviceId,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'isActive': isActive,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class SlnRecipeItemCreate {
  SlnRecipeItemCreate({
    required this.productId,
    this.quantity = 1,
    this.unit = 'gr',
    this.notes,
    this.sortOrder = 0,
  });

  final int productId;
  final double quantity;
  final String unit;
  final String? notes;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
        'unit': unit,
        if (notes != null) 'notes': notes,
        'sortOrder': sortOrder,
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
