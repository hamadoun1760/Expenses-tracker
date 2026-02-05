import 'dart:typed_data';

class User {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final Uint8List? profilePicture;
  final DateTime? dateOfBirth;
  final String? address;
  final String? bio;
  final String defaultCurrency;
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final bool biometricEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.profilePicture,
    this.dateOfBirth,
    this.address,
    this.bio,
    this.defaultCurrency = 'EUR',
    this.language = 'fr',
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.biometricEnabled = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';
  
  String get initials {
    String first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    Uint8List? profilePicture,
    DateTime? dateOfBirth,
    String? address,
    String? bio,
    String? defaultCurrency,
    String? language,
    String? theme,
    bool? notificationsEnabled,
    bool? biometricEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePicture: profilePicture ?? this.profilePicture,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'date_of_birth': dateOfBirth?.millisecondsSinceEpoch,
      'address': address,
      'bio': bio,
      'default_currency': defaultCurrency,
      'language': language,
      'theme': theme,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'biometric_enabled': biometricEnabled ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      firstName: map['first_name'] ?? '',
      lastName: map['last_name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phone_number'],
      profilePicture: map['profile_picture'],
      dateOfBirth: map['date_of_birth'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['date_of_birth']) 
          : null,
      address: map['address'],
      bio: map['bio'],
      defaultCurrency: map['default_currency'] ?? 'EUR',
      language: map['language'] ?? 'fr',
      theme: map['theme'] ?? 'system',
      notificationsEnabled: map['notifications_enabled'] == 1,
      biometricEnabled: map['biometric_enabled'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, firstName: $firstName, lastName: $lastName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}