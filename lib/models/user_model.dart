class User {
  final int? id;
  final String name;
  final String email;
  final String? password;
  final String? token;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.token,
    this.createdAt,
    this.updatedAt,
  });

  // Untuk konversi dari JSON (response dari API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  // Untuk konversi ke JSON (request ke API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'token': token,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Untuk menyimpan ke local storage (SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
    };
  }

  // Untuk mengambil dari local storage
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      token: map['token'],
    );
  }

  // Copy with method untuk update data
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? token,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Model untuk request login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

// Model untuk request register
class RegisterRequest {
  final String name;
  final String email;
  final String password;
  final String? passwordConfirmation;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
    this.passwordConfirmation,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation ?? password,
    };
  }
}