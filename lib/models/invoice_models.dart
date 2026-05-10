/// Adisyon (Sales/Invoices) — `GET /api/sln-finance/invoices`.
class SlnInvoice {
  SlnInvoice({
    required this.id,
    required this.invoiceNo,
    required this.invoiceDate,
    required this.totalAmount,
    required this.discountAmount,
    required this.netAmount,
    required this.paymentMethodId,
    required this.statusId,
    required this.tipAmount,
    required this.items,
    this.clientName,
    this.personnelName,
  });

  final int id;
  final String invoiceNo;
  final DateTime invoiceDate;
  final String? clientName;
  final double totalAmount;
  final double discountAmount;
  final double netAmount;
  final int paymentMethodId;
  final String? personnelName;
  final int statusId;
  final double tipAmount;
  final List<SlnInvoiceItem> items;

  /// 1=Acik (odenmemis), 2=Odendi, 3=Iptal, 4=Iade.
  bool get isOpen => statusId == 1;
  bool get isPaid => statusId == 2;
  bool get isCancelled => statusId == 3;
  bool get isRefunded => statusId == 4;

  factory SlnInvoice.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final dateRaw = json['invoiceDate'];
    DateTime date = DateTime.now();
    if (dateRaw is String) {
      date = DateTime.tryParse(dateRaw)?.toLocal() ?? date;
    } else if (dateRaw != null) {
      date = DateTime.tryParse(dateRaw.toString())?.toLocal() ?? date;
    }

    return SlnInvoice(
      id: (json['id'] as num?)?.toInt() ?? 0,
      invoiceNo: json['invoiceNo']?.toString() ?? '',
      invoiceDate: date,
      clientName: json['clientName'] as String?,
      totalAmount: _money(json['totalAmount']),
      discountAmount: _money(json['discountAmount']),
      netAmount: _money(json['netAmount']),
      paymentMethodId: (json['paymentMethodId'] as num?)?.toInt() ?? 0,
      personnelName: json['personnelName'] as String?,
      statusId: (json['statusId'] as num?)?.toInt() ?? 1,
      tipAmount: _money(json['tipAmount']),
      items: rawItems
          .map((e) => SlnInvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SlnInvoiceItem {
  SlnInvoiceItem({
    required this.id,
    required this.itemName,
    required this.quantity,
    required this.unitPrice,
    required this.discountAmount,
    required this.lineTotal,
    this.personnelName,
  });

  final int id;
  final String itemName;
  final String? personnelName;
  final double quantity;
  final double unitPrice;
  final double discountAmount;
  final double lineTotal;

  factory SlnInvoiceItem.fromJson(Map<String, dynamic> json) {
    return SlnInvoiceItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemName: json['itemName']?.toString() ?? '',
      personnelName: json['personnelName'] as String?,
      quantity: _money(json['quantity']),
      unitPrice: _money(json['unitPrice']),
      discountAmount: _money(json['discountAmount']),
      lineTotal: _money(json['lineTotal']),
    );
  }
}

/// `POST /api/sln-finance/invoices` body — yeni adisyon.
class SlnInvoiceCreate {
  SlnInvoiceCreate({
    this.slnClientId,
    this.paymentMethodId = 1,
    this.giftCardCode,
    this.posDeviceId,
    this.discountAmount = 0,
    this.tipAmount = 0,
    this.includeTipInTotal = false,
    this.notes,
    required this.items,
  });

  final int? slnClientId;
  final int paymentMethodId;
  final String? giftCardCode;
  final int? posDeviceId;
  final double discountAmount;
  final double tipAmount;
  final bool includeTipInTotal;
  final String? notes;
  final List<SlnInvoiceItemCreate> items;

  Map<String, dynamic> toJson() => {
        if (slnClientId != null) 'slnClientId': slnClientId,
        'paymentMethodId': paymentMethodId,
        if (giftCardCode != null && giftCardCode!.isNotEmpty)
          'giftCardCode': giftCardCode,
        if (posDeviceId != null) 'posDeviceId': posDeviceId,
        'discountAmount': discountAmount,
        'tipAmount': tipAmount,
        'includeTipInTotal': includeTipInTotal,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class SlnInvoiceItemCreate {
  SlnInvoiceItemCreate({
    this.serviceId,
    this.productId,
    this.personnelId,
    this.quantity = 1,
    required this.unitPrice,
    this.discountAmount = 0,
  });

  final int? serviceId;
  final int? productId;
  final int? personnelId;
  final double quantity;
  final double unitPrice;
  final double discountAmount;

  Map<String, dynamic> toJson() => {
        if (serviceId != null) 'serviceId': serviceId,
        if (productId != null) 'productId': productId,
        if (personnelId != null) 'personnelId': personnelId,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'discountAmount': discountAmount,
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// Web Sales.js parite — odeme tipi.
enum InvoicePaymentMethod {
  cash(1, 'Nakit'),
  creditCard(2, 'Kredi Karti'),
  bankTransfer(3, 'Havale/EFT'),
  giftCard(4, 'Hediye Kart'),
  loyaltyPoint(5, 'Puan');

  const InvoicePaymentMethod(this.id, this.label);
  final int id;
  final String label;

  static InvoicePaymentMethod fromId(int id) {
    return values.firstWhere(
      (e) => e.id == id,
      orElse: () => InvoicePaymentMethod.cash,
    );
  }
}
