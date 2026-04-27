import 'package:equatable/equatable.dart';
import 'subscription_type.dart';

/// Entidade que representa um benefício do plano
class PlanBenefit extends Equatable {
  final String title;
  final String description;

  const PlanBenefit({
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [title, description];
}

/// Entidade que representa um plano de assinatura
class PlanEntity extends Equatable {
  final SubscriptionType type;
  final List<PlanBenefit> benefits;

  const PlanEntity({
    required this.type,
    required this.benefits,
  });

  @override
  List<Object?> get props => [type, benefits];
}
