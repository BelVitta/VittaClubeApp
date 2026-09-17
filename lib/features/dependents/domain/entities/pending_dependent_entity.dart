import 'package:equatable/equatable.dart';

import 'dependent_entity.dart';

/// Um dependente `pending` junto com dados do titular, para a fila de
/// aprovação do admin.
class PendingDependentEntity extends Equatable {
  final DependentEntity dependent;
  final String holderName;
  final String holderEmail;

  const PendingDependentEntity({
    required this.dependent,
    required this.holderName,
    required this.holderEmail,
  });

  @override
  List<Object?> get props => [dependent, holderName, holderEmail];
}
