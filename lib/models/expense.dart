class Expense {
  final String id;
  final String title;
  final double amount;
  final String? description;
  final DateTime expenseDate;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    this.description,
    required this.expenseDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      amount: _parseDouble(json['amount']),
      description: json['description'],
      expenseDate: DateTime.parse(json['expense_date'] ??
          json['date'] ??
          DateTime.now().toIso8601String()),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'amount': amount,
      'description': description,
      'expense_date':
          expenseDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
    };
  }

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    String? description,
    DateTime? expenseDate,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
    );
  }
}
