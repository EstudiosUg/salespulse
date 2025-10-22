class User {
  final int id;
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String? avatar;
  final bool twoFactorEnabled;
  final bool isPremium;
  final DateTime? premiumExpiresAt;
  final String? theme;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    this.avatar,
    required this.twoFactorEnabled,
    required this.isPremium,
    this.premiumExpiresAt,
    this.theme,
    required this.isActive,
  });

  String get fullName => name.isNotEmpty ? name : '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      // Use avatar_url if available (full URL), otherwise use avatar (filename)
      avatar: json['avatar_url'] ?? json['avatar'],
      twoFactorEnabled:
          json['two_factor_enabled'] == 1 || json['two_factor_enabled'] == true,
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
      premiumExpiresAt: json['premium_expires_at'] != null
          ? DateTime.parse(json['premium_expires_at'])
          : null,
      theme: json['theme'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'avatar': avatar,
      'two_factor_enabled': twoFactorEnabled,
      'is_premium': isPremium,
      'premium_expires_at': premiumExpiresAt?.toIso8601String(),
      'theme': theme,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'theme': theme,
    };
  }
}

class AuthResponse {
  final User user;
  final String token;
  final String tokenType;

  AuthResponse({
    required this.user,
    required this.token,
    required this.tokenType,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? 'Bearer',
    );
  }
}
