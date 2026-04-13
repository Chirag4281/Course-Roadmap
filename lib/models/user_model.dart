class User {
  final String id;
  final String name;
  final String email;
  final String? highestQualification;
  final List<String> interests;
  final DateTime createdAt;
  final DateTime? profileCompletedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.highestQualification,
    this.interests = const [],
    required this.createdAt,
    this.profileCompletedAt,
  });

  bool get isProfileComplete =>
      highestQualification != null && interests.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'highest_qualification': highestQualification,
      'profile_completed_at': profileCompletedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      highestQualification: map['highest_qualification'] as String?,
      interests: [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      profileCompletedAt: map['profile_completed_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['profile_completed_at'] as int)
          : null,
    );
  }

  User copyWith({
    String? name,
    String? email,
    String? highestQualification,
    List<String>? interests,
    DateTime? profileCompletedAt,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      highestQualification: highestQualification ?? this.highestQualification,
      interests: interests ?? this.interests,
      createdAt: createdAt,
      profileCompletedAt: profileCompletedAt ?? this.profileCompletedAt,
    );
  }
}