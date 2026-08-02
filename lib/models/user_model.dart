class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role;
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.createdAt,
  });

  // ------------------------------------------------------------
  // CREATE MODEL FROM FIRESTORE DATA
  // ------------------------------------------------------------

  factory UserModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  // ------------------------------------------------------------
  // CONVERT MODEL TO FIRESTORE DATA
  // ------------------------------------------------------------

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt,
    };
  }

  // ------------------------------------------------------------
  // COPY WITH
  // ------------------------------------------------------------

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ------------------------------------------------------------
  // DATE CONVERSION
  // ------------------------------------------------------------

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value;
    }

    // Handles Firebase Timestamp without importing Firebase
    // types directly into this model.
    if (value.runtimeType.toString() == 'Timestamp') {
      try {
        return value.toDate();
      } catch (_) {
        return null;
      }
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}