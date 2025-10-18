class Sale {
  final String id;
  final String productName;
  final double price;
  final int quantity;
  final double commission;
  final bool commissionPaid;
  final int? supplierId;
  final String? supplierName;
  final String? feedback;
  final DateTime saleDate;

  Sale({
    required this.id,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.commission,
    required this.commissionPaid,
    this.supplierId,
    this.supplierName,
    this.feedback,
    required this.saleDate,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id']?.toString() ?? '',
      productName: json['product_name'] ?? '',
      price: _parseDouble(json['price']),
      quantity: _parseInt(json['quantity']),
      commission: _parseDouble(json['commission']),
      commissionPaid:
          json['commission_paid'] == 1 || json['commission_paid'] == true,
      supplierId: json['supplier_id'],
      supplierName: json['supplier']?['name'] ?? json['supplier_name'],
      feedback: json['feedback'],
      saleDate: DateTime.parse(json['sale_date'] ??
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

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.parse(value);
    return 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'product_name': productName,
      'price': price,
      'quantity': quantity,
      'commission': commission,
      'commission_paid': commissionPaid,
      'supplier_id': supplierId,
      'feedback': feedback,
      'sale_date':
          saleDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
    };
  }

  double get totalAmount => price * quantity;
  double get netEarning => totalAmount - commission;
}
