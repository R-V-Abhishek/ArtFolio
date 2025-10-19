import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { artist, audience, sponsor, organisation }

class User {

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.profilePictureUrl,
    required this.bio,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create User object from Map
  factory User.fromMap(Map<String, dynamic> map) => User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      profilePictureUrl: map['profilePictureUrl'] ?? '',
      bio: map['bio'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.audience,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );

  // Create User object from Firestore DocumentSnapshot
  factory User.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data()! as Map<String, dynamic>;
    return User.fromMap(data);
  }
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String profilePictureUrl;
  final String bio;
  final UserRole role;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Convert User object to Map for Firestore
  Map<String, dynamic> toMap() => {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'bio': bio,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

  // Copy with method for updating fields
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? profilePictureUrl,
    String? bio,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );

  @override
  String toString() => 'User(id: $id, username: $username, email: $email, fullName: $fullName, role: $role)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
