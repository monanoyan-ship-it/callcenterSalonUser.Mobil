/// Kasa (cash register) — `GET /api/sln-finance/cash-registers`. Backend anonymous,
/// asagidaki alanlar javascript Cash.js'in basvurdugu set.
class CashRegister {
  CashRegister({
    required this.id,
    required this.name,
    required this.isActive,
    this.branchId,
    this.branchName,
    this.balance = 0,
  });

  final int id;
  final String name;
  final int? branchId;
  final String? branchName;
  final bool isActive;
  final double balance;

  factory CashRegister.fromJson(Map<String, dynamic> json) {
    return CashRegister(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName']?.toString(),
      isActive: json['isActive'] as bool? ?? true,
      balance: _money(json['balance']),
    );
  }
}

/// `GET /api/sln-finance/cash-registers/{id}/transactions`.
class CashTransaction {
  CashTransaction({
    required this.id,
    required this.transactionTypeId,
    required this.amount,
    required this.description,
    required this.paymentMethodId,
    required this.createdAt,
    this.registerName,
  });

  final int id;
  final String? registerName;
  final int transactionTypeId; // 1=Gelir, 2=Gider, 3=Transfer
  final double amount;
  final String description;
  final int paymentMethodId; // 1=Nakit, 2=KrediKarti
  final DateTime createdAt;

  bool get isIncome => transactionTypeId == 1;
  bool get isExpense => transactionTypeId == 2;
  bool get isTransfer => transactionTypeId == 3;

  String get typeLabel {
    switch (transactionTypeId) {
      case 1: return 'Gelir';
      case 2: return 'Gider';
      case 3: return 'Transfer';
      default: return 'Diger';
    }
  }

  String get paymentLabel {
    switch (paymentMethodId) {
      case 1: return 'Nakit';
      case 2: return 'Kredi Karti';
      case 3: return 'Havale/EFT';
      default: return '-';
    }
  }

  factory CashTransaction.fromJson(Map<String, dynamic> json) {
    final dt = json['createdAt'];
    DateTime created = DateTime.now();
    if (dt is String) {
      created = DateTime.tryParse(dt)?.toLocal() ?? created;
    }
    return CashTransaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      registerName: json['registerName'] as String?,
      transactionTypeId: (json['transactionTypeId'] as num?)?.toInt() ?? 0,
      amount: _money(json['amount']),
      description: json['description']?.toString() ?? '',
      paymentMethodId: (json['paymentMethodId'] as num?)?.toInt() ?? 0,
      createdAt: created,
    );
  }
}

/// `POST /api/sln-finance/cash-registers/{id}/transactions` body.
class CashTransactionCreate {
  CashTransactionCreate({
    required this.transactionTypeId,
    required this.amount,
    required this.description,
    this.paymentMethodId = 1,
  });

  final int transactionTypeId;
  final double amount;
  final String description;
  final int paymentMethodId;

  Map<String, dynamic> toJson() => {
        'transactionTypeId': transactionTypeId,
        'amount': amount,
        'description': description,
        'paymentMethodId': paymentMethodId,
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
