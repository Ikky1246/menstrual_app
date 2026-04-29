// lib/models/user_model.dart

class User {
  final int? idUser;
  final String name;
  final String email;
  final String? password;
  final String? token;
  final String? status;
  final String? namaLengkap;
  final String? noTelepon;
  final int? age;
  final double? weightKg;
  final double? heightCm;
  final double? bmi;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    this.idUser,
    required this.name,
    required this.email,
    this.password,
    this.token,
    this.status,
    this.namaLengkap,
    this.noTelepon,
    this.age,
    this.weightKg,
    this.heightCm,
    this.bmi,
    this.createdAt,
    this.updatedAt,
  });

  // From JSON (response dari API)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser: json['id_user'] ?? json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      status: json['status'] ?? 'Aktif',
      namaLengkap: json['nama_lengkap'],
      noTelepon: json['no_telepon'],
      age: json['age'],
      weightKg: json['weight_kg']?.toDouble(),
      heightCm: json['height_cm']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  // To JSON (request ke API)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      if (password != null) 'password': password,
      if (namaLengkap != null) 'nama_lengkap': namaLengkap,
      if (noTelepon != null) 'no_telepon': noTelepon,
      if (age != null) 'age': age,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
    };
  }

  // To Map (untuk local storage)
  Map<String, dynamic> toMap() {
    return {
      'id_user': idUser,
      'name': name,
      'email': email,
      'token': token,
      'status': status,
      'nama_lengkap': namaLengkap,
      'no_telepon': noTelepon,
      'age': age,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'bmi': bmi,
    };
  }

  // From Map (dari local storage)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      idUser: map['id_user'] ?? map['id'] ?? 0,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      token: map['token'],
      status: map['status'] ?? 'Aktif',
      namaLengkap: map['nama_lengkap'],
      noTelepon: map['no_telepon'],
      age: map['age']?.toInt(),
      weightKg: map['weight_kg']?.toDouble(),
      heightCm: map['height_cm']?.toDouble(),
      bmi: map['bmi']?.toDouble(),
    );
  }

  // Cek apakah onboarding sudah lengkap
  bool get isOnboardingComplete {
    return namaLengkap != null &&
           namaLengkap!.isNotEmpty &&
           noTelepon != null &&
           noTelepon!.isNotEmpty &&
           age != null;
  }

  // Copy with
  User copyWith({
    int? idUser,
    String? name,
    String? email,
    String? password,
    String? token,
    String? status,
    String? namaLengkap,
    String? noTelepon,
    int? age,
    double? weightKg,
    double? heightCm,
    double? bmi,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      idUser: idUser ?? this.idUser,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      token: token ?? this.token,
      status: status ?? this.status,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      noTelepon: noTelepon ?? this.noTelepon,
      age: age ?? this.age,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bmi: bmi ?? this.bmi,
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

// Model untuk update profile (onboarding)
class UpdateProfileRequest {
  final String? namaLengkap;
  final String? noTelepon;
  final int? age;
  final double? weightKg;
  final double? heightCm;

  UpdateProfileRequest({
    this.namaLengkap,
    this.noTelepon,
    this.age,
    this.weightKg,
    this.heightCm,
  });

  Map<String, dynamic> toJson() {
    return {
      if (namaLengkap != null) 'nama_lengkap': namaLengkap,
      if (noTelepon != null) 'no_telepon': noTelepon,
      if (age != null) 'age': age,
      if (weightKg != null) 'weight_kg': weightKg,
      if (heightCm != null) 'height_cm': heightCm,
    };
  }
}