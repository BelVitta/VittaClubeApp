import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.avatarUrl,
    required super.role,
    required super.memberSince,
    super.memberCode,
    super.receptionistCode,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final memberSinceRaw = json['member_since'];
    DateTime memberSince;
    if (memberSinceRaw is String && memberSinceRaw.isNotEmpty) {
      memberSince = DateTime.tryParse(memberSinceRaw) ?? DateTime.now();
    } else if (memberSinceRaw is DateTime) {
      memberSince = memberSinceRaw;
    } else {
      memberSince = DateTime.now();
    }

    return ProfileModel(
      id: json['id'] as String,
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: (json['role'] as String?) ?? 'user',
      memberSince: memberSince,
      memberCode: json['member_code'] as String?,
      receptionistCode: json['receptionist_code'] as String?,
    );
  }
}
