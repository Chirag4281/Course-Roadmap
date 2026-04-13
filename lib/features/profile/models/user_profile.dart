import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String highestQualification;

  @HiveField(3)
  final List<String> interests;

  @HiveField(4)
  final DateTime createdAt;

  UserProfile({
    required this.name,
    required this.email,
    required this.highestQualification,
    required this.interests,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserProfile.empty() => UserProfile(
    name: '',
    email: '',
    highestQualification: '',
    interests: [],
  );
}