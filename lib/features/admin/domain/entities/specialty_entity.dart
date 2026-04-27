import 'package:equatable/equatable.dart';

/// Entidade de especialidade médica - objeto de negócio puro.
/// Não possui dependências de Flutter ou packages externos.
class SpecialtyEntity extends Equatable {
  final String id;
  final String name;
  final bool isActive;

  const SpecialtyEntity({
    required this.id,
    required this.name,
    required this.isActive,
  });

  @override
  List<Object?> get props => [id, name, isActive];
}
