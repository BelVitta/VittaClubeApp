import 'package:equatable/equatable.dart';

import 'dependent_enums.dart';

class DependentEntity extends Equatable {
  final String id;
  final String holderUserId;
  final String name;
  final String cpf;
  final DateTime birthDate;
  final String relationship;
  final DependentStatus status;
  final DateTime createdAt;
  final String? rejectionReason;

  const DependentEntity({
    required this.id,
    required this.holderUserId,
    required this.name,
    required this.cpf,
    required this.birthDate,
    required this.relationship,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
  });

  bool get isActive => status == DependentStatus.active;
  bool get isPending => status == DependentStatus.pending;

  @override
  List<Object?> get props => [
        id,
        holderUserId,
        name,
        cpf,
        birthDate,
        relationship,
        status,
        createdAt,
        rejectionReason,
      ];
}
