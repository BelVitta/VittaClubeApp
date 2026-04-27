import 'package:equatable/equatable.dart';

/// Entidade de plano no painel admin - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class PlanAdminEntity extends Equatable {
  final String id;
  final String name;
  final String subscriptionType;
  final double price;
  final String? discountLabel;
  final List<String> benefits;
  final bool isActive;

  const PlanAdminEntity({
    required this.id,
    required this.name,
    required this.subscriptionType,
    required this.price,
    this.discountLabel,
    required this.benefits,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        subscriptionType,
        price,
        discountLabel,
        benefits,
        isActive,
      ];
}
