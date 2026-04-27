import 'package:equatable/equatable.dart';

/// Entidade de usuário no painel admin - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class UserAdminEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String cpf;
  final String phone;
  final String? currentPlanId;
  final String planLevelName;
  final String status;
  final String memberSince;
  final String? planActivationDate;
  final int consultationCountThisMonth;
  final int totalReferralCount;
  final String role;

  const UserAdminEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.cpf,
    required this.phone,
    this.currentPlanId,
    required this.planLevelName,
    required this.status,
    required this.memberSince,
    this.planActivationDate,
    this.consultationCountThisMonth = 0,
    this.totalReferralCount = 0,
    this.role = 'user',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        cpf,
        phone,
        currentPlanId,
        planLevelName,
        status,
        memberSince,
        planActivationDate,
        consultationCountThisMonth,
        totalReferralCount,
        role,
      ];
}
