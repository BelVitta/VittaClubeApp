import '../../domain/entities/user_admin_entity.dart';

/// Model de usuario admin - DTO para serializacao.
/// Estende UserAdminEntity e adiciona metodos fromJson/toJson.
class UserAdminModel extends UserAdminEntity {
  const UserAdminModel({
    required super.id,
    required super.name,
    required super.email,
    required super.cpf,
    required super.phone,
    super.currentPlanId,
    required super.planLevelName,
    required super.status,
    required super.memberSince,
    super.planActivationDate,
    super.consultationCountThisMonth,
    super.totalReferralCount,
    super.role,
  });

  /// Cria UserAdminModel a partir de JSON
  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      cpf: json['cpf'] as String,
      phone: json['phone'] as String,
      currentPlanId: json['currentPlanId'] as String?,
      planLevelName: json['planLevelName'] as String,
      status: json['status'] as String,
      memberSince: json['memberSince'] as String,
      planActivationDate: json['planActivationDate'] as String?,
      consultationCountThisMonth:
          json['consultationCountThisMonth'] as int? ?? 0,
      totalReferralCount: json['totalReferralCount'] as int? ?? 0,
      role: json['role'] as String? ?? 'user',
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'cpf': cpf,
      'phone': phone,
      'currentPlanId': currentPlanId,
      'planLevelName': planLevelName,
      'status': status,
      'memberSince': memberSince,
      'planActivationDate': planActivationDate,
      'consultationCountThisMonth': consultationCountThisMonth,
      'totalReferralCount': totalReferralCount,
      'role': role,
    };
  }

  /// Cria UserAdminModel a partir de UserAdminEntity
  factory UserAdminModel.fromEntity(UserAdminEntity entity) {
    return UserAdminModel(
      id: entity.id,
      name: entity.name,
      email: entity.email,
      cpf: entity.cpf,
      phone: entity.phone,
      currentPlanId: entity.currentPlanId,
      planLevelName: entity.planLevelName,
      status: entity.status,
      memberSince: entity.memberSince,
      planActivationDate: entity.planActivationDate,
      consultationCountThisMonth: entity.consultationCountThisMonth,
      totalReferralCount: entity.totalReferralCount,
      role: entity.role,
    );
  }
}
