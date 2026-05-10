// Phase 11 — Expenses (sln-finance/expenses).

class ExpenseCategory {
  ExpenseCategory({required this.id, required this.name});
  final int id;
  final String name;
  factory ExpenseCategory.fromJson(Map<String, dynamic> json) => ExpenseCategory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name']?.toString() ?? '',
      );
}

class Expense {
  Expense({
    required this.id,
    required this.categoryName,
    required this.amount,
    required this.expenseDate,
    required this.paymentMethodId,
    this.description,
  });

  final int id;
  final String categoryName;
  final double amount;
  final DateTime expenseDate;
  final String? description;
  final int paymentMethodId;

  String get paymentLabel {
    switch (paymentMethodId) {
      case 1: return 'Nakit';
      case 2: return 'Kredi Karti';
      case 3: return 'Havale/EFT';
      default: return '-';
    }
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    final dt = json['expenseDate'];
    DateTime date = DateTime.now();
    if (dt is String) date = DateTime.tryParse(dt)?.toLocal() ?? date;
    return Expense(
      id: (json['id'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName']?.toString() ?? '',
      amount: _money(json['amount']),
      expenseDate: date,
      description: json['description'] as String?,
      paymentMethodId: (json['paymentMethodId'] as num?)?.toInt() ?? 1,
    );
  }
}

class ExpenseCreate {
  ExpenseCreate({
    required this.categoryId,
    required this.amount,
    required this.expenseDate,
    this.description,
    this.paymentMethodId = 1,
  });

  final int categoryId;
  final double amount;
  final DateTime expenseDate;
  final String? description;
  final int paymentMethodId;

  Map<String, dynamic> toJson() => {
        'categoryId': categoryId,
        'amount': amount,
        'expenseDate': expenseDate.toUtc().toIso8601String(),
        if (description != null) 'description': description,
        'paymentMethodId': paymentMethodId,
      };
}

double _money(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
