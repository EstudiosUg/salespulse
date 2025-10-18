class Supplier {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? address;
  final String? notes;
  final bool isActive;

  Supplier({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.address,
    this.notes,
    required this.isActive,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      notes: json['notes'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'notes': notes,
      'is_active': isActive,
    };
  }
}
