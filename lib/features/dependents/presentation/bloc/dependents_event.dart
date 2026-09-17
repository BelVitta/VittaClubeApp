import 'package:equatable/equatable.dart';

import '../../domain/entities/dependent_enums.dart';

abstract class DependentsEvent extends Equatable {
  const DependentsEvent();

  @override
  List<Object?> get props => [];
}

class LoadDependents extends DependentsEvent {
  final String holderUserId;
  final String cycleReference;

  /// `null` (default) = todos os status — é o que a tela do titular precisa
  /// pra mostrar o badge de "pendente de aprovação".
  final DependentStatus? status;

  const LoadDependents({
    required this.holderUserId,
    required this.cycleReference,
    this.status,
  });

  @override
  List<Object?> get props => [holderUserId, cycleReference, status];
}

class CreateDependentRequested extends DependentsEvent {
  final String holderUserId;
  final String name;
  final String cpf;
  final DateTime birthDate;
  final String relationship;

  const CreateDependentRequested({
    required this.holderUserId,
    required this.name,
    required this.cpf,
    required this.birthDate,
    required this.relationship,
  });

  @override
  List<Object?> get props => [holderUserId, name, cpf, birthDate, relationship];
}

class DeactivateDependentRequested extends DependentsEvent {
  final String holderUserId;
  final String dependentId;

  const DeactivateDependentRequested({
    required this.holderUserId,
    required this.dependentId,
  });

  @override
  List<Object?> get props => [holderUserId, dependentId];
}
